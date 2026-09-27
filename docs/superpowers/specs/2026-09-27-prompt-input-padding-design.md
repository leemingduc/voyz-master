# Design Spec: Prompt & Input Fields Padding and Typography Refinement

**Date**: 2026-09-27  
**Branch**: `feature/app-padding`  
**Goal**: Refine padding, typography, alignment, and border spacing for prompt and text input fields across AIVIVU so that text does not stick to borders and typography feels polished while typing.

---

## 1. Problem Statement
- In `_AiPromptBox` (`lib/screens/smart_planner_screen.dart`), the search/prompt input field currently has `border: InputBorder.none`, `isDense: true`, and `contentPadding: EdgeInsets.zero`. When users type, the text is glued right to the top/bottom and too close to the icon and divider. The search icon (size 30) is not vertically aligned with the baseline or cap-height of the text.
- Across secondary screens (`chat_screen.dart`, `best_time_screen.dart`, `compare_screen.dart`, `destination_detail_screen.dart`, `friends_screen.dart`, `saved_screen.dart`), several text fields lack adequate `contentPadding` or proper line heights (`height: 1.4`), causing input text to feel cramped against the border.

---

## 2. Proposed Changes

### 2.1 Smart Planner Prompt Box (`_AiPromptBox` in `lib/screens/smart_planner_screen.dart`)
- **Container**: Increase padding from `const EdgeInsets.all(16)` to `const EdgeInsets.fromLTRB(18, 18, 18, 16)` with rounded borders (`BorderRadius.circular(20)`).
- **Search Icon**: Size adjusted to `26`, wrapped with `Padding(padding: EdgeInsets.only(top: 3))` so it aligns symmetrically with the first line of text.
- **TextField**:
  - `style`: `TextStyle(color: Colors.white, fontSize: 16, height: 1.4, letterSpacing: 0.2)`
  - `decoration.hintStyle`: `TextStyle(color: Colors.white.withValues(alpha: 0.42), fontSize: 16, height: 1.4, letterSpacing: 0.2)`
  - `decoration.contentPadding`: `EdgeInsets.symmetric(horizontal: 4, vertical: 4)`
  - Spacing before divider adjusted cleanly (`const SizedBox(height: 14)`).

### 2.2 Chat Screen Prompt Input (`lib/screens/chat_screen.dart`)
- TextField `contentPadding`: `const EdgeInsets.symmetric(horizontal: 20, vertical: 14)`.
- Text style: `TextStyle(color: Colors.white, fontSize: 15, height: 1.35)`.
- Enabled and focused borders with subtle outline border colors.

### 2.3 Best Time Screen Prompt Input (`lib/screens/best_time_screen.dart`)
- TextField `contentPadding`: `const EdgeInsets.symmetric(horizontal: 18, vertical: 14)`.
- `style`: `TextStyle(color: Colors.white, fontSize: 15, height: 1.35)`.
- Border radius: 14px with subtle border outlines on enabled/focused states.

### 2.4 Compare Screen Prompt Inputs (`lib/screens/compare_screen.dart`)
- Update the 3 destination input fields:
  - `contentPadding`: `const EdgeInsets.symmetric(horizontal: 18, vertical: 14)`.
  - `style`: `TextStyle(color: Colors.white, fontSize: 15, height: 1.35)`.

### 2.5 Destination Detail Review Input (`lib/screens/destination_detail_screen.dart`)
- `contentPadding`: `const EdgeInsets.symmetric(horizontal: 16, vertical: 14)`.
- `style`: `TextStyle(color: Colors.white, fontSize: 14, height: 1.4)`.

### 2.6 Friends Screen Inputs (`lib/screens/friends_screen.dart`)
- Search friends: `contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)`.
- Chat message: `contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13)`.

### 2.7 App Theme Base Defaults (`lib/theme/app_theme.dart`)
- Ensure `inputDecorationTheme` has `contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15)` and consistent line height support.

---

## 3. Scope & Verification
- Verify with `flutter analyze` or unit/widget tests.
- Confirm only committed to `feature/app-padding`, never pushing to `master`.
