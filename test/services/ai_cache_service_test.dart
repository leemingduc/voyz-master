import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:voyz/services/ai_cache_service.dart';

void main() {
  late Directory tempDir;
  final cache = AiCacheService.instance;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('ai_cache_test_');
    Hive.init(tempDir.path);
    await cache.init();
  });

  setUp(() async => cache.clear());

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('buildKey', () {
    test('cung input, dao thu tu map va list van cho cung key', () {
      final a = cache.buildKey('suggestions', {
        'destination': 'Da Nang',
        'interests': ['Beach', 'Food'],
      });
      final b = cache.buildKey('suggestions', {
        'interests': ['Food', 'Beach'],
        'destination': 'Da Nang',
      });
      expect(a, equals(b));
    });

    test('khac participants cho key khac', () {
      final a = cache.buildKey('suggestions', {'budget': 'moderate', 'participants': '2'});
      final b = cache.buildKey('suggestions', {'budget': 'moderate', 'participants': '4'});
      expect(a, isNot(equals(b)));
    });

    test('khac prefix cho key khac', () {
      final a = cache.buildKey('detail', {'name': 'Hue'});
      final b = cache.buildKey('itinerary', {'name': 'Hue'});
      expect(a, isNot(equals(b)));
    });
  });

  group('get / put', () {
    test('put roi get tra dung payload', () async {
      await cache.put('k1', '{"ok":true}');
      expect(cache.get('k1'), equals('{"ok":true}'));
    });

    test('key chua co tra null', () {
      expect(cache.get('khong_ton_tai'), isNull);
    });

    test('put ghi expiresAt cach now khoang 7 ngay', () async {
      await cache.put('k2', 'x');
      final raw = Hive.box<String>(AiCacheService.boxName).get('k2')!;
      final expiresAt = DateTime.parse(jsonDecode(raw)['expiresAt'] as String);
      final expected = DateTime.now().add(AiCacheService.ttl);
      expect(expiresAt.difference(expected).inMinutes.abs(), lessThan(1));
    });

    test('entry het han tra null va bi xoa khoi box', () async {
      final box = Hive.box<String>(AiCacheService.boxName);
      await box.put('k3', jsonEncode({
        'payload': 'cu',
        'expiresAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      }));
      expect(cache.get('k3'), isNull);
      expect(box.containsKey('k3'), isFalse);
    });

    test('entry thieu expiresAt coi la het han', () async {
      final box = Hive.box<String>(AiCacheService.boxName);
      await box.put('k4', jsonEncode({'payload': 'cu'}));
      expect(cache.get('k4'), isNull);
    });
  });
}
