import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One cached API payload plus the moment it was last received from the backend.
class CachedEntry {
  const CachedEntry({
    required this.key,
    required this.data,
    required this.updatedAt,
  });

  final String key;

  /// The decoded JSON payload (a `List<dynamic>` or `Map<String, dynamic>`
  /// for every resource TinyCare caches).
  final Object? data;

  /// When the backend last handed this payload to the authenticated user.
  final DateTime updatedAt;
}

/// Offline cache for API payloads, backed by the SharedPreferences storage the
/// app already uses (token, locale, saved user, translation overlay).
///
/// USER ISOLATION: every entry is stored under a key that embeds the id of the
/// authenticated user it was fetched for (`<prefix><userId>::<cacheKey>`).
/// Reading or writing requires a bound scope, so
/// - a parent that never bound a scope reads nothing,
/// - parent B can never read a key written while parent A was signed in,
/// - logging out wipes the previous user's entries (safest policy).
///
/// Nothing sensitive is ever written: [write] strips credential-ish fields and
/// refuses payloads above [_maxEntryBytes]. Tokens and session state keep using
/// the existing `auth_token` preference handled by `ApiService`.
class OfflineCacheService {
  OfflineCacheService._();

  static final OfflineCacheService instance = OfflineCacheService._();

  static const String _dataPrefix = 'tc_cache_v1_data_';
  static const String _indexPrefix = 'tc_cache_v1_index_';
  static const String _scopeKey = 'tc_cache_v1_scope';

  /// Upper bound of cached entries per user, oldest are evicted first.
  static const int maxEntriesPerUser = 120;

  /// Upper bound of a single serialized entry (SharedPreferences is not a
  /// database; oversized payloads are skipped instead of stored).
  static const int maxEntryBytes = 512 * 1024;

  /// Field names that must never reach the cache, whatever the payload is.
  static const Set<String> _forbiddenFields = {
    'password',
    'password_confirmation',
    'current_password',
    'new_password',
    'new_password_confirmation',
    'token',
    'api_token',
    'access_token',
    'refresh_token',
    'secret',
    'api_secret',
    'api_key',
    'private_key',
    'firebase_key',
  };

  String? _userId;

  /// Id of the user the cache is currently scoped to; null when signed out.
  String? get userId => _userId;

  /// Whether reads/writes are allowed at all.
  bool get hasScope => _userId != null && _userId!.isNotEmpty;

