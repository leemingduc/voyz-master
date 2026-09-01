import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/services/gemini_service.dart';

void main() {
  test('uses Gemini 3.1 Flash Lite for every AI feature', () {
    expect(GeminiService.modelName, 'gemini-3.1-flash-lite');
  });

  group('languageInstruction', () {
    test('returns Vietnamese instruction for vi', () {
      final result = GeminiService.languageInstruction('vi');
      expect(result, contains('Vietnamese'));
    });

    test('returns Korean instruction for ko', () {
      final result = GeminiService.languageInstruction('ko');
      expect(result, contains('Korean'));
    });

    test('returns English instruction for en', () {
      final result = GeminiService.languageInstruction('en');
      expect(result, contains('English'));
    });

    test('returns English instruction for unsupported language', () {
      final result = GeminiService.languageInstruction('fr');
      expect(result, contains('English'));
    });
  });

  group('chatLanguageInstruction', () {
    test('returns Vietnamese plain-text instruction for vi', () {
      final result = GeminiService.chatLanguageInstruction('vi');
      expect(result, 'Reply in Vietnamese.');
    });
  });

  group('requireApiKey', () {
    test('accepts a configured API key', () {
      expect(
        GeminiService.requireApiKey('AQ.example-configured-key'),
        'AQ.example-configured-key',
      );
    });

    test('rejects missing and placeholder API keys', () {
      expect(
        () => GeminiService.requireApiKey(null),
        throwsA(isA<Exception>()),
      );
      expect(
        () => GeminiService.requireApiKey('YOUR_API_KEY_HERE'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('safeJsonDecode', () {
    test('decodes plain JSON object', () {
      final result = GeminiService.instance.safeJsonDecode('{"key":"value"}');
      expect(result, isA<Map<String, dynamic>>());
      expect((result as Map<String, dynamic>)['key'], 'value');
    });

    test('decodes JSON with markdown code fence', () {
      final result = GeminiService.instance
          .safeJsonDecode('```json\n{"key":"value"}\n```');
      expect(result, isA<Map<String, dynamic>>());
    });

    test('decodes plain JSON array', () {
      final result = GeminiService.instance.safeJsonDecode('[1, 2, 3]');
      expect(result, isA<List<dynamic>>());
    });

    test('heals array closed with } instead of ]', () {
      final result = GeminiService.instance.safeJsonDecode(
        '[{"name":"Hà Nội"},{"name":"Đà Nẵng"}]',
      );
      expect(result, isA<List<dynamic>>());
    });
  });

  group('buildSuggestionsPrompt - prompt-first behavior', () {
    test('prompt-only trip asks AI to infer the destination, not Vietnam', () {
      final trip = TripData(aiPrompt: 'Đi biển 5 ngày cùng gia đình 4 người');
      final prompt =
          GeminiService.instance.buildSuggestionsPrompt(trip, 5, 'vi');
      expect(prompt, contains('suy ra điểm đến'));
      expect(prompt, isNot(contains('Điểm đến mong muốn: Việt Nam')));
      expect(
        prompt,
        contains('Mô tả chuyến đi: Đi biển 5 ngày cùng gia đình 4 người'),
      );
    });

    test('explicit destination field still wins over inference', () {
      final trip = TripData(destination: 'Đà Lạt', aiPrompt: 'nghỉ dưỡng');
      final prompt =
          GeminiService.instance.buildSuggestionsPrompt(trip, 5, 'vi');
      expect(prompt, contains('Điểm đến mong muốn: Đà Lạt'));
      expect(prompt, isNot(contains('suy ra điểm đến')));
    });

    test('fully empty trip keeps the Vietnam fallback', () {
      final prompt =
          GeminiService.instance.buildSuggestionsPrompt(TripData(), 5, 'vi');
      expect(prompt, contains('Điểm đến mong muốn: Việt Nam'));
    });

    test('missing dates and party size point the AI at the description', () {
      final trip = TripData(aiPrompt: 'Đi 5 ngày, 4 người lớn');
      final prompt =
          GeminiService.instance.buildSuggestionsPrompt(trip, 5, 'vi');
      expect(prompt, contains('nếu mô tả chuyến đi nêu thời gian'));
      expect(prompt, contains('suy ra từ mô tả chuyến đi'));
    });
  });

  group('buildDetailPrompt - prompt-first behavior', () {
    test('includes the trip description and drops the fake date fallback', () {
      final trip = TripData(aiPrompt: 'Đi 5 ngày với bố mẹ, thích ẩm thực');
      final prompt = GeminiService.instance
          .buildDetailPrompt('Đà Nẵng', trip, 'vi');
      expect(
        prompt,
        contains('Mô tả chuyến đi của người dùng: Đi 5 ngày với bố mẹ'),
      );
      expect(prompt, contains('Thời gian dự kiến: Linh hoạt'));
      expect(prompt, isNot(contains('Mar 15 - Mar 18')));
    });

    test('picked dates still appear verbatim', () {
      final trip = TripData(
        departDate: DateTime(2026, 10, 1),
        returnDate: DateTime(2026, 10, 5),
      );
      final prompt = GeminiService.instance
          .buildDetailPrompt('Đà Nẵng', trip, 'vi');
      expect(prompt, isNot(contains('Linh hoạt')));
    });
  });

  group('buildItineraryPrompt - prompt-first behavior', () {
    test('no dates: lets the AI honor a day count from the description', () {
      final trip = TripData(aiPrompt: 'Chuyến đi 5 ngày khám phá ẩm thực');
      final prompt = GeminiService.instance
          .buildItineraryPrompt('Huế', 3, trip, 4, 'vi', null);
      expect(prompt, contains('Mô tả chuyến đi của người dùng:'));
      expect(prompt, contains('nêu số ngày cụ thể'));
      expect(prompt, contains('Thời gian: Linh hoạt'));
      expect(prompt, isNot(contains('MAR 15 - MAR 18')));
    });

    test('picked dates: exact numDays is kept, no override instruction', () {
      final trip = TripData(
        departDate: DateTime(2026, 10, 1),
        returnDate: DateTime(2026, 10, 4),
        aiPrompt: 'đi chơi',
      );
      final prompt = GeminiService.instance
          .buildItineraryPrompt('Huế', 3, trip, 4, 'vi', null);
      expect(prompt, isNot(contains('nêu số ngày cụ thể')));
    });
  });
}
