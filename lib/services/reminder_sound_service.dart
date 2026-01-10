import 'package:audioplayers/audioplayers.dart';

/// Service for playing reminder notification sounds.
class ReminderSoundService {
  static final AudioPlayer _player = AudioPlayer();

  /// Available sound options.
  static const List<String> availableSounds = ['chime', 'bell', 'alert', 'soft'];

  /// Human-readable labels for sound options.
  static const Map<String, String> soundLabels = {
    'chime': 'Chime',
    'bell': 'Bell',
    'alert': 'Alert',
    'soft': 'Soft',
  };

  /// Play the specified reminder sound.
  static Future<void> play(String soundName) async {
    final validSound = availableSounds.contains(soundName) ? soundName : 'chime';
    await _player.play(AssetSource('sounds/$validSound.mp3'));
  }

  /// Stop any currently playing sound.
  static Future<void> stop() async {
    await _player.stop();
  }

  /// Get the human-readable label for a sound.
  static String getLabel(String soundName) {
    return soundLabels[soundName] ?? 'Chime';
  }
}
