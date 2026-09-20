# AIVIVU Dark Glass UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the approved Stitch-informed dark glass visual system to every existing AIVIVU Flutter screen without changing functionality or navigation flow.

**Architecture:** Centralize colors, typography, surfaces, spacing, and Material defaults in `AppTheme`; layer reusable wordmark, header, page background, cards, buttons, and bottom navigation on top. Update screens to consume those visual primitives only, retaining their present state, callbacks, routes, and data sources.

**Tech Stack:** Flutter, Material 3, `google_fonts`, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-09-20-aivivu-dark-glass-ui-design.md`

## Global Constraints

- Preserve all services, models, providers, localization keys, callbacks, and routes.
- Work only on `feature/ui-redesign`; never push or merge to `master` without separate user approval.
- Use Plus Jakarta Sans, background `#06070B`--`#10131A`, cyan `#00E5FF`, violet `#8B5CF6`, magenta `#FF3366`.
- Use a single AIVIVU wordmark, header treatment, and three-item bottom navigation component.
- Keep all controls responsive with 44px minimum touch targets and unchanged behavior.

## Review Focus

- A narrow device does not clip the fixed three-item navigation or its labels.
- A wide screen preserves readable, centered content rather than stretching cards indefinitely.
- Screens using a back affordance retain their original back callback and title/action controls.
- A disabled primary action retains its original disabled behavior and clear contrast.
- Vietnamese and Korean localized labels remain readable with CJK fallback fonts.

---

### Task 1: Theme and branded visual primitives

