import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:voyz/services/friends_service.dart';
import 'package:voyz/services/supabase_service.dart';

/// Manages user active presence, periodic heartbeat, and app lifecycle tracking.
class UserPresenceService with WidgetsBindingObserver {
  UserPresenceService._();

  static final UserPresenceService instance = UserPresenceService._();

  Timer? _heartbeatTimer;
  Timer? _tickerTimer;
  bool _isInitialized = false;
  bool _isTracking = false;

  /// Ticker notifier that increments every 30 seconds to trigger UI relative
  /// time re-computations (e.g. "Hoạt động 5 phút trước").
  final ValueNotifier<DateTime> currentTick = ValueNotifier<DateTime>(DateTime.now());

  void init() {
    if (_isInitialized) return;
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
    _startTicker();
  }

  void _startTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      currentTick.value = DateTime.now();
    });
  }

  /// Starts presence tracking and periodic heartbeat for the signed-in user.
  Future<void> start() async {
    init();
    final user = SupabaseService.instance.auth.currentUser;
    if (user == null) {
      stop();
      return;
    }

    _isTracking = true;
    await _sendHeartbeat();
    _startHeartbeatTimer();
  }

  /// Stops heartbeat when user signs out.
  void stop() {
    _isTracking = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _startHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (_isTracking) {
        _sendHeartbeat();
      }
    });
  }

  Future<void> _sendHeartbeat() async {
    try {
      if (SupabaseService.instance.auth.currentUser == null) return;
      await FriendsService.instance.updateLastActive();
    } catch (e) {
      debugPrint('User presence heartbeat error (non-fatal): $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isTracking) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _sendHeartbeat();
        _startHeartbeatTimer();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _heartbeatTimer?.cancel();
        // Record immediate departure timestamp
        _sendHeartbeat();
        break;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    _tickerTimer?.cancel();
    _isInitialized = false;
    _isTracking = false;
  }
}
