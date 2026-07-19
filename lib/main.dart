import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voyz/data/locale_provider.dart';
import 'package:voyz/data/saved_trips_provider.dart';
import 'package:voyz/screens/auth_gate.dart';
import 'package:voyz/services/cache_service.dart';
import 'package:voyz/services/search_history_service.dart';
import 'package:voyz/services/supabase_service.dart';
import 'package:voyz/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await SupabaseService.instance.init();
  await Hive.initFlutter();
  await CacheService.instance.init();
  await SearchHistoryService.instance.init();

  // Resolve the initial locale before rendering.
  final initialLocale = await LocaleSettingsStore.instance.load(
    WidgetsBinding.instance.platformDispatcher.locale,
  );

  runApp(VoyzApp(initialLocale: initialLocale));
}

class VoyzApp extends StatefulWidget {
  const VoyzApp({super.key, required this.initialLocale});

  final Locale initialLocale;

  @override
  State<VoyzApp> createState() => _VoyzAppState();
}

class _VoyzAppState extends State<VoyzApp> {
  late final LocaleController _localeController;

  @override
  void initState() {
    super.initState();
    _localeController = LocaleController(widget.initialLocale);
  }

  @override
  void dispose() {
    _localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LocaleProvider(
      controller: _localeController,
      child: SavedTripsProvider(
        child: Builder(
          builder: (context) {
            // Reading LocaleProvider.of here ensures this Builder rebuilds
            // whenever the locale changes.
            final locale = LocaleProvider.of(context).value;
            return MaterialApp(
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
            );
          },
        ),
      ),
    );
  }
}
