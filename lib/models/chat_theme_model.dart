import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Chat Theme Model
// ─────────────────────────────────────────────────────────────────────────────

enum ChatWallpaper { none, bubbles, stars, waves, grid, hearts, travel, tread }

class ChatThemePreset {
  const ChatThemePreset({
    required this.id,
    required this.name,
    required this.emoji,
    required this.backgroundGradient,
    required this.myBubbleGradient,
    required this.myBubbleTextColor,
    required this.theirBubbleColor,
    required this.theirBubbleTextColor,
    required this.inputBarColor,
    required this.wallpaper,
    required this.accentColor,
    required this.previewColors,
  });

  final String id;
  final String name;
  final String emoji;

  // Background
  final Gradient backgroundGradient;

  // My bubble (sent)
  final Gradient myBubbleGradient;
  final Color myBubbleTextColor;

  // Their bubble (received)
  final Color theirBubbleColor;
  final Color theirBubbleTextColor;

  // Input dock
  final Color inputBarColor;

  // Wallpaper overlay pattern
  final ChatWallpaper wallpaper;

  // Accent (send button, borders, etc.)
  final Color accentColor;

  // Preview swatch colors shown in picker
  final List<Color> previewColors;
}

// ─────────────────────────────────────────────────────────────────────────────
// Built-in Presets
// ─────────────────────────────────────────────────────────────────────────────

