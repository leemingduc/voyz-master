import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyz/screens/auth_screen.dart';
import 'package:voyz/screens/destination_detail_screen.dart';
import 'package:voyz/screens/smart_planner_screen.dart';
import 'package:voyz/screens/splash_screen.dart';
import 'package:voyz/data/friend_message_notification_settings.dart';
import 'package:voyz/services/supabase_service.dart';
import 'package:voyz/services/friend_message_notification_service.dart';
import 'package:voyz/services/user_presence_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    this.showSplash = true,
    this.sharedDestinationName,
  });

  final bool showSplash;

  final String? sharedDestinationName;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late bool _splashComplete;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _splashComplete = !widget.showSplash;
    _authSubscription = SupabaseService.instance.auth.onAuthStateChange.listen(
      (_) => _syncFriendMessageNotifications(),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _syncFriendMessageNotifications(),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _syncFriendMessageNotifications() async {
    if (SupabaseService.instance.auth.currentSession == null) {
      FriendMessageNotificationSettings.instance.clearUser();
      await FriendMessageNotificationService.instance.stop();
      UserPresenceService.instance.stop();
      return;
    }
    final userId = SupabaseService.instance.auth.currentUser?.id;
    if (userId == null) return;
    await FriendMessageNotificationSettings.instance.loadForUser(userId);
    await FriendMessageNotificationService.instance.start();
    await UserPresenceService.instance.start();
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
        if (session == null) return const AuthScreen();
        final destinationName = widget.sharedDestinationName;
        return destinationName == null
            ? const SmartPlannerScreen()
            : DestinationDetailScreen(destinationName: destinationName);
      },
    );
  }
}
