import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/services/gemini_service.dart';

void main() {
  group('GeminiService - safeJsonDecode Tests', () {
    test('Should parse pure JSON string', () {
      final jsonStr = '{"name": "Hanoi", "rating": 4.8}';
      final result = GeminiService.instance.safeJsonDecode(jsonStr);
      expect(result, isA<Map<String, dynamic>>());
      expect(result['name'], 'Hanoi');
      expect(result['rating'], 4.8);
    });

    test('Should parse JSON wrapped in ```json markdown block', () {
      final jsonStr = '''
```json
{
  "name": "Da Nang",
  "rating": 4.5
}
```
''';
      final result = GeminiService.instance.safeJsonDecode(jsonStr);
      expect(result, isA<Map<String, dynamic>>());
      expect(result['name'], 'Da Nang');
      expect(result['rating'], 4.5);
    });

    test('Should parse JSON wrapped in ``` markdown block without language specifier', () {
      final jsonStr = '''
```
{
  "name": "Saigon",
  "rating": 4.7
}
```
''';
      final result = GeminiService.instance.safeJsonDecode(jsonStr);
      expect(result, isA<Map<String, dynamic>>());
      expect(result['name'], 'Saigon');
      expect(result['rating'], 4.7);
    });

    test('Should parse JSON array wrapped in markdown', () {
      final jsonStr = '''
Here is the requested information in JSON format:
```json
[
  {"name": "Hue", "rating": 4.2},
  {"name": "Nha Trang", "rating": 4.4}
]
```
Please let me know if you need anything else!
''';
      final result = GeminiService.instance.safeJsonDecode(jsonStr);
      expect(result, isA<List<dynamic>>());
      expect(result.length, 2);
      expect(result[0]['name'], 'Hue');
      expect(result[1]['name'], 'Nha Trang');
    });
  });

  group('GeminiService - parseSuggestionsSync Tests', () {
    test('Should parse standard JSON array of destinations', () {
      final jsonStr = '''
[
  {"name": "Phu Quoc", "matchPercent": 95, "rating": 4.7, "reviewCount": 120, "price": "3M VNĐ", "aiInsight": "Great beach", "isTopMatch": true}
]
''';
      final result = GeminiService.instance.parseSuggestionsSync(jsonStr);
      expect(result, isNotEmpty);
      expect(result.first.name, 'Phu Quoc');
      expect(result.first.rating, 4.7);
    });

    test('Should auto-extract list from wrapped JSON object', () {
      final jsonStr = '''
{
  "trending_destinations": [
    {"name": "Ha Giang", "matchPercent": 92, "rating": 4.8, "reviewCount": 90, "price": "2.5M VNĐ", "aiInsight": "Beautiful loop", "isTopMatch": false}
  ]
}
''';
      final result = GeminiService.instance.parseSuggestionsSync(jsonStr);
      expect(result, isNotEmpty);
      expect(result.first.name, 'Ha Giang');
      expect(result.first.rating, 4.8);
      expect(result.first.isTopMatch, true); // Auto-promoted first item to top match if none set
    });

    test('Should handle mismatched types and cast safely without throwing TypeError', () {
      final jsonStr = '''
[
  {
    "name": 12345, 
    "matchPercent": "90", 
    "rating": "4.2", 
    "reviewCount": "100", 
    "price": "Free", 
    "aiInsight": null, 
    "isTopMatch": false
  }
]
''';
      final result = GeminiService.instance.parseSuggestionsSync(jsonStr);
      expect(result, isNotEmpty);
      expect(result.first.name, '12345'); // Cast to string
      expect(result.first.matchPercent, 90); // Parsed to int
      expect(result.first.rating, 4.2); // Parsed to double
      expect(result.first.reviewCount, 100); // Parsed to int
      expect(result.first.price, 'Free');
      expect(result.first.aiInsight, ''); // Null turned to empty string
    });
    test('Should heal JSON array closed with } instead of ] (Gemini model bug)', () {
      // This is the exact bug pattern we observed: Gemini ends an array with } instead of ]
      final jsonStr = '[{"name": "Phu Quoc", "matchPercent": 98, "rating": 4.8, "reviewCount": 100, "price": "5M VNĐ", "aiInsight": "Great", "isTopMatch": true}]'.replaceFirst(']', '}');
      final result = GeminiService.instance.parseSuggestionsSync(jsonStr);
      expect(result, isNotEmpty);
      expect(result.first.name, 'Phu Quoc');
    });

    test('Should heal multi-item JSON array closed with } instead of ]', () {
      // Same Gemini bug with multiple items (the actual observed output)
      const jsonStr = '''[
  {"name": "Phu Quoc", "matchPercent": 98, "rating": 4.8, "reviewCount": 100, "price": "5M VNĐ", "aiInsight": "Great beach", "isTopMatch": true},
  {"name": "Da Nang", "matchPercent": 85, "rating": 4.5, "reviewCount": 80, "price": "3M VNĐ", "aiInsight": "Great city", "isTopMatch": false}
}'''; // Note: ends with } instead of ]
      final result = GeminiService.instance.parseSuggestionsSync(jsonStr);
      expect(result.length, 2);
      expect(result.first.name, 'Phu Quoc');
      expect(result.last.name, 'Da Nang');
    });
  });
}