  /// Scope the cache to [userId] (the authenticated user's id).
  ///
  /// Changing the scope immediately stops any access to the previous user's
  /// entries, so a different account can never observe them.
  Future<void> bindUser(Object? userId) async {
    final normalized = userId?.toString().trim();
    if (normalized == null || normalized.isEmpty) {
      await unbindUser();
      return;
    }
    _userId = normalized;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_scopeKey, normalized);
    } catch (e) {
      debugPrint('[OfflineCache] bindUser failed: $e');
    }
  }

  /// Drop the active scope without deleting the stored entries.
  Future<void> unbindUser() async {
    _userId = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_scopeKey);
    } catch (e) {
      debugPrint('[OfflineCache] unbindUser failed: $e');
    }
  }

  /// Read the cached payload for [key], or null when nothing was stored for
  /// the currently bound user.
  Future<CachedEntry?> read(String key) async {
    final storageKey = _storageKey(key);
    if (storageKey == null) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final payload = decoded['data'];
      final updatedAt = decoded['updated_at'];
      return CachedEntry(
        key: key,
        data: payload,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          updatedAt is int ? updatedAt : 0,
        ),
      );
    } catch (e) {
      debugPrint('[OfflineCache] read($key) failed: $e');
      return null;
    }
  }

  /// When [key] was last refreshed from the backend for the bound user.
  Future<DateTime?> lastUpdated(String key) async {
    final entry = await read(key);
    return entry?.updatedAt;
  }

  /// Store [data] as the freshest payload for [key], stamping it with [now].
  ///
  /// Returns true when the entry was persisted. Credential-like fields are
  /// stripped first and oversized payloads are skipped, so a cache write can
  /// never leak a secret or break the app.
  Future<bool> write(String key, Object? data, {DateTime? now}) async {
    final storageKey = _storageKey(key);
    if (storageKey == null || data == null) return false;

    try {
      final sanitized = _sanitize(data);
      final payload = jsonEncode({
        'updated_at': (now ?? DateTime.now()).millisecondsSinceEpoch,
        'data': sanitized,
      });
      if (payload.length > maxEntryBytes) {
        debugPrint('[OfflineCache] write($key) skipped: payload too large');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, payload);
      await _touchIndex(prefs, key, now ?? DateTime.now());
      return true;
    } catch (e) {
      debugPrint('[OfflineCache] write($key) failed: $e');
      return false;
    }
  }

  /// Drop a single entry of the currently bound user.
  ///
  /// Used when the backend answers a request with a real error (401/403/404...):
  /// the user is not allowed to see that payload, so neither the cached copy nor
  /// the in-memory one may be displayed or re-rendered later.
  Future<void> invalidate(String key) async {
    final storageKey = _storageKey(key);
    if (storageKey == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(storageKey);
      final uid = _userId;
      if (uid == null || uid.isEmpty) return;
      final indexKey = '$_indexPrefix$uid';
      final index = _readIndex(prefs, indexKey);
      if (index.remove(key) != null) {
        await prefs.setString(indexKey, jsonEncode(index));
      }
    } catch (e) {
      debugPrint('[OfflineCache] invalidate($key) failed: $e');
    }
  }

  /// Remove every entry of the currently bound user (used on logout).
  Future<void> clearCurrentUser() async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().toList()) {
        if (key.startsWith('$_dataPrefix$uid::') ||
            key == '$_indexPrefix$uid') {
          await prefs.remove(key);
        }
      }
      debugPrint('[OfflineCache] cleared cache for user $uid');
    } catch (e) {
      debugPrint('[OfflineCache] clearCurrentUser failed: $e');
    }
  }

  /// Remove every cached entry of every user (used when a session is dropped
  /// by the API layer and the acting user is no longer known).
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().toList()) {
        if (key.startsWith(_dataPrefix) || key.startsWith(_indexPrefix)) {
          await prefs.remove(key);
        }
      }
      await prefs.remove(_scopeKey);
    } catch (e) {
      debugPrint('[OfflineCache] clearAll failed: $e');
    }
  }

  String? _storageKey(String key) {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return null;
    return '$_dataPrefix$uid::$key';
  }

  Future<void> _touchIndex(
    SharedPreferences prefs,
    String key,
    DateTime now,
  ) async {
    final uid = _userId;
    if (uid == null) return;
    final indexKey = '$_indexPrefix$uid';
    final index = _readIndex(prefs, indexKey);
    index[key] = now.millisecondsSinceEpoch;

    if (index.length > maxEntriesPerUser) {
      final sorted = index.keys.toList()
        ..sort((a, b) => (index[a] ?? 0).compareTo(index[b] ?? 0));
      final overflow = index.length - maxEntriesPerUser;
      for (var i = 0; i < overflow; i++) {
        final evicted = sorted[i];
        index.remove(evicted);
        await prefs.remove('$_dataPrefix$uid::$evicted');
      }
    }

    await prefs.setString(indexKey, jsonEncode(index));
  }

  Map<String, int> _readIndex(SharedPreferences prefs, String indexKey) {
    try {
      final raw = prefs.getString(indexKey);
      if (raw == null || raw.isEmpty) return <String, int>{};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, int>{};
      return decoded.map(
        (k, v) => MapEntry(k.toString(), v is int ? v : 0),
      );
    } catch (e) {
      debugPrint('[OfflineCache] readIndex failed: $e');
      return <String, int>{};
    }
  }

  /// Recursively drop credential-ish fields before anything is persisted.
  Object? _sanitize(Object? value) {
    if (value is Map) {
      final out = <String, dynamic>{};
      value.forEach((k, v) {
        final name = k.toString().toLowerCase();
        if (_forbiddenFields.contains(name)) return;
        out[k.toString()] = _sanitize(v);
      });
      return out;
    }
    if (value is List) {
      return value.map(_sanitize).toList();
    }
    return value;
  }
}
