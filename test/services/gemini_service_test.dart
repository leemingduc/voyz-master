import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/data/ai_model_settings.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/models/destination_detail.dart';
import 'package:voyz/models/plan_turn.dart';
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

    test('requires exact days and five to six activities per day', () {
      final prompt = GeminiService.instance.buildItineraryPrompt(
        'Hue',
        7,
        TripData(),
        6,
        'en',
        null,
      );

      expect(prompt, contains('Return exactly 7 entries in `days`'));
      expect(
        prompt,
        contains('Every day must contain 5 to 6 time-stamped activities'),
      );
    });
  });
  group('parseTripMap', () {
    final service = GeminiService.instance;
    Map<String, dynamic> m(String json) =>
        jsonDecode(json) as Map<String, dynamic>;

    test(
      'JSON day du: moi truong vao dung cho, participants so thanh chuoi',
      () {
        final trip = service.parseTripMap(m('''
{"destination":"Da Lat","departDate":"2026-10-01","returnDate":"2026-10-03",
 "numDays":3,"budgetTier":"economy","participants":4,"ageRange":"30-40",
 "interests":["food","culture"]}
'''), originalPrompt: 'Di Da Lat');
        expect(trip.destination, 'Da Lat');
        expect(trip.departDate, DateTime(2026, 10, 1));
        expect(trip.returnDate, DateTime(2026, 10, 3));
        expect(trip.numDays, 3);
        expect(trip.budget, 'economy');
        expect(trip.participants, '4');
        expect(trip.ageRange, '30-40');
        expect(trip.selectedInterests, ['food', 'culture']);
        expect(trip.aiPrompt, 'Di Da Lat');
      },
    );

    test('JSON chi co destination: cac truong khac rong', () {
      final trip = service.parseTripMap(m('{"destination":"Hue"}'));
      expect(trip.destination, 'Hue');
      expect(trip.departDate, isNull);
      expect(trip.returnDate, isNull);
      expect(trip.numDays, isNull);
      expect(trip.budget, '');
      expect(trip.participants, '');
      expect(trip.ageRange, '');
      expect(trip.selectedInterests, isEmpty);
    });

    test('tier la va interest la bi bo, interest hop le giu lai', () {
      final trip = service.parseTripMap(
        m('{"budgetTier":"cheap","interests":["beach","shopping"]}'),
      );
      expect(trip.budget, '');
      expect(trip.selectedInterests, ['beach']);
    });

    test('departDate + numDays khong co returnDate: tinh returnDate', () {
      final trip = service.parseTripMap(
        m('{"departDate":"2026-10-01","numDays":3}'),
      );
      expect(trip.departDate, DateTime(2026, 10, 1));
      expect(trip.returnDate, DateTime(2026, 10, 3));
    });

    test('chi numDays khong co departDate: giu numDays, hai ngay null', () {
      final trip = service.parseTripMap(m('{"numDays":5}'));
      expect(trip.departDate, isNull);
      expect(trip.returnDate, isNull);
      expect(trip.numDays, 5);
      expect(trip.dayCount(), 5);
    });

    test('numDays dang chuoi van doc duoc, so am bi bo', () {
      expect(service.parseTripMap(m('{"numDays":"7"}')).numDays, 7);
      expect(service.parseTripMap(m('{"numDays":-2}')).numDays, isNull);
    });

    test('participants khong phai so thi rong', () {
      final trip = service.parseTripMap(m('{"participants":"gia dinh"}'));
      expect(trip.participants, '');
    });

    test('chuoi "null" duoc coi la rong', () {
      final trip = service.parseTripMap(
        m('{"destination":"null","ageRange":"NULL"}'),
      );
      expect(trip.destination, '');
      expect(trip.ageRange, '');
    });

    test('ngay co gio va Z duoc chuan hoa ve date-only local', () {
      final trip = service.parseTripMap(
        m('{"departDate":"2026-10-01T00:00:00Z","returnDate":"2026-10-03T15:30:00Z"}'),
      );
      expect(trip.departDate, DateTime(2026, 10, 1));
      expect(trip.returnDate, DateTime(2026, 10, 3));
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

  group('parsePlanTurn', () {
    final service = GeminiService.instance;

    test('question turn: reply and trip, no options', () {
      final turn = service.parsePlanTurn(
        '{"reply":"Bạn đi mấy ngày?","trip":{"destination":"Côn Đảo"},"options":[]}',
      );
      expect(turn.reply, 'Bạn đi mấy ngày?');
      expect(turn.trip.destination, 'Côn Đảo');
      expect(turn.hasOptions, isFalse);
      expect(turn.raw, contains('Bạn đi mấy ngày?'));
    });

    test('options turn: fields mapped, imageStop kept', () {
      final turn = service.parsePlanTurn('''
{"reply":"3 phương án cho bạn","trip":{"destination":"Côn Đảo","numDays":4},
 "options":[{"title":"Biển & lặn","destination":"Côn Đảo, Việt Nam","numDays":4,
   "stops":["Bến Đầm"," Hòn Bảy Cạnh ",""],"imageStop":"Hòn Bảy Cạnh",
   "price":"~6.5M VND","aiInsight":"Hợp bạn trẻ"}]}
''');
      final option = turn.options.single;
      expect(option.title, 'Biển & lặn');
      expect(option.destination, 'Côn Đảo, Việt Nam');
      expect(option.numDays, 4);
      expect(option.stops, ['Bến Đầm', 'Hòn Bảy Cạnh']);
      expect(option.imageStop, 'Hòn Bảy Cạnh');
      expect(option.price, '~6.5M VND');
      expect(option.aiInsight, 'Hợp bạn trẻ');
      expect(option.imageUrl, '');
    });

    test('bad options dropped, fallbacks applied, at most 3 kept', () {
      final turn = service.parsePlanTurn('''
{"reply":"r","trip":{"numDays":5},"options":[
 {"title":"","destination":"A","stops":["x"]},
 {"title":"T1","destination":"","stops":["x"]},
 {"title":"T2","destination":"D","stops":[]},
 {"title":"T3","destination":"D","stops":["s1","s2"]},
 {"title":"T4","destination":"D","stops":["a","b","c","d","e","f"],"numDays":2},
 {"title":"T5","destination":"D","stops":["y"]},
 {"title":"T6","destination":"D","stops":["z"]}
]}
''');
      expect(turn.options.map((o) => o.title), ['T3', 'T4', 'T5']);
      expect(turn.options[0].imageStop, 's1');
      expect(turn.options[0].numDays, 5);
      expect(turn.options[1].numDays, 2);
      expect(turn.options[1].stops.length, 5);
    });

    test('numDays falls back to 3 when neither option nor trip has it', () {
      final turn = service.parsePlanTurn(
        '{"reply":"r","trip":{},"options":[{"title":"T","destination":"D","stops":["s"]}]}',
      );
      expect(turn.options.single.numDays, 3);
    });

    test('option numDays is capped at 7 like the itinerary', () {
      final turn = service.parsePlanTurn(
        '{"reply":"r","trip":{"numDays":14},"options":['
        '{"title":"A","destination":"D","numDays":14,"stops":["s"]},'
        '{"title":"B","destination":"D","stops":["s"]}]}',
      );
      expect(turn.options.map((o) => o.numDays), [7, 7]);
    });

    test('missing keys and invalid JSON give an empty turn', () {
      final empty = service.parsePlanTurn('{}');
      expect(empty.reply, '');
      expect(empty.hasOptions, isFalse);
      final broken = service.parsePlanTurn('not json at all');
      expect(broken.reply, '');
      expect(broken.hasOptions, isFalse);
    });
  });

  group('questionsSinceLastOptions', () {
    PlannerMessage ask() =>
        PlannerMessage.agent(PlanTurn(reply: 'q', trip: TripData()));
    PlannerMessage offer() => PlannerMessage.agent(
      PlanTurn(
        reply: 'r',
        trip: TripData(),
        options: const [
          TripOption(
            title: 'T',
            destination: 'D',
            numDays: 3,
            stops: ['s'],
            imageStop: 's',
            price: '',
            aiInsight: '',
          ),
        ],
      ),
    );
    final user = PlannerMessage.user('u');

    test('counts agent questions, resets after an options turn', () {
      expect(GeminiService.questionsSinceLastOptions([]), 0);
      expect(GeminiService.questionsSinceLastOptions([user, ask(), user]), 1);
      expect(
        GeminiService.questionsSinceLastOptions([
          user,
          ask(),
          user,
          ask(),
          user,
        ]),
        2,
      );
      expect(
        GeminiService.questionsSinceLastOptions([
          user,
          ask(),
          user,
          ask(),
          user,
          offer(),
          user,
          ask(),
          user,
        ]),
        1,
      );
    });
  });

  group('buildPlanTurnPrompt', () {
    final service = GeminiService.instance;
    final messages = [
      PlannerMessage.user('Du lịch Côn Đảo'),
      PlannerMessage.agent(
        PlanTurn(
          reply: 'Bạn đi mấy ngày?',
          trip: TripData(),
          raw: '{"reply":"Bạn đi mấy ngày?"}',
        ),
      ),
      PlannerMessage.user('1 tuần'),
    ];

    test('contains today, the transcript and the destination rule', () {
      final p = service.buildPlanTurnPrompt(
        messages,
        forceOptions: false,
        languageCode: 'vi',
        today: DateTime(2026, 9, 27),
      );
      expect(p, contains('2026-09-27'));
      expect(p, contains('Người dùng: Du lịch Côn Đảo'));
      expect(p, contains('AI (JSON): {"reply":"Bạn đi mấy ngày?"}'));
      expect(p, contains('Người dùng: 1 tuần'));
      expect(p, contains('PHẢI nằm trong điểm đến đó'));
      expect(p, contains('Vietnamese'));
      expect(p, isNot(contains('BẮT BUỘC đưa đúng 3 phương án')));
      expect(p, contains('tên gốc tiếng địa phương có dấu'));
      expect(p, contains('không gộp hai câu hỏi làm một'));
    });

    test('forced turn adds the mandatory options rule', () {
      final p = service.buildPlanTurnPrompt(
        messages,
        forceOptions: true,
        languageCode: 'en',
        today: DateTime(2026, 9, 27),
      );
      expect(p, contains('BẮT BUỘC đưa đúng 3 phương án'));
      expect(p, contains('English'));
    });
  });

  group('pickOptionImages', () {
    TripOption opt(String title, String imageStop, List<String> stops) =>
        TripOption(
          title: title,
          destination: 'Côn Đảo, Việt Nam',
          numDays: 4,
          stops: stops,
          imageStop: imageStop,
          price: '',
          aiInsight: '',
        );

    test('three cards never share a photo', () async {
      final options = [
        opt('A', 'Hòn Bảy Cạnh', ['Bến Đầm', 'Hòn Bảy Cạnh']),
        opt('B', 'Hòn Bảy Cạnh', ['Hòn Bảy Cạnh', 'Nhà tù Côn Đảo']),
        opt('C', 'Bãi Đầm Trầu', ['Bãi Đầm Trầu']),
      ];
      const urls = {
        'Hòn Bảy Cạnh, Côn Đảo, Việt Nam': 'https://img/hon-bay-canh.jpg',
        'Bến Đầm, Côn Đảo, Việt Nam': 'https://img/ben-dam.jpg',
        'Nhà tù Côn Đảo, Côn Đảo, Việt Nam': 'https://img/nha-tu.jpg',
        'Bãi Đầm Trầu, Côn Đảo, Việt Nam': 'https://img/hon-bay-canh.jpg',
        'Côn Đảo, Việt Nam': 'https://img/con-dao.jpg',
      };
      final result = await GeminiService.pickOptionImages(
        options,
        (q) async => urls[q] ?? '',
      );
      expect(result.map((o) => o.imageUrl), [
        'https://img/hon-bay-canh.jpg',
        'https://img/nha-tu.jpg',
        'https://img/con-dao.jpg',
      ]);
      expect(result.map((o) => o.title), ['A', 'B', 'C']);
    });

    test('lookup errors and misses end with an empty url', () async {
      final result = await GeminiService.pickOptionImages([
        opt('A', 'X', ['X', 'Y']),
      ], (q) async => q.startsWith('Y') ? throw Exception('429') : '');
      expect(result.single.imageUrl, '');
    });
  });
}
