import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

const presetAvatarIds = <String>[
  'explorer',
  'beach',
  'mountain',
  'camera',
  'food',
  'plane',
  'city',
  'sun',
  'art',
  'music',
  'sport',
  'coffee',
];

/// Human-readable label for each preset avatar.
const presetAvatarLabels = <String, String>{
  'explorer': 'Explorer',
  'beach': 'Beach',
  'mountain': 'Mountain',
  'camera': 'Camera',
  'food': 'Food',
  'plane': 'Plane',
  'city': 'City',
  'sun': 'Sun',
  'art': 'Art',
  'music': 'Music',
  'sport': 'Sport',
  'coffee': 'Coffee',
};

bool isPresetAvatar(String? value) =>
    value != null && value.startsWith('preset:');

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.avatarUrl,
    required this.radius,
  });

  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final value = avatarUrl;
    if (isPresetAvatar(value)) {
      return _PresetAvatar(
        id: value!.substring('preset:'.length),
        radius: radius,
      );
    }

    if (value == null || value.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF24304A),
        child: Icon(Icons.person, color: Colors.white, size: radius),
      );
    }

    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: value,
          fit: BoxFit.cover,
          placeholder: (_, _) => const ColoredBox(color: Color(0xFF24304A)),
          errorWidget: (_, _, _) => ColoredBox(
            color: const Color(0xFF24304A),
            child: Icon(Icons.person, color: Colors.white, size: radius),
          ),
        ),
      ),
    );
  }
}

class _PresetAvatar extends StatelessWidget {
  const _PresetAvatar({required this.id, required this.radius});

  final String id;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (id) {
      'beach' => (Icons.beach_access_rounded, const Color(0xFF0EA5E9)),
      'mountain' => (Icons.terrain_rounded, const Color(0xFF16A34A)),
      'camera' => (Icons.camera_alt_rounded, const Color(0xFFA855F7)),
      'food' => (Icons.restaurant_rounded, const Color(0xFFF97316)),
      'plane' => (Icons.flight_rounded, const Color(0xFF2563EB)),
      'city' => (Icons.location_city_rounded, const Color(0xFF64748B)),
      'sun' => (Icons.wb_sunny_rounded, const Color(0xFFF59E0B)),
      'art' => (Icons.palette_rounded, const Color(0xFFE879F9)),
      'music' => (Icons.music_note_rounded, const Color(0xFF14B8A6)),
      'sport' => (Icons.sports_soccer_rounded, const Color(0xFF22C55E)),
      'coffee' => (Icons.coffee_rounded, const Color(0xFF92400E)),
      _ => (Icons.explore_rounded, const Color(0xFFEC4899)),
    };

    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Icon(icon, color: Colors.white, size: radius * 0.9),
    );
  }
}
