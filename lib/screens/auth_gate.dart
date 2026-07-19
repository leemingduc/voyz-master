import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyz/screens/auth_screen.dart';
import 'package:voyz/screens/smart_planner_screen.dart';
import 'package:voyz/screens/splash_screen.dart';
import 'package:voyz/services/supabase_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.showSplash = true});

  final bool showSplash;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late bool _splashComplete;

  @override
  void initState() {
    super.initState();
    _splashComplete = !widget.showSplash;
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashComplete) {
      return SplashScreen(
        onFinished: () {
          if (mounted) setState(() => _splashComplete = true);
        },
      );
    }

    return StreamBuilder<AuthState>(
      stream: SupabaseService.instance.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = SupabaseService.instance.auth.currentSession;
        return session == null ? const AuthScreen() : const SmartPlannerScreen();
      },
    );
  }
}
