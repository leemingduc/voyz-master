# AI Trip Consultation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Provide an interactive AI discussion screen (`TripConsultationScreen`) after entering a prompt in `SmartPlannerScreen`, allowing users to chat with AI to discuss/refine trip ideas, edit trip info (budget, duration, interests) inline, and confirm before viewing recommended destinations and detailed itineraries.

**Architecture:** 
- Navigates from `SmartPlannerScreen` to new `TripConsultationScreen`.
- Integrates `GeminiService.consultTrip(...)` for conversational recommendations aware of user prompt and current `TripData`.
- Includes a collapsible panel to edit `TripData` on the fly with live sync to `SavedTripsProvider`.
- Upon confirmation, navigates to `SuggestionsScreen` (with updated parameters) and subsequent `DestinationPlanScreen`.

**Tech Stack:** Flutter / Dart, `SavedTripsProvider`, `GeminiService`, Flutter Localization (`AppLocalizations`).

## Global Constraints
- **CRITICAL**: Do NOT push code to branch `master`. All commits remain local on `feature/ui-redesign`.
- Retain glassmorphism and Aivivu brand styling (AppTheme.surfaceDark, AppTheme.brandGradient, cyan/magenta accents).
- Fully support multi-language (en, vi, ko).

---

### Task 1: Add Localization Strings for Trip Consultation

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Modify: `lib/l10n/app_ko.arb`

- [ ] **Step 1: Add localization keys to ARB files**
Add `tripConsultationTitle`, `confirmAndSeeSuggestions`, `tripInfo`, `tripInfoUpdated`, `consultationInitialPrompt`, `quickChipRelaxed`, `quickChipFoodie`, `quickChipBudget`, `quickChipReady` to `app_en.arb`, `app_vi.arb`, and `app_ko.arb`.

- [ ] **Step 2: Generate localizations**
Run: `flutter gen-l10n`

- [ ] **Step 3: Commit localization changes**
```bash
git add lib/l10n/
git commit -m "feat(l10n): add translation strings for trip consultation"
```

---

### Task 2: Add `consultTrip` to `GeminiService`

**Files:**
- Modify: `lib/services/gemini_service.dart`
- Test: `test/services/gemini_service_test.dart` (or verify with existing tests)

**Interfaces:**
- Produces: `Future<String> consultTrip({required String message, required List<ChatMessage> history, required TripData currentTrip, required String languageCode})`

- [ ] **Step 1: Implement `consultTrip` in `GeminiService`**
Build custom prompt with travel consultant persona, incorporating current trip budget, interests, dates, and chat history.

- [ ] **Step 2: Verify compilation and tests**
Run: `flutter test test/data/locale_provider_test.dart`

- [ ] **Step 3: Commit GeminiService additions**
```bash
git add lib/services/gemini_service.dart
git commit -m "feat(ai): add consultTrip service method"
```

---

### Task 3: Create `TripConsultationScreen`

**Files:**
- Create: `lib/screens/trip_consultation_screen.dart`
- Test: `test/screens/trip_consultation_screen_test.dart`

**Interfaces:**
- Consumes: `SavedTripsProvider`, `CurrencyProvider`, `GeminiService.consultTrip`
- Produces: `TripConsultationScreen` widget

- [ ] **Step 1: Write test for `TripConsultationScreen`**
Create `test/screens/trip_consultation_screen_test.dart` asserting that the screen renders the title, trip info summary, input field, and confirm button.

- [ ] **Step 2: Implement `TripConsultationScreen`**
Implement the screen with:
- Glassmorphism App Bar with "Xác nhận & Xem gợi ý" action button.
- Collapsible Trip Info Banner with inline editor for Budget Tier and Interests.
- Chat message stream with typing indicator.
- Quick prompt chips.
- Text input box.
- Confirmation logic to navigate to `SuggestionsScreen`.

- [ ] **Step 3: Run test to verify it passes**
Run: `flutter test test/screens/trip_consultation_screen_test.dart`

- [ ] **Step 4: Commit `TripConsultationScreen`**
```bash
git add lib/screens/trip_consultation_screen.dart test/screens/trip_consultation_screen_test.dart
git commit -m "feat(ui): implement TripConsultationScreen"
```

---

### Task 4: Connect `SmartPlannerScreen` to `TripConsultationScreen`

**Files:**
- Modify: `lib/screens/smart_planner_screen.dart`

- [ ] **Step 1: Update navigation in `_onGetSuggestions`**
Change `Navigator.push` in `_onGetSuggestions` of `SmartPlannerScreen` to push `TripConsultationScreen` instead of directly pushing `SuggestionsScreen`.

- [ ] **Step 2: Verify app compiles cleanly**
Run: `flutter analyze`

- [ ] **Step 3: Commit navigation update**
```bash
git add lib/screens/smart_planner_screen.dart
git commit -m "feat(planner): route suggest action to TripConsultationScreen"
```

---

### Task 5: End-to-End Verification

- [ ] **Step 1: Run flutter test suite**
Run: `flutter test`

- [ ] **Step 2: Manual walkthrough verification in browser**
Verify clicking suggest in SmartPlannerScreen opens TripConsultationScreen, chat works, editing trip info updates provider, and clicking confirm navigates to SuggestionsScreen and DestinationPlanScreen.
