# Multilingual System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a persistent English, Vietnamese, and Korean UI locale and make newly generated Gemini travel content use the active locale.

**Architecture:** Flutter's generated ARB localization is the source of truth for UI copy. A root-level `LocaleProvider`, backed by Hive, exposes the current `Locale` and rebuilds `MaterialApp` on changes. Screens obtain the active language code when calling Gemini; every Gemini cache key includes that code.

**Tech Stack:** Flutter, `flutter_localizations`, Flutter ARB generation, Hive/Hive Flutter, `flutter_test`, Gemini SDK.

## Global Constraints

- Support exactly `en`, `vi`, and `ko`.
- Use the device language only on first launch and only when it is one of the supported language codes; otherwise use `en`.
- Persist the explicit choice in Hive under `language_code` in a dedicated `app_settings` box.
- All user-visible UI copy must be generated from `AppLocalizations`; do not add new inline UI strings.
- Gemini JSON property names, numeric values, and icon identifiers must remain language-neutral and unchanged.
- Every Gemini cache key must include `languageCode`.
- Changing language must not mutate an already-rendered AI result; the next request or refresh receives localized AI content.

---

## File Structure

| Path | Responsibility |
| --- | --- |
| `l10n.yaml` | Enables deterministic Flutter localization generation. |
| `lib/l10n/app_en.arb`, `app_vi.arb`, `app_ko.arb` | English source copy and complete Vietnamese/Korean translations. |
| `lib/data/locale_provider.dart` | Defines the locale controller, supported-locale validation, Hive persistence, and the widget-tree accessor. |
| `lib/main.dart` | Initializes the provider after Hive and configures `MaterialApp` delegates/locales. |
| `lib/screens/profile_screen.dart` | Shows and changes the persistent language setting. |
| `lib/screens/*.dart`, `lib/widgets/shared/*.dart` | Uses `AppLocalizations` for every visible label, hint, message, and action. |
| `lib/services/gemini_service.dart` | Includes language instructions in all prompts and language in every cache input. |
| `test/data/locale_provider_test.dart` | Verifies locale selection and Hive persistence. |
| `test/services/gemini_service_test.dart` | Verifies prompt locale instruction and cache separation through extracted pure helpers. |
| `test/widget_test.dart` | Verifies generated delegates and runtime locale rebuild behavior. |

### Task 1: Enable generated Flutter localizations

**Files:**
- Create: `l10n.yaml`
- Create: `lib/l10n/app_en.arb`
- Create: `lib/l10n/app_vi.arb`
- Create: `lib/l10n/app_ko.arb`
- Modify: `pubspec.yaml`
- Test: `test/widget_test.dart`

**Interfaces:**
- Produces: generated `AppLocalizations` with `localizationsDelegates`, `supportedLocales`, and typed getters.
- Consumes: Flutter's `flutter_localizations` SDK dependency.

- [ ] **Step 1: Write the failing localization widget test**

```dart
testWidgets('generated localization supplies Vietnamese copy', (tester) async {
  await tester.pumpWidget(const MaterialApp(
    locale: Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: LocalizedProbe(),
  ));
  expect(find.text('Đăng nhập'), findsOneWidget);
});
```

`LocalizedProbe` must render `Text(AppLocalizations.of(context)!.signIn)`. Run:

```powershell
flutter test test/widget_test.dart
```

Expected: compilation fails because `AppLocalizations` and `signIn` do not yet exist.

- [ ] **Step 2: Add localization configuration and SDK dependency**

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

flutter:
  generate: true
  uses-material-design: true
```

Create `l10n.yaml`:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
```

- [ ] **Step 3: Add the initial typed ARB contract**

All three ARB files must contain exactly the same keys. Start the English source with:

```json
{
  "@@locale": "en",
  "appTitle": "AIVIVU - AI Travel Advisor",
  "profile": "Profile",
  "language": "Language",
  "english": "English",
  "vietnamese": "Tiếng Việt",
  "korean": "한국어",
  "signIn": "Sign in",
  "genericError": "Something went wrong. Please try again.",
  "save": "Save",
  "cancel": "Cancel"
}
```

Add the corresponding verified translations:

```json
// app_vi.arb
{"@@locale":"vi","appTitle":"AIVIVU - Cố vấn du lịch AI","profile":"Hồ sơ","language":"Ngôn ngữ","english":"English","vietnamese":"Tiếng Việt","korean":"한국어","signIn":"Đăng nhập","genericError":"Đã có lỗi xảy ra. Vui lòng thử lại.","save":"Lưu","cancel":"Hủy"}
```

