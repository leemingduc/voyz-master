import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service to manage background music playback throughout the app.
/// Music plays continuously on loop and persists across screen navigation.
class BackgroundMusicService {
  BackgroundMusicService._();
  static final BackgroundMusicService instance = BackgroundMusicService._();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isInitialized = false;
  double _volume = 0.3; // Default volume at 30%

  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);

  bool get isInitialized => _isInitialized;

  /// Initialize the music service and start playing background music.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Enable looping
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);

      // Set initial volume
      await _audioPlayer.setVolume(_volume);

      // Set the audio source from assets (with timeout to avoid blocking)
      await _audioPlayer
          .setSource(AssetSource('audio/background_music.mp3'))
          .timeout(const Duration(seconds: 5));

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error preparing background music source: $e');
      _isInitialized = true;
    }

    // Try starting playback (browsers on web may block autoplay until user interacts)
    await play();
  }

  /// Start or resume playing the background music.
  Future<void> play() async {
    try {
      if (!_isInitialized) {
        await init();
      }

      if (_audioPlayer.state == PlayerState.paused) {
        await _audioPlayer.resume();
      } else {
        await _audioPlayer.play(AssetSource('audio/background_music.mp3'));
      }

      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(_volume);

      _isPlaying = true;
      isPlayingNotifier.value = true;
    } catch (e) {
      debugPrint('Error playing background music: $e');
      _isPlaying = false;
      isPlayingNotifier.value = false;
    }
  }

  /// Pause the background music.
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      _isPlaying = false;
      isPlayingNotifier.value = false;
    } catch (e) {
      debugPrint('Error pausing background music: $e');
    }
  }

  /// Stop the background music completely.
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      isPlayingNotifier.value = false;
    } catch (e) {
      debugPrint('Error stopping background music: $e');
    }
  }

  /// Toggle play/pause state.
  Future<void> toggle() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Set the volume (0.0 to 1.0).
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    try {
      await _audioPlayer.setVolume(_volume);
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  /// Get current playing state.
  bool get isPlaying => _isPlaying;

  /// Get current volume.
  double get volume => _volume;

  /// Dispose the service and release resources.
  void dispose() {
    _audioPlayer.dispose();
    _isInitialized = false;
    _isPlaying = false;
    isPlayingNotifier.value = false;
  }
}

