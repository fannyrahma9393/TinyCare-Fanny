import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_strings.dart';
import 'api_service.dart';

/// Remote translation overlay service for Mobile.
///
/// Fetches the admin-editable key => value catalog from the backend
/// (GET /v1/translations?locale=...) and merges it ON TOP of the static
/// catalogs bundled in the APK (`lib/l10n/partials/*`). The static catalogs
/// are never modified or removed — they remain the fallback whenever a key
/// has no remote override or the API is unreachable.
///
/// Priority: remote DB value > cached remote value > static locale catalog >
/// Indonesian key fallback (handled by AppStrings.tr).
///
/// Offline: the last successful fetch is persisted in SharedPreferences and
/// re-applied on startup, so the app NEVER depends on the network to render
/// localized text.
class TranslationService {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  static const String _cacheKey = 'tinycare_remote_translations';
  static const Duration _ttl = Duration(hours: 1);

  DateTime? _lastFetch;

  /// Apply a persisted overlay from a previous session (called at startup).
  Future<void> restoreCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return;

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final idMap = _toStringMap(decoded['id']);
      final enMap = _toStringMap(decoded['en']);
      final fetchedAt = decoded['fetched_at'];

      AppStrings.instance.applyOverlay(idMap: idMap, enMap: enMap);
      if (fetchedAt is int) {
        _lastFetch = DateTime.fromMillisecondsSinceEpoch(fetchedAt);
      }
    } catch (e) {
      debugPrint('[TranslationService] restoreCache failed: $e');
    }
  }

  /// Fetch both locale catalogs from the backend and apply them as overlays.
  /// Silent by design: any failure keeps the cached/static translations.
  Future<void> refresh({bool force = false}) async {
    if (!force && _lastFetch != null && DateTime.now().difference(_lastFetch!) < _ttl) {
      return; // fresh enough
    }

    final results = await Future.wait([
      _fetchLocale('id'),
      _fetchLocale('en'),
    ]);

    final idMap = results[0];
    final enMap = results[1];

    if (idMap == null && enMap == null) {
      debugPrint('[TranslationService] refresh skipped (network unavailable)');
      return;
    }

    AppStrings.instance.applyOverlay(idMap: idMap, enMap: enMap);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode({
        'id': idMap ?? const <String, String>{},
        'en': enMap ?? const <String, String>{},
        'fetched_at': DateTime.now().millisecondsSinceEpoch,
      }));
      _lastFetch = DateTime.now();
    } catch (e) {
      debugPrint('[TranslationService] cache persist failed: $e');
    }
  }

  /// Fetch one locale catalog; null when the request fails.
  Future<Map<String, String>?> _fetchLocale(String locale) async {
    try {
      final response = await ApiService().getTranslations(locale);
      final data = response['data'];
      final translations = data is Map ? data['translations'] : null;
      if (translations is Map) {
        return translations
            .map((k, v) => MapEntry(k.toString(), v.toString()));
      }
      return null;
    } catch (e) {
      debugPrint('[TranslationService] fetch $locale failed: $e');
      return null;
    }
  }

  Map<String, String> _toStringMap(dynamic raw) {
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return const <String, String>{};
  }
}
