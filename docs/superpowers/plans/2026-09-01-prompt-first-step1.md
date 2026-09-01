# Smart Planner Prompt-First Step 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the free-text AI prompt the only required input on the Smart Planner screen, and make the three Gemini prompt builders infer missing structured fields from that free text, without changing the screen layout.

**Architecture:** The screen keeps every component; only `_validateInput()` and two label strings change. `GeminiService`'s three private prompt builders become `@visibleForTesting` public methods and learn conditional inference wording when a field is empty but `trip.aiPrompt` is not. Cache key maps gain the prompt so distinct free-text searches stop colliding.

**Tech Stack:** Flutter/Dart, flutter gen-l10n (arb files), google_generative_ai, flutter_test.

**Spec:** `docs/superpowers/specs/2026-09-01-prompt-first-step1-design.md`

## Global Constraints

- Work on branch `feature/prompt-first-step1` (already created). NEVER commit or push to `master`. Finish with a Pull Request.
- Before the PR: `flutter analyze` shows no new issues versus master, and `flutter test` passes (repo rule in AGENTS.md).
- No layout changes on the Smart Planner screen. Every widget stays. Only label text and validation behavior change.
- Never use the em dash or en dash characters in any text you write (docs, commit messages, comments). Plain hyphen only where needed.
- Do not hardcode any image URLs (repo rule; not expected in this work).
- All Gemini prompt text is Vietnamese by convention; the `languageInstruction` line controls the output language. Follow the existing wording style.
- Run all commands from the repo root: `/Users/nguyenducthuan/Documents/learning/class/encourse s2/AIVIVU/voyz-master` (quote the path, it contains a space).

---

### Task 1: Localization strings (arb files + regeneration)

**Files:**
- Modify: `lib/l10n/app_en.arb` (around lines 172-173 and after 248)
- Modify: `lib/l10n/app_vi.arb` (around lines 59 and 84)
- Modify: `lib/l10n/app_ko.arb` (around lines 59 and 84)
- Regenerate: `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_vi.dart`, `app_localizations_ko.dart` (via `flutter gen-l10n`, files are checked in)

**Interfaces:**
- Consumes: nothing.
- Produces: `AppLocalizations.describeTripRequired` getter (String) and reworded `AppLocalizations.requiredInfo`. Task 2 uses `describeTripRequired`.

- [ ] **Step 1: Edit app_en.arb**

Change the existing entry:

```json
  "requiredInfo": "TRIP DETAILS (OPTIONAL)",
  "@requiredInfo": {"description": "Section heading for planner detail fields, all optional since the AI prompt became the only required input"},
```

Directly below the existing `fillAllRequired` entry (keep `fillAllRequired` untouched), add:

```json
  "describeTripRequired": "Please describe your trip first",
  "@describeTripRequired": {"description": "Validation snackbar when the AI prompt box is empty"},
```

- [ ] **Step 2: Edit app_vi.arb**

Change:

```json
  "requiredInfo": "THÔNG TIN CHUYẾN ĐI (TÙY CHỌN)",
```

Directly below the existing `fillAllRequired` line, add:

```json
  "describeTripRequired": "Hãy mô tả chuyến đi của bạn trước",
```

- [ ] **Step 3: Edit app_ko.arb**

Change:

```json
  "requiredInfo": "여행 정보 (선택)",
```

Directly below the existing `fillAllRequired` line, add:

```json
  "describeTripRequired": "먼저 여행을 설명해 주세요",
```

(vi and ko arb files carry no `@` metadata entries; only the en template does. Keep it that way.)

- [ ] **Step 4: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: exits silently with code 0.

Verify: `grep -n "describeTripRequired" lib/l10n/app_localizations.dart lib/l10n/app_localizations_vi.dart`
Expected: an abstract getter in `app_localizations.dart` and the Vietnamese string in `app_localizations_vi.dart`.

- [ ] **Step 5: Analyze**

Run: `flutter analyze`
Expected: no new issues (same output as on master).

- [ ] **Step 6: Commit**

```bash
git add lib/l10n
git commit -m "feat: reword planner section label, add prompt-required message (en/vi/ko)"
```

---

### Task 2: Prompt-only validation in the Smart Planner screen

**Files:**
- Modify: `lib/screens/smart_planner_screen.dart:151-168` (`_validateInput`)

**Interfaces:**
- Consumes: `AppLocalizations.describeTripRequired` from Task 1.
- Produces: nothing used by later tasks.

There is no practical unit test for this method: it lives in private widget state and a widget test would need Supabase, dotenv, and provider scaffolding that the repo's existing tests do not have. Verification is `flutter analyze` plus the manual smoke test in Task 6. Do not build that scaffolding for this task.

