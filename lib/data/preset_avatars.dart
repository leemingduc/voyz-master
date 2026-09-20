import 'package:flutter/material.dart';

class PresetAvatarItem {
  final String id;
  final String title;
  final String category;
  final String avatarUrl;
  final Color badgeColor;
  final IconData icon;

  const PresetAvatarItem({
    required this.id,
    required this.title,
    required this.category,
    required this.avatarUrl,
    required this.badgeColor,
    required this.icon,
  });
}

class PresetAvatarsData {
  static const List<PresetAvatarItem> presets = [
    PresetAvatarItem(
      id: 'explorer_sky',
      title: 'Explorer',
      category: 'Traveler',
      avatarUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=Explorer&backgroundColor=00bcd4',
      badgeColor: Color(0xFF00BCD4),
      icon: Icons.explore,
    ),
    PresetAvatarItem(
      id: 'nomad_sunset',
      title: 'Nomad',
      category: 'Traveler',
      avatarUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=Nomad&backgroundColor=ff9800',
      badgeColor: Color(0xFFFF9800),
      icon: Icons.flight_takeoff,
    ),
    PresetAvatarItem(
      id: 'hiker_forest',
      title: 'Hiker',
      category: 'Adventure',
      avatarUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=Hiker&backgroundColor=4caf50',
      badgeColor: Color(0xFF4CAF50),
      icon: Icons.hiking,
    ),
    PresetAvatarItem(
      id: 'cosmic_voyager',
      title: 'Cosmic Voyager',
      category: 'Cosmic',
      avatarUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=Voyager&backgroundColor=7c4dff',
      badgeColor: Color(0xFF7C4DFF),
      icon: Icons.auto_awesome,
    ),
    PresetAvatarItem(
      id: 'pilot_sky',
      title: 'Sky Pilot',
      category: 'Traveler',
      avatarUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Pilot&backgroundColor=2196f3',
      badgeColor: Color(0xFF2196F3),
      icon: Icons.connecting_airports,
    ),
    PresetAvatarItem(
      id: 'beach_wanderer',
      title: 'Beach Lover',
      category: 'Vacation',
      avatarUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=BeachLover&backgroundColor=e91e63',
      badgeColor: Color(0xFFE91E63),
      icon: Icons.beach_access,
    ),
    PresetAvatarItem(
      id: 'backpack_scout',
      title: 'Backpacker',
      category: 'Adventure',
      avatarUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Backpacker&backgroundColor=009688',
      badgeColor: Color(0xFF009688),
      icon: Icons.backpack,
    ),
    PresetAvatarItem(
      id: 'aivivu_bot',
      title: 'AI Companion',
      category: 'AI Assistant',
      avatarUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=AIVIVU&backgroundColor=673ab7',
      badgeColor: Color(0xFF673AB7),
      icon: Icons.smart_toy,
    ),
    PresetAvatarItem(
      id: 'urban_photographer',
      title: 'Photographer',
      category: 'Vacation',
      avatarUrl: 'https://api.dicebear.com/7.x/micah/png?seed=Photographer&backgroundColor=f44336',
      badgeColor: Color(0xFFF44336),
      icon: Icons.photo_camera,
    ),
  ];
}
