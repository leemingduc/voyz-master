# Smart Planner, prompt-first step 1: loosen validation, prompt-aware AI calls

Date: 2026-09-01
Status: Draft for review
Companion diagram: `2026-09-01-prompt-first-step1-flow.html` (open in a browser)

## Context

The Smart Planner screen (`lib/screens/smart_planner_screen.dart`) currently requires destination, depart date, return date, budget tier, participants, and age range before the user can request AI suggestions. Ironically the free-text AI prompt is the one field that is NOT required. The long-term goal is an AI-first, minimal UI where the user simply describes their trip. This spec covers step 1 only: make the prompt the primary input without changing the screen layout. Step 2 (removing redundant components and adding AI extraction of structured fields) is a separate spec.

Downstream code is already null-tolerant: the Gemini prompt builders fall back to "linh hoạt" and "không rõ" for missing fields, the itinerary flow defaults to 3 days when dates are absent, and search history and saved trips accept empty values.

## Goal

With ONLY the prompt box filled, the full journey works end to end and produces sensible results: Planner -> Suggestions -> Destination detail -> Itinerary plan.

## Decisions (agreed in brainstorming)

1. Minimum input: the free-text prompt is the single required field. Everything else is optional.
2. When the destination field is empty, the AI must infer the destination from the trip description instead of assuming "Việt Nam".
3. When no dates are picked, the AI may honor a day count stated in the prompt (for example "5-day trip"), defaulting to 3 days as today.
4. UI stays intact. Every component remains on screen. Only label text changes: the "REQUIRED INFO" section header is reworded to an optional wording, and the validation snackbar message changes. Component removal is step 2.

## Changes

### 1. Validation (lib/screens/smart_planner_screen.dart)

- `_validateInput()` requires only `_promptController.text.trim().isNotEmpty`.
- All other checks (destination, dates, budget, participants, age range) are removed.
- Snackbar uses a new localized message asking the user to describe their trip.

### 2. Localization (lib/l10n/app_en.arb, app_vi.arb, app_ko.arb + generated files)

- `requiredInfo` reworded to an optional-details heading, for example:
  - en: "TRIP DETAILS (OPTIONAL)"
  - vi: "THÔNG TIN CHUYẾN ĐI (TÙY CHỌN)"
  - ko: "여행 정보 (선택)"
- New key `describeTripRequired` for the snackbar, for example:
  - en: "Please describe your trip first"
  - vi: "Hãy mô tả chuyến đi của bạn trước"
  - ko: "먼저 여행을 설명해 주세요"
- `fillAllRequired` key stays in the arb files untouched; the planner simply stops referencing it. Deleting unused keys is cleanup for step 2.

### 3. Suggestions prompt (lib/services/gemini_service.dart, `_buildSuggestionsPrompt`)

- When `trip.destination` is empty and `trip.aiPrompt` is non-empty: the destination line instructs the model to infer the destination from the trip description instead of hardcoding "Việt Nam".
- When dates or participants are missing and a trip description exists, the prompt tells the model to infer those from the description too (instead of just "linh hoạt" / "không rõ").
- Keep the "Việt Nam" fallback only for the case where both destination and prompt are empty (defensive; the planner now always sends a prompt).

### 4. Detail and itinerary prompts (lib/services/gemini_service.dart)

- `_buildItineraryPrompt` and `_buildDetailPrompt` include the trip description (`trip.aiPrompt`) when non-empty.
- Itinerary: when `departDate`/`returnDate` are null, instruct the model to use a day count stated in the trip description if present, otherwise the passed `numDays` (callers keep the existing default of 3 and the cap of 7). The plan screen already renders however many days come back in the JSON.

### 5. Cache keys (lib/services/gemini_service.dart)

- Suggestions cache key adds: `aiPrompt`, `additionalNotes`, depart/return dates. Today two different prompt-only searches with the same budget and interests collide and return the same cached list.
- Itinerary cache key adds: `aiPrompt`.
- Detail cache key adds: `aiPrompt` (the detail prompt now includes the trip description).

## Error handling

Unchanged. Existing try/catch paths, empty-result handling, and JSON parse fallbacks stay as they are.

## Testing

- Unit tests where feasible for the prompt builders (missing fields plus aiPrompt produce the inference instructions; cache keys differ when prompts differ).
- `flutter analyze` reports no new issues; `flutter test` passes (repo rule before any PR).
- Manual smoke: prompt-only input ("Đi chơi 5 ngày với bố mẹ, thích ẩm thực") through Planner -> Suggestions -> Detail -> Plan.

## Out of scope (step 2)

- Removing form components from the screen.
- An AI extraction call that parses the prompt into structured TripData fields.
- Changing the 7-day itinerary cap or the search history schema.

## Risks

- Cache key changes invalidate existing cached suggestions once (acceptable; cache repopulates).
- Prompt wording changes can shift AI output quality; mitigated by keeping all existing fallback wording when a field IS provided.