- [ ] **Step 1: Replace the body of `_validateInput`**

Replace the whole method (currently checks destination, both dates, budget, participants, age range and shows `fillAllRequired`) with:

```dart
  bool _validateInput() {
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.describeTripRequired),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
    return true;
  }
```

Touch nothing else in the file. The section header at the `l10n.requiredInfo` usage updates by itself through Task 1.

- [ ] **Step 2: Analyze**

Run: `flutter analyze`
Expected: no new issues. In particular no "unused" warnings; `fillAllRequired` is intentionally kept in the arb files even though no Dart code references it anymore (generated getters do not trigger analyzer warnings).

- [ ] **Step 3: Run existing tests to confirm nothing broke**

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/smart_planner_screen.dart
git commit -m "feat: require only the AI prompt on the smart planner"
```

---

### Task 3: Prompt-aware suggestions builder (TDD)

**Files:**
- Modify: `lib/services/gemini_service.dart:286` (call site) and `lib/services/gemini_service.dart:443-504` (`_buildSuggestionsPrompt`)
- Test: `test/services/gemini_service_test.dart`

**Interfaces:**
- Consumes: `TripData` from `package:voyz/data/trip_data.dart` (all-optional constructor, `aiPrompt` is a String defaulting to '').
- Produces: `@visibleForTesting String buildSuggestionsPrompt(TripData trip, int limit, String languageCode)` on `GeminiService`. Task 5 leaves it untouched; tests call it via `GeminiService.instance`.

- [ ] **Step 1: Write the failing tests**

In `test/services/gemini_service_test.dart`, add the import `import 'package:voyz/data/trip_data.dart';` at the top, and add this group inside `main()`:

```dart
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/services/gemini_service_test.dart`
Expected: compile error, "The method 'buildSuggestionsPrompt' isn't defined for the type 'GeminiService'".

- [ ] **Step 3: Implement**

In `lib/services/gemini_service.dart`:

a) At the call site (line ~286) change `_buildSuggestionsPrompt(trip, limit, languageCode)` to `buildSuggestionsPrompt(trip, limit, languageCode)`.

b) Replace the `_buildSuggestionsPrompt` method signature and the variable block at its top (keep the returned template string otherwise identical, including the JSON example and rules):

```dart
  /// Builds the suggestions prompt. Public for testing only.
  @visibleForTesting
  String buildSuggestionsPrompt(
    TripData trip,
    int limit,
    String languageCode,
  ) {
    final hasTripDescription = trip.aiPrompt.trim().isNotEmpty;

    final interests = trip.selectedInterests.isNotEmpty
        ? trip.selectedInterests.join(', ')
        : 'du lịch tổng hợp';

    final destination = trip.destination.isNotEmpty
        ? trip.destination
        : hasTripDescription
        ? 'chưa xác định, hãy tự suy ra điểm đến phù hợp từ mô tả chuyến đi bên dưới'
        : 'Việt Nam';

    final budgetDescription = _describeBudgetTier(trip.budget, trip.currency);

    final dateInfo = trip.departDate != null && trip.returnDate != null
        ? 'từ ${_formatDate(trip.departDate!)} đến ${_formatDate(trip.returnDate!)}'
        : hasTripDescription
        ? 'linh hoạt (nếu mô tả chuyến đi nêu thời gian, hãy dùng thời gian đó)'
        : 'linh hoạt';

    final unknownHint = hasTripDescription
        ? 'không rõ (suy ra từ mô tả chuyến đi nếu có)'
        : 'không rõ';

    final additionalNotes = trip.additionalNotes.isNotEmpty
        ? '\nYêu cầu thêm: ${trip.additionalNotes}'
        : '';

    final aiPromptExtra = hasTripDescription
        ? '\nMô tả chuyến đi: ${trip.aiPrompt.trim()}'
        : '';

    final langInst = languageInstruction(languageCode);
```

c) In the template string, change the two lines that used inline ternaries for participants and age to use the new variable:

```
- Số người: ${trip.participants.isNotEmpty ? trip.participants : unknownHint}
- Độ tuổi: ${trip.ageRange.isNotEmpty ? trip.ageRange : unknownHint}$additionalNotes$aiPromptExtra
```

(`@visibleForTesting` resolves through the existing `package:flutter/foundation.dart` import.)

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/services/gemini_service_test.dart`
Expected: all tests pass, including the pre-existing safeJsonDecode groups.

- [ ] **Step 5: Commit**

```bash
git add lib/services/gemini_service.dart test/services/gemini_service_test.dart
git commit -m "feat: suggestions prompt infers destination/dates/party from trip description"
```

---

### Task 4: Prompt-aware detail and itinerary builders (TDD)

**Files:**
- Modify: `lib/services/gemini_service.dart:531` and `:576-627` (`_buildDetailPrompt`), `:663-670` (call site) and `:699-766` (`_buildItineraryPrompt`)
- Test: `test/services/gemini_service_test.dart`

**Interfaces:**
- Consumes: `TripData` as in Task 3.
- Produces:
  - `@visibleForTesting String buildDetailPrompt(String destinationName, TripData trip, String languageCode)`
  - `@visibleForTesting String buildItineraryPrompt(String destinationName, int numDays, TripData trip, int limit, String languageCode, String? additionalInstruction)`

- [ ] **Step 1: Write the failing tests**

Add to `test/services/gemini_service_test.dart` inside `main()`:

```dart
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/services/gemini_service_test.dart`
Expected: compile errors, "The method 'buildDetailPrompt' isn't defined" and the same for `buildItineraryPrompt`.

- [ ] **Step 3: Implement the detail builder**

a) Call site line ~531: `_buildDetailPrompt(...)` becomes `buildDetailPrompt(...)`.

