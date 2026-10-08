import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voyz/data/locale_provider.dart';
import 'package:voyz/data/ai_model_settings.dart';
import 'package:voyz/data/currency_provider.dart';
import 'package:voyz/data/friend_message_notification_settings.dart';
import 'package:voyz/data/saved_trips_provider.dart';
import 'package:voyz/screens/auth_gate.dart';
import 'package:voyz/screens/friends_screen.dart';
import 'package:voyz/services/ai_cache_service.dart';
import 'package:voyz/services/background_music_service.dart';
import 'package:voyz/services/currency_service.dart';
import 'package:voyz/services/friend_message_notification_service.dart';
import 'package:voyz/services/search_history_service.dart';
import 'package:voyz/services/supabase_service.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/ai_tools_button.dart';
import 'package:voyz/widgets/shared/aivivu_page_background.dart';

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
    await AiCacheService.instance.init();
    await SearchHistoryService.instance.init();
    await ExchangeRateService.instance.init();
    initialDisplayCurrency = await CurrencySettingsStore.instance.load();
    await AiModelSettings.instance.load();
    await FriendMessageNotificationSettings.instance.load();
    // Don't block app startup on background music init.
    BackgroundMusicService.instance.init();
  } catch (e, st) {
    debugPrint('❌ Init error: $e\n$st');
  }

  // Resolve the initial locale before rendering.
  Locale initialLocale;
  try {
    initialLocale = await LocaleSettingsStore.instance.load();
  } catch (e, st) {
    debugPrint('❌ Locale load error: $e\n$st');
    initialLocale = const Locale('vi');
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
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  late final StreamSubscription<FriendMessageAlert> _friendMessageAlerts;

  @override
  void initState() {
    super.initState();
    _localeController = LocaleController(widget.initialLocale);
    _currencyController = CurrencyController(widget.initialDisplayCurrency);
    _friendMessageAlerts = FriendMessageNotificationService.instance.alerts
        .listen(_showFriendMessageAlert);
  }

  @override
  void dispose() {
    _localeController.dispose();
    _currencyController.dispose();
    _friendMessageAlerts.cancel();
    super.dispose();
  }

  void _showFriendMessageAlert(FriendMessageAlert alert) {
    final messenger = _scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    final friend = alert.friendship.friend;
    final name = friend.displayName.isEmpty ? friend.email : friend.displayName;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('$name: ${alert.message.body}'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Xem',
          onPressed: () {
            _navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => FriendChatScreen(friendship: alert.friendship),
              ),
            );
          },
        ),
      ),
    );
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
                scaffoldMessengerKey: _scaffoldMessengerKey,
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
                    : const Locale('vi'),
                home: const AuthGate(),
                builder: (context, child) {
                  return AivivuPageBackground(
                    padding: false,
                    constrainContent: false,
                    child: Stack(
                      children: [
                        child ?? const SizedBox.shrink(),
                        // AIToolsButton positions itself and can be dragged anywhere.
                        ValueListenableBuilder<bool>(
                          valueListenable: AIToolsButtonVisibility.isHidden,
                          builder: (context, isHidden, _) => isHidden
                              ? const SizedBox.shrink()
                              : AIToolsButton(navigatorKey: _navigatorKey),
                        ),
                      ],
                    ),
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
