import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinycare_mobile/l10n/app_strings.dart';
import 'package:tinycare_mobile/services/translation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Reset singleton state between tests.
    AppStrings.instance.isEnglish = false;
    AppStrings.instance.applyOverlay(idMap: {}, enMap: {});
  });

  group('AppStrings overlay', () {
    test('ID default: key is returned as-is (Indonesian source)', () {
      AppStrings.instance.isEnglish = false;
      expect(tr('Simpan'), 'Simpan');
    });

    test('EN switch uses static catalog', () {
      AppStrings.instance.isEnglish = true;
      AppStrings.instance.addEn({'Simpan': 'Save'});
      expect(tr('Simpan'), 'Save');
    });

    test('remote EN overlay wins over static EN catalog', () {
      AppStrings.instance.isEnglish = true;
      AppStrings.instance.addEn({'Simpan': 'Save'});
      AppStrings.instance.applyOverlay(enMap: {'Simpan': 'Simpan Perubahan'});
      expect(tr('Simpan'), 'Simpan Perubahan');
    });

    test('remote ID overlay rewords the Indonesian text', () {
      AppStrings.instance.isEnglish = false;
      AppStrings.instance.applyOverlay(idMap: {'Simpan': 'Silakan Simpan'});
      expect(tr('Simpan'), 'Silakan Simpan');
    });

    test('missing key falls back safely to the key itself (no crash)', () {
      AppStrings.instance.isEnglish = true;
      expect(tr('Key Tidak Ada Sekali'), 'Key Tidak Ada Sekali');
    });

    test('placeholders are replaced and data is preserved', () {
      AppStrings.instance.isEnglish = false;
      AppStrings.instance.applyOverlay(
        idMap: {'Paket {{child_name}} berakhir {{date}}': 'Paket {{child_name}} berakhir {{date}}'},
      );
      final rendered = tr(
        'Paket {{child_name}} berakhir {{date}}',
        {'child_name': 'Budi', 'date': '17 September 2026'},
      );
      expect(rendered, 'Paket Budi berakhir 17 September 2026');
    });

    test('overlayVersion increments when a new overlay is applied', () {
      final before = AppStrings.instance.overlayVersion.value;
      AppStrings.instance.applyOverlay(idMap: {'A': 'A'});
      expect(AppStrings.instance.overlayVersion.value, before + 1);
    });
  });

  group('TranslationService cache', () {
    test('restoreCache applies persisted overlay and survives restart', () async {
      // Simulate a previously persisted overlay (as written by refresh():
      // a JSON-encoded string in SharedPreferences).
      SharedPreferences.setMockInitialValues({
        'flutter.tinycare_remote_translations': jsonEncode({
          'id': {'Cari': 'Cari versi admin'},
          'en': {'Cari': 'Search version admin'},
          'fetched_at': DateTime.now().millisecondsSinceEpoch,
        }),
      });

      final service = TranslationService.instance;
      await service.restoreCache();

      AppStrings.instance.isEnglish = false;
      expect(tr('Cari'), 'Cari versi admin');

      AppStrings.instance.isEnglish = true;
      expect(tr('Cari'), 'Search version admin');
    });

    test('restoreCache with empty prefs is a no-op (offline first run)', () async {
      SharedPreferences.setMockInitialValues({});
      await TranslationService.instance.restoreCache();

      AppStrings.instance.isEnglish = false;
      expect(tr('Simpan'), 'Simpan'); // static behavior intact
    });
  });
}
