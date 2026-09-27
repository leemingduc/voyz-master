# Comprehensive Audit & Standardization of Inputs, Prompts & Textareas Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Standardize internal padding, line-height, text vertical alignment, and border clearance across all text inputs, prompt boxes, and textareas in AIVIVU according to a unified design system.

**Architecture:** Update global `inputDecorationTheme` in `lib/theme/app_theme.dart`. Standardize `_AiPromptBox` in `smart_planner_screen.dart`, `_AuthField` in `auth_screen.dart`, password/phone fields in `profile_screen.dart`, and textareas/inputs in `destination_detail_screen.dart`, `saved_screen.dart`, `chat_screen.dart`, `compare_screen.dart`, `best_time_screen.dart`, and `friends_screen.dart`. Write comprehensive widget tests verifying short text, long text, multiline text, and placeholder spacing.

**Tech Stack:** Flutter / Dart, Material 3, Flutter Test.

## Global Constraints

- Work strictly on branch `feature/app-padding` without pushing to `master` or remote.
- Keep current colors, backgrounds, borders, glow, and border-radii intact; refine only typography, spacing, and vertical alignment.
- Ensure all tests pass with 0 analyzer errors on modified files.

---

### Task 1: Update Global Theme and Smart Planner Prompt Box

**Files:**
- Modify: `lib/theme/app_theme.dart`
- Modify: `lib/screens/smart_planner_screen.dart`
- Test: `test/widgets/smart_planner_prompt_test.dart`

- [ ] **Step 1: Enhance `app_theme.dart` inputDecorationTheme**
Update `hintStyle` and `labelStyle` with `height: 1.45, fontSize: 15, letterSpacing: 0.2`, and `contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15)`.

- [ ] **Step 2: Enhance `_AiPromptBox` in `smart_planner_screen.dart`**
Add `textAlignVertical: TextAlignVertical.top` and ensure `style` and `hintStyle` have `height: 1.45, letterSpacing: 0.2`.

- [ ] **Step 3: Run existing prompt test**
Run: `flutter test test/widgets/smart_planner_prompt_test.dart`
Expected: PASS

- [ ] **Step 4: Commit task 1**
```bash
git add lib/theme/app_theme.dart lib/screens/smart_planner_screen.dart test/widgets/smart_planner_prompt_test.dart
git commit -m "style(theme): standardize global input decoration and prompt typography"
```

---

### Task 2: Standardize Auth & Profile Form Inputs

**Files:**
- Modify: `lib/screens/auth_screen.dart`
- Modify: `lib/screens/profile_screen.dart`
- Test: `test/widgets/input_padding_standardization_test.dart`

- [ ] **Step 1: Write test for Auth and Profile inputs padding & height**
Create `test/widgets/input_padding_standardization_test.dart` testing single-line input vertical alignment, height, and contentPadding.

- [ ] **Step 2: Update `_AuthField` in `lib/screens/auth_screen.dart`**
Add `contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15)`, `textAlignVertical: TextAlignVertical.center`, and `style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.45, letterSpacing: 0.2)`.

- [ ] **Step 3: Update `_PasswordField` and `_ContactPhoneField` in `lib/screens/profile_screen.dart`**
Add `contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15)`, `textAlignVertical: TextAlignVertical.center`, and `style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.45, letterSpacing: 0.2)`.

- [ ] **Step 4: Run test**
Run: `flutter test test/widgets/input_padding_standardization_test.dart`
Expected: PASS

- [ ] **Step 5: Commit task 2**
```bash
git add lib/screens/auth_screen.dart lib/screens/profile_screen.dart test/widgets/input_padding_standardization_test.dart
git commit -m "fix(auth/profile): standardize padding and typography in form inputs"
```

---

### Task 3: Standardize Chat, Textareas, and Exploration Inputs

**Files:**
- Modify: `lib/screens/destination_detail_screen.dart`
- Modify: `lib/screens/saved_screen.dart`
- Modify: `lib/screens/chat_screen.dart`
- Modify: `lib/screens/best_time_screen.dart`
- Modify: `lib/screens/compare_screen.dart`
- Modify: `lib/screens/friends_screen.dart`

- [ ] **Step 1: Standardize textareas in `destination_detail_screen.dart` & `saved_screen.dart`**
Set `textAlignVertical: TextAlignVertical.top`, `contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)`, `style.height: 1.45`, `hintStyle.height: 1.45`.

- [ ] **Step 2: Standardize chat inputs in `chat_screen.dart` & `friends_screen.dart`**
Set `textAlignVertical: TextAlignVertical.center`, `contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)`, `style.height: 1.45`.

- [ ] **Step 3: Standardize inputs in `best_time_screen.dart` & `compare_screen.dart`**
Set `textAlignVertical: TextAlignVertical.center`, `contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)`, `style.height: 1.45`.

- [ ] **Step 4: Commit task 3**
```bash
git add lib/screens/destination_detail_screen.dart lib/screens/saved_screen.dart lib/screens/chat_screen.dart lib/screens/best_time_screen.dart lib/screens/compare_screen.dart lib/screens/friends_screen.dart
git commit -m "fix(inputs): standardize textareas and secondary prompt inputs"
```

---

### Task 4: Comprehensive Verification (Short, Long, Multiline, Placeholder & Responsive)

**Files:**
- Modify: `test/widgets/input_padding_standardization_test.dart`

- [ ] **Step 1: Add test cases for short text, long text, multiline text, and placeholder spacing**
- [ ] **Step 2: Run all widget & unit tests**
Run: `flutter test`
Expected: All tests pass.
- [ ] **Step 3: Run flutter analyze**
Run: `flutter analyze`
Expected: 0 issues on all modified files.
- [ ] **Step 4: Commit task 4**
```bash
git add test/widgets/input_padding_standardization_test.dart
git commit -m "test(inputs): add comprehensive edge-case tests for inputs padding and multiline"
```