final List<ChatThemePreset> kChatThemes = [
  // 1. AIVIVU (default)
  const ChatThemePreset(
    id: 'aivivu',
    name: 'AIVIVU',
    emoji: '✈️',
    backgroundGradient: RadialGradient(
      center: Alignment.topRight,
      radius: 1.5,
      colors: [Color(0xFF141927), Color(0xFF06070B)],
    ),
    myBubbleGradient: LinearGradient(
      colors: [Color(0xFFFF3366), Color(0xFF00E5FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    myBubbleTextColor: Colors.white,
    theirBubbleColor: Color(0x14FFFFFF),
    theirBubbleTextColor: Colors.white,
    inputBarColor: Color(0xFF10131A),
    wallpaper: ChatWallpaper.none,
    accentColor: Color(0xFF00E5FF),
    previewColors: [Color(0xFFFF3366), Color(0xFF00E5FF), Color(0xFF06070B)],
  ),

  // 2. Twilight Purple
  const ChatThemePreset(
    id: 'twilight',
    name: 'Twilight',
    emoji: '🌙',
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1A0533), Color(0xFF0D0820), Color(0xFF130B2E)],
    ),
    myBubbleGradient: LinearGradient(
      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    myBubbleTextColor: Colors.white,
    theirBubbleColor: Color(0x1AFFFFFF),
    theirBubbleTextColor: Colors.white,
    inputBarColor: Color(0xFF160D2E),
    wallpaper: ChatWallpaper.stars,
    accentColor: Color(0xFF8B5CF6),
    previewColors: [Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF1A0533)],
  ),

  // 3. Ocean Breeze
  const ChatThemePreset(
    id: 'ocean',
    name: 'Ocean',
    emoji: '🌊',
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0C2340), Color(0xFF0A3354), Color(0xFF0D1B2A)],
    ),
    myBubbleGradient: LinearGradient(
      colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    myBubbleTextColor: Colors.white,
    theirBubbleColor: Color(0x1A38BDF8),
    theirBubbleTextColor: Color(0xFFBAE6FD),
    inputBarColor: Color(0xFF0C2340),
    wallpaper: ChatWallpaper.waves,
    accentColor: Color(0xFF0EA5E9),
    previewColors: [Color(0xFF0EA5E9), Color(0xFF06B6D4), Color(0xFF0C2340)],
  ),

  // 4. Sakura (soft pink)
  const ChatThemePreset(
    id: 'sakura',
    name: 'Sakura',
    emoji: '🌸',
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF2D0A1A), Color(0xFF1A0812), Color(0xFF0F050A)],
    ),
    myBubbleGradient: LinearGradient(
      colors: [Color(0xFFF472B6), Color(0xFFFB7185)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    myBubbleTextColor: Colors.white,
    theirBubbleColor: Color(0x1AF9A8D4),
    theirBubbleTextColor: Color(0xFFFCE7F3),
    inputBarColor: Color(0xFF1A0812),
    wallpaper: ChatWallpaper.hearts,
    accentColor: Color(0xFFF472B6),
    previewColors: [Color(0xFFF472B6), Color(0xFFFB7185), Color(0xFF2D0A1A)],
  ),

  // 5. Forest (dark green)
  const ChatThemePreset(
    id: 'forest',
    name: 'Forest',
    emoji: '🌿',
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF062010), Color(0xFF0A2E1A), Color(0xFF051508)],
    ),
    myBubbleGradient: LinearGradient(
      colors: [Color(0xFF10B981), Color(0xFF34D399)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    myBubbleTextColor: Colors.white,
    theirBubbleColor: Color(0x1A6EE7B7),
    theirBubbleTextColor: Color(0xFFD1FAE5),
    inputBarColor: Color(0xFF062010),
    wallpaper: ChatWallpaper.bubbles,
    accentColor: Color(0xFF10B981),
    previewColors: [Color(0xFF10B981), Color(0xFF34D399), Color(0xFF062010)],
  ),

  // 6. Golden Hour (sunset)
  const ChatThemePreset(
    id: 'golden',
    name: 'Golden Hour',
    emoji: '🌅',
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1A0B00), Color(0xFF2D1500), Color(0xFF0F0800)],
    ),
    myBubbleGradient: LinearGradient(
      colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    myBubbleTextColor: Colors.white,
    theirBubbleColor: Color(0x1AFBBF24),
    theirBubbleTextColor: Color(0xFFFEF3C7),
    inputBarColor: Color(0xFF1A0B00),
    wallpaper: ChatWallpaper.travel,
    accentColor: Color(0xFFF59E0B),
    previewColors: [Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFF1A0B00)],
  ),

  // 7. Road Grip (tire tread)
  const ChatThemePreset(
    id: 'road_grip',
    name: 'Road Grip',
    emoji: '🛞',
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF111318), Color(0xFF252A32), Color(0xFF08090C)],
    ),
    myBubbleGradient: LinearGradient(
      colors: [Color(0xFFFF7A00), Color(0xFFFFB000)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    myBubbleTextColor: Color(0xFF17120A),
    theirBubbleColor: Color(0xFF2D333B),
    theirBubbleTextColor: Color(0xFFF4F4F5),
    inputBarColor: Color(0xFF171A20),
    wallpaper: ChatWallpaper.tread,
    accentColor: Color(0xFFFF8A00),
    previewColors: [Color(0xFFFF8A00), Color(0xFF2D333B), Color(0xFF08090C)],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Theme Persistence (Hive)
// ─────────────────────────────────────────────────────────────────────────────

class ChatThemeStore {
  static const _boxName = 'chat_theme';
  static const _keyPrefix = 'theme_';

  static Future<Box> _open() => Hive.openBox(_boxName);

  /// Save the selected theme ID for a given friendship.
  static Future<void> save(String friendshipId, String themeId) async {
    final box = await _open();
    await box.put('$_keyPrefix$friendshipId', themeId);
  }

  /// Load the saved theme ID for a friendship, returns null if not set.
  static Future<String?> load(String friendshipId) async {
    final box = await _open();
    return box.get('$_keyPrefix$friendshipId') as String?;
  }

  /// Resolve a theme preset by ID (falls back to default).
  static ChatThemePreset resolve(String? id) {
    if (id == null) return kChatThemes.first;
    return kChatThemes.firstWhere(
      (t) => t.id == id,
      orElse: () => kChatThemes.first,
    );
  }
}
