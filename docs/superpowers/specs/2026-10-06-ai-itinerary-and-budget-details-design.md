# Design Spec: AI Detailed Itinerary & Budget Activity Optimization

**Date:** 2026-10-06  
**Branch:** `feature/ai-itinerary-and-budget-details`  
**Status:** Approved by User  

---

## 1. Overview & Goals
Enhance the AI itinerary generation in Voyz by providing richer, more detailed activity breakdowns (location, estimated cost, tips, and step-by-step details), renaming the budget optimization chip to **"Hoạt động nhiều hơn (Tối ưu ngân sách)"** to reflect maximum experiences per budget, and enabling interactive visual detail bottom sheets when users tap on itinerary activities or refinement chips.

---

## 2. Structural & Model Enhancements

### 2.1 Model Updates (`lib/models/itinerary_plan.dart`)
Extend `ItineraryItem` model with optional fields:
- `location` (`String?`): Specific place/address or area for the activity.
- `estimatedCost` (`String?`): Estimated expense range or tag (e.g., `"Miễn phí"`, `"~150.000 VNĐ"`).
- `tips` (`String?`): Practical advice/tips for visiting.
- `details` (`String?`): Expanded step-by-step description for the activity.

All new fields are optional with defaults, maintaining 100% backward compatibility with legacy JSON cache.

---

## 3. Gemini Prompt Tuning (`lib/services/gemini_service.dart`)

### 3.1 Prompt Refinement
Update `buildItineraryPrompt` in `GeminiService` to instruct AI to output:
- Clearer activities with specific locations, cost estimates, and practical tips.
- Rich JSON properties (`location`, `estimatedCost`, `tips`, `details`).

### 3.2 Refinement Prompt Action
When user triggers the budget/activity optimization chip, send prompt instruction:
- `"Ưu tiên tối ưu ngân sách để trải nghiệm thêm nhiều hoạt động, địa điểm thú vị và giá trị cao nhất trong cùng mức chi phí."`

---

## 4. UI & Interactive Detail Components (`lib/screens/destination_plan_screen.dart` & Localization)

### 4.1 Localization (`lib/l10n/app_vi.arb`, `app_en.arb`, `app_ko.arb`)
- Update `refineForBudget` key:
  - `vi`: `"Hoạt động nhiều hơn (Tối ưu ngân sách)"`
  - `en`: `"More Activities (Budget Optimized)"`
  - `ko`: `"더 많은 활동 (예산 최적화)"`

### 4.2 Timeline Activity Card Interactivity
- Make timeline activity cards in `_Timeline` tappable with visual ripple/hover effect.
- Tapping an activity opens `_showActivityDetailBottomSheet(context, item, color)`:
  - **Header:** Icon, activity title, and time tag.
  - **Location Chip:** Displays location name with pin icon.
  - **Estimated Cost Badge:** Highlights price/budget badge.
  - **Full Description & Details:** Comprehensive guide on what to do.
  - **Practical Tips Card:** Styled tip box with lightbulb icon.

### 4.3 Refinement Actions Bar (`_RefinementActions`)
- Enhance buttons with clear icons, rounded glassmorphic styling, and active loading indicators.
- Refinement prompt triggers AI refresh with explicit feedback.

---

## 5. Verification Plan

### 5.1 Static Analysis & Testing
- Run `flutter analyze` to ensure zero compilation or type errors.
- Run `flutter test` to ensure existing unit & widget tests pass cleanly.

---
