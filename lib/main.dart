import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voyz/data/locale_provider.dart';
import 'package:voyz/data/ai_model_settings.dart';
import 'package:voyz/data/currency_provider.dart';
import 'package:voyz/data/saved_trips_provider.dart';
import 'package:voyz/screens/auth_gate.dart';
import 'package:voyz/screens/friends_screen.dart';
import 'package:voyz/screens/destination_detail_screen.dart';
import 'package:voyz/services/ai_cache_service.dart';
import 'package:voyz/services/background_music_service.dart';
import 'package:voyz/services/currency_service.dart';
import 'package:voyz/services/friend_message_notification_service.dart';
import 'package:voyz/services/search_history_service.dart';
import 'package:voyz/services/supabase_service.dart';
import 'package:voyz/utils/destination_share.dart';
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
      sharedDestinationName: Uri.base.queryParameters['destination'],
    ),
  );
}

class VoyzApp extends StatefulWidget {
  const VoyzApp({
    super.key,
    required this.initialLocale,
    required this.initialDisplayCurrency,
    this.sharedDestinationName,
  });

  final Locale initialLocale;
  final String initialDisplayCurrency;
  final String? sharedDestinationName;

  @override
  State<VoyzApp> createState() => _VoyzAppState();
}

class _VoyzAppState extends State<VoyzApp> {
  late final LocaleController _localeController;
  late final CurrencyController _currencyController;
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  late final StreamSubscription<FriendMessageAlert> _friendMessageAlerts;
  OverlayEntry? _friendMessageAlertEntry;
  Timer? _friendMessageAlertTimer;

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
    _friendMessageAlertTimer?.cancel();
    _friendMessageAlertEntry?.remove();
    super.dispose();
  }

  void _showFriendMessageAlert(FriendMessageAlert alert) {
    final overlay = _navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    final friend = alert.friendship.friend;
    final sharedDestinationName = destinationNameFromShareMessage(
      alert.message.body,
    );
    final name = friend.displayName.isEmpty ? friend.email : friend.displayName;
    _dismissFriendMessageAlert();

    final entry = OverlayEntry(
      builder: (context) => SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: InkWell(
                  onTap: () {
                    _dismissFriendMessageAlert();
                    if (sharedDestinationName != null) {
                      FriendMessageNotificationService.instance.markRead(
                        alert.friendship.id,
                      );
                      _navigatorKey.currentState?.push(
                        MaterialPageRoute(
                          builder: (_) => DestinationDetailScreen(
                            destinationName: sharedDestinationName,
                          ),
                        ),
                      );
                    } else {
                      _navigatorKey.currentState?.push(
                        MaterialPageRoute(
                          builder: (_) =>
                              FriendChatScreen(friendship: alert.friendship),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF172033),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF22D3EE).withValues(alpha: 0.7),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.mark_chat_unread_rounded,
                          color: Color(0xFF22D3EE),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                alert.message.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Xem',
                          style: TextStyle(
                            color: Color(0xFF22D3EE),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    _friendMessageAlertEntry = entry;
    overlay.insert(entry);
    _friendMessageAlertTimer = Timer(const Duration(seconds: 3), () {
      if (_friendMessageAlertEntry == entry) {
        _dismissFriendMessageAlert();
      }
    });
  }

  void _dismissFriendMessageAlert() {
    _friendMessageAlertTimer?.cancel();
    _friendMessageAlertTimer = null;
    _friendMessageAlertEntry?.remove();
    _friendMessageAlertEntry = null;
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
                home: AuthGate(
                  sharedDestinationName: widget.sharedDestinationName,
                ),
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
