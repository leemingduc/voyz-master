import 'package:flutter/material.dart';
import 'package:voyz/services/background_music_service.dart';

/// A floating action button that toggles background music on/off.
/// Displays a music note icon with animated state indicator.
class BackgroundMusicButton extends StatefulWidget {
  const BackgroundMusicButton({super.key});

  @override
  State<BackgroundMusicButton> createState() => _BackgroundMusicButtonState();
}

class _BackgroundMusicButtonState extends State<BackgroundMusicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicService = BackgroundMusicService.instance;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _animController.forward(),
        onTapUp: (_) => _animController.reverse(),
        onTapCancel: () => _animController.reverse(),
        onTap: () {
          musicService.toggle();
          setState(() {}); // Trigger rebuild to update icon
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: musicService.isPlaying
                ? Colors.white.withOpacity(0.15)
                : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
          ),
          child: Icon(
            musicService.isPlaying
                ? Icons.music_note_rounded
                : Icons.music_off_rounded,
            color: musicService.isPlaying
                ? Colors.white
                : Colors.white.withOpacity(0.5),
            size: 20,
          ),
        ),
      ),
    );
  }
}
