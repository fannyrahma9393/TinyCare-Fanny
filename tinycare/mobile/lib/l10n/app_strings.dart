library;

/// Lightweight in-house localization.
///
/// Keys are the Indonesian source strings (e.g. 'Simpan'). When the active
/// locale is Indonesian the key itself is shown; when English is selected the
/// key is looked up in the merged English map and translated. Unknown keys
/// gracefully fall back to the Indonesian source text.
///
/// Placeholders use `{{name}}` and are filled from the optional `args` map,
/// e.g. `tr('Halo {{nama}}', {'nama': name})`.
///
/// REMOTE OVERLAY: the backend exposes an admin-editable catalog
/// (translations table) that is merged on top of the static catalogs via
/// [applyOverlay] (see TranslationService). Overlay values WIN over static
/// ones; a missing overlay/static entry always degrades to the key itself,
/// so a missing translation can never crash the UI.
import 'package:flutter/foundation.dart';
class AppStrings {
  AppStrings._();

  static final AppStrings instance = AppStrings._();

  final Map<String, String> _en = {};
  bool isEnglish = false;

  // Remote overlay maps (admin-editable wording from the backend).
  Map<String, String> _idOverlay = {};
  Map<String, String> _enOverlay = {};

  /// Increments every time a new overlay is applied. Widgets that need to
  /// re-render remote wording immediately can listen to this (the app shell
  /// in main.dart wraps MaterialApp with it).
  final ValueNotifier<int> overlayVersion = ValueNotifier<int>(0);

  /// Read-only view of the merged English catalog (`lib/l10n/partials/*.dart`).
  /// Exposed so tooling and tests can assert that every key has a translation.
  Map<String, String> get englishCatalog => Map.unmodifiable(_en);

  void addEn(Map<String, String> strings) {
    _en.addAll(strings);
  }

  /// Merge the remote overlay on top of the static catalogs.
  /// Either map may be empty/null (no overlay for that locale).
  void applyOverlay({Map<String, String>? idMap, Map<String, String>? enMap}) {
    _idOverlay = idMap ?? _idOverlay;
    _enOverlay = enMap ?? _enOverlay;
    overlayVersion.value++;
  }

  String tr(String key, [Map<String, dynamic>? args]) {
    var text = key;
    if (isEnglish) {
      text = _enOverlay[key] ?? _en[key] ?? _idOverlay[key] ?? key;
    } else {
      text = _idOverlay[key] ?? key;
    }
    if (args != null) {
      args.forEach((k, v) {
        text = text.replaceAll('{{$k}}', '$v');
      });
    }
    return text;
  }
}

/// Global translate helper: `tr('Simpan')` / `tr('Halo {{nama}}', {'nama': n})`.
///
/// Widgets rebuild when [LocaleProvider] changes the locale (MaterialApp
/// rebuilds its subtree), so calling this during `build` always yields the
/// currently selected language.
String tr(String key, [Map<String, dynamic>? args]) =>
    AppStrings.instance.tr(key, args);
