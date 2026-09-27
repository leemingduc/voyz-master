import 'package:flutter/material.dart';
import 'package:voyz/services/background_music_service.dart';

/// A switch that toggles background music on and off.
class BackgroundMusicButton extends StatefulWidget {
  const BackgroundMusicButton({super.key});

  @override
  State<BackgroundMusicButton> createState() => _BackgroundMusicButtonState();
}

class _BackgroundMusicButtonState extends State<BackgroundMusicButton> {
  @override
  Widget build(BuildContext context) {
    final musicService = BackgroundMusicService.instance;

    return Switch(
      value: musicService.isPlaying,
      activeThumbColor: Colors.white,
      activeTrackColor: const Color(0xFF06B6D4),
      inactiveThumbColor: Colors.white70,
      inactiveTrackColor: Colors.white24,
      onChanged: (_) async {
        await musicService.toggle();
        if (mounted) setState(() {});
      },
    );
  }
}