```json
// app_ko.arb
{"@@locale":"ko","appTitle":"AIVIVU - AI 여행 어드바이저","profile":"프로필","language":"언어","english":"English","vietnamese":"Tiếng Việt","korean":"한국어","signIn":"로그인","genericError":"문제가 발생했습니다. 다시 시도해 주세요.","save":"저장","cancel":"취소"}
```

- [ ] **Step 4: Generate and run the test**

```powershell
flutter pub get
flutter gen-l10n
flutter test test/widget_test.dart
```

Expected: the localization probe passes.

- [ ] **Step 5: Commit**

```powershell
git add pubspec.yaml pubspec.lock l10n.yaml lib/l10n test/widget_test.dart
git commit -m "feat: configure generated app localizations"
```

### Task 2: Add a persistent, testable locale provider

**Files:**
- Create: `lib/data/locale_provider.dart`
- Create: `test/data/locale_provider_test.dart`
- Modify: `lib/main.dart`

**Interfaces:**
- Produces: `LocaleProvider.of(BuildContext)`, `LocaleController.value`, and `Future<void> LocaleController.setLocale(Locale locale)`.
- Consumes: initialized Hive and `Locale`.
- Depends on: Task 1's `AppLocalizations` contract.

- [ ] **Step 1: Write failing provider tests**

```dart
test('uses English for an unsupported device language', () async {
  expect(
    await LocaleSettingsStore.instance.load(const Locale('fr')),
    const Locale('en'),
  );
});

test('persists and restores Korean', () async {
  await LocaleSettingsStore.instance.save(const Locale('ko'));
  expect(await LocaleSettingsStore.instance.load(const Locale('en')), const Locale('ko'));
});
```

Initialize Hive with a temporary directory in `setUpAll`, delete the `app_settings` box in `setUp`, and close Hive in `tearDownAll`. Run:

```powershell
flutter test test/data/locale_provider_test.dart
```

Expected: compilation fails because `LocaleSettingsStore` and `LocaleProvider` do not exist.

- [ ] **Step 2: Implement the provider and persistence boundary**

```dart
const supportedLanguageCodes = <String>{'en', 'vi', 'ko'};

class LocaleSettingsStore {
  LocaleSettingsStore._();
  static final instance = LocaleSettingsStore._();
  static const _boxName = 'app_settings';
  static const _languageCodeKey = 'language_code';

  Future<Locale> load(Locale deviceLocale) async {
    final box = await Hive.openBox<String>(_boxName);
    final saved = box.get(_languageCodeKey);
    final code = saved ?? deviceLocale.languageCode;
    return Locale(supportedLanguageCodes.contains(code) ? code : 'en');
  }

  Future<void> save(Locale locale) async {
    final box = await Hive.openBox<String>(_boxName);
    await box.put(_languageCodeKey, locale.languageCode);
  }
}
```

Implement a `LocaleController extends ValueNotifier<Locale>` with `Future<void> setLocale(Locale locale)`. The method must reject unsupported codes, set `value`, and then call `LocaleSettingsStore.instance.save`. Implement `LocaleProvider extends InheritedNotifier<LocaleController>`; its static `of(BuildContext)` returns the controller with `dependOnInheritedWidgetOfExactType`.

- [ ] **Step 3: Bootstrap the resolved locale before rendering**

In `main()`, after `Hive.initFlutter()` and before `runApp`, resolve the device locale and pass it to the app:

```dart
final initialLocale = await LocaleSettingsStore.instance.load(
  WidgetsBinding.instance.platformDispatcher.locale,
);
runApp(VoyzApp(initialLocale: initialLocale));
```

Change `VoyzApp` to receive `required this.initialLocale` and make it stateful. Its state creates one `LocaleController(initialLocale)`, disposes it, and wraps a `Builder` in `LocaleProvider(controller: _localeController, child: ...) `. The builder must read `LocaleProvider.of(context).value` so an inherited-notifier update rebuilds `MaterialApp`.

- [ ] **Step 4: Run tests**

```powershell
flutter test test/data/locale_provider_test.dart test/widget_test.dart
```

Expected: provider tests and existing splash test pass.

- [ ] **Step 5: Commit**

```powershell
git add lib/data/locale_provider.dart lib/main.dart test/data/locale_provider_test.dart test/widget_test.dart
git commit -m "feat: persist application locale"
```

### Task 3: Wire the provider into MaterialApp and Profile language settings

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/screens/profile_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Modify: `lib/l10n/app_ko.arb`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `LocaleProvider.of(context).value` and `LocaleController.setLocale`.
- Produces: a live `MaterialApp.locale` and a Profile selector.

