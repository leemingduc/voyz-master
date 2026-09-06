# Planner AI Fill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Nút planner hai bước: "Phân tích bằng AI" trích xuất `TripData` từ mô tả và đổ vào form cho người dùng review, rồi "Nhận gợi ý AI" đi tiếp như cũ.

**Architecture:** Một hàm mới `GeminiService.extractTripData` (JSON mode, không cache) với parser thuần `parseExtractedTripData` test được. Planner thêm 4 cờ state và hàm `_applyExtracted` theo quy tắc "AI chỉ điền chỗ người dùng chưa đụng". Không đổi DB, provider, màn hình khác.

**Tech Stack:** Flutter, `google_generative_ai`, `intl` (DateFormat), flutter l10n (`flutter gen-l10n`).

**Spec:** `docs/superpowers/specs/2026-09-07-planner-ai-fill-design.md`

## Global Constraints

- Nhánh tách từ `master` mới nhất, tên mô tả việc (ví dụ `planner-ai-fill`). Không push lên `master`. Mở PR hoặc merge local khi xong.
- Trước PR: `flutter analyze` không lỗi mới, `flutter test` pass.
- Không dùng em dash hay en dash trong bất kỳ text nào (code, comment, arb, commit).
- Prompt gửi Gemini viết tiếng Việt, kèm dòng chỉ thị ngôn ngữ như các prompt khác.
- Không hardcode URL ảnh. Không chạm `lib/data/`, `lib/services/ai_cache_service.dart`, `supabase/`.
- Chỉ 3 file code thay đổi: `lib/services/gemini_service.dart`, `lib/screens/smart_planner_screen.dart`, `test/services/gemini_service_test.dart`; cộng 3 file arb và 4 file `lib/l10n/app_localizations*.dart` do `flutter gen-l10n` sinh ra.

---

### Task 1: `extractTripData` và parser thuần, TDD

**Files:**
- Modify: `lib/services/gemini_service.dart`
- Test: `test/services/gemini_service_test.dart` (thêm group)

**Interfaces:**
- Consumes: `GeminiService._gemini` (JSON model), `safeJsonDecode`, `languageInstruction`, `TripData` (`lib/data/trip_data.dart`), `MockData.interests` (`lib/data/mock_data.dart`).
- Produces:
  - `Future<TripData> extractTripData(String prompt, {String languageCode = 'vi'})`
  - `@visibleForTesting TripData parseExtractedTripData(String text, {String originalPrompt = ''})`
  - `@visibleForTesting String buildExtractPrompt(String prompt, String languageCode, DateTime today)`

- [ ] **Step 1: Viết test (thêm vào cuối `main()` trong `test/services/gemini_service_test.dart`)**

