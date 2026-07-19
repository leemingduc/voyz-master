import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// Language codes supported by this application.
const Set<String> supportedLanguageCodes = <String>{'en', 'vi', 'ko'};

// ── Persistence layer ─────────────────────────────────────────────────────

/// Reads and writes the user's chosen locale to Hive.
///
/// All persistence is isolated in this class so it can be swapped or
/// mocked in tests.
class LocaleSettingsStore {
  LocaleSettingsStore._();
  static final LocaleSettingsStore instance = LocaleSettingsStore._();

  static const String _boxName = 'app_settings';
  static const String _languageCodeKey = 'language_code';

  /// Returns the persisted locale, or [deviceLocale] as a fallback.
  ///
  /// Falls back to English if neither is a supported language code.
  Future<Locale> load(Locale deviceLocale) async {
    final box = await Hive.openBox<String>(_boxName);
    final saved = box.get(_languageCodeKey);
    final code = saved ?? deviceLocale.languageCode;
    return Locale(supportedLanguageCodes.contains(code) ? code : 'en');
  }

  /// Persists [locale] so it is restored after an app restart.
  Future<void> save(Locale locale) async {
    final box = await Hive.openBox<String>(_boxName);
    await box.put(_languageCodeKey, locale.languageCode);
  }
}

// ── Controller ────────────────────────────────────────────────────────────

/// Holds the active [Locale] and notifies listeners when it changes.
///
/// Use [setLocale] to change and persist the locale.  Unsupported codes
/// are silently rejected so callers never need to guard against invalid input.
class LocaleController extends ValueNotifier<Locale> {
  LocaleController(super.initial);

  /// Changes the active locale, persists it to Hive, and notifies listeners.
  ///
  /// Does nothing if [locale] is not in [supportedLanguageCodes].
  Future<void> setLocale(Locale locale) async {
    if (!supportedLanguageCodes.contains(locale.languageCode)) return;
    value = locale;
    await LocaleSettingsStore.instance.save(locale);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────

/// Exposes [LocaleController] to the widget tree via [InheritedNotifier].
///
/// Because [InheritedNotifier] rebuilds dependents whenever
/// [LocaleController] notifies, any widget that calls [LocaleProvider.of]
/// is automatically rebuilt after a locale change.
class LocaleProvider extends InheritedNotifier<LocaleController> {
  const LocaleProvider({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Returns the [LocaleController] for [context] and registers it as a
  /// dependency, so the calling widget rebuilds on locale changes.
  static LocaleController of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<LocaleProvider>();
    assert(
      provider != null,
      'No LocaleProvider found in widget tree. '
      'Wrap your app with LocaleProvider.',
    );
    return provider!.notifier!;
  }
}