b) Method header and variables:

```dart
  /// Builds the destination detail prompt. Public for testing only.
  @visibleForTesting
  String buildDetailPrompt(
    String destinationName,
    TripData trip,
    String languageCode,
  ) {
    final hasTripDescription = trip.aiPrompt.trim().isNotEmpty;

    final dateInfo = trip.departDate != null && trip.returnDate != null
        ? '${_formatDateShort(trip.departDate!)} - ${_formatDateShort(trip.returnDate!)}'
        : 'Linh hoạt';

    final tripDescription = hasTripDescription
        ? '\nMô tả chuyến đi của người dùng: ${trip.aiPrompt.trim()}'
        : '';

    final dateRule = hasTripDescription && trip.departDate == null
        ? '\n- Nếu mô tả chuyến đi nêu thời gian cụ thể, dùng thời gian đó cho dateRange thay vì "Linh hoạt".'
        : '';

    final budgetDescription = _describeBudgetTier(trip.budget, trip.currency);
    final langInst = languageInstruction(languageCode);
```

c) In the template: the line `Thời gian dự kiến: $dateInfo` becomes `Thời gian dự kiến: $dateInfo$tripDescription`, and `$dateRule` is appended at the end of the `Quy tắc:` list, on the line right before `- $langInst`.

- [ ] **Step 4: Implement the itinerary builder**

a) Call site line ~663: `_buildItineraryPrompt(...)` becomes `buildItineraryPrompt(...)`.

b) Method header and variables:

```dart
  /// Builds the itinerary prompt. Public for testing only.
  @visibleForTesting
  String buildItineraryPrompt(
    String destinationName,
    int numDays,
    TripData trip,
    int limit,
    String languageCode,
    String? additionalInstruction,
  ) {
    final hasTripDescription = trip.aiPrompt.trim().isNotEmpty;

    final dateInfo = trip.departDate != null && trip.returnDate != null
        ? '${_formatDateShort(trip.departDate!)} - ${_formatDateShort(trip.returnDate!)}'
        : 'Linh hoạt';

    final tripDescription = hasTripDescription
        ? '\nMô tả chuyến đi của người dùng: ${trip.aiPrompt.trim()}'
        : '';

    final dayCountInstruction = hasTripDescription && trip.departDate == null
        ? '\nNếu mô tả chuyến đi nêu số ngày cụ thể, hãy lên kế hoạch đúng số ngày đó (tối đa 7 ngày) thay vì $numDays ngày.'
        : '';
```

c) In the template: the line `Thời gian: $dateInfo` becomes `Thời gian: $dateInfo$tripDescription$dayCountInstruction`. Everything else (JSON example, `dateRange": "$dateInfo"`, rules) stays as is.

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/services/gemini_service_test.dart`
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add lib/services/gemini_service.dart test/services/gemini_service_test.dart
git commit -m "feat: detail and itinerary prompts honor the free-text trip description"
```

---

### Task 5: Cache keys include the free-text prompt

**Files:**
- Modify: `lib/services/gemini_service.dart:268-275` (suggestions key), `:517-520` (detail key), `:645-650` (itinerary key)
- Test: `test/services/ai_cache_service_test.dart`

**Interfaces:**
- Consumes: `AiCacheService.instance.buildKey(String prefix, Map<String, dynamic> parts)` (sorts entries by key, lowercases values).
- Produces: nothing used by later tasks.

The meaningful change (which fields go into each key map) is not unit-testable without network mocks; it is verified by inspection and by `flutter analyze`. The test below documents the collision-fix property at the `buildKey` level.