```dart
  group('parseExtractedTripData', () {
    final service = GeminiService.instance;

    test('JSON day du: moi truong vao dung cho, participants so thanh chuoi', () {
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
    });

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
      final trip = service.parseExtractedTripData('{"participants":"gia dinh"}');
      expect(trip.participants, '');
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
    });
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `flutter test test/services/gemini_service_test.dart`
Expected: FAIL khi compile (`parseExtractedTripData`, `buildExtractPrompt` chưa có).

- [ ] **Step 3: Thêm import và code vào `gemini_service.dart`**

Thêm import (nếu chưa có): `import 'package:voyz/data/mock_data.dart';` và `import 'package:intl/intl.dart';`.

Thêm vào class `GeminiService`, ngay trước section Explore (sau `_withImages`):

```dart
  // ── Trích xuất TripData từ mô tả (planner hai bước) ──────────────────

  static const _validTiers = ['economy', 'moderate', 'premium', 'luxury'];

  /// Bóc tách thông tin có cấu trúc từ mô tả chuyến đi. Không cache:
  /// người dùng sửa mô tả là phân tích lại.
  Future<TripData> extractTripData(
    String prompt, {
    String languageCode = 'vi',
  }) async {
    final text = (await _gemini.generateContent([
      Content.text(buildExtractPrompt(prompt, languageCode, DateTime.now())),
    ])).text;
    if (text == null || text.isEmpty) throw Exception('noAiResponse');
    return parseExtractedTripData(text, originalPrompt: prompt);
  }

  @visibleForTesting
  String buildExtractPrompt(String prompt, String languageCode, DateTime today) {
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    return '''
Bạn là trợ lý du lịch. Hôm nay là $todayStr. Đọc mô tả chuyến đi của người dùng và bóc tách thông tin.

Mô tả: "$prompt"

Trả về JSON đúng các key sau, không thêm key khác:
{
  "destination": "tên điểm đến, hoặc null nếu không nêu",
  "departDate": "yyyy-MM-dd hoặc null (chỉ khi mô tả nêu ngày hoặc mốc thời gian đủ rõ để tính từ hôm nay)",
  "returnDate": "yyyy-MM-dd hoặc null",
  "numDays": "số nguyên hoặc null",
  "budgetTier": "một trong: economy | moderate | premium | luxury, hoặc null",
  "participants": "số người, số nguyên hoặc null",
  "ageRange": "khoảng tuổi dạng chuỗi, hoặc null",
  "interests": ["chỉ dùng các giá trị: beach, adventure, culture, food, wellness"]
}

Quy tắc:
- Không đoán bừa: không có thông tin thì để null hoặc mảng rỗng.
- "tiết kiệm", "rẻ" là economy; "sang", "5 sao" là luxury; "cao cấp" là premium.
- CHỈ trả về JSON, KHÔNG thêm markdown hay text khác.
- ${languageInstruction(languageCode)}
''';
  }

  /// Parser thuần cho JSON trích xuất. Key thiếu hoặc sai thì để rỗng.
  @visibleForTesting
  TripData parseExtractedTripData(String text, {String originalPrompt = ''}) {
    final decoded = safeJsonDecode(text);
    final map = decoded is Map ? Map<String, dynamic>.from(decoded) : <String, dynamic>{};

    DateTime? depart = DateTime.tryParse(map['departDate']?.toString() ?? '');
    DateTime? ret = DateTime.tryParse(map['returnDate']?.toString() ?? '');
    final numDays = map['numDays'] is num
        ? (map['numDays'] as num).toInt()
        : int.tryParse(map['numDays']?.toString() ?? '');
    if (depart != null && ret == null && numDays != null && numDays > 0) {
      ret = depart.add(Duration(days: numDays - 1));
    }
    if (depart == null) ret = null;

    final tier = map['budgetTier']?.toString().trim().toLowerCase() ?? '';
    final participants = map['participants'];
    final participantsStr = participants is num
        ? participants.toInt().toString()
        : (int.tryParse(participants?.toString() ?? '')?.toString() ?? '');
    final interests = TripData.stringList(map['interests'])
        .map((e) => e.trim().toLowerCase())
        .where(MockData.interests.contains)
        .toList();

    return TripData(
      destination: map['destination']?.toString().trim() ?? '',
      departDate: depart,
      returnDate: ret,
      budget: _validTiers.contains(tier) ? tier : '',
      participants: participantsStr,
      ageRange: map['ageRange']?.toString().trim() ?? '',
      aiPrompt: originalPrompt,
      selectedInterests: interests,
    );
  }
```

Lưu ý: `map['destination']?.toString()` với giá trị JSON `null` cho `null`, `?? ''` xử lý. Nếu analyzer báo `dead_null_aware_expression` ở chỗ nào, sửa thành `(map['x'] ?? '').toString().trim()`.

- [ ] **Step 4: Chạy test, xác nhận pass**

Run: `flutter test test/services/gemini_service_test.dart && flutter analyze lib/services/gemini_service.dart`
Expected: toàn bộ test PASS (27 cũ + 7 mới = 34), analyze sạch cho file.

- [ ] **Step 5: Commit**

```bash
git add lib/services/gemini_service.dart test/services/gemini_service_test.dart
git commit -m "feat: GeminiService.extractTripData parses trip details from the free-text prompt"
```

---

### Task 2: Chuỗi l10n mới

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`, `lib/l10n/app_ko.arb`
- Generated: `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_vi.dart`, `app_localizations_ko.dart`

**Interfaces:**
- Produces: `l10n.analyzeTrip`, `l10n.analyzingTrip`, `l10n.aiFilledFields(int count)`, `l10n.aiFilledNothing`.

- [ ] **Step 1: Thêm key vào `app_en.arb`** (đặt ngay sau key `getAiSuggestions`)

```json
  "analyzeTrip": "Analyze with AI",
  "@analyzeTrip": {"description": "Planner primary button before the AI has extracted trip details from the prompt"},
  "analyzingTrip": "Analyzing...",
  "@analyzingTrip": {"description": "Planner primary button label while the extraction request is in flight"},
  "aiFilledFields": "AI filled {count} fields. Review, then tap Get AI Suggestions.",
  "@aiFilledFields": {
    "description": "Snackbar after AI extraction filled some form fields",
    "placeholders": {"count": {"type": "int"}}
  },
  "aiFilledNothing": "AI could not extract details from your description. Fill the form, then continue.",
  "@aiFilledNothing": {"description": "Snackbar after AI extraction filled nothing"},
```

