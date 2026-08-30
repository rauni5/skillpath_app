import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum SoundEffect {
  quizPass,
  quizFail,
  achievementUnlock,
  buttonTap,
  buttonTap2,
}

const Map<SoundEffect, String> _assetPaths = {
  SoundEffect.quizPass: 'sounds/quiz_pass.mp3',
  SoundEffect.quizFail: 'sounds/quiz_fail.mp3',
  SoundEffect.achievementUnlock: 'sounds/achievement_unlock.mp3',
  SoundEffect.buttonTap: 'sounds/button_tap.wav',
  SoundEffect.buttonTap2: 'sounds/button_tap_2.wav',
};

class SoundEffectsService {
  SoundEffectsService._internal();
  static final SoundEffectsService instance = SoundEffectsService._internal();

  final Map<SoundEffect, AudioPlayer> _players = {};
  bool _enabled = true;
  bool _ready = false;

  void setEnabled(bool enabled) {
    _enabled = enabled;
    debugPrint('[SoundEffectsService] setEnabled($enabled)');
  }

  Future<void> preload() async {
    debugPrint('[SoundEffectsService] starting preload()...');
    if (_ready) {
      debugPrint('[SoundEffectsService] preload() skipped: already ready.');
      return;
    }

    for (final entry in _assetPaths.entries) {
      final effect = entry.key;
      final assetPath = entry.value;
      debugPrint(
        '[SoundEffectsService] Preloading effect: ${effect.name} -> path: "$assetPath"',
      );

      try {
        final player = AudioPlayer(playerId: 'sfx_${effect.name}');

        debugPrint(
          '[SoundEffectsService] Setting ReleaseMode.stop for ${effect.name}',
        );
        await player.setReleaseMode(ReleaseMode.stop);

        debugPrint(
          '[SoundEffectsService] Calling setSource(AssetSource("$assetPath")) for ${effect.name}...',
        );
        await player.setSource(AssetSource(assetPath));

        _players[effect] = player;
        debugPrint('[SoundEffectsService] SUCCESS: Preloaded ${effect.name}');
      } catch (e, stackTrace) {
        debugPrint(
          '[SoundEffectsService] ERROR: Failed to preload ${effect.name} ("$assetPath")',
        );
        debugPrint('[SoundEffectsService] Exception: $e');
        debugPrint('[SoundEffectsService] StackTrace: $stackTrace');
      }
    }

    _ready = true;
    debugPrint(
      '[SoundEffectsService] preload() completed. Total ready players: ${_players.length}/${_assetPaths.length}',
    );
  }

  void play(SoundEffect effect) {
    debugPrint('[SoundEffectsService] play() requested for: ${effect.name}');

    if (!_enabled) {
      debugPrint('[SoundEffectsService] play() skipped: service is disabled.');
      return;
    }

    final player = _players[effect];

    if (player == null) {
      debugPrint(
        '[SoundEffectsService] WARNING: No preloaded player found for ${effect.name}. Attempting fallback execution...',
      );

      final assetPath = _assetPaths[effect];
      if (assetPath == null) {
        debugPrint(
          '[SoundEffectsService] ERROR: No asset path defined for ${effect.name}',
        );
        return;
      }

      final fallbackPlayer = AudioPlayer();
      debugPrint(
        '[SoundEffectsService] Fallback player created. Triggering play(AssetSource("$assetPath"))...',
      );

      fallbackPlayer
          .play(AssetSource(assetPath))
          .then((_) {
            debugPrint(
              '[SoundEffectsService] Fallback play() succeeded for ${effect.name}',
            );
          })
          .catchError((e, stackTrace) {
            debugPrint(
              '[SoundEffectsService] ERROR: Fallback play() failed for ${effect.name}',
            );
            debugPrint('[SoundEffectsService] Exception: $e');
            debugPrint('[SoundEffectsService] StackTrace: $stackTrace');
          });
      return;
    }

    debugPrint(
      '[SoundEffectsService] Preloaded player found for ${effect.name}. Stopping current playback...',
    );

    player
        .stop()
        .then((_) {
          debugPrint(
            '[SoundEffectsService] Stopping complete for ${effect.name}. Re-playing asset...',
          );
          final assetPath = _assetPaths[effect]!;
          return player.play(AssetSource(assetPath));
        })
        .then((_) {
          debugPrint(
            '[SoundEffectsService] SUCCESS: Playback started for ${effect.name}',
          );
        })
        .catchError((e, stackTrace) {
          debugPrint(
            '[SoundEffectsService] ERROR: Failed to play preloaded sound for ${effect.name}',
          );
          debugPrint('[SoundEffectsService] Exception: $e');
          debugPrint('[SoundEffectsService] StackTrace: $stackTrace');
        });
  }

  Future<void> dispose() async {
    debugPrint('[SoundEffectsService] Disposing all audio players...');
    for (final entry in _players.entries) {
      debugPrint(
        '[SoundEffectsService] Disposing player for ${entry.key.name}',
      );
      await entry.value.dispose();
    }
    _players.clear();
    _ready = false;
    debugPrint('[SoundEffectsService] Service disposed cleanly.');
  }
}