- [ ] **Step 1: Write the failing-in-spirit test**

Add to `test/services/ai_cache_service_test.dart`, following that file's existing setup style, inside `main()`:

```dart
  test('keys differ when only the free-text prompt differs', () {
    final a = AiCacheService.instance.buildKey('suggestions', {
      'budget': 'moderate',
      'aiPrompt': 'đi biển với gia đình',
    });
    final b = AiCacheService.instance.buildKey('suggestions', {
      'budget': 'moderate',
      'aiPrompt': 'đi núi một mình',
    });
    expect(a, isNot(equals(b)));
  });
```

Run: `flutter test test/services/ai_cache_service_test.dart`
Expected: PASS immediately (buildKey already hashes every entry). This test pins the behavior the key-map change relies on.

- [ ] **Step 2: Extend the suggestions cache key (line ~268)**

```dart
    final cacheKey = _aiCache.buildKey('suggestions', {
      'destination': trip.destination,
      'budget': trip.budget,
      'currency': trip.currency,
      'interests': trip.selectedInterests,
      'limit': limit,
      'lang': languageCode,
      'aiPrompt': trip.aiPrompt.trim(),
      'notes': trip.additionalNotes.trim(),
      'depart': trip.departDate?.toIso8601String() ?? '',
      'return': trip.returnDate?.toIso8601String() ?? '',
    });
```

- [ ] **Step 3: Extend the detail cache key (line ~517)**

```dart
    final cacheKey = _aiCache.buildKey('detail', {
      'name': destinationName,
      'lang': languageCode,
      'aiPrompt': trip.aiPrompt.trim(),
    });
```

- [ ] **Step 4: Extend the itinerary cache key (line ~645)**

```dart
    final cacheKey = _aiCache.buildKey('itinerary', {
      'name': destinationName,
      'numDays': numDays,
      'lang': languageCode,
      'instruction': additionalInstruction,
      'aiPrompt': trip.aiPrompt.trim(),
    });
```

- [ ] **Step 5: Analyze and run the full test suite**

Run: `flutter analyze && flutter test`
Expected: no new analyzer issues, all tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/services/gemini_service.dart test/services/ai_cache_service_test.dart
git commit -m "fix: include free-text prompt in AI cache keys to prevent collisions"
```

---

### Task 6: Full verification and Pull Request

**Files:**
- No code changes. Verification and PR only.

**Interfaces:**
- Consumes: everything above.
- Produces: an open PR from `feature/prompt-first-step1` to `master`.

- [ ] **Step 1: Gate commands (repo rule)**

Run: `flutter analyze`
Expected: no new issues versus master (if master already had infos/warnings, only those may appear).

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 2: Manual smoke test, prompt-only**

Run the app (for example `flutter run -d chrome`). After login, on the Smart Planner screen:
1. Leave destination, dates, budget untouched (budget defaults to moderate, that is fine), participants and age empty.
2. Type only a prompt, for example: "Đi chơi 5 ngày với bố mẹ, thích ẩm thực và biển".
3. Tap "Get AI Suggestions". Expected: no validation snackbar; suggestions load and are NOT all Vietnam-biased if the prompt named elsewhere.
4. Tap a suggestion card. Expected: the detail screen loads with a budget breakdown.
5. Open the itinerary plan. Expected: a plan renders; ideally 5 days per the prompt, minimum a 3-day plan with no crash.
6. Empty the prompt box and tap the button. Expected: snackbar "Hãy mô tả chuyến đi của bạn trước" (device in Vietnamese) and no navigation.

- [ ] **Step 3: Push the branch and open the PR**

```bash
git push -u origin feature/prompt-first-step1
gh pr create --base master --head feature/prompt-first-step1 \
  --title "feat: prompt-first Smart Planner step 1 - prompt-only validation, prompt-aware AI calls" \
  --body "$(cat <<'EOF'
## Summary
- Only the free-text AI prompt is required on the Smart Planner; destination, dates, budget, participants, and age range are now optional (UI unchanged, labels reworded in en/vi/ko)
- Suggestions/detail/itinerary Gemini prompts infer missing fields from the trip description instead of hardcoding "Việt Nam" and fake dates; itinerary may honor a day count stated in the prompt
- AI cache keys now include the free-text prompt (fixes collisions between different prompt-only searches)

Spec: docs/superpowers/specs/2026-09-01-prompt-first-step1-design.md

## Test plan
- [x] flutter analyze clean
- [x] flutter test passes (new prompt-builder and cache-key tests)
- [x] Manual prompt-only smoke: planner -> suggestions -> detail -> itinerary

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Expected: PR URL printed. Do not merge; wait for review.
