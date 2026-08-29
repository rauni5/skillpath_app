import 'package:flutter/foundation.dart';

import '../../audio/sound_effects_service.dart';
import '../../../core/models/achievement.dart';
import '../../../core/models/streak.dart';
import '../../../core/network/api_exception.dart';
import '../data/gamification_repository.dart';

enum GamificationLoadState { initial, loading, loaded, error }

class GamificationProvider extends ChangeNotifier {
  GamificationProvider({GamificationRepository? repository})
    : _repo = repository ?? GamificationRepository();

  final GamificationRepository _repo;
  bool _hasLoadedOnce = false;

  GamificationLoadState state = GamificationLoadState.initial;
  List<Achievement> achievements = [];
  Streak? streak;
  String? errorMessage;

  List<Achievement> newlyUnlocked = [];

  int get unlockedCount => achievements.where((a) => a.unlocked).length;

  Future<void> load(int userId) async {
    state = GamificationLoadState.loading;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.getAchievements(userId),
        _repo.getStreak(userId),
      ]);
      final freshAchievements = results[0] as List<Achievement>;

      newlyUnlocked = _hasLoadedOnce
          ? _diffNewlyUnlocked(previous: achievements, fresh: freshAchievements)
          : [];

      if (newlyUnlocked.isNotEmpty) {
        SoundEffectsService.instance.play(SoundEffect.achievementUnlock);
      }

      achievements = freshAchievements;
      streak = results[1] as Streak;
      state = GamificationLoadState.loaded;
      _hasLoadedOnce = true;
    } catch (e) {
      errorMessage = e is ApiException
          ? e.message
          : 'Could not load your achievements.';
      state = GamificationLoadState.error;
    }
    notifyListeners();
  }

  List<Achievement> _diffNewlyUnlocked({
    required List<Achievement> previous,
    required List<Achievement> fresh,
  }) {
    final previouslyUnlockedCodes = previous
        .where((a) => a.unlocked)
        .map((a) => a.code)
        .toSet();
    return fresh
        .where((a) => a.unlocked && !previouslyUnlockedCodes.contains(a.code))
        .toList();
  }

  void clearNewlyUnlocked() {
    if (newlyUnlocked.isEmpty) return;
    newlyUnlocked = [];
    notifyListeners();
  }

  void reset() {
    state = GamificationLoadState.initial;
    achievements = [];
    streak = null;
    errorMessage = null;
    newlyUnlocked = [];
    _hasLoadedOnce = false;
    notifyListeners();
  }
}
