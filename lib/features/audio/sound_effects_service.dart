import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum SoundEffect { quizPass, quizFail, achievementUnlock }

const Map<SoundEffect, String> _assetPaths = {
  SoundEffect.quizPass: 'sounds/quiz_pass.mp3',
  SoundEffect.quizFail: 'sounds/quiz_fail.mp3',
  SoundEffect.achievementUnlock: 'sounds/achievement_unlock.mp3',
};
const Map<SoundEffect, int> _poolSizes = {
  SoundEffect.quizPass: 2,
  SoundEffect.quizFail: 2,
  SoundEffect.achievementUnlock: 2,
};

class SoundEffectsService {
  SoundEffectsService._internal();
  static final SoundEffectsService instance = SoundEffectsService._internal();

  final Map<SoundEffect, AudioPool> _pools = {};
  bool _enabled = true;
  bool _ready = false;
  final List<SoundEffect> _pending = [];

  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  Future<void> preload() async {
    if (_ready) return;

    final entries = await Future.wait(
      _assetPaths.entries.map((entry) async {
        try {
          final pool = await AudioPool.createFromAsset(
            path: entry.value,
            maxPlayers: _poolSizes[entry.key] ?? 2,
            playerMode: PlayerMode.lowLatency,
          );
          return MapEntry(entry.key, pool);
        } catch (e, stackTrace) {
          debugPrint(
            '[SoundEffectsService] Failed to preload ${entry.key.name}: $e\n$stackTrace',
          );
          return null;
        }
      }),
    );

    for (final entry in entries) {
      if (entry != null) _pools[entry.key] = entry.value;
    }
    _ready = true;

    final pending = List<SoundEffect>.from(_pending);
    _pending.clear();
    for (final effect in pending) {
      play(effect);
    }
  }

  void play(SoundEffect effect) {
    if (!_enabled) return;
    if (!_ready) {
      _pending.add(effect);
      return;
    }
    final pool = _pools[effect];
    if (pool == null) return;
    unawaited(_start(pool, effect));
  }

  Future<void> _start(AudioPool pool, SoundEffect effect) async {
    try {
      await pool.start();
    } catch (e, stackTrace) {
      debugPrint(
        '[SoundEffectsService] Failed to play ${effect.name}: $e\n$stackTrace',
      );
    }
  }

  Future<void> dispose() async {
    for (final pool in _pools.values) {
      await pool.dispose();
    }
    _pools.clear();
    _ready = false;
  }
}
