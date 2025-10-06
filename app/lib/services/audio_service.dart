import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;

  /// Initialize the audio service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set audio context for better performance
      await _audioPlayer.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            // Removed all options that require playAndRecord category
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.notification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );
      _isInitialized = true;
    } catch (e) {
      // Handle initialization error silently
    }
  }

  /// Play notification sound
  Future<void> playNotificationSound() async {
    try {
      // Try to play custom notification sound first
      if (!_isInitialized) {
        await initialize();
      }

      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      // Fallback to SystemSound if custom sound fails
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (systemSoundError) {
        // Final fallback: try system sounds via audioplayers
        await _playSystemTone();
      }
    }
  }

  /// Play a simple system tone as fallback
  Future<void> _playSystemTone() async {
    try {
      // Try iOS system sounds first
      final iosSounds = [
        '/System/Library/Audio/UISounds/new-mail.caf',
        '/System/Library/Audio/UISounds/sms-received1.caf',
        '/System/Library/Audio/UISounds/sms-received2.caf',
        '/System/Library/Audio/UISounds/sms-received3.caf',
        '/System/Library/Audio/UISounds/sms-received4.caf',
        '/System/Library/Audio/UISounds/sms-received5.caf',
        '/System/Library/Audio/UISounds/sms-received6.caf',
      ];

      bool soundPlayed = false;
      for (final soundPath in iosSounds) {
        try {
          await _audioPlayer.play(DeviceFileSource(soundPath));
          soundPlayed = true;
          break;
        } catch (e) {
          // Try next sound
          continue;
        }
      }

      if (!soundPlayed) {
        // Try Android system sounds
        final androidSounds = [
          '/system/media/audio/ui/Effect_Tick.ogg',
          '/system/media/audio/ui/KeypressStandard.ogg',
          '/system/media/audio/ui/KeypressSpacebar.ogg',
        ];

        for (final soundPath in androidSounds) {
          try {
            await _audioPlayer.play(DeviceFileSource(soundPath));
            soundPlayed = true;
            break;
          } catch (e) {
            // Try next sound
            continue;
          }
        }
      }

      if (!soundPlayed && kDebugMode) {
        print('All system tones failed - notification will show without sound');
      }
    } catch (e) {
      if (kDebugMode) {
        print('System tone also failed: $e');
      }
      // If all else fails, just log the error - the notification will still show
    }
  }

  /// Play a simple beep sound as fallback
  Future<void> playBeepSound() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Create a simple beep sound programmatically
      // This is a fallback when no sound file is available
      await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
    } catch (e) {
      // Handle error silently
    }
  }

  /// Stop any currently playing sound
  Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      // Handle error silently
    }
  }

  /// Dispose resources
  void dispose() {
    _audioPlayer.dispose();
    _isInitialized = false;
  }
}
