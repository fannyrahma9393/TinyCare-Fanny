import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../utils/api_error.dart';
import 'network_status_service.dart';
import 'offline_cache_service.dart';

/// The states a data page can be in.
enum ResourceStatus {
  /// First load, nothing renderable yet (show a loading indicator).
  loading,

  /// Fresh data received from the backend.
  online,

  /// Showing the last cached payload because the backend could not be reached.
  offline,

  /// The backend answered and there is genuinely nothing to show.
  empty,

  /// The request failed and no cached payload exists.
  error,
}

/// Cache-first loader shared by every parent-facing page.
///
/// Read strategy (offline-cache spec):
/// 1. read the cached payload of the current user and render it immediately,
/// 2. request the API,
/// 3. on success use the fresh payload, overwrite the cache, stamp lastUpdated,
/// 4. on a reachability failure keep the cached payload and report
///    [ResourceStatus.offline] instead of pretending the data is empty,
/// 5. on a real API error (4xx) report [ResourceStatus.error] — cached data is
///    never used to mask an authentication or permission failure.
///
/// A 401 keeps following the existing authentication flow (the Dio interceptor
/// in `ApiService` clears the session). This controller never logs anyone out
/// and never treats a network error as an invalid session.
class CachedResource<T> {
  CachedResource({required this.onChanged, this.isEmptyData});

  /// Invoked on every state transition so the owning widget can rebuild.
  final VoidCallback onChanged;

  /// Overrides how "the API answered with nothing useful" is decided. When it
  /// returns true the resource reports [ResourceStatus.empty] instead of
  /// [ResourceStatus.online], so pages can show a proper empty state.
  final bool Function(T data)? isEmptyData;

  T? _data;
  ResourceStatus _status = ResourceStatus.loading;
  DateTime? _lastUpdated;
  bool _fromCache = false;
  bool _pending = false;
  String? _error;

  /// The payload currently displayed (fresh or cached).
  T? get data => _data;

  ResourceStatus get status => _status;

  /// When the displayed payload was last received from the backend.
  DateTime? get lastUpdated => _lastUpdated;

  /// Whether the displayed payload came from the local cache.
  bool get isFromCache => _fromCache;

  /// A request is in flight.
  bool get isPending => _pending;

  /// Full-screen loading: a request is running and nothing is renderable yet.
  bool get isLoading => _pending && _data == null;

  /// Light refresh: a request is running on top of an already visible payload.
  bool get isRefreshing => _pending && _data != null;

  bool get hasData => _data != null;

  bool get isOffline => _status == ResourceStatus.offline;

  bool get isEmpty => _status == ResourceStatus.empty;

  bool get hasError => _error != null;

  /// Failure text (a localization key), or null.
  String? get error => _error;

  /// Default failure key used when the API gives no better message.
  static const String defaultErrorKey = 'Gagal memuat data.';

  /// Cache-first load.
  ///
  /// [fetch] performs the API request. Safe to `await` from a pull-to-refresh
  /// handler: when the request fails but a cache exists, the cached payload
  /// stays on screen instead of an error page.
  Future<void> load({
    required String cacheKey,
    required Future<T> Function() fetch,
    String errorKey = defaultErrorKey,
  }) async {
    if (_pending) return;

    // 1. Render the last payload this user received, without waiting for HTTP.
    final entry = await OfflineCacheService.instance.read(cacheKey);
    if (entry != null && entry.data != null) {
      final cached = _decode(entry.data);
      if (cached != null) {
        _data = cached;
        _lastUpdated = entry.updatedAt;
        _fromCache = true;
        _status = _isEmpty(cached) ? ResourceStatus.empty : ResourceStatus.loading;
        _error = null;
        _pending = true;
        onChanged();
      }
    }

    _pending = true;
    _error = null;
    if (_data == null) _status = ResourceStatus.loading;
    onChanged();

    // 2. Ask the backend for the freshest payload.
    try {
      final fresh = await fetch();
      _pending = false;
      _data = fresh;
      _fromCache = false;
      _error = null;
      _status = _isEmpty(fresh) ? ResourceStatus.empty : ResourceStatus.online;
      NetworkStatusService.instance.reportSuccess();
      onChanged();
      // 3. Cache only successful responses, never errors.
      await OfflineCacheService.instance.write(cacheKey, fresh);
      _lastUpdated = DateTime.now();
      onChanged();
    } catch (error) {
      _pending = false;
      if (ApiErrorHandler.isReachabilityError(error)) {
        // Backend down / unreachable: keep whatever is already on screen.
        NetworkStatusService.instance.reportFailure(error);
        if (_data != null) {
          _status = ResourceStatus.offline;
          _fromCache = true;
          _error = null;
        } else {
          _status = ResourceStatus.error;
          _error = errorKey;
        }
      } else {
        // A real answer from a live API (401, 403, 404, 422...). The cached
        // copy is discarded on purpose: the user is not allowed to see this
        // payload, so it must not stay on screen nor be re-rendered later.
        _data = null;
        _fromCache = false;
        _status = ResourceStatus.error;
        _error = _messageOrDefault(error, errorKey);
        await OfflineCacheService.instance.invalidate(cacheKey);
      }
      onChanged();
    }
  }

  /// Pull-to-refresh / retry. Keeps the current payload visible while the
  /// request runs, so there is never a blank screen when a cache exists.
  Future<void> refresh({
    required String cacheKey,
    required Future<T> Function() fetch,
    String errorKey = defaultErrorKey,
  }) =>
      load(cacheKey: cacheKey, fetch: fetch, errorKey: errorKey);

  /// Replace the displayed payload after a confirmed write.
  void setData(T value) {
    _data = value;
    _fromCache = false;
    _status = _isEmpty(value) ? ResourceStatus.empty : ResourceStatus.online;
    _error = null;
    onChanged();
  }

  bool _isEmpty(T value) {
    final checker = isEmptyData;
    if (checker != null) return checker(value);
    if (value is Iterable) return value.isEmpty;
    if (value is Map) return value.isEmpty;
    return false;
  }

  /// Cached payloads come back as plain JSON, so maps/lists need a re-typed cast.
  T? _decode(Object? raw) {
    if (raw is T) return raw;
    if (raw is Map) {
      final typed = raw.cast<String, dynamic>();
      if (typed is T) return typed as T;
    }
    if (raw is List) {
      final typed = List<dynamic>.from(raw);
      if (typed is T) return typed as T;
    }
    return null;
  }

  String _messageOrDefault(Object error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    }
    return fallback;
  }
}

/// Mixin for pages that own one or more [CachedResource]s.
///
/// `onResourceChanged` is the only bridge a resource needs: it rebuilds the
/// page (while still mounted) so cache-first renders, refresh progress and the
/// offline banner reach the UI without duplicating load logic in widgets.
mixin ResourceBinding<S extends StatefulWidget> on State<S> {
  /// Safe to hand to [CachedResource.onChanged].
  @protected
  void onResourceChanged() {
    if (mounted) setState(() {});
  }
}
