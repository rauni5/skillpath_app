import 'package:flutter/foundation.dart';

import '../../../core/models/achievement.dart';
import '../../../core/models/streak.dart';
import '../../../core/network/api_exception.dart';
import '../data/gamification_repository.dart';

enum GamificationLoadState { initial, loading, loaded, error }

class GamificationProvider extends ChangeNotifier {
  GamificationProvider({GamificationRepository? repository})
    : _repo = repository ?? GamificationRepository();

  final GamificationRepository _repo;

  GamificationLoadState state = GamificationLoadState.initial;
  List<Achievement> achievements = [];
  Streak? streak;
  String? errorMessage;

  int get unlockedCount => achievements.where((a) => a.unlocked).length;

  Future<void> load(int userId) async {
    state = GamificationLoadState.loading;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.getAchievements(userId),
        _repo.getStreak(userId),
      ]);
      achievements = results[0] as List<Achievement>;
      streak = results[1] as Streak;
      state = GamificationLoadState.loaded;
    } catch (e) {
      errorMessage = e is ApiException
          ? e.message
          : 'Could not load your achievements.';
      state = GamificationLoadState.error;
    }
    notifyListeners();
  }
}
