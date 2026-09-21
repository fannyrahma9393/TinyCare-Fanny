import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';

/// Persists the app language ('id' / 'en') and reactively notifies the UI when
/// it changes so MaterialApp rebuilds with the new locale.
class LocaleProvider extends ChangeNotifier {
  LocaleProvider() {
    AppStrings.instance.isEnglish = false;
  }

  static const String _key = 'tinycare_locale';
  String _locale = 'id';

  String get locale => _locale;

  Locale get localeValue => Locale(_locale);

  bool get isEnglish => _locale == 'en';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && (saved == 'id' || saved == 'en')) {
      _locale = saved;
      AppStrings.instance.isEnglish = saved == 'en';
      notifyListeners();
    }
  }

  Future<void> setLocale(String locale) async {
    if (locale != 'id' && locale != 'en') return;
    _locale = locale;
    AppStrings.instance.isEnglish = locale == 'en';
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale);
  }

  /// Toggle helper for quick switching.
  Future<void> toggle() => setLocale(_locale == 'id' ? 'en' : 'id');
}