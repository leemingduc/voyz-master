import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Stores whether in-app alerts for incoming friend messages are visible.
///
/// Unread messages are still tracked while alerts are disabled, so turning the
/// setting back on does not lose any messages received in the meantime.
class FriendMessageNotificationSettings {
  FriendMessageNotificationSettings._();

  static final FriendMessageNotificationSettings instance =
      FriendMessageNotificationSettings._();

  static const _boxName = 'friend_message_notification_settings';
  static const _enabledKey = 'enabled';

  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  Future<void> load() async {
    final box = await Hive.openBox<bool>(_boxName);
    enabled.value = box.get(_enabledKey, defaultValue: true) ?? true;
  }

  Future<void> save(bool value) async {
    enabled.value = value;
    final box = await Hive.openBox<bool>(_boxName);
    await box.put(_enabledKey, value);
  }
}
