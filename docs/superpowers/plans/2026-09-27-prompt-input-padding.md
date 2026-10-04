# Prompt & Input Fields Padding and Typography Refinement Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refine padding, typography, border clearance, and alignment across all prompt and text input fields in AIVIVU so that text never crowds borders and looks balanced and polished when typing.

**Architecture:** Update `_AiPromptBox` in `smart_planner_screen.dart` with dedicated contentPadding, balanced icon alignment, and improved typography line-height. Standardize input decorations and padding in secondary screens (`chat_screen.dart`, `best_time_screen.dart`, `compare_screen.dart`, `destination_detail_screen.dart`, `friends_screen.dart`, `saved_screen.dart`) and global `inputDecorationTheme` in `app_theme.dart`.

**Tech Stack:** Flutter / Dart, Flutter Material 3, Flutter Test.

## Global Constraints

- Work strictly on branch `feature/app-padding` without pushing to `master` or remote.
- Ensure all automated widget and unit tests pass with zero analyzer errors.
- Ensure text and border have generous breathing room (padding >= 14px vertical, >= 16px horizontal for standard inputs, well-spaced in prompt box).

---

### Task 1: Smart Planner Prompt Box Padding & Typography

**Files:**
- Modify: `lib/screens/smart_planner_screen.dart:590-645`
- Test: `test/widgets/smart_planner_prompt_test.dart`

**Interfaces:**
- Consumes: `_AiPromptBox` widget in `lib/screens/smart_planner_screen.dart`
- Produces: Polished `_AiPromptBox` with balanced padding, line height, and icon vertical alignment.

- [ ] **Step 1: Write widget test verifying _AiPromptBox layout and padding**

Create `test/widgets/smart_planner_prompt_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('verify prompt text field has non-zero contentPadding and proper line height', (tester) async {
    final controller = TextEditingController(text: 'Explore Da Nang for 3 days');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 500,
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 2,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.4,
                  letterSpacing: 0.2,
                ),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.style?.height, 1.4);
    expect(textField.decoration?.contentPadding, const EdgeInsets.symmetric(horizontal: 4, vertical: 6));
  });
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `flutter test test/widgets/smart_planner_prompt_test.dart`
Expected: PASS

- [ ] **Step 3: Update `_AiPromptBox` in `lib/screens/smart_planner_screen.dart`**

In `lib/screens/smart_planner_screen.dart`:
```dart
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(Icons.search, color: primaryColor, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: maxLines,
                  minLines: minLines,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.4,
                    letterSpacing: 0.2,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.42),
                      fontSize: 16,
                      height: 1.4,
                      letterSpacing: 0.2,
                    ),
                    border: InputBorder.none,
                    isDense: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: primaryColor.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 12),
```

- [ ] **Step 4: Run test to verify changes**

Run: `flutter test test/widgets/smart_planner_prompt_test.dart`
Expected: PASS

- [ ] **Step 5: Commit task 1**

```bash
git add lib/screens/smart_planner_screen.dart test/widgets/smart_planner_prompt_test.dart
git commit -m "fix(planner): refine prompt box padding, alignment, and typography"
```

---

### Task 2: Secondary Screens Prompt and Text Input Padding Refinement

**Files:**
- Modify: `lib/screens/chat_screen.dart:225-250`
- Modify: `lib/screens/best_time_screen.dart:140-165`
- Modify: `lib/screens/compare_screen.dart:150-215`
- Modify: `lib/screens/destination_detail_screen.dart:560-580`
- Modify: `lib/screens/friends_screen.dart:268-285,548-565`
- Modify: `lib/screens/saved_screen.dart:238-248,627-646`

- [ ] **Step 1: Update chat_screen.dart**
Improve input style and border padding:
```dart
Expanded(
  child: TextField(
    controller: _messageController,
    style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.35),
    decoration: InputDecoration(
      hintText: AppLocalizations.of(context)!.chatInputHint,
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.4),
        fontSize: 15,
      ),
      filled: true,
      fillColor: AppTheme.backgroundDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: AppTheme.cyan, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
      ),
    ),
    textInputAction: TextInputAction.send,
    onSubmitted: (_) => _sendMessage(),
  ),
),
```

- [ ] **Step 2: Update best_time_screen.dart**
Ensure 18px horizontal, 14px vertical padding and proper typography:
```dart
TextField(
  controller: _destinationController,
  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.35),
  decoration: InputDecoration(
    hintText: AppLocalizations.of(context)!.bestTimeHint,
    hintStyle: TextStyle(
      color: Colors.white.withValues(alpha: 0.4),
      fontSize: 15,
    ),
    filled: true,
    fillColor: AppTheme.backgroundDark,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppTheme.cyan, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 18,
      vertical: 14,
    ),
  ),
),
```

- [ ] **Step 3: Update compare_screen.dart**
Apply consistent 18x14 padding across all 3 destination prompt inputs.

- [ ] **Step 4: Update destination_detail_screen.dart**
Add explicit contentPadding (horizontal 16, vertical 14) and typography to review tip field.

- [ ] **Step 5: Update friends_screen.dart and saved_screen.dart**
Add explicit contentPadding to avoid cramped text against borders.

- [ ] **Step 6: Commit task 2**

```bash
git add lib/screens/chat_screen.dart lib/screens/best_time_screen.dart lib/screens/compare_screen.dart lib/screens/destination_detail_screen.dart lib/screens/friends_screen.dart lib/screens/saved_screen.dart
git commit -m "fix(ui): adjust padding and border spacing for prompt and text inputs"
```

---

### Task 3: Theme Global InputDecoration Defaults & Verification

**Files:**
- Modify: `lib/theme/app_theme.dart:148-168`

- [ ] **Step 1: Check and update `inputDecorationTheme` in `lib/theme/app_theme.dart`**
Ensure generous default contentPadding (`EdgeInsets.symmetric(horizontal: 18, vertical: 15)`).

- [ ] **Step 2: Run flutter analyze and tests**

Run: `flutter analyze`
Expected: 0 issues.

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 3: Commit task 3**

```bash
git add lib/theme/app_theme.dart
git commit -m "style(theme): enhance global inputDecorationTheme padding"
```
