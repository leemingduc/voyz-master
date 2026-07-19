# Multilingual System Design

**Date:** 2026-07-19  
**Branch:** `feature/multilingual`

## Goal

Provide a persistent application language setting for English (`en`), Vietnamese (`vi`), and Korean (`ko`). The selected language must immediately update the app UI and determine the language of new Gemini-generated travel content.

## Scope

- Localize all user-facing application UI strings into English, Vietnamese, and Korean.
- Persist the language selection locally and restore it on the next launch.
- Default to the device language when it is supported; otherwise default to English.
- Add a language selector to the Profile screen with English, Tiếng Việt, and 한국어 options.
- Pass the selected locale to Gemini prompt builders so all textual JSON content is returned in that language.
- Partition the Gemini cache by locale.

## Out of Scope

- Translating existing generated, saved, or cached content after the user changes language.
- A language selector on the login screen.
- Languages other than English, Vietnamese, and Korean.
- Runtime machine translation of application strings.

## Architecture

### Flutter localization

Use Flutter's standard localization stack:

- Add `flutter_localizations` from the Flutter SDK.
- Configure code generation through `flutter: generate: true` and `l10n.yaml`.
- Store application strings in `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`, and `lib/l10n/app_ko.arb`.
- Configure `MaterialApp` with the generated `AppLocalizations` delegates, supported locales, and the locale supplied by `LocaleProvider`.
- Replace direct UI literals with `AppLocalizations.of(context)` accessors, including labels, hints, buttons, validation and error messages, empty states, dialogs, and SnackBars.

### Locale state and persistence

Create `LocaleProvider`, following the existing state-provider pattern:

- It owns the active `Locale` and exposes a method to change it.
- It reads and writes a `language_code` value in a dedicated Hive box.
- During app initialization, it restores a saved supported language. When no saved value exists, it selects the device language only if it is `en`, `vi`, or `ko`; otherwise it uses `en`.
- It notifies descendants after a selection changes so `MaterialApp` rebuilds with the new locale.

The Profile screen contains a dedicated Language card with the three named choices. Selecting one updates the provider and persists it immediately.

## Gemini and Cache Flow

1. A screen reads the active language code from `LocaleProvider`.
2. It passes that code to the relevant `GeminiService` method.
3. Gemini prompt builders add a concise instruction requiring every human-readable JSON field to use the selected language. Structural keys, numeric values, IDs, and icon names remain stable.
4. Cache-key inputs include `languageCode`, so otherwise-identical requests in `en`, `vi`, and `ko` have independent entries.
5. Parsed results are displayed as returned. Changing the UI language does not mutate content already on screen; a new request or explicit refresh obtains content in the new language.

All existing Gemini request paths are covered: trending exploration, travel suggestions, destination details, and itinerary generation.

## Error Handling

- Unsupported or missing persisted values fall back to English without crashing.
- Failed persistence leaves the in-memory language selection usable and surfaces a localized, user-friendly message where appropriate.
- Gemini failures and invalid JSON retain current behavior while their messages shown to users are localized.
- Prompt and cache changes preserve the existing JSON response schema, so model parsers continue to work for all supported languages.

## Testing

- Unit tests for locale restoration, supported-device-locale selection, English fallback, and persistence after changing each supported language.
- Widget tests for app strings updating after a locale change and the Profile language selector setting the provider.
- Gemini-service tests confirming the locale instruction is included in prompts and `languageCode` contributes to cache keys.
- Run Flutter analysis and the existing widget-test suite as regression checks.

## Acceptance Criteria

1. Users can select English, Vietnamese, or Korean from Profile.
2. The selected language survives an app restart.
3. The UI immediately renders in the selected language.
4. A supported device locale is used on first launch; unsupported locales use English.
5. New Gemini outputs use the selected language.
6. Gemini cache results never cross language boundaries.
7. Existing app flows remain functional under all three locales.