- [ ] **Step 1: Write a failing locale-switch widget test**

```dart
testWidgets('selecting Korean rebuilds localized UI', (tester) async {
  await tester.pumpWidget(VoyzApp(initialLocale: const Locale('en')));
  await tester.tap(find.text('한국어'));
  await tester.pumpAndSettle();
  expect(find.text('프로필'), findsWidgets);
});
```

Use a test-only `ProfileScreen` route or extract `LanguageSettingsCard` so the test can pump it without Supabase.

- [ ] **Step 2: Configure MaterialApp**

```dart
final localeState = LocaleProvider.of(context);
return MaterialApp(
  onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
  locale: localeState.value,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  localeResolutionCallback: (locale, supported) =>
      supported.any((item) => item.languageCode == locale?.languageCode)
          ? locale
          : const Locale('en'),
  // preserve theme and home values
);
```

- [ ] **Step 3: Add a reusable Profile language card**

Add `language`, `english`, `vietnamese`, `korean`, and `languageSaved` to every ARB file. Implement a card below the account card that maps the display labels to `Locale` values:

```dart
for (final option in const [
  (Locale('en'), 'english'),
  (Locale('vi'), 'vietnamese'),
  (Locale('ko'), 'korean'),
])
  RadioListTile<Locale>(
    value: option.$1,
    groupValue: LocaleProvider.of(context).value,
    onChanged: (locale) async {
      if (locale == null) return;
      await LocaleProvider.of(context).setLocale(locale);
      if (mounted) _showMessage(AppLocalizations.of(context)!.languageSaved);
    },
    title: Text(localizedLabel(context, option.$2)),
  );
```

Use a local `localizedLabel` switch returning the appropriate generated getter; do not use the ARB key as UI text.

- [ ] **Step 4: Generate localization output and run tests**

```powershell
flutter gen-l10n
flutter test test/widget_test.dart
```

Expected: the selector changes the app locale and the app rebuilds.

- [ ] **Step 5: Commit**

```powershell
git add lib/main.dart lib/screens/profile_screen.dart lib/l10n test/widget_test.dart
git commit -m "feat: add profile language selector"
```

### Task 4: Localize shared widgets and app shell

