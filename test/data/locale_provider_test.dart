import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:voyz/data/locale_provider.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('locale_test_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    // Start each test with a clean app_settings box.
    if (await Hive.boxExists('app_settings')) {
      final box = await Hive.openBox<String>('app_settings');
      await box.deleteAll(box.keys);
      await box.close();
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('LocaleSettingsStore', () {
    test('uses English for an unsupported device language', () async {
      expect(
        await LocaleSettingsStore.instance.load(const Locale('fr')),
        const Locale('en'),
      );
    });

    test('uses device language when it is supported and nothing is saved',
        () async {
      expect(
        await LocaleSettingsStore.instance.load(const Locale('vi')),
        const Locale('vi'),
      );
    });

    test('persists and restores Korean', () async {
      await LocaleSettingsStore.instance.save(const Locale('ko'));
      expect(
        await LocaleSettingsStore.instance.load(const Locale('en')),
        const Locale('ko'),
      );
    });

    test('persists and restores Vietnamese', () async {
      await LocaleSettingsStore.instance.save(const Locale('vi'));
      expect(
        await LocaleSettingsStore.instance.load(const Locale('en')),
        const Locale('vi'),
      );
    });

    test('overwriting with English works', () async {
      await LocaleSettingsStore.instance.save(const Locale('ko'));
      await LocaleSettingsStore.instance.save(const Locale('en'));
      expect(
        await LocaleSettingsStore.instance.load(const Locale('vi')),
        const Locale('en'),
      );
    });
  });

  group('LocaleController', () {
    test('initial value is preserved', () {
      final ctrl = LocaleController(const Locale('vi'));
      expect(ctrl.value, const Locale('vi'));
      ctrl.dispose();
    });

    test('setLocale updates value for supported codes', () async {
      final ctrl = LocaleController(const Locale('en'));
      await ctrl.setLocale(const Locale('ko'));
      expect(ctrl.value, const Locale('ko'));
      ctrl.dispose();
    });

    test('setLocale ignores unsupported codes', () async {
      final ctrl = LocaleController(const Locale('en'));
      await ctrl.setLocale(const Locale('fr'));
      expect(ctrl.value, const Locale('en'));
      ctrl.dispose();
    });
  });
}
