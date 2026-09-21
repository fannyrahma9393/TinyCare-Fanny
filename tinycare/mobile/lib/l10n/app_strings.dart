/// Lightweight in-house localization.
///
/// Keys are the Indonesian source strings (e.g. 'Simpan'). When the active
/// locale is Indonesian the key itself is shown; when English is selected the
/// key is looked up in the merged English map and translated. Unknown keys
/// gracefully fall back to the Indonesian source text.
///
/// Placeholders use `{{name}}` and are filled from the optional `args` map,
/// e.g. `tr('Halo {{nama}}', {'nama': name})`.
class AppStrings {
  AppStrings._();

  static final AppStrings instance = AppStrings._();

  final Map<String, String> _en = {};
  bool isEnglish = false;

  /// Read-only view of the merged English catalog (`lib/l10n/partials/*.dart`).
  /// Exposed so tooling and tests can assert that every key has a translation.
  Map<String, String> get englishCatalog => Map.unmodifiable(_en);

  void addEn(Map<String, String> strings) {
    _en.addAll(strings);
  }

  String tr(String key, [Map<String, dynamic>? args]) {
    var text = key;
    if (isEnglish && _en.containsKey(key)) {
      text = _en[key]!;
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