**Files:**
- Modify: `lib/widgets/shared/account_menu_button.dart`
- Modify: `lib/widgets/shared/bottom_nav_bar.dart`
- Modify: `lib/widgets/shared/gradient_button.dart`
- Modify: `lib/widgets/shared/interest_chip.dart`
- Modify: `lib/screens/splash_screen.dart`
- Modify: `lib/screens/auth_gate.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Modify: `lib/l10n/app_ko.arb`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: `AppLocalizations.of(context)!`.
- Produces: localized shared navigation and reusable controls.

- [ ] **Step 1: Extend the failing probe test**

```dart
expect(find.text(AppLocalizations.of(context)!.savedTrips), findsOneWidget);
expect(find.text(AppLocalizations.of(context)!.profile), findsOneWidget);
```

Run `flutter test test/widget_test.dart`; expected failure is missing generated getters.

- [ ] **Step 2: Add and translate shell keys**

Add exact semantic keys such as `home`, `explore`, `savedTrips`, `profile`, `signOut`, `loading`, `back`, and `aiPowered` to all ARB files. Replace every shared-widget `Text('...')`, tooltip, and SnackBar literal with the matching generated getter. Keep visual style, routes, icons, and callbacks unchanged.

- [ ] **Step 3: Verify**

```powershell
flutter gen-l10n
flutter test test/widget_test.dart
flutter analyze lib/widgets/shared lib/screens/splash_screen.dart lib/screens/auth_gate.dart
```

Expected: no analyzer diagnostics and tests pass.

- [ ] **Step 4: Commit**

```powershell
git add lib/widgets/shared lib/screens/splash_screen.dart lib/screens/auth_gate.dart lib/l10n test/widget_test.dart
git commit -m "feat: localize shared app controls"
```

### Task 5: Localize authentication and profile copy

**Files:**
- Modify: `lib/screens/auth_screen.dart`
- Modify: `lib/screens/profile_screen.dart`
- Modify: `lib/services/profile_service.dart` only if it exposes a user-facing error literal
- Modify: all three `lib/l10n/app_*.arb`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: generated auth/profile getters and `LocaleProvider`.
- Produces: no inline auth/profile user-visible strings.

- [ ] **Step 1: Write failing English/Vietnamese widget assertions**

```dart
expect(find.text('Sign in'), findsOneWidget);
await tester.pumpWidget(localizedAuthApp(const Locale('vi')));
expect(find.text('Đăng nhập'), findsOneWidget);
```

- [ ] **Step 2: Replace the complete screen copy**

Add semantic keys for sign-in/sign-up mode, email, password, confirm password, password validation, account/profile headings, avatar controls, password controls, and success/error SnackBars. Replace string literals in widget constructors and in `_showMessage` call sites with `AppLocalizations` accessors. Keep Supabase exception content as returned; wrap only app-owned fallback copy in generated strings.

- [ ] **Step 3: Verify**

```powershell
flutter gen-l10n
flutter test test/widget_test.dart
flutter analyze lib/screens/auth_screen.dart lib/screens/profile_screen.dart
```

Expected: all tests pass and neither screen has direct UI text literals.

- [ ] **Step 4: Commit**

```powershell
git add lib/screens/auth_screen.dart lib/screens/profile_screen.dart lib/services/profile_service.dart lib/l10n test/widget_test.dart
git commit -m "feat: localize authentication and profile"
```

### Task 6: Localize planner, exploration, and saved-trip flows

**Files:**
- Modify: `lib/screens/smart_planner_screen.dart`
- Modify: `lib/screens/explore_screen.dart`
- Modify: `lib/screens/suggestions_screen.dart`
- Modify: `lib/screens/saved_screen.dart`
- Modify: `lib/data/mock_data.dart`
- Modify: all three `lib/l10n/app_*.arb`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: generated copy for planner input labels, buttons, loading, empty states, and notifications.
- Produces: localized non-AI app copy in core discovery flows.

- [ ] **Step 1: Add failing locale assertions for planner actions**

```dart
await tester.pumpWidget(localizedPlannerApp(const Locale('en')));
expect(find.text('Get AI Suggestions'), findsOneWidget);
await tester.pumpWidget(localizedPlannerApp(const Locale('ko')));
expect(find.text('AI 추천 받기'), findsOneWidget);
```

- [ ] **Step 2: Add semantic ARB keys and replace literals**

Translate every title, field label, hint, optional marker, button, tab, loading text, empty state, validation message, and app-owned SnackBar in the four screens. Move `MockData` UI labels and planner hint behind localization accessors; keep only data constants that are not user-facing. Preserve date, currency, trip-model, and navigation behavior.

- [ ] **Step 3: Verify**

```powershell
flutter gen-l10n
flutter test test/widget_test.dart
flutter analyze lib/screens/smart_planner_screen.dart lib/screens/explore_screen.dart lib/screens/suggestions_screen.dart lib/screens/saved_screen.dart lib/data/mock_data.dart
```

Expected: tests pass with no analyzer diagnostics.

- [ ] **Step 4: Commit**

```powershell
git add lib/screens/smart_planner_screen.dart lib/screens/explore_screen.dart lib/screens/suggestions_screen.dart lib/screens/saved_screen.dart lib/data/mock_data.dart lib/l10n test/widget_test.dart
git commit -m "feat: localize travel discovery flows"
```

### Task 7: Localize destination detail and itinerary views

**Files:**
- Modify: `lib/screens/destination_detail_screen.dart`
- Modify: `lib/screens/destination_plan_screen.dart`
- Modify: `lib/models/destination_detail.dart` only if a UI fallback literal exists
- Modify: `lib/models/itinerary_plan.dart` only if a UI fallback literal exists
- Modify: all three `lib/l10n/app_*.arb`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: localized UI labels while displaying model text returned by Gemini unchanged.
- Produces: localized labels surrounding detail, budget, and itinerary data.

- [ ] **Step 1: Write failing view-label assertions**

```dart
await tester.pumpWidget(localizedDetailApp(const Locale('vi')));
expect(find.text('Lưu chuyến đi'), findsOneWidget);
await tester.pumpWidget(localizedDetailApp(const Locale('ko')));
expect(find.text('여행 저장'), findsOneWidget);
```

- [ ] **Step 2: Localize only application-owned UI**

Add and use ARB keys for detail metadata labels, budget categories, itinerary headings, load/retry actions, save actions, duplicate-save notice, and error copy. Do not translate `DestinationDetail` or `ItineraryPlan` fields in widgets: those come from Gemini and will be locale-specific by Task 8.

- [ ] **Step 3: Verify**

```powershell
flutter gen-l10n
flutter test test/widget_test.dart
flutter analyze lib/screens/destination_detail_screen.dart lib/screens/destination_plan_screen.dart
```

Expected: tests pass and model data displays unchanged.

- [ ] **Step 4: Commit**

```powershell
git add lib/screens/destination_detail_screen.dart lib/screens/destination_plan_screen.dart lib/models/destination_detail.dart lib/models/itinerary_plan.dart lib/l10n test/widget_test.dart
git commit -m "feat: localize destination views"
```

### Task 8: Make Gemini prompts and cache keys locale-aware

**Files:**
- Modify: `lib/services/gemini_service.dart`
- Modify: `lib/screens/explore_screen.dart`
- Modify: `lib/screens/suggestions_screen.dart`
- Modify: `lib/screens/destination_detail_screen.dart`
- Modify: `lib/screens/destination_plan_screen.dart`
- Create: `test/services/gemini_service_test.dart`

**Interfaces:**
- Changes all public Gemini methods to require `String languageCode`: `getExploreTrending`, `getSuggestions`, `getDestinationDetail`, and `getItineraryPlan`.
- Produces: pure `languageInstruction(String languageCode)` and cache input maps containing `languageCode`.
- Consumes: `LocaleProvider.of(context).locale.languageCode`.

- [ ] **Step 1: Extract pure helpers and write failing tests**

```dart
test('Korean instruction requests Korean human-readable JSON fields', () {
  expect(languageInstruction('ko'), contains('Korean'));
});

