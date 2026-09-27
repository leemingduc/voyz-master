# Planner Chat Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the Smart Planner into a Gemini style chat that asks short questions when needed and shows 3 trip option cards (theme, duration, route of named stops) in the chat; tapping a card opens the existing `DestinationDetailScreen`.

**Architecture:** One structured Gemini call per turn (`GeminiService.planTurn`) with a `responseSchema`, returning `reply`, `trip` and `options`. The planner screen keeps the conversation in state, renders bubbles and option cards, and on pick writes `TripData` (with the chosen route in `aiPrompt`) to `SavedTripsProvider` before pushing the unchanged detail screen. `SuggestionsScreen` and the old suggestions/extraction code are deleted.

**Tech Stack:** Flutter 3.38, Dart, `google_generative_ai` 0.4.7 (`Schema`, `GenerationConfig.responseSchema`), `flutter_test`, ARB l10n via `flutter gen-l10n`.

**Spec:** `docs/superpowers/specs/2026-09-27-planner-chat-design.md`. Roadmap: `docs/project_phase3_roadmap_ai_first.md` section 2.6.

## Global Constraints

- Work on branch `planner-chat`. Never commit to `master`. Stage only the files each task names (the working tree has unrelated `ios/` and `macos/` changes and `docs/ui_redesign_prompt.md`; never stage them).
- Commit messages end with the line `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- No em dash or en dash characters anywhere (code, comments, docs, commit messages).
- Every AI call goes through `GeminiService`. Screens never import `google_generative_ai` or `supabase_flutter`.
- No hardcoded image URLs in Dart code.
- Prompts sent to Gemini are written in Vietnamese; only the output language line changes by locale (`GeminiService.languageInstruction`).
- AI numbers are estimates and are labeled ("Ước tính AI").
- Do not change `lib/screens/destination_detail_screen.dart` or `lib/screens/destination_plan_screen.dart`.
- Baseline before this work: `flutter analyze` has 0 errors (18 info/warning items), `flutter test` passes 98 tests. After each task: 0 analyzer errors and all tests pass.
- Code comments follow the file's existing language (Vietnamese in `gemini_service.dart`, `trip_data.dart`, planner screen).

## File Structure

| File | Status | Responsibility |
|---|---|---|
| `lib/data/trip_data.dart` | Modify | `TripData.numDays`, `dayCount()` order: dates, then `numDays`, then fallback |
| `lib/models/plan_turn.dart` | Create | `TripOption`, `PlanTurn`, `PlannerMessage`, `tripForOption()` |
| `lib/services/gemini_service.dart` | Modify | `parseTripMap`, `planTurn`, `buildPlanTurnPrompt`, `parsePlanTurn`, `questionsSinceLastOptions`, `pickOptionImages`, `enrichOptionsWithImages`; delete suggestions and extraction code |
| `lib/widgets/planner/planner_bubble.dart` | Create | Chat bubble in the `ChatScreen` style |
| `lib/widgets/planner/trip_option_card.dart` | Create | Option card in the old `_DestinationCard` style |
| `lib/screens/smart_planner_screen.dart` | Modify | Hero mode plus chat mode, dock, pick handling |
| `lib/screens/suggestions_screen.dart` | Delete | Replaced by the chat |
| `lib/l10n/app_en.arb`, `app_vi.arb`, `app_ko.arb` + generated `app_localizations*.dart` | Modify | 7 new keys, 9 removed keys |
| `test/data/saved_trips_sync_test.dart` | Modify | `numDays` and `dayCount` tests |
| `test/models/plan_turn_test.dart` | Create | `tripForOption`, `PlannerMessage` |
| `test/services/gemini_service_test.dart` | Modify | New planner tests; remove suggestions/extraction prompt tests |
| `test/widgets/trip_option_card_test.dart` | Create | Card renders title, duration, route, estimate label |

---

### Task 1: `TripData.numDays` and `dayCount`

**Files:**
- Modify: `lib/data/trip_data.dart:5-94`
- Test: `test/data/saved_trips_sync_test.dart` (inside the existing group, after the `TripData.dayCount tinh ca ngay di va ngay ve, kep 1..7` test, around line 123)

**Interfaces:**
- Produces: `TripData({..., int? numDays})` with a mutable field `int? numDays;` (the other `TripData` fields are mutable too). `copyWith({..., int? numDays})`. `toMap()` key `'numDays'`. `fromMap` reads `'numDays'`. `int dayCount({int fallback = 3})`.

- [ ] **Step 1: Write the failing tests**

Add after the existing `dayCount` test in `test/data/saved_trips_sync_test.dart`:

```dart
    test('TripData.dayCount dung numDays khi khong co ngay', () {
      expect(TripData(numDays: 7).dayCount(), equals(7));
      expect(TripData(numDays: 4).dayCount(), equals(4));
      expect(TripData(numDays: 10).dayCount(), equals(7));
      expect(TripData(numDays: 0).dayCount(), equals(3));
    });

    test('TripData.dayCount uu tien ngay di/ve hon numDays', () {
      expect(
        TripData(
          departDate: DateTime(2026, 10, 10),
          returnDate: DateTime(2026, 10, 13),
          numDays: 7,
        ).dayCount(),
        equals(4),
      );
    });

    test('TripData numDays di qua toMap/fromMap/copyWith', () {
      final trip = TripData(destination: 'Con Dao', numDays: 5);
      final restored = TripData.fromMap(trip.toMap());
      expect(restored.numDays, equals(5));
      expect(TripData.fromMap({'numDays': '6'}).numDays, equals(6));
      expect(TripData.fromMap({}).numDays, isNull);
      expect(trip.copyWith(destination: 'Hue').numDays, equals(5));
      expect(trip.copyWith(numDays: 2).numDays, equals(2));
    });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/data/saved_trips_sync_test.dart`
Expected: compile error, `No named parameter with the name 'numDays'`.

- [ ] **Step 3: Implement**

In `lib/data/trip_data.dart`, class `TripData`:

1. Add the field after `String aiPrompt;`:

```dart
  /// Số ngày người dùng nêu bằng thời lượng ("1 tuần", "4 ngày 3 đêm")
  /// khi không có ngày đi/về cụ thể. Null là không rõ.
  int? numDays;
```

2. Constructor: add `this.numDays,` after `this.aiPrompt = '',`.

3. `fromMap`: add after the `aiPrompt:` line:

```dart
      numDays: int.tryParse(map['numDays']?.toString() ?? ''),
```

4. `copyWith`: add parameter `int? numDays,` after `String? aiPrompt,` and in the returned `TripData(...)` add `numDays: numDays ?? this.numDays,` after the `aiPrompt:` line.

5. `toMap()`: add `'numDays': numDays,` after `'aiPrompt': aiPrompt,`.

6. Replace `dayCount` (lines 84-88) with:

```dart
  /// Số ngày của chuyến đi, tối đa 7. Có ngày đi và ngày về thì tính cả hai
  /// ngày; không có thì dùng [numDays]; không có nữa mới dùng [fallback].
  int dayCount({int fallback = 3}) {
    final int days;
    if (departDate != null && returnDate != null) {
      days = returnDate!.difference(departDate!).inDays + 1;
    } else if (numDays != null && numDays! > 0) {
      days = numDays!;
    } else {
      days = fallback;
    }
    return days.clamp(1, 7).toInt();
  }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/data/saved_trips_sync_test.dart`
Expected: all tests pass (including the existing `dayCount` test, where `fallback: 5` still returns 5).

- [ ] **Step 5: Commit**

```bash
git add lib/data/trip_data.dart test/data/saved_trips_sync_test.dart
git commit -m "feat(trip): keep trip length as numDays when there are no dates

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: `parseTripMap` keeps `numDays`