- [ ] **Step 2: Thêm vào `app_vi.arb`** (sau `getAiSuggestions`)

```json
  "analyzeTrip": "Phân tích bằng AI",
  "analyzingTrip": "Đang phân tích...",
  "aiFilledFields": "AI đã điền {count} thông tin. Kiểm tra rồi bấm Nhận gợi ý AI.",
  "aiFilledNothing": "AI chưa suy ra được thông tin nào từ mô tả. Hãy điền form rồi tiếp tục.",
```

- [ ] **Step 3: Thêm vào `app_ko.arb`** (sau `getAiSuggestions`)

```json
  "analyzeTrip": "AI로 분석",
  "analyzingTrip": "분석 중...",
  "aiFilledFields": "AI가 {count}개 항목을 채웠습니다. 확인 후 AI 추천 받기를 누르세요.",
  "aiFilledNothing": "AI가 설명에서 정보를 추출하지 못했습니다. 양식을 채운 뒤 계속하세요.",
```

Chú ý dấu phẩy JSON: các file arb hiện có key tiếp theo sau `getAiSuggestions`, giữ hợp lệ JSON.

- [ ] **Step 4: Sinh code và kiểm tra**

Run: `flutter gen-l10n && flutter analyze lib/l10n/ && grep -c "aiFilledFields" lib/l10n/app_localizations.dart`
Expected: không lỗi, grep trả về ít nhất 1. Mở `lib/l10n/app_localizations_vi.dart` thấy 4 getter/method mới.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/
git commit -m "feat(l10n): planner analyze button and AI fill snackbar strings (en, vi, ko)"
```

---

### Task 3: Planner hai bước, AI điền form

**Files:**
- Modify: `lib/screens/smart_planner_screen.dart`

**Interfaces:**
- Consumes: `GeminiService.instance.extractTripData(prompt, languageCode:)` (Task 1), 4 chuỗi l10n (Task 2), `LocaleProvider.of(context).value.languageCode` (đã import trong file? kiểm tra; nếu chưa thì thêm `import 'package:voyz/data/locale_provider.dart';`), `ErrorLocalizer` nếu file đã dùng, không thì `e.toString()`.

- [ ] **Step 1: State và listener**

Trong `_SmartPlannerScreenState`, sau `late List<bool> _selectedInterests;` thêm:

```dart
  /// Đã phân tích mô tả hiện tại chưa. Sửa mô tả thì về false.
  bool _analyzed = false;
  bool _isAnalyzing = false;

  /// Người dùng đã tự chọn trong phiên này thì AI không ghi đè.
  bool _tierTouched = false;
  bool _interestsTouched = false;
```

Trong `initState()`, ngay sau `super.initState();` thêm:

```dart
    _promptController.addListener(() {
      if (_analyzed && mounted) setState(() => _analyzed = false);
    });
```

Kiểm tra `dispose()` đã dispose `_promptController` (đang có); listener sẽ được giải phóng cùng controller.

- [ ] **Step 2: Đánh dấu "đã chạm" ở tier và chip**

Trong `_buildBudgetTierSelector`, tại handler tap chọn tier (chỗ gán `_selectedBudgetTier = tier.key` hoặc tương đương), thêm `_tierTouched = true;` bên trong cùng `setState`.

Trong `_buildInterests`, `onTap` của `InterestChip` đổi thành:

```dart
                onTap: () {
                  setState(() {
                    _interestsTouched = true;
                    _selectedInterests[i] = !_selectedInterests[i];
                  });
                },