test('cache keys differ by language', () {
  expect(
    cacheKeyForSuggestions(trip, languageCode: 'en'),
    isNot(cacheKeyForSuggestions(trip, languageCode: 'vi')),
  );
});
```

Run:

```powershell
flutter test test/services/gemini_service_test.dart
```

Expected: compilation fails because helpers are absent.

- [ ] **Step 2: Implement language normalization and prompt instruction**

```dart
String languageInstruction(String languageCode) {
  return switch (languageCode) {
    'vi' => 'Write every human-readable JSON value in Vietnamese.',
    'ko' => 'Write every human-readable JSON value in Korean.',
    _ => 'Write every human-readable JSON value in English.',
  };
}
```

Append `languageInstruction(languageCode)` to every prompt. For every `_cache.buildKey` call, include `'languageCode': languageCode` in the input map. Preserve JSON keys, numeric fields, icon names, and parser methods.

- [ ] **Step 3: Pass the active locale from every caller**

```dart
final languageCode = LocaleProvider.of(context).locale.languageCode;
final results = await GeminiService.instance.getSuggestions(
  trip,
  languageCode: languageCode,
);
```

Apply the same argument to trending, destination detail, and itinerary calls. Use the captured `languageCode` for the duration of a request so a locale change cannot create a mismatched prompt/cache pair.

- [ ] **Step 4: Run focused tests and analysis**

```powershell
flutter test test/services/gemini_service_test.dart
flutter analyze lib/services/gemini_service.dart lib/screens/explore_screen.dart lib/screens/suggestions_screen.dart lib/screens/destination_detail_screen.dart lib/screens/destination_plan_screen.dart
```

Expected: cache-separation and prompt tests pass; no caller is missing the required argument.

- [ ] **Step 5: Commit**

```powershell
git add lib/services/gemini_service.dart lib/screens/explore_screen.dart lib/screens/suggestions_screen.dart lib/screens/destination_detail_screen.dart lib/screens/destination_plan_screen.dart test/services/gemini_service_test.dart
git commit -m "feat: localize Gemini responses by app language"
```

### Task 9: Run the regression suite and audit UI string coverage

**Files:**
- Modify only if gaps are found: `lib/l10n/app_*.arb`, corresponding screen/widget file, and focused test.

**Interfaces:**
- Consumes: all previous tasks.
- Produces: verified three-locale behavior without direct application-owned UI literals.

- [ ] **Step 1: Audit remaining direct UI literals**

```powershell
rg -n "Text\('([^']+)'|label: '([^']+)'|hintText: '([^']+)'|title: '([^']+)'" lib
```

For every match that is user-visible application copy, add the semantic ARB key and its English, Vietnamese, and Korean translations, then replace the literal. Do not replace model data, route names, icon names, Hive key names, or JSON keys.

- [ ] **Step 2: Regenerate and run the complete test suite**

```powershell
flutter gen-l10n
flutter analyze
flutter test
```

Expected: `flutter analyze` has no diagnostics and `flutter test` exits with code 0.

- [ ] **Step 3: Manually smoke-test each locale**

For each of `en`, `vi`, and `ko`: start the app, select the language in Profile, restart the app, verify the choice persists, then request a suggestion and verify new Gemini prose uses that language. Confirm that a query made in another locale is not reused.

- [ ] **Step 4: Commit final corrections**

```powershell
git add lib test pubspec.yaml pubspec.lock l10n.yaml
git commit -m "test: verify multilingual application flows"
```