**Files:**
- Modify: `lib/theme/app_theme.dart`
- Create: `lib/widgets/shared/aivivu_wordmark.dart`
- Create: `lib/widgets/shared/aivivu_page_background.dart`
- Modify: `lib/widgets/shared/glass_card.dart`
- Modify: `lib/widgets/shared/gradient_button.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Produces: `AppTheme.brandGradient`, `AppTheme.pagePadding(BuildContext)`, `AivivuWordmark`, and `AivivuPageBackground` for all later screen work.
- Consumes: Flutter `ThemeData` and `GoogleFonts.plusJakartaSansTextTheme`.

- [ ] **Step 1: Write failing widget tests**

```dart
testWidgets('AIVIVU wordmark keeps the uppercase brand treatment', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: AivivuWordmark()));
  expect(find.text('AIVIVU'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart --name "AIVIVU wordmark"`
Expected: FAIL because `AivivuWordmark` does not exist.

- [ ] **Step 3: Implement theme and primitives**

```dart
static const Color cyan = Color(0xFF00E5FF);
static const Color violet = Color(0xFF8B5CF6);
static const Color magenta = Color(0xFFFF3366);
static const LinearGradient brandGradient = LinearGradient(
  colors: [cyan, violet, magenta],
);
```

Replace the Inter text theme with Plus Jakarta Sans while retaining existing CJK fallbacks. Implement `AivivuWordmark` with uppercase bold italic letter-spaced gradient text and a restrained shadow. Implement `AivivuPageBackground` as a low-contrast dark gradient/ambient accent wrapper. Make `GlassCard` and `GradientButton` consume the new tokens, with a 16--24px radius and no broad glow.

- [ ] **Step 4: Run focused tests**

Run: `flutter test test/widget_test.dart --name "AIVIVU wordmark"`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/theme/app_theme.dart lib/widgets/shared/aivivu_wordmark.dart lib/widgets/shared/aivivu_page_background.dart lib/widgets/shared/glass_card.dart lib/widgets/shared/gradient_button.dart test/widget_test.dart
git commit -m "feat: add dark glass design primitives"
```

### Task 2: Shared header and canonical navigation

**Files:**
- Create: `lib/widgets/shared/aivivu_header.dart`
- Modify: `lib/widgets/shared/bottom_nav_bar.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `AivivuWordmark`, `AppTheme`, localization labels, existing `ValueChanged<int>? onTap`.
- Produces: `AivivuHeader` and an equal-width three-item `BottomNavBar` used by every routed content screen.

- [ ] **Step 1: Write failing widget tests**

```dart
testWidgets('bottom navigation renders exactly three equal destinations', (tester) async {
  await tester.pumpWidget(_localizedApp(const BottomNavBar(currentIndex: 1)));
  expect(find.byType(Expanded), findsNWidgets(3));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart --name "exactly three equal destinations"`
Expected: FAIL until the navigation exposes the three equal items under the new visual contract.

- [ ] **Step 3: Implement the shared chrome**

```dart
const AivivuHeader({super.key, this.leading, this.actions = const []});
const BottomNavBar({super.key, required this.currentIndex, this.onTap});
```

Give `AivivuHeader` a glass transparent background, branded title, and support for existing leading/action widgets. Give `BottomNavBar` a safe-area-aware glass container, fixed 48px item touch targets, cyan active pill, and the current three localized destinations. Clamp any legacy `currentIndex` greater than 2 to its contextual Explore index without changing its callback.

- [ ] **Step 4: Run focused tests**

Run: `flutter test test/widget_test.dart --name "exactly three equal destinations"`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/shared/aivivu_header.dart lib/widgets/shared/bottom_nav_bar.dart test/widget_test.dart
git commit -m "feat: unify AIVIVU app chrome"
```

### Task 3: Apply the shell to entry, planner, discovery, and saved flows

**Files:**
- Modify: `lib/screens/splash_screen.dart`
- Modify: `lib/screens/auth_screen.dart`
- Modify: `lib/screens/auth_gate.dart`
- Modify: `lib/screens/smart_planner_screen.dart`
- Modify: `lib/screens/explore_screen.dart`
- Modify: `lib/screens/suggestions_screen.dart`
- Modify: `lib/screens/saved_screen.dart`
- Modify: `lib/screens/destination_detail_screen.dart`
- Modify: `lib/screens/destination_plan_screen.dart`

**Interfaces:**
- Consumes: visual primitives from Tasks 1--2.
- Produces: entry and core trip-flow screens with unchanged route arguments and handlers.

- [ ] **Step 1: Add a failing smoke test for shared brand rendering**

```dart
testWidgets('splash renders the shared AIVIVU wordmark', (tester) async {
  await tester.pumpWidget(_localizedApp(SplashScreen(nextScreen: const SizedBox())));
  expect(find.byType(AivivuWordmark), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart --name "splash renders the shared"`
Expected: FAIL until splash consumes `AivivuWordmark`.

- [ ] **Step 3: Apply visual-only screen changes**

Wrap screen bodies in `AivivuPageBackground`, replace local brand text and app bars with `AivivuWordmark`/`AivivuHeader`, and replace legacy color literals in visual controls with `AppTheme` tokens. Preserve all method bodies that load data, mutate state, or call `Navigator`.

- [ ] **Step 4: Run focused tests**

Run: `flutter test test/widget_test.dart --name "splash renders the shared"`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/splash_screen.dart lib/screens/auth_screen.dart lib/screens/auth_gate.dart lib/screens/smart_planner_screen.dart lib/screens/explore_screen.dart lib/screens/suggestions_screen.dart lib/screens/saved_screen.dart lib/screens/destination_detail_screen.dart lib/screens/destination_plan_screen.dart test/widget_test.dart
git commit -m "feat: restyle core trip screens"
```

### Task 4: Apply the shell to assistant, utilities, and account flows

**Files:**
- Modify: `lib/screens/chat_screen.dart`
- Modify: `lib/screens/ai_tools_screen.dart`
- Modify: `lib/screens/compare_screen.dart`
- Modify: `lib/screens/best_time_screen.dart`
- Modify: `lib/screens/cultural_tips_screen.dart`
- Modify: `lib/screens/friends_screen.dart`
- Modify: `lib/screens/profile_screen.dart`

**Interfaces:**
- Consumes: `AivivuPageBackground`, `AivivuHeader`, shared navigation and theme tokens.
- Produces: assistant, utility, and account screens with the same existing interactions on the new visual system.

- [ ] **Step 1: Add a failing shared-header widget test**

```dart
testWidgets('AI tools uses the shared AIVIVU header', (tester) async {
  await tester.pumpWidget(_localizedApp(const AIToolsScreen()));
  expect(find.byType(AivivuHeader), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart --name "AI tools uses the shared"`
Expected: FAIL because the AI tools screen still declares its local app bar.

- [ ] **Step 3: Apply visual-only screen changes**

Use the shared page background/header or the same branded full-screen treatment where an app bar is not present. Update screen-local glass panels, chips, input borders, and CTAs to tokens without changing their callbacks, form controllers, service calls, or route arguments. Convert all legacy bottom navigation indices to 0, 1, or 2 according to their existing contextual destination.

- [ ] **Step 4: Run focused tests**

Run: `flutter test test/widget_test.dart --name "AI tools uses the shared"`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/chat_screen.dart lib/screens/ai_tools_screen.dart lib/screens/compare_screen.dart lib/screens/best_time_screen.dart lib/screens/cultural_tips_screen.dart lib/screens/friends_screen.dart lib/screens/profile_screen.dart test/widget_test.dart
git commit -m "feat: restyle assistant and account screens"
```

### Task 5: Full verification and responsive review

**Files:**
- Modify: files identified by analyzer only if required to resolve a new UI compilation error.
- Test: full Flutter suite.

**Interfaces:**
- Consumes: all completed UI primitives and screen changes.
- Produces: a verified build with no new analyzer errors and passing tests.

- [ ] **Step 1: Run static analysis**

Run: `flutter analyze`
Expected: no new diagnostics attributable to the UI redesign.

- [ ] **Step 2: Run the complete test suite**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 3: Verify representative responsive layouts**

Run: `flutter test test/widget_test.dart`
Expected: PASS while validating wordmark, three-item navigation, and localized text fallbacks. Manually inspect Planner, Explore, Detail, Saved, Auth, and Profile at narrow and wide widths; confirm controls are visible and original actions still respond.

- [ ] **Step 4: Commit verification-only fixes when needed**

If static analysis identifies a new UI compilation issue, stage only the exact
screen or shared-widget file fixed for that diagnostic and commit it as
`fix: resolve UI verification findings`. Do not stage the pre-existing
generated plugin files.
