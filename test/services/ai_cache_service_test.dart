import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/services/ai_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiCacheService Tests', () {
    final aiCache = AiCacheService.instance;

    test('buildKey creates deterministic keys regardless of map entry order', () {
      final key1 = aiCache.buildKey('suggestions', {
        'destination': 'Da Nang',
        'budget': '5M',
        'interests': ['Beach', 'Food'],
      });

      final key2 = aiCache.buildKey('suggestions', {
        'interests': ['Food', 'Beach'], // Reversed list
        'budget': '5M',
        'destination': 'Da Nang',
      });

      expect(key1, equals(key2));
    });

    test('CachedAiResponse serializes and deserializes correctly', () {
      final response = CachedAiResponse(
        payload: '[{"name": "Phu Quoc"}]',
        imageUrls: {'Phu Quoc': 'https://example.com/pq.jpg'},
      );

      final map = response.toMap();
      final fromMap = CachedAiResponse.fromMap(map);

      expect(fromMap.payload, equals('[{"name": "Phu Quoc"}]'));
      expect(fromMap.imageUrls['Phu Quoc'], equals('https://example.com/pq.jpg'));
    });

    test('Tier 1 In-Memory caching works seamlessly', () async {
      const testKey = 'test_key_memory_only';
      const testPayload = '{"result": "cached_data"}';
      final testImages = {'Da Nang': 'https://example.com/danang.jpg'};

      await aiCache.putResponse(
        testKey,
        testPayload,
        featureType: 'test',
        imageUrls: testImages,
      );

      final cached = await aiCache.getResponse(testKey);
      expect(cached, isNotNull);
      expect(cached!.payload, equals(testPayload));
      expect(cached.imageUrls['Da Nang'], equals('https://example.com/danang.jpg'));

      final rawPayload = await aiCache.get(testKey);
      expect(rawPayload, equals(testPayload));
    });
  });
}
