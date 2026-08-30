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
        imageUrls: {
          'Phu Quoc':
              'https://commons.wikimedia.org/wiki/Special:FilePath/Phu_Quoc_Beach.jpg?width=1280',
        },
      );

      final map = response.toMap();
      final fromMap = CachedAiResponse.fromMap(map);

      expect(fromMap.payload, equals('[{"name": "Phu Quoc"}]'));
      expect(
        fromMap.imageUrls['Phu Quoc'],
        equals(
          'https://commons.wikimedia.org/wiki/Special:FilePath/Phu_Quoc_Beach.jpg?width=1280',
        ),
      );
    });

    test('Tier 1 In-Memory caching works seamlessly', () async {
      const testKey = 'test_key_memory_only';
      const testPayload = '{"result": "cached_data"}';
      final testImages = {
        'Da Nang':
            'https://upload.wikimedia.org/wikipedia/commons/thumb/a/aa/Da_Nang.jpg/1280px-Da_Nang.jpg',
      };

      await aiCache.putResponse(
        testKey,
        testPayload,
        featureType: 'test',
        imageUrls: testImages,
      );

      final cached = await aiCache.getResponse(testKey);
      expect(cached, isNotNull);
      expect(cached!.payload, equals(testPayload));
      expect(
        cached.imageUrls['Da Nang'],
        equals(
          'https://upload.wikimedia.org/wikipedia/commons/thumb/a/aa/Da_Nang.jpg/1280px-Da_Nang.jpg',
        ),
      );

      final rawPayload = await aiCache.get(testKey);
      expect(rawPayload, equals(testPayload));
    });
  });

  group('sanitizeImageUrls', () {
    // Pre-caching từng lưu URL bịa và URL từ dịch vụ đã chết vào cache đa
    // tầng. Allowlist theo host chặn tái nhiễm từ mọi tầng.
    test('keeps wikimedia and supabase hosts, drops everything else', () {
      final input = {
        'A':
            'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bf/X.jpg/1280px-X.jpg',
        'B':
            'https://commons.wikimedia.org/wiki/Special:FilePath/Y.jpg?width=1280',
        'C':
            'https://abcd1234.supabase.co/storage/v1/object/public/destination-media/z.jpg',
        'D': 'https://source.unsplash.com/featured/1200x800?Koh%20Lipe',
        'E': 'https://loremflickr.com/960/640/Koh%20Lipe',
        'F': 'not a url',
      };

      final out = AiCacheService.sanitizeImageUrls(input);

      expect(out.keys, unorderedEquals(['A', 'B', 'C']));
    });

    test('applies on deserialization so poisoned entries are dropped on read',
        () {
      final fromMap = CachedAiResponse.fromMap({
        'payload': '[]',
        'imageUrls': {
          'Dead': 'https://loremflickr.com/960/640/Dead',
          'Alive':
              'https://commons.wikimedia.org/wiki/Special:FilePath/Alive.jpg?width=1280',
        },
      });

      expect(fromMap.imageUrls.keys, ['Alive']);
    });
  });
}
