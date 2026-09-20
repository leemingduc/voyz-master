import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:voyz/data/ai_model_settings.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('ai_model_test_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    if (await Hive.boxExists('app_settings')) {
      final box = await Hive.openBox<String>('app_settings');
      await box.deleteAll(box.keys);
      await box.close();
    }
    AiModelSettings.instance.current = supportedAiModels.first.id;
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('resolve keeps a supported id and falls back for anything else', () {
    expect(AiModelSettings.resolve('gemini-3.8-flash'), 'gemini-3.8-flash');
    expect(
      AiModelSettings.resolve('gemini-9-ultra'),
      supportedAiModels.first.id,
    );
    expect(AiModelSettings.resolve(null), supportedAiModels.first.id);
  });

  test('load without a saved value gives the default', () async {
    await AiModelSettings.instance.load();
    expect(AiModelSettings.instance.current, supportedAiModels.first.id);
  });

  test('save then load round trips the chosen model', () async {
    await AiModelSettings.instance.save('gemini-3.1-pro-preview');
    expect(AiModelSettings.instance.current, 'gemini-3.1-pro-preview');

    AiModelSettings.instance.current = supportedAiModels.first.id;
    await AiModelSettings.instance.load();
    expect(AiModelSettings.instance.current, 'gemini-3.1-pro-preview');
  });

  test('save with an unknown id stores the default', () async {
    await AiModelSettings.instance.save('typo-model');
    expect(AiModelSettings.instance.current, supportedAiModels.first.id);
  });
}
