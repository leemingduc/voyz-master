import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/data/ai_model_settings.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/models/destination_detail.dart';
import 'package:voyz/services/gemini_service.dart';

void main() {
  test('defaults to Gemini 3.1 Flash Lite for every AI feature', () {
    expect(supportedAiModels.first.id, 'gemini-3.1-flash-lite');
    expect(GeminiService.instance.modelName, 'gemini-3.1-flash-lite');
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
      final result = GeminiService.instance.safeJsonDecode(
        '```json\n{"key":"value"}\n```',
      );
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

    test(
      'parses JSON wrapped in ``` markdown block without language specifier',
      () {
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
      },
    );

    test('parses JSON array wrapped in markdown', () {
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

  group('parseSuggestionsSync', () {
    test('parses standard JSON array of destinations', () {
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

    test('auto-extracts list from wrapped JSON object', () {
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
      expect(result.first.isTopMatch, true);
    });

    test(
      'handles mismatched types and casts safely without throwing TypeError',
      () {
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
        expect(result.first.name, '12345');
        expect(result.first.matchPercent, 90);
        expect(result.first.rating, 4.2);
        expect(result.first.reviewCount, 100);
        expect(result.first.price, 'Free');
        expect(result.first.aiInsight, '');
      },
    );

    test('heals JSON array closed with } instead of ] (Gemini model bug)', () {
      final jsonStr =
          '[{"name": "Phu Quoc", "matchPercent": 98, "rating": 4.8, "reviewCount": 100, "price": "5M VNĐ", "aiInsight": "Great", "isTopMatch": true}]'
              .replaceFirst(']', '}');
      final result = GeminiService.instance.parseSuggestionsSync(jsonStr);
      expect(result, isNotEmpty);
      expect(result.first.name, 'Phu Quoc');
    });

    test('heals multi-item JSON array closed with } instead of ]', () {
      const jsonStr = '''[
  {"name": "Phu Quoc", "matchPercent": 98, "rating": 4.8, "reviewCount": 100, "price": "5M VNĐ", "aiInsight": "Great beach", "isTopMatch": true},
  {"name": "Da Nang", "matchPercent": 85, "rating": 4.5, "reviewCount": 80, "price": "3M VNĐ", "aiInsight": "Great city", "isTopMatch": false}
}''';
      final result = GeminiService.instance.parseSuggestionsSync(jsonStr);
      expect(result.length, 2);
      expect(result.first.name, 'Phu Quoc');
      expect(result.last.name, 'Da Nang');
    });
  });

  group('buildSuggestionsPrompt - prompt-first behavior', () {
    test('prompt-only trip asks AI to infer the destination, not Vietnam', () {
      final trip = TripData(aiPrompt: 'Đi biển 5 ngày cùng gia đình 4 người');
      final prompt = GeminiService.instance.buildSuggestionsPrompt(
        trip,
        5,
        'vi',
      );
      expect(prompt, contains('suy ra điểm đến'));
      expect(prompt, isNot(contains('Điểm đến mong muốn: Việt Nam')));
      expect(
        prompt,
        contains('Mô tả chuyến đi: Đi biển 5 ngày cùng gia đình 4 người'),
      );
    });

    test('explicit destination field still wins over inference', () {
      final trip = TripData(destination: 'Đà Lạt', aiPrompt: 'nghỉ dưỡng');
      final prompt = GeminiService.instance.buildSuggestionsPrompt(
        trip,
        5,
        'vi',
      );
      expect(prompt, contains('Điểm đến mong muốn: Đà Lạt'));
      expect(prompt, isNot(contains('suy ra điểm đến')));
    });

    test('fully empty trip keeps the Vietnam fallback', () {
      final prompt = GeminiService.instance.buildSuggestionsPrompt(
        TripData(),
        5,
        'vi',
      );
      expect(prompt, contains('Điểm đến mong muốn: Việt Nam'));
    });

    test('missing dates and party size point the AI at the description', () {
      final trip = TripData(aiPrompt: 'Đi 5 ngày, 4 người lớn');
      final prompt = GeminiService.instance.buildSuggestionsPrompt(
        trip,
        5,
        'vi',
      );
      expect(prompt, contains('nếu mô tả chuyến đi nêu thời gian'));
      expect(prompt, contains('suy ra từ mô tả chuyến đi'));
    });
  });

  group('buildDetailPrompt - prompt-first behavior', () {
    test('includes the trip description and drops the fake date fallback', () {
      final trip = TripData(aiPrompt: 'Đi 5 ngày với bố mẹ, thích ẩm thực');
      final prompt = GeminiService.instance.buildDetailPrompt(
        'Đà Nẵng',
        trip,
        'vi',
      );
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
      final prompt = GeminiService.instance.buildDetailPrompt(
        'Đà Nẵng',
        trip,
        'vi',
      );
      expect(prompt, isNot(contains('Linh hoạt')));
    });
  });

  group('buildItineraryPrompt - prompt-first behavior', () {
    test('no dates: lets the AI honor a day count from the description', () {
      final trip = TripData(aiPrompt: 'Chuyến đi 5 ngày khám phá ẩm thực');
      final prompt = GeminiService.instance.buildItineraryPrompt(
        'Huế',
        3,
        trip,
        4,
        'vi',
        null,
      );
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
      final prompt = GeminiService.instance.buildItineraryPrompt(
        'Huế',
        3,
        trip,
        4,
        'vi',
        null,
      );
      expect(prompt, isNot(contains('nêu số ngày cụ thể')));
    });
  });

  group('parseExtractedTripData', () {
    final service = GeminiService.instance;

    test(
      'JSON day du: moi truong vao dung cho, participants so thanh chuoi',
      () {
        final trip = service.parseExtractedTripData('''
{"destination":"Da Lat","departDate":"2026-10-01","returnDate":"2026-10-03",
 "numDays":3,"budgetTier":"economy","participants":4,"ageRange":"30-40",
 "interests":["food","culture"]}
''', originalPrompt: 'Di Da Lat');
        expect(trip.destination, 'Da Lat');
        expect(trip.departDate, DateTime(2026, 10, 1));
        expect(trip.returnDate, DateTime(2026, 10, 3));
        expect(trip.budget, 'economy');
        expect(trip.participants, '4');
        expect(trip.ageRange, '30-40');
        expect(trip.selectedInterests, ['food', 'culture']);
        expect(trip.aiPrompt, 'Di Da Lat');
      },
    );

    test('JSON chi co destination: cac truong khac rong', () {
      final trip = service.parseExtractedTripData('{"destination":"Hue"}');
      expect(trip.destination, 'Hue');
      expect(trip.departDate, isNull);
      expect(trip.returnDate, isNull);
      expect(trip.budget, '');
      expect(trip.participants, '');
      expect(trip.ageRange, '');
      expect(trip.selectedInterests, isEmpty);
    });

    test('tier la va interest la bi bo, interest hop le giu lai', () {
      final trip = service.parseExtractedTripData(
        '{"budgetTier":"cheap","interests":["beach","shopping"]}',
      );
      expect(trip.budget, '');
      expect(trip.selectedInterests, ['beach']);
    });

    test('departDate + numDays khong co returnDate: tinh returnDate', () {
      final trip = service.parseExtractedTripData(
        '{"departDate":"2026-10-01","numDays":3}',
      );
      expect(trip.departDate, DateTime(2026, 10, 1));
      expect(trip.returnDate, DateTime(2026, 10, 3));
    });

    test('chi numDays khong co departDate: ca hai ngay null', () {
      final trip = service.parseExtractedTripData('{"numDays":5}');
      expect(trip.departDate, isNull);
      expect(trip.returnDate, isNull);
    });

    test('participants khong phai so thi rong', () {
      final trip = service.parseExtractedTripData(
        '{"participants":"gia dinh"}',
      );
      expect(trip.participants, '');
    });

    test('chuoi "null" duoc coi la rong', () {
      final trip = service.parseExtractedTripData(
        '{"destination":"null","ageRange":"NULL"}',
      );
      expect(trip.destination, '');
      expect(trip.ageRange, '');
    });

    test('ngay co gio va Z duoc chuan hoa ve date-only local', () {
      final trip = service.parseExtractedTripData(
        '{"departDate":"2026-10-01T00:00:00Z","returnDate":"2026-10-03T15:30:00Z"}',
      );
      expect(trip.departDate, DateTime(2026, 10, 1));
      expect(trip.returnDate, DateTime(2026, 10, 3));
    });
  });

  group('buildExtractPrompt', () {
    test('chua mo ta, ngay hom nay va danh sach interest hop le', () {
      final p = GeminiService.instance.buildExtractPrompt(
        'Di bien voi ban',
        'vi',
        DateTime(2026, 9, 7),
      );
      expect(p, contains('Di bien voi ban'));
      expect(p, contains('2026-09-07'));
      expect(p, contains('beach, adventure, culture, food, wellness'));
      expect(p, contains('economy | moderate | premium | luxury'));
      expect(p, contains('không dịch'));
    });
  });

  group('fillEmptyLandmarkImages', () {
    const main = 'https://upload.wikimedia.org/x/Main.jpg';

    test('landmark rong lay anh chinh, landmark co anh giu nguyen', () {
      final gallery = [
        const DestinationLandmarkPhoto(title: 'Cau Vang', imageUrl: ''),
        const DestinationLandmarkPhoto(
          title: 'Ba Na',
          imageUrl: 'https://upload.wikimedia.org/x/BaNa.jpg',
        ),
      ];

      final filled = GeminiService.fillEmptyLandmarkImages(gallery, main);

      expect(filled[0].title, 'Cau Vang');
      expect(filled[0].imageUrl, main);
      expect(filled[1].imageUrl, 'https://upload.wikimedia.org/x/BaNa.jpg');
    });

    test('anh chinh rong thi giu gallery nguyen ven', () {
      final gallery = [
        const DestinationLandmarkPhoto(title: 'Cau Vang', imageUrl: ''),
      ];

      final filled = GeminiService.fillEmptyLandmarkImages(gallery, '');

      expect(filled.single.imageUrl, isEmpty);
    });
  });
}
