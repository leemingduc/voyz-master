import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voyz/data/locale_provider.dart';
import 'package:voyz/data/currency_provider.dart';
import 'package:voyz/data/saved_trips_provider.dart';
import 'package:voyz/screens/auth_gate.dart';
import 'package:voyz/services/ai_cache_service.dart';
import 'package:voyz/services/background_music_service.dart';
import 'package:voyz/services/cache_service.dart';
import 'package:voyz/services/currency_service.dart';
import 'package:voyz/services/search_history_service.dart';
import 'package:voyz/services/supabase_service.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/ai_tools_button.dart';
import 'package:voyz/widgets/shared/background_music_button.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e, st) {
    debugPrint('Environment init error: $e\n$st');
  }

  try {
    await SupabaseService.instance.init();
  } catch (e, st) {
    debugPrint('Supabase init error: $e\n$st');
  }

  String initialDisplayCurrency = 'VND';
  try {
    await Hive.initFlutter();
    await CacheService.instance.init();
    await AiCacheService.instance.init();
    await SearchHistoryService.instance.init();
    await ExchangeRateService.instance.init();
    initialDisplayCurrency = await CurrencySettingsStore.instance.load();
    // Don't block app startup on background music init.
    BackgroundMusicService.instance.init();
  } catch (e, st) {
    debugPrint('❌ Init error: $e\n$st');
  }

  // Resolve the initial locale before rendering.
  Locale initialLocale;
  try {
    initialLocale = await LocaleSettingsStore.instance.load(
      WidgetsBinding.instance.platformDispatcher.locale,
    );
  } catch (e, st) {
    debugPrint('❌ Locale load error: $e\n$st');
    initialLocale = const Locale('en');
  }

  runApp(
    VoyzApp(
      initialLocale: initialLocale,
      initialDisplayCurrency: initialDisplayCurrency,
    ),
  );
}

class VoyzApp extends StatefulWidget {
  const VoyzApp({
    super.key,
    required this.initialLocale,
    required this.initialDisplayCurrency,
  });

  final Locale initialLocale;
  final String initialDisplayCurrency;

  @override
  State<VoyzApp> createState() => _VoyzAppState();
}

class _VoyzAppState extends State<VoyzApp> {
  late final LocaleController _localeController;
  late final CurrencyController _currencyController;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _localeController = LocaleController(widget.initialLocale);
    _currencyController = CurrencyController(widget.initialDisplayCurrency);
  }

  @override
  void dispose() {
    _localeController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CurrencyProvider(
      controller: _currencyController,
      child: LocaleProvider(
        controller: _localeController,
        child: SavedTripsProvider(
          child: Builder(
            builder: (context) {
              // Reading LocaleProvider.of here ensures this Builder rebuilds
              // whenever the locale changes.
              final locale = LocaleProvider.of(context).value;
              return MaterialApp(
                navigatorKey: _navigatorKey,
                onGenerateTitle: (ctx) =>
                    AppLocalizations.of(ctx)?.appTitle ??
                    'AIVIVU - AI Travel Advisor',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme(),
                darkTheme: AppTheme.darkTheme(),
                themeMode: ThemeMode.dark,
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                localeResolutionCallback: (deviceLocale, supported) =>
                    supported.any(
                      (s) => s.languageCode == deviceLocale?.languageCode,
                    )
                    ? deviceLocale
                    : const Locale('en'),
                home: const AuthGate(),
                builder: (context, child) {
                  return Stack(
                    children: [
                      child ?? const SizedBox.shrink(),
                      // Persistent background music toggle button
                      Positioned(
                        left: 12,
                        bottom: MediaQuery.of(context).padding.bottom + 92,
                        child: const BackgroundMusicButton(),
                      ),
                      Positioned(
                        right: 16,
                        // Keeps this shortcut above the bottom navigation.
                        bottom: MediaQuery.of(context).padding.bottom + 92,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: AIToolsButtonVisibility.isHidden,
                          builder: (context, isHidden, _) => isHidden
                              ? const SizedBox.shrink()
                              : AIToolsButton(navigatorKey: _navigatorKey),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
