# Design Spec: Comprehensive Audit & Standardization of Inputs, Prompts & Textareas

**Date**: 2026-09-27  
**Branch**: `feature/app-padding`  
**Goal**: Standardize internal padding, typography line-height, text vertical alignment, and border clearance across all text inputs, prompts, and textareas in AIVIVU.

---

## 1. Problem Definition
- In various text inputs across the app, typed text lacks adequate internal padding, leading to characters crowding against borders.
- Text without explicit `height: 1.45` can exhibit line crowding or clipping, particularly for Vietnamese diacritics (`ệ, ợ, ẩ, ỹ`) and characters with ascenders/descenders (`g, y, p, d`).
- Placeholders and typed text in some fields had slight height mismatches, causing subtle cursor/line shifts when typing.
- Multi-line inputs (e.g. Smart Planner prompt, Review tip, Notes, Chat) need `textAlignVertical: TextAlignVertical.top` or `TextAlignVertical.center` to ensure proper layout balance for both short and long text.

---

## 2. Standardized Design Tokens & Rules

### 2.1 Typography Tokens
- **Font Size**:
  - Prompts & Primary Inputs: `16px`
  - Secondary / Form Inputs: `15px`
  - Compact Notes / Tips: `14px`
- **Line Height**: `height: 1.45` across both `style` and `hintStyle` / `labelStyle` to ensure consistent vertical rhythm, preventing text clipping on multiline and singleline.
- **Letter Spacing**: `letterSpacing: 0.2` for legible readability.

### 2.2 Padding Tokens
- **Single-line Inputs** (`AuthField`, `PasswordField`, `ContactPhoneField`, `BestTime`, `Compare`, `FindFriends`, `DialogField`):
  - `contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15)`
  - `textAlignVertical: TextAlignVertical.center`
  - Consistent border thickness and padding across enabled and focused states.
- **Multi-line / Textarea Inputs** (`DestinationDetail` review, `SavedScreen` notes):
  - `contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)`
  - `textAlignVertical: TextAlignVertical.top`
- **Smart Planner AI Prompt Box** (`_AiPromptBox`):
  - Outer Container: `EdgeInsets.fromLTRB(18, 18, 18, 16)`
  - Search Icon: Size 26 with `Padding(padding: EdgeInsets.only(top: 3))`
  - Inner TextField: `contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4)`, `textAlignVertical: TextAlignVertical.top` when multiline.

### 2.3 Shared Theme (`lib/theme/app_theme.dart`)
- Update `inputDecorationTheme`:
  - `contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15)`
  - `hintStyle: const TextStyle(color: textMuted, height: 1.45, fontSize: 15)`
  - `labelStyle: const TextStyle(color: textMuted, height: 1.45, fontSize: 15)`

---

## 3. Inventory of Modified Screens
1. `lib/theme/app_theme.dart` (Global theme)
2. `lib/screens/smart_planner_screen.dart` (`_AiPromptBox`)
3. `lib/screens/chat_screen.dart` (`_messageController` input)
4. `lib/screens/best_time_screen.dart` (`_destinationController`)
5. `lib/screens/compare_screen.dart` (`_dest1Controller`, `_dest2Controller`, `_dest3Controller`)
6. `lib/screens/destination_detail_screen.dart` (`_reviewController`)
7. `lib/screens/friends_screen.dart` (search & direct message)
8. `lib/screens/auth_screen.dart` (`_AuthField`)
9. `lib/screens/profile_screen.dart` (`_PasswordField`, `_ContactPhoneField`)
10. `lib/screens/saved_screen.dart` (collection dialog & notes textarea)

---

## 4. Verification
- All automated unit and widget tests pass (`flutter test`).
- Static analyzer clean with 0 warnings on updated files.
- Strictly maintained on `feature/app-padding` without pushing to `master`.