Refactor `parseExtractedTripData(String)` into `parseTripMap(Map)` so the planner turn can reuse it. `extractTripData` keeps working until Task 8 deletes it.

**Files:**
- Modify: `lib/services/gemini_service.dart:121-210`
- Test: `test/services/gemini_service_test.dart:314-391` (group `parseExtractedTripData`)

**Interfaces:**
- Consumes: `TripData.numDays` (Task 1).
- Produces: `TripData parseTripMap(Map<String, dynamic> map, {String originalPrompt = ''})` (public, `@visibleForTesting`), and private `static int? _toInt(dynamic value)` in `GeminiService`.

- [ ] **Step 1: Rewrite the test group**

In `test/services/gemini_service_test.dart`, rename the group `parseExtractedTripData` to `parseTripMap` and change every call `service.parseExtractedTripData('<json>'...)` to `service.parseTripMap(jsonDecode('<json>') as Map<String, dynamic>...)`. Add `import 'dart:convert';` at the top of the file. The full group becomes:

```dart
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
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/services/gemini_service_test.dart`
Expected: compile error, `The method 'parseTripMap' isn't defined`.

- [ ] **Step 3: Implement**

In `lib/services/gemini_service.dart`:

1. Add under `_cleanString` (around line 117):

```dart
  /// Số nguyên từ JSON (số hoặc chuỗi số). Không đọc được thì null.
  static int? _toInt(dynamic value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString().trim() ?? '');
```

2. In `extractTripData`, replace `return parseExtractedTripData(text, originalPrompt: prompt);` with:

```dart
    final decoded = safeJsonDecode(text);
    return parseTripMap(
      decoded is Map ? Map<String, dynamic>.from(decoded) : {},
      originalPrompt: prompt,
    );
```

3. Replace the whole `parseExtractedTripData` method (doc comment through closing brace, lines 165-210) with:

```dart
  /// Parser thuần cho object `trip` do AI trả. Key thiếu hoặc sai thì để rỗng.
  /// `numDays` luôn được giữ, kể cả khi không có ngày đi.
  @visibleForTesting
  TripData parseTripMap(
    Map<String, dynamic> map, {
    String originalPrompt = '',
  }) {
    DateTime? depart = DateTime.tryParse(map['departDate']?.toString() ?? '');
    DateTime? ret = DateTime.tryParse(map['returnDate']?.toString() ?? '');
    final rawDays = _toInt(map['numDays']);
    final numDays = rawDays != null && rawDays > 0 ? rawDays : null;
    if (depart != null && ret == null && numDays != null) {
      ret = depart.add(Duration(days: numDays - 1));
    }
    // Chỉ có ngày về mà không có ngày đi thì bỏ, không dùng được.
    if (depart == null) ret = null;

    DateTime? dateOnly(DateTime? d) =>
        d == null ? null : DateTime(d.year, d.month, d.day);
    depart = dateOnly(depart);
    ret = dateOnly(ret);

    final tier = map['budgetTier']?.toString().trim().toLowerCase() ?? '';
    final participants = _toInt(map['participants']);
    final interests = TripData.stringList(map['interests'])
        .map((e) => e.trim().toLowerCase())
        .where(MockData.interests.contains)
        .toList();

    return TripData(
      destination: _cleanString(map['destination']),
      departDate: depart,
      returnDate: ret,
      numDays: numDays,
      budget: _validTiers.contains(tier) ? tier : '',
      participants: participants?.toString() ?? '',
      ageRange: _cleanString(map['ageRange']),
      aiPrompt: originalPrompt,
      selectedInterests: interests,
    );
  }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/services/gemini_service_test.dart`
Expected: PASS. Then run `flutter analyze` and confirm 0 errors.

- [ ] **Step 5: Commit**

```bash
git add lib/services/gemini_service.dart test/services/gemini_service_test.dart
git commit -m "refactor(ai): parse the trip object from a map and keep numDays

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Planner models

**Files:**
- Create: `lib/models/plan_turn.dart`
- Test: `test/models/plan_turn_test.dart`

**Interfaces:**
- Consumes: `TripData.numDays`, `TripData.copyWith(numDays:)` (Task 1).
- Produces (exact):
  - `class TripOption { const TripOption({required String title, required String destination, required int numDays, required List<String> stops, required String imageStop, required String price, required String aiInsight, String imageUrl = ''}); TripOption copyWith({String? imageUrl}); }`
  - `class PlanTurn { const PlanTurn({required String reply, required TripData trip, List<TripOption> options = const [], String raw = ''}); bool get hasOptions; PlanTurn copyWith({List<TripOption>? options}); }`
  - `class PlannerMessage { factory PlannerMessage.user(String text); factory PlannerMessage.agent(PlanTurn turn); final String text; final PlanTurn? turn; bool get isUser; }`
  - `TripData tripForOption(PlanTurn turn, TripOption option, List<String> userMessages)`

- [ ] **Step 1: Write the failing test**

Create `test/models/plan_turn_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/models/plan_turn.dart';

