import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  runApp(const VoyzApp());
}

class VoyzApp extends StatelessWidget {
  const VoyzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SavedTripsProvider(
      child: MaterialApp(
        title: 'AIVIVU - AI Travel Advisor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.dark,
        home: const AuthGate(),
      ),
    );
  }
}