```

- [ ] **Step 3: Hàm phân tích và đổ vào form**

Thêm sau `_validateInput()`:

```dart
  /// Đổ kết quả AI vào form. Chỉ điền chỗ người dùng chưa đụng.
  /// Trả về số trường đã điền.
  int _applyExtracted(TripData ai) {
    var filled = 0;
    if (_destinationController.text.trim().isEmpty && ai.destination.isNotEmpty) {
      _destinationController.text = ai.destination;
      filled++;
    }
    if (_departDate == null && _returnDate == null && ai.departDate != null) {
      _departDate = ai.departDate;
      _returnDate = ai.returnDate;
      filled++;
    }
    if (_participantsController.text.trim().isEmpty && ai.participants.isNotEmpty) {
      _participantsController.text = ai.participants;
      filled++;
    }
    if (_ageRangeController.text.trim().isEmpty && ai.ageRange.isNotEmpty) {
      _ageRangeController.text = ai.ageRange;
      filled++;
    }
    if (!_tierTouched && ai.budget.isNotEmpty) {
      _selectedBudgetTier = ai.budget;
      filled++;
    }
    if (!_interestsTouched && ai.selectedInterests.isNotEmpty) {
      for (int i = 0; i < MockData.interests.length; i++) {
        _selectedInterests[i] = ai.selectedInterests.contains(MockData.interests[i]);
      }
      filled++;
    }
    return filled;
  }

  Future<void> _onAnalyze() async {
    if (!_validateInput() || _isAnalyzing) return;
    final l10n = AppLocalizations.of(context)!;
    final languageCode = LocaleProvider.of(context).value.languageCode;
    setState(() => _isAnalyzing = true);
    try {
      final ai = await GeminiService.instance.extractTripData(
        _promptController.text.trim(),
        languageCode: languageCode,
      );
      if (!mounted) return;
      int filled = 0;
      setState(() {
        filled = _applyExtracted(ai);
        _analyzed = true;
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(filled > 0 ? l10n.aiFilledFields(filled) : l10n.aiFilledNothing),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
```

Thêm import `import 'package:voyz/services/gemini_service.dart';` và `import 'package:voyz/data/locale_provider.dart';` nếu chưa có. Nếu file đã có `ErrorLocalizer` (grep `error_localizer`), dùng nó thay `e.toString()` theo đúng cách các screen khác đang dùng; không thì giữ `e.toString()`.

- [ ] **Step 4: Nút hai trạng thái**

Thay `GradientButton` ở cuối form (hiện `label: l10n.getAiSuggestions, icon: Icons.arrow_forward, onPressed: _onGetSuggestions`) bằng:

```dart
                            child: GradientButton(
                              label: _isAnalyzing
                                  ? l10n.analyzingTrip
                                  : (_analyzed ? l10n.getAiSuggestions : l10n.analyzeTrip),
                              icon: _analyzed ? Icons.arrow_forward : Icons.auto_awesome,
                              height: 52,
                              onPressed: _isAnalyzing
                                  ? () {}
                                  : (_analyzed ? _onGetSuggestions : _onAnalyze),
                            ),
```

Kiểm tra chữ ký `GradientButton` (`lib/widgets/shared/gradient_button.dart`): nếu `onPressed` nhận `VoidCallback?` thì dùng `null` thay `() {}` khi đang phân tích; nếu là `VoidCallback` bắt buộc thì giữ `() {}`.

- [ ] **Step 5: Analyze và test**

Run: `flutter analyze && flutter test`
Expected: analyze không lỗi mới so với `master`; test PASS (77 = 70 + 7).

- [ ] **Step 6: Commit**

```bash
git add lib/screens/smart_planner_screen.dart
git commit -m "feat: planner analyzes the prompt with AI and fills untouched form fields for review"
```

---

### Task 4: Nghiệm thu tay

**Files:** không sửa code.

- [ ] Chạy app, làm 7 tiêu chí ở spec mục 7. Ghi kết quả vào PR hoặc báo giáo viên.
- [ ] Nếu AI hay trả tier sai (ví dụ "gia đình" thành luxury), sửa dòng quy tắc trong `buildExtractPrompt`, không sửa parser.

---

## Self-review

- Spec 3 (extract + parser + prompt có ngày hôm nay): Task 1.
- Spec 4 (quy tắc điền, 4 cờ state, listener, nút vô hiệu khi chờ): Task 3.
- Spec 5 (4 chuỗi, 3 ngôn ngữ, gen-l10n): Task 2.
- Spec 6 (5 test parser, thêm 1 test participants và 1 test prompt): Task 1.
- Spec 7: Task 4.
- Tên nhất quán: `extractTripData`, `parseExtractedTripData(text, originalPrompt:)`, `buildExtractPrompt(prompt, languageCode, today)`, `_applyExtracted`, `_onAnalyze`, `_analyzed`, `_isAnalyzing`, `_tierTouched`, `_interestsTouched`, `analyzeTrip`, `analyzingTrip`, `aiFilledFields(count)`, `aiFilledNothing`.