void main() {
  const option = TripOption(
    title: 'Biển & lặn',
    destination: 'Côn Đảo, Việt Nam',
    numDays: 4,
    stops: ['Bến Đầm', 'Hòn Bảy Cạnh', 'Bãi Đầm Trầu'],
    imageStop: 'Hòn Bảy Cạnh',
    price: '~6.5M VND',
    aiInsight: 'Hợp nhóm bạn thích biển',
  );

  group('PlannerMessage', () {
    test('user message has no turn', () {
      final m = PlannerMessage.user('Du lịch Côn Đảo');
      expect(m.isUser, isTrue);
      expect(m.text, 'Du lịch Côn Đảo');
      expect(m.turn, isNull);
    });

    test('agent message takes text from the turn reply', () {
      final turn = PlanTurn(reply: 'Bạn đi mấy ngày?', trip: TripData());
      final m = PlannerMessage.agent(turn);
      expect(m.isUser, isFalse);
      expect(m.text, 'Bạn đi mấy ngày?');
      expect(m.turn, same(turn));
    });
  });

  group('PlanTurn and TripOption', () {
    test('hasOptions reflects the list', () {
      expect(PlanTurn(reply: 'q', trip: TripData()).hasOptions, isFalse);
      expect(
        PlanTurn(reply: 'r', trip: TripData(), options: [option]).hasOptions,
        isTrue,
      );
    });

    test('copyWith replaces only what is given', () {
      final withImage = option.copyWith(imageUrl: 'https://x/y.jpg');
      expect(withImage.imageUrl, 'https://x/y.jpg');
      expect(withImage.title, option.title);
      expect(withImage.stops, option.stops);

      final turn = PlanTurn(reply: 'r', trip: TripData(), raw: '{}');
      final updated = turn.copyWith(options: [withImage]);
      expect(updated.options.single.imageUrl, 'https://x/y.jpg');
      expect(updated.raw, '{}');
      expect(updated.reply, 'r');
    });
  });

  group('tripForOption', () {
    test('sets destination, numDays and the chosen route in aiPrompt', () {
      final turn = PlanTurn(
        reply: 'r',
        trip: TripData(destination: 'Côn Đảo', participants: '2'),
        options: const [option],
      );
      final trip = tripForOption(turn, option, [
        'Du lịch Côn Đảo',
        '  ',
        '4 ngày, 2 người',
      ]);
      expect(trip.destination, 'Côn Đảo, Việt Nam');
      expect(trip.numDays, 4);
      expect(trip.participants, '2');
      expect(
        trip.aiPrompt,
        'Du lịch Côn Đảo\n4 ngày, 2 người\n'
        'Phương án đã chọn: Biển & lặn, 4 ngày, '
        'lộ trình: Bến Đầm, Hòn Bảy Cạnh, Bãi Đầm Trầu.',
      );
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/models/plan_turn_test.dart`
Expected: compile error, `Target of URI doesn't exist: 'package:voyz/models/plan_turn.dart'`.

- [ ] **Step 3: Implement**

Create `lib/models/plan_turn.dart`:

```dart
import 'package:voyz/data/trip_data.dart';

/// Một phương án chuyến đi AI đưa ra trong planner chat: một chủ đề,
/// một thời lượng và lộ trình nhiều điểm dừng trong cùng điểm đến gốc.
class TripOption {
  const TripOption({
    required this.title,
    required this.destination,
    required this.numDays,
    required this.stops,
    required this.imageStop,
    required this.price,
    required this.aiInsight,
    this.imageUrl = '',
  });

  /// Chủ đề, ví dụ "Biển & lặn ngắm san hô".
  final String title;

  /// Điểm đến gốc dạng "Côn Đảo, Việt Nam". Truyền nguyên cho màn chi tiết.
  final String destination;
  final int numDays;

  /// 3-5 địa danh có tên riêng theo thứ tự đi.
  final List<String> stops;

  /// Địa danh tiêu biểu nhất cho chủ đề, dùng để tra ảnh.
  final String imageStop;

  /// Giá ước tính của AI (chuỗi kèm mã tiền tệ), không phải báo giá.
  final String price;
  final String aiInsight;

  /// Rỗng tới khi tra ảnh xong; rỗng mãi thì UI vẽ placeholder.
  final String imageUrl;

  TripOption copyWith({String? imageUrl}) => TripOption(
    title: title,
    destination: destination,
    numDays: numDays,
    stops: stops,
    imageStop: imageStop,
    price: price,
    aiInsight: aiInsight,
    imageUrl: imageUrl ?? this.imageUrl,
  );
}

/// Một lượt trả lời của AI trong planner chat.
class PlanTurn {
  const PlanTurn({
    required this.reply,
    required this.trip,
    this.options = const [],
    this.raw = '',
  });

  /// Câu hỏi thêm, hoặc câu giới thiệu khi có phương án.
  final String reply;

  /// Mọi thông tin chuyến đi đã biết tới lượt này.
  final TripData trip;

  /// Rỗng khi AI đang hỏi thêm.
  final List<TripOption> options;

  /// JSON gốc, gửi lại cho AI làm lịch sử hội thoại.
  final String raw;

  bool get hasOptions => options.isNotEmpty;

  PlanTurn copyWith({List<TripOption>? options}) => PlanTurn(
    reply: reply,
    trip: trip,
    options: options ?? this.options,
    raw: raw,
  );
}

/// Một tin nhắn trong planner chat: của người dùng ([turn] null) hoặc của AI.
class PlannerMessage {
  const PlannerMessage._(this.text, this.turn);

  factory PlannerMessage.user(String text) => PlannerMessage._(text, null);

  factory PlannerMessage.agent(PlanTurn turn) =>
      PlannerMessage._(turn.reply, turn);

  final String text;
  final PlanTurn? turn;

  bool get isUser => turn == null;
}

/// TripData giao cho màn chi tiết khi người dùng chọn [option].
///
/// Lộ trình đã chọn nằm trong `aiPrompt`: prompt chi tiết và itinerary đã đọc
/// `aiPrompt`, nên itinerary bám theo lộ trình mà không phải sửa hai màn đó.
TripData tripForOption(
  PlanTurn turn,
  TripOption option,
  List<String> userMessages,
) {
  final chosen =
      'Phương án đã chọn: ${option.title}, ${option.numDays} ngày, '
      'lộ trình: ${option.stops.join(', ')}.';
  final lines = [
    ...userMessages.map((m) => m.trim()).where((m) => m.isNotEmpty),
    chosen,
  ];
  return turn.trip.copyWith(
    destination: option.destination,
    numDays: option.numDays,
    aiPrompt: lines.join('\n'),
  );
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/models/plan_turn_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/plan_turn.dart test/models/plan_turn_test.dart
git commit -m "feat(planner): add plan turn, trip option and message models

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: `planTurn` in `GeminiService`

**Files:**
- Modify: `lib/services/gemini_service.dart` (imports at the top; new section after `parseTripMap`, before `// ── Explore`)
- Test: `test/services/gemini_service_test.dart` (new groups at the end of `main`)

**Interfaces:**
- Consumes: `parseTripMap`, `_toInt`, `_cleanString`, `_validTiers`, `safeJsonDecode`, `languageInstruction`, `_createModel` (existing / Task 2); models from Task 3.
- Produces:
  - `Future<PlanTurn> planTurn(List<PlannerMessage> messages, {bool forceOptions = false, String languageCode = 'vi'})`
  - `@visibleForTesting String buildPlanTurnPrompt(List<PlannerMessage> messages, {required bool forceOptions, required String languageCode, required DateTime today})`
  - `@visibleForTesting PlanTurn parsePlanTurn(String text)`
  - `static int questionsSinceLastOptions(List<PlannerMessage> messages)`

- [ ] **Step 1: Write the failing tests**

Add `import 'package:voyz/models/plan_turn.dart';` to `test/services/gemini_service_test.dart`, then add at the end of `main()`:

```dart
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
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/services/gemini_service_test.dart`
Expected: compile errors, `parsePlanTurn`, `questionsSinceLastOptions`, `buildPlanTurnPrompt` not defined.

- [ ] **Step 3: Implement**

In `lib/services/gemini_service.dart`:

1. Add the import after `import 'package:voyz/models/itinerary_plan.dart';`:

```dart
import 'package:voyz/models/plan_turn.dart';
```

2. Add this section right after the closing brace of `parseTripMap`, before `// ── Explore (independent, no TripData needed)`:

```dart
  // ── Planner chat (roadmap 2.6) ────────────────────────────────────────

  /// Khung JSON cố định cho mọi lượt planner. Có schema thì model không
  /// thể trả thiếu `reply`, `trip`, `options` hay sai kiểu.
  static final Schema _planTurnSchema = Schema.object(
    properties: {
      'reply': Schema.string(),
      'trip': Schema.object(
        properties: {
          'destination': Schema.string(nullable: true),
          'departDate': Schema.string(nullable: true, description: 'yyyy-MM-dd'),
          'returnDate': Schema.string(nullable: true, description: 'yyyy-MM-dd'),
          'numDays': Schema.integer(nullable: true),
          'budgetTier': Schema.enumString(
            enumValues: _validTiers,
            nullable: true,
          ),
          'participants': Schema.integer(nullable: true),
          'ageRange': Schema.string(nullable: true),
          'interests': Schema.array(
            items: Schema.enumString(enumValues: MockData.interests),
          ),
        },
      ),
      'options': Schema.array(
        items: Schema.object(
          properties: {
            'title': Schema.string(),
            'destination': Schema.string(),
            'numDays': Schema.integer(),
            'stops': Schema.array(items: Schema.string()),
            'imageStop': Schema.string(),
            'price': Schema.string(),
            'aiInsight': Schema.string(),
          },
          requiredProperties: [
            'title',
            'destination',
            'numDays',
            'stops',
            'imageStop',
            'price',
            'aiInsight',
          ],
        ),
      ),
    },
    requiredProperties: ['reply', 'trip', 'options'],
  );

  /// Một lượt planner chat. [messages] là cả hội thoại, tin cuối thường là
  /// của người dùng. Code (không phải model) quyết định lúc nào bắt buộc đưa
  /// phương án: người dùng bấm "Gợi ý luôn", hoặc AI đã hỏi 2 lượt liền.
  /// Không cache: mỗi lượt phụ thuộc cả hội thoại.
  Future<PlanTurn> planTurn(
    List<PlannerMessage> messages, {
    bool forceOptions = false,
    String languageCode = 'vi',
  }) async {
    final force = forceOptions || questionsSinceLastOptions(messages) >= 2;
    final model = _createModel(
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _planTurnSchema,
        temperature: 0.7,
        maxOutputTokens: 12288,
      ),
    );
    final prompt = buildPlanTurnPrompt(
      messages,
      forceOptions: force,
      languageCode: languageCode,
      today: DateTime.now(),
    );
    final text = (await model.generateContent([Content.text(prompt)])).text;
    if (text == null || text.isEmpty) throw Exception('noAiResponse');
    return parsePlanTurn(text);
  }

  /// Số lượt AI hỏi thêm kể từ lượt gần nhất có phương án.
  static int questionsSinceLastOptions(List<PlannerMessage> messages) {
    var count = 0;
    for (final message in messages.reversed) {
      final turn = message.turn;
      if (turn == null) continue;
      if (turn.hasOptions) break;
      count++;
    }
    return count;
  }

  @visibleForTesting
  String buildPlanTurnPrompt(
    List<PlannerMessage> messages, {
    required bool forceOptions,
    required String languageCode,
    required DateTime today,
  }) {
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final transcript = messages
        .map(
          (m) => m.isUser ? 'Người dùng: ${m.text}' : 'AI (JSON): ${m.turn!.raw}',
        )
        .join('\n');
    final forceRule = forceOptions
        ? '\n- LƯỢT NÀY BẮT BUỘC đưa đúng 3 phương án, không hỏi thêm. Thiếu thông tin thì tự giả định hợp lý và nói rõ giả định trong "reply" (ví dụ "Mình giả định 3N2Đ, 2 người").'
        : '';

    return '''
Bạn là chuyên gia tư vấn du lịch AI, trò chuyện với người dùng để lên phương án chuyến đi. Hôm nay là $todayStr.

Hội thoại đến giờ:
$transcript

Nhiệm vụ: trả lời lượt tiếp theo bằng JSON theo schema, gồm "reply", "trip", "options".

Quy tắc:
- "trip" chứa mọi thông tin đã biết từ cả hội thoại. Không bỏ giá trị người dùng đã nêu. Không có thì để null.
- Độ dài chuyến: người dùng nêu ngày đi và ngày về thì điền "departDate" và "returnDate" (yyyy-MM-dd, tính từ hôm nay nếu nói "tuần sau"). Người dùng nêu thời lượng ("4 ngày 3 đêm", "1 tuần", "cuối tuần") thì điền "numDays" (1 tuần là 7, cuối tuần là 2).
- Cần đủ hai thứ mới đưa phương án: điểm đến (hoặc kiểu chuyến như "đi biển") và độ dài chuyến. Thiếu thì hỏi đúng 1 câu ngắn trong "reply" và để "options" là mảng rỗng. Đủ thì đưa phương án ngay, không hỏi thêm.
- Mỗi lượt hỏi tối đa 1 câu.$forceRule
- Khi đưa phương án: đúng 3 phần tử trong "options"; "reply" là 1 câu giới thiệu ngắn.
- Người dùng đã nêu điểm đến thì cả 3 phương án PHẢI nằm trong điểm đến đó, khác nhau ở chủ đề hoặc nhịp đi. Không đưa điểm đến khác. Chưa nêu điểm đến thì mỗi phương án có thể là một điểm đến khác nhau.
- "destination": tên điểm đến gốc dạng "Tên, Quốc gia" (ví dụ "Côn Đảo, Việt Nam").
- "numDays": số ngày của phương án, khớp với độ dài chuyến người dùng muốn.
- "stops": 3 đến 5 địa danh có tên riêng, theo thứ tự đi. Không dùng tên chung như "bãi biển", "chợ đêm", "nhà hàng hải sản".
- "imageStop": một địa danh trong "stops" tiêu biểu nhất cho chủ đề. 3 phương án phải có "imageStop" khác nhau.
- "price": chi phí ước tính thực tế cho 1 người cả chuyến, ghi kèm mã tiền tệ (ví dụ "~6.5M VND").
- "aiInsight": 1 câu vì sao phương án này hợp với người dùng.
- Người dùng muốn chỉnh ("rẻ hơn", "thêm lặn biển") thì đưa bộ 3 phương án mới theo yêu cầu.
- "budgetTier" và "interests" luôn viết bằng tiếng Anh theo đúng giá trị cho phép, không dịch.
- ${languageInstruction(languageCode)}
''';
  }

  /// Parser thuần cho một lượt planner. JSON hỏng thì trả lượt rỗng,
  /// màn planner coi đó là lỗi.
  @visibleForTesting
  PlanTurn parsePlanTurn(String text) {
    Map<String, dynamic> map;
    try {
      final decoded = safeJsonDecode(text);
      map = decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } catch (_) {
      map = {};
    }
    final tripMap = map['trip'] is Map
        ? Map<String, dynamic>.from(map['trip'] as Map)
        : <String, dynamic>{};
    final trip = parseTripMap(tripMap);
    final rawOptions = map['options'] is List ? map['options'] as List : [];
    final options = rawOptions
        .whereType<Map>()
        .map((e) => _parseTripOption(Map<String, dynamic>.from(e), trip))
        .whereType<TripOption>()
        .take(3)
        .toList();
    return PlanTurn(
      reply: _cleanString(map['reply']),
      trip: trip,
      options: options,
      raw: text.trim(),
    );
  }

  /// Phương án thiếu tiêu đề, điểm đến hoặc điểm dừng thì bỏ.
  TripOption? _parseTripOption(Map<String, dynamic> map, TripData trip) {
    final title = _cleanString(map['title']);
    final destination = _cleanString(map['destination']);
    final stops = TripData.stringList(map['stops'])
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .take(5)
        .toList();
    if (title.isEmpty || destination.isEmpty || stops.isEmpty) return null;
    final imageStop = _cleanString(map['imageStop']);
    final days = _toInt(map['numDays']);
    return TripOption(
      title: title,
      destination: destination,
      numDays: days != null && days > 0 ? days : (trip.numDays ?? 3),
      stops: stops,
      imageStop: imageStop.isNotEmpty ? imageStop : stops.first,
      price: _cleanString(map['price']),
      aiInsight: _cleanString(map['aiInsight']),
    );
  }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/services/gemini_service_test.dart`
Expected: PASS. Run `flutter analyze`: 0 errors.

- [ ] **Step 5: Commit**

```bash
git add lib/services/gemini_service.dart test/services/gemini_service_test.dart
git commit -m "feat(ai): add planTurn with a response schema for the planner chat

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Distinct images per option

**Files:**
- Modify: `lib/services/gemini_service.dart` (append to the planner chat section from Task 4)
- Test: `test/services/gemini_service_test.dart` (new group at the end)

**Interfaces:**
- Consumes: `TripOption.copyWith(imageUrl:)` (Task 3), `ImageService.instance.getImageUrl(String)` (existing).
- Produces: `@visibleForTesting static Future<List<TripOption>> pickOptionImages(List<TripOption> options, Future<String> Function(String query) lookup)` and `Future<List<TripOption>> enrichOptionsWithImages(List<TripOption> options)`.

Note for the implementer: `ImageService.getImageUrl` looks up only the text before the first comma, and uses the full string as its cache key. So `"Hòn Bảy Cạnh, Côn Đảo, Việt Nam"` searches "Hòn Bảy Cạnh". This matches `getLandmarkPhotos`.

- [ ] **Step 1: Write the failing test**

Add at the end of `main()` in `test/services/gemini_service_test.dart`:

```dart
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/services/gemini_service_test.dart`
Expected: compile error, `pickOptionImages` not defined.

- [ ] **Step 3: Implement**

Append inside the planner chat section of `GeminiService` (after `_parseTripOption`):

```dart
  /// Tra ảnh cho từng thẻ phương án qua ImageService, không để hai thẻ
  /// trùng ảnh. Lỗi ảnh không làm hỏng kết quả AI.
  Future<List<TripOption>> enrichOptionsWithImages(List<TripOption> options) =>
      pickOptionImages(options, ImageService.instance.getImageUrl);

  /// Thứ tự thử cho mỗi thẻ: `imageStop`, các điểm dừng còn lại, rồi điểm
  /// đến gốc. URL đầu tiên không rỗng và chưa thẻ nào dùng thì lấy.
  @visibleForTesting
  static Future<List<TripOption>> pickOptionImages(
    List<TripOption> options,
    Future<String> Function(String query) lookup,
  ) async {
    final used = <String>{};
    final result = <TripOption>[];
    for (final option in options) {
      final candidates = [
        '${option.imageStop}, ${option.destination}',
        for (final stop in option.stops)
          if (stop != option.imageStop) '$stop, ${option.destination}',
        option.destination,
      ];
      var url = '';
      for (final query in candidates) {
        String found;
        try {
          found = await lookup(query);
        } catch (e) {
          debugPrint('Option image lookup failed (non-fatal): $e');
          found = '';
        }
        if (found.isNotEmpty && !used.contains(found)) {
          url = found;
          break;
        }
      }
      if (url.isNotEmpty) used.add(url);
      result.add(option.copyWith(imageUrl: url));
    }
    return result;
  }
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/services/gemini_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/services/gemini_service.dart test/services/gemini_service_test.dart
git commit -m "feat(ai): pick a different photo for each trip option

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: l10n keys, bubble and option card widgets

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`, `lib/l10n/app_ko.arb` (append before the closing `}`)
- Regenerate: `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_vi.dart`, `app_localizations_ko.dart`
- Create: `lib/widgets/planner/planner_bubble.dart`, `lib/widgets/planner/trip_option_card.dart`
- Test: `test/widgets/trip_option_card_test.dart`

**Interfaces:**
- Consumes: `TripOption` (Task 3); existing `DestinationImage`, `CurrencyAmountText`, `AppTheme`, `AppLocalizations`.
- Produces:
  - l10n getters `suggestNow`, `plannerChatHint`, `plannerSend`, `newPlannerChat`, `aiEstimateLabel`, `viewDetails`, and method `tripDays(int n)`.
  - `class PlannerBubble extends StatelessWidget { const PlannerBubble({super.key, required String text, required bool isUser}); }`
  - `class TripOptionCard extends StatelessWidget { const TripOptionCard({super.key, required TripOption option, required VoidCallback onTap}); }`

- [ ] **Step 1: Add the l10n keys**

In `lib/l10n/app_en.arb`, replace the last line `  "quickPromptsLabel": "Quick ideas:"` with:

```json
  "quickPromptsLabel": "Quick ideas:",
  "suggestNow": "Suggest now",
  "@suggestNow": {"description": "Planner chat button that asks the AI for trip options right away"},
  "plannerChatHint": "Tell the AI more...",
  "@plannerChatHint": {"description": "Hint of the planner chat input"},
  "plannerSend": "Send",
  "@plannerSend": {"description": "Send button of the planner chat"},
  "newPlannerChat": "New chat",
  "@newPlannerChat": {"description": "Tooltip of the button that restarts the planner chat"},
  "aiEstimateLabel": "AI estimate",
  "@aiEstimateLabel": {"description": "Label under an AI generated price"},
  "viewDetails": "View details",
  "@viewDetails": {"description": "Button on a trip option card"},
  "tripDays": "{n, plural, =1{1 day} other{{n} days}}",
  "@tripDays": {"description": "Trip duration badge", "placeholders": {"n": {"type": "int"}}}
```

In `lib/l10n/app_vi.arb`, replace `  "quickPromptsLabel": "Gợi ý nhanh:"` with:

```json
  "quickPromptsLabel": "Gợi ý nhanh:",
  "suggestNow": "Gợi ý luôn",
  "plannerChatHint": "Nhắn thêm cho AI...",
  "plannerSend": "Gửi",
  "newPlannerChat": "Cuộc trò chuyện mới",
  "aiEstimateLabel": "Ước tính AI",
  "viewDetails": "Xem chi tiết",
  "tripDays": "{n} ngày"
```

In `lib/l10n/app_ko.arb`, replace `  "quickPromptsLabel": "빠른 아이디어:"` with:

```json
  "quickPromptsLabel": "빠른 아이디어:",
  "suggestNow": "바로 추천",
  "plannerChatHint": "AI에게 더 알려주세요...",
  "plannerSend": "보내기",
  "newPlannerChat": "새 대화",
  "aiEstimateLabel": "AI 추정",
  "viewDetails": "자세히 보기",
  "tripDays": "{n}일"
```

Run: `flutter gen-l10n`
Expected: no errors; `lib/l10n/app_localizations.dart` now declares `String tripDays(int n);` and the six getters.

- [ ] **Step 2: Write the failing widget test**

Create `test/widgets/trip_option_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/data/currency_provider.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/models/plan_turn.dart';
import 'package:voyz/widgets/planner/trip_option_card.dart';

void main() {
  testWidgets('shows title, duration, route and estimate label', (
    tester,
  ) async {
    var tapped = 0;
    await tester.pumpWidget(
      CurrencyProvider(
        controller: CurrencyController('VND'),
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: TripOptionCard(
                // Giá không parse được thành tiền: CurrencyAmountText hiện
                // nguyên chuỗi, test không gọi mạng quy đổi tiền.
                option: const TripOption(
                  title: 'Biển & lặn',
                  destination: 'Côn Đảo, Việt Nam',
                  numDays: 4,
                  stops: ['Bến Đầm', 'Hòn Bảy Cạnh', 'Bãi Đầm Trầu'],
                  imageStop: 'Hòn Bảy Cạnh',
                  price: 'khoảng sáu triệu',
                  aiInsight: 'Hợp nhóm bạn thích biển',
                ),
                onTap: () => tapped++,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Biển & lặn'), findsOneWidget);
    expect(find.text('Côn Đảo, Việt Nam'), findsOneWidget);
    expect(find.text('4 ngày'), findsOneWidget);
    expect(find.text('Bến Đầm → Hòn Bảy Cạnh → Bãi Đầm Trầu'), findsOneWidget);
    expect(find.text('Ước tính AI'), findsOneWidget);
    expect(find.text('khoảng sáu triệu'), findsOneWidget);

    await tester.ensureVisible(find.text('Xem chi tiết'));
    await tester.pump();
    await tester.tap(find.text('Xem chi tiết'));
    expect(tapped, 1);
  });
}
```

Run: `flutter test test/widgets/trip_option_card_test.dart`
Expected: compile error, `trip_option_card.dart` does not exist.

- [ ] **Step 3: Implement the bubble**

Create `lib/widgets/planner/planner_bubble.dart` (same look as `_ChatBubble` in `lib/screens/chat_screen.dart:272-348`):

```dart
import 'package:flutter/material.dart';
import 'package:voyz/theme/app_theme.dart';

/// Bong bóng tin nhắn của planner chat, cùng kiểu với màn Chat.
class PlannerBubble extends StatelessWidget {
  const PlannerBubble({super.key, required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: AppTheme.brandGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.primaryPink.withValues(alpha: 0.2)
                    : AppTheme.surfaceDark,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser
                      ? AppTheme.primaryPink.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.primaryPink,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Implement the option card**

Create `lib/widgets/planner/trip_option_card.dart` (restyled from `_DestinationCard` in `lib/screens/suggestions_screen.dart:315-563`):

```dart
import 'package:flutter/material.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/models/plan_turn.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/currency_amount_text.dart';
import 'package:voyz/widgets/shared/destination_image.dart';

/// Thẻ phương án chuyến đi trong planner chat. Giữ kiểu thẻ gợi ý cũ,
/// thay sao/đánh giá bằng lộ trình và badge % bằng badge số ngày.
class TripOptionCard extends StatelessWidget {
  const TripOptionCard({super.key, required this.option, required this.onTap});

  final TripOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DestinationImage(
                    imageUrl: option.imageUrl,
                    destinationName: option.imageStop,
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        l10n.tripDays(option.numDays),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(option: option, theme: theme, l10n: l10n),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.route,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          option.stops.join(' → '),
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (option.aiInsight.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InsightBox(text: option.aiInsight, l10n: l10n),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onTap,
                      icon: Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      label: Text(
                        l10n.viewDetails,
                        style: TextStyle(color: theme.colorScheme.primary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: 0.08,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.option,
    required this.theme,
    required this.l10n,
  });

  final TripOption option;
  final ThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    const muted = TextStyle(fontSize: 10, color: Color(0xFF94A3B8));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                option.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                option.destination,
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
        if (option.price.isNotEmpty) ...[
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CurrencyAmountText(
                option.price,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.tertiary,
                ),
                originalStyle: muted,
                textAlign: TextAlign.right,
              ),
              Text(l10n.perPerson, style: muted.copyWith(letterSpacing: 0.5)),
              Text(l10n.aiEstimateLabel, style: muted),
            ],
          ),
        ],
      ],
    );
  }
}

class _InsightBox extends StatelessWidget {
  const _InsightBox({required this.text, required this.l10n});

  final String text;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, height: 1.5),
          children: [
            TextSpan(
              text: l10n.aiInsightPrefix,
              style: TextStyle(fontWeight: FontWeight.w700, color: accent),
            ),
            TextSpan(
              text: text,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
```

Note: `aiInsightPrefix` already starts with the 💡 emoji in every locale, so the card does not add a second one (the old card did).

- [ ] **Step 5: Run the tests and analyzer**

Run: `flutter test test/widgets/trip_option_card_test.dart`
Expected: PASS. If `find.text('Ước tính AI')` fails because `CurrencyAmountText` renders extra text, check that the price string is not parseable by `MoneyParser` and keep it as `'khoảng sáu triệu'`.

Run: `flutter analyze`
Expected: 0 errors.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/ lib/widgets/planner/ test/widgets/trip_option_card_test.dart
git commit -m "feat(planner): add chat bubble, trip option card and their strings

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Check `git status` first: `lib/l10n/build` must not appear in the staged files if it was not tracked before (`git ls-files lib/l10n/build` shows whether it is tracked). If it shows up as new, unstage it with `git restore --staged lib/l10n/build`.

---

### Task 7: Planner screen chat mode

**Files:**
- Modify: `lib/screens/smart_planner_screen.dart:1-469` (imports, state class, `_AiPromptBox`). Keep `_QuickPromptChips` and `_CosmicEarthArtwork` (lines 471-571) exactly as they are.

**Interfaces:**
- Consumes: `GeminiService.instance.planTurn(...)`, `GeminiService.instance.enrichOptionsWithImages(...)` (Tasks 4, 5); `PlannerMessage`, `PlanTurn`, `TripOption`, `tripForOption` (Task 3); `PlannerBubble`, `TripOptionCard`, the l10n getters (Task 6); existing `DestinationDetailScreen({required String destinationName})`, `ErrorLocalizer.getLocalizedMessage(Object, AppLocalizations)`.
- Produces: nothing new for later tasks. After this task the planner no longer imports `suggestions_screen.dart`.

- [ ] **Step 1: Replace imports**

Replace lines 1-16 with:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/data/currency_provider.dart';
import 'package:voyz/data/saved_trips_provider.dart';
import 'package:voyz/models/plan_turn.dart';
import 'package:voyz/screens/destination_detail_screen.dart';
import 'package:voyz/screens/saved_screen.dart';
import 'package:voyz/screens/explore_screen.dart';
import 'package:voyz/data/locale_provider.dart';
import 'package:voyz/services/gemini_service.dart';
import 'package:voyz/services/profile_service.dart';
import 'package:voyz/services/search_history_service.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/utils/error_localizer.dart';
import 'package:voyz/widgets/planner/planner_bubble.dart';
import 'package:voyz/widgets/planner/trip_option_card.dart';
import 'package:voyz/widgets/shared/aivivu_wordmark.dart';
import 'package:voyz/widgets/shared/account_menu_button.dart';
import 'package:voyz/widgets/shared/bottom_nav_bar.dart';
```

- [ ] **Step 2: Replace the state class and `_AiPromptBox`**

Replace everything from the `/// Planner AI-first:` doc comment above `class SmartPlannerScreen` down to the closing brace of `_AiPromptBox` with:

```dart
/// Planner AI-first dạng chat. Trước lượt gửi đầu là màn hero như cũ; sau đó
/// là hội thoại với AI, AI hỏi thêm khi thiếu thông tin rồi đưa 3 thẻ phương
/// án. Chọn thẻ thì mở màn chi tiết như chạm một gợi ý trước đây.
/// Hội thoại chỉ nằm trong state, không lưu.
class SmartPlannerScreen extends StatefulWidget {
  const SmartPlannerScreen({super.key});

  @override
  State<SmartPlannerScreen> createState() => _SmartPlannerScreenState();
}

class _SmartPlannerScreenState extends State<SmartPlannerScreen> {
  final _promptController = TextEditingController();
  final _scrollController = ScrollController();

  /// Sở thích lấy từ profile, dùng khi AI không suy ra được sở thích nào.
  List<String> _profileInterests = const [];

  final List<PlannerMessage> _messages = [];
  bool _isSending = false;
  Object? _error;

  /// Lượt đang chạy có bắt buộc đưa phương án không, để "Thử lại" gọi lại y hệt.
  bool _lastForce = false;

  bool get _inChat => _messages.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final trip = SavedTripsProvider.of(context).currentTrip;
      final currency = CurrencyProvider.of(context);
      UserProfile? profile;
      try {
        profile = await ProfileService.instance.loadCurrentProfile();
        await currency.setDisplayCurrency(
          trip.currency.isNotEmpty ? trip.currency : profile.preferredCurrency,
        );
      } catch (_) {}
      if (!mounted) return;

      setState(() {
        _profileInterests =
            profile?.travelStyles
                .map((style) => style.toLowerCase().replaceAll(' ', '_'))
                .toList() ??
            const [];
        _promptController.text = trip.aiPrompt;
      });
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showPromptRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.describeTripRequired),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ExploreScreen()),
          (route) => false,
        );
        break;
      case 2:
        _savePrompt();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SavedScreen()),
          (route) => false,
        );
        break;
    }
  }

  /// Rời planner khi chưa bắt đầu chat thì giữ lại mô tả đang gõ.
  void _savePrompt() {
    if (_inChat) return;
    final provider = SavedTripsProvider.of(context);
    provider.updateTrip(
      provider.currentTrip.copyWith(aiPrompt: _promptController.text),
    );
  }

  /// Gửi tin nhắn đang gõ. "Gợi ý luôn" được bấm khi ô trống: không thêm
  /// tin mới, chỉ bắt AI đưa phương án.
  Future<void> _send({bool forceOptions = false}) async {
    if (_isSending) return;
    final text = _promptController.text.trim();
    if (text.isEmpty && !(forceOptions && _inChat)) {
      if (!_inChat) _showPromptRequired();
      return;
    }
    setState(() {
      if (text.isNotEmpty) _messages.add(PlannerMessage.user(text));
      _promptController.clear();
    });
    await _runTurn(forceOptions: forceOptions);
  }

  Future<void> _runTurn({required bool forceOptions}) async {
    final languageCode = LocaleProvider.of(context).value.languageCode;
    setState(() {
      _isSending = true;
      _error = null;
      _lastForce = forceOptions;
    });
    _scrollToBottom();
    try {
      final turn = await GeminiService.instance.planTurn(
        List.of(_messages),
        forceOptions: forceOptions,
        languageCode: languageCode,
      );
      if (turn.reply.isEmpty && !turn.hasOptions) {
        throw Exception('noAiResponse');
      }
      if (!mounted) return;
      final message = PlannerMessage.agent(turn);
      setState(() {
        _messages.add(message);
        _isSending = false;
      });
      _scrollToBottom();
      if (turn.hasOptions) unawaited(_loadImages(message));
    } catch (e) {
      debugPrint('SmartPlanner: planTurn failed: $e');
      if (!mounted) return;
      setState(() {
        _error = e;
        _isSending = false;
      });
    }
  }

  /// Ảnh về sau text: thay đúng tin nhắn đó, bỏ qua nếu chat đã bị làm mới.
  Future<void> _loadImages(PlannerMessage message) async {
    final turn = message.turn!;
    final options = await GeminiService.instance.enrichOptionsWithImages(
      turn.options,
    );
    if (!mounted) return;
    final index = _messages.indexOf(message);
    if (index < 0) return;
    setState(() {
      _messages[index] = PlannerMessage.agent(turn.copyWith(options: options));
    });
  }

  void _newChat() {
    setState(() {
      _messages.clear();
      _error = null;
      _isSending = false;
      _promptController.clear();
    });
  }

  Future<void> _pickOption(PlanTurn turn, TripOption option) async {
    final provider = SavedTripsProvider.of(context);
    final currency = CurrencyProvider.of(context).value;
    final userMessages = [
      for (final m in _messages)
        if (m.isUser) m.text,
    ];
    final trip = tripForOption(turn, option, userMessages);
    provider.updateTrip(
      trip.copyWith(
        currency: currency,
        selectedInterests: trip.selectedInterests.isEmpty
            ? _profileInterests
            : null,
      ),
    );
    await SearchHistoryService.instance.recordTripSearch(provider.currentTrip);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            DestinationDetailScreen(destinationName: option.destination),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [AppTheme.surfaceDark, AppTheme.backgroundDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(l10n),
              Expanded(
                child: _inChat
                    ? _buildChat(l10n)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingLg,
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1180),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                _buildPlannerHero(theme, l10n),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
              if (_inChat) _buildChatDock(l10n),
            ],
          ),
        ),
      ),
      bottomSheet: BottomNavBar(currentIndex: 0, onTap: _onNavTap),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingMd,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AivivuWordmark(fontSize: 20),
              Text(
                l10n.smartPlanner,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_inChat)
                IconButton(
                  tooltip: l10n.newPlannerChat,
                  onPressed: _newChat,
                  icon: const Icon(
                    Icons.add_comment_outlined,
                    color: Colors.white,
                  ),
                ),
              const AccountMenuButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChat(AppLocalizations l10n) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            for (final message in _messages) ...[
              if (message.text.isNotEmpty)
                PlannerBubble(text: message.text, isUser: message.isUser),
              if (message.turn != null)
                for (final option in message.turn!.options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TripOptionCard(
                      option: option,
                      onTap: () => _pickOption(message.turn!, option),
                    ),
                  ),
            ],
            if (_isSending) _TypingRow(label: l10n.chatAiReply),
            if (_error != null)
              _ErrorRow(
                message: ErrorLocalizer.getLocalizedMessage(_error!, l10n),
                retryLabel: l10n.retry,
                onRetry: () => _runTurn(forceOptions: _lastForce),
              ),
          ],
        ),
      ),
    );
  }

  /// Ô nhập ở đáy khi đang chat. Chừa chỗ cho thanh điều hướng nổi.
  Widget _buildChatDock(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 76),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: _AiPromptBox(
            controller: _promptController,
            hintText: l10n.plannerChatHint,
            minLines: 1,
            maxLines: 3,
            actionLabel: _isSending ? l10n.analyzingTrip : l10n.plannerSend,
            actionIcon: Icons.send,
            onAction: _isSending ? null : _send,
            secondaryLabel: l10n.suggestNow,
            secondaryIcon: Icons.auto_awesome_outlined,
            onSecondary: _isSending ? null : () => _send(forceOptions: true),
          ),
        ),
      ),
    );
  }

  Widget _buildPlannerHero(ThemeData theme, AppLocalizations l10n) {
    final intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.cyan.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.32)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppTheme.cyan,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.smartPlanner.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.cyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: AppTheme.brandGradient.createShader,
          child: Text(
            l10n.plannerGreeting,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.9,
              height: 1.12,
            ),
          ),
        ),
      ],
    );

    final prompt = _AiPromptBox(
      controller: _promptController,
      hintText: l10n.aiPromptHint,
      minLines: 2,
      maxLines: 4,
      actionLabel: _isSending ? l10n.analyzingTrip : l10n.getAiSuggestions,
      actionIcon: Icons.auto_awesome,
      onAction: _isSending ? null : _send,
      secondaryLabel: l10n.explore,
      secondaryIcon: Icons.explore_outlined,
      onSecondary: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ExploreScreen()));
      },
    );

    final quickPrompts = _QuickPromptChips(
      onSelected: (promptText) => _promptController.text = promptText,
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [prompt, const SizedBox(height: 12), quickPrompts],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        if (!isDesktop) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              intro,
              const SizedBox(height: 20),
              const _CosmicEarthArtwork(),
              const SizedBox(height: 24),
              content,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(flex: 9, child: _CosmicEarthArtwork()),
            const SizedBox(width: 42),
            Expanded(
              flex: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [intro, const SizedBox(height: 22), content],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TypingRow extends StatelessWidget {
  const _TypingRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPink),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}

/// Ô prompt dùng cho cả hero và dock chat. Nút phụ viền cyan đổi theo chế
/// độ: Khám phá ở hero, "Gợi ý luôn" khi đang chat.
class _AiPromptBox extends StatelessWidget {
  const _AiPromptBox({
    required this.controller,
    required this.hintText,
    required this.minLines,
    required this.maxLines,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    required this.secondaryLabel,
    required this.secondaryIcon,
    required this.onSecondary,
  });

  final TextEditingController controller;
  final String hintText;
  final int minLines;
  final int maxLines;
  final String actionLabel;
  final IconData actionIcon;

  /// Null khi đang chờ AI.
  final VoidCallback? onAction;
  final String secondaryLabel;
  final IconData secondaryIcon;

  /// Null khi đang chờ AI.
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.9),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.12),
            blurRadius: 20,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.search, color: primaryColor, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: maxLines,
                  minLines: minLines,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.42),
                      fontSize: 16,
                      height: 1.25,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: primaryColor.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: onSecondary,
                    icon: Icon(secondaryIcon, size: 19),
                    label: Text(secondaryLabel),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.cyan,
                      backgroundColor: AppTheme.cyan.withValues(alpha: 0.08),
                      side: const BorderSide(color: AppTheme.cyan, width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                Opacity(
                  opacity: onAction == null ? 0.6 : 1,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppTheme.brandGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.magenta.withValues(alpha: 0.36),
                          blurRadius: 20,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onAction,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                actionLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(actionIcon, size: 18, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Analyze and run tests**

Run: `flutter analyze`
Expected: 0 errors. (`SuggestionsScreen` is now unused but still compiles; it is deleted in Task 8.)

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/smart_planner_screen.dart
git commit -m "feat(planner): turn the planner into a chat with trip option cards

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Delete the old suggestions path

**Files:**
- Delete: `lib/screens/suggestions_screen.dart`
- Modify: `lib/services/gemini_service.dart` (remove `extractTripData`, `buildExtractPrompt`, `getSuggestions`, `buildSuggestionsPrompt`, `_formatDate`)
- Modify: `test/services/gemini_service_test.dart` (remove groups `buildSuggestionsPrompt - prompt-first behavior` and `buildExtractPrompt`)
- Modify: the three ARB files + regenerate l10n (remove 9 keys)

**Interfaces:**
- Consumes: nothing new.
- Produces: nothing. After this task no code references the removed names.

- [ ] **Step 1: Confirm nothing else uses the code to delete**

Run:

```bash
grep -rn "SuggestionsScreen\|suggestions_screen\|getSuggestions\|buildSuggestionsPrompt\|extractTripData\|buildExtractPrompt\|parseExtractedTripData" lib test
```

Expected: matches only inside `lib/screens/suggestions_screen.dart`, the definitions in `lib/services/gemini_service.dart`, and the two test groups named above. If anything else shows up, stop and report it.

- [ ] **Step 2: Delete the code**

```bash
git rm lib/screens/suggestions_screen.dart
```

In `lib/services/gemini_service.dart` delete:
1. `extractTripData` (doc comment `/// Bóc tách thông tin có cấu trúc...` through its closing brace).
2. `buildExtractPrompt` (from `@visibleForTesting` above it through its closing brace).
3. `getSuggestions` (from the `/// Get AI travel suggestions based on user's trip preferences.` doc comment through its closing brace). Keep the `enrichSuggestionsWithImages`, `parseSuggestionsSync` and `_withImages` methods; Explore uses them.
4. `buildSuggestionsPrompt` (from `/// Builds the suggestions prompt. Public for testing only.` through its closing brace).
5. `_formatDate` in the Helpers section. Keep `_formatDateShort` and `_describeBudgetTier`.
6. Rename the section comment `// ── Trích xuất TripData từ mô tả (planner hai bước) ──` to `// ── Đọc TripData từ JSON của AI ──` (`_validTiers`, `_cleanString`, `_toInt`, `parseTripMap` stay).

Then run `grep -n "_formatDate(" lib/services/gemini_service.dart` and expect no output.

In `test/services/gemini_service_test.dart` delete the whole `group('buildSuggestionsPrompt - prompt-first behavior', ...)` and `group('buildExtractPrompt', ...)` blocks.

- [ ] **Step 3: Remove the unused l10n keys**

Re-check each key is unused outside `lib/l10n/`:

```bash
for k in addToWishlist addedToWishlist alreadySaved cannotLoadSuggestions contextCompareSuggestions loadingSuggestionsDetail noSuggestionsFound reviewsCount travelSuggestions; do echo "$k: $(grep -rlE "\.$k\b" lib test | grep -v '^lib/l10n/' | tr '\n' ' ')"; done
```

Expected: every line ends with nothing after the colon. Then delete the one line entries (value and `@` metadata) from all three ARB files:

```bash
for f in lib/l10n/app_en.arb lib/l10n/app_vi.arb lib/l10n/app_ko.arb; do
  sed -i '' -E '/^[[:space:]]*"@?(addToWishlist|addedToWishlist|alreadySaved|cannotLoadSuggestions|contextCompareSuggestions|loadingSuggestionsDetail|noSuggestionsFound|reviewsCount|travelSuggestions)":/d' "$f"
done
flutter gen-l10n
```

Expected: `flutter gen-l10n` succeeds. Check that each ARB file is still valid JSON:

```bash
for f in lib/l10n/app_*.arb; do python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$f" && echo "$f ok"; done
```

- [ ] **Step 4: Analyze and run all tests**

Run: `flutter analyze`
Expected: 0 errors, and no new warnings compared with the baseline (18 items, possibly fewer).

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add -A lib/screens/suggestions_screen.dart lib/services/gemini_service.dart test/services/gemini_service_test.dart lib/l10n/
git commit -m "refactor(planner): remove the suggestions screen and one-shot extraction

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Check `git status` before committing; do not stage `lib/l10n/build` if it was untracked.

---

### Task 9: Manual check in the running app and PR

**Files:**
- Modify: `docs/project_phase3_roadmap_ai_first.md` (tick the 2.6 "Nghiệm thu" boxes that pass)

- [ ] **Step 1: Run the web app**

Run (background): `flutter run -d web-server --web-port 8080`
Open `http://localhost:8080` in Chrome (chrome-devtools MCP), sign in with the test account the user provides if the auth gate requires it.

- [ ] **Step 2: Walk the acceptance list**

Check each item from roadmap 2.6 "Nghiệm thu" and take a screenshot of the chat for each:
1. "Du lịch Côn Đảo": agent asks for the length (or states an assumption); all 3 options are in Côn Đảo.
2. "4 ngày 3 đêm Nha Trang": options on the first turn, badge "4 ngày", multi stop route.
3. "Muốn đi biển 1 tuần": 3 options in 3 different destinations.
4. After options, "rẻ hơn": a new set of options in the same chat.
5. While the agent is asking, "Gợi ý luôn": options on the next turn.
6. The 3 cards show 3 different photos (or the placeholder when none is found).
7. "1 tuần Côn Đảo", pick a card, open the itinerary from the detail screen: 7 days. "Từ 10/10 đến 13/10": 4 days.
8. Picking a card opens the detail screen as before; the itinerary follows the picked route.

Record failures with the screenshot. Fix a failure only if it is inside this plan's scope; otherwise report it.

- [ ] **Step 3: Tick the roadmap boxes and commit**

Change `- [ ]` to `- [x]` in roadmap 2.6 "Nghiệm thu" for the items that passed, then:

```bash
git add docs/project_phase3_roadmap_ai_first.md
git commit -m "docs(roadmap): mark planner chat acceptance checks

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 4: Final checks and PR**

Run: `flutter analyze` (0 errors) and `flutter test` (all pass). Then:

```bash
git push -u origin planner-chat
gh pr create --base master --title "Planner chat with trip option cards (roadmap 2.6)" --body "$(cat <<'EOF'
## Summary
- The Smart Planner is now a chat: the AI asks at most one short question per turn (two turns max), then shows 3 trip option cards with a theme, duration, route of named stops, a labeled price estimate and a distinct photo.
- Tapping a card opens the existing destination detail screen; the chosen route travels in `aiPrompt`, so the itinerary follows it. Detail and plan screens are unchanged.
- `TripData.numDays` keeps durations like "1 tuần" when there are no dates, and `dayCount()` uses it.
- Removed the suggestions screen, `getSuggestions`, and the one-shot extraction.

Spec: `docs/superpowers/specs/2026-09-27-planner-chat-design.md`
Plan: `docs/superpowers/plans/2026-09-27-planner-chat.md`

## Test plan
- [ ] `flutter analyze` has no new errors
- [ ] `flutter test` passes
- [ ] Roadmap 2.6 acceptance checks (see the roadmap)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Report the PR URL.
