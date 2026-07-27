import 'package:flutter/foundation.dart';

import '../../../core/models/roadmap_step.dart';
import '../../../core/network/api_exception.dart';
import '../data/roadmap_repository.dart';

enum RoadmapLoadState { initial, loading, loaded, error }

class RoadmapProvider extends ChangeNotifier {
  RoadmapProvider({RoadmapRepository? repository}) : _repo = repository ?? RoadmapRepository();

  final RoadmapRepository _repo;

  RoadmapLoadState state = RoadmapLoadState.initial;
  List<RoadmapStep> steps = [];
  String? errorMessage;

  /// Step ids currently being marked done, so the UI can show a small
  /// per-row spinner instead of blocking the whole screen.
  final Set<int> pendingStepIds = {};

  Future<void> load(int userId) async {
    state = RoadmapLoadState.loading;
    notifyListeners();
    try {
      steps = await _repo.getRoadmap(userId);
      state = RoadmapLoadState.loaded;
    } catch (e) {
      errorMessage = e is ApiException ? e.message : 'Could not load your roadmap.';
      state = RoadmapLoadState.error;
    }
    notifyListeners();
  }

  Future<void> markDone(int userId, int stepId) async {
    pendingStepIds.add(stepId);
    notifyListeners();
    try {
      final updated = await _repo.markDone(userId, stepId);
      steps = [
        for (final s in steps) if (s.id == updated.id) updated else s,
      ];
    } catch (_) {
      // Silently ignore — the row simply won't flip to done, user can retry.
    } finally {
      pendingStepIds.remove(stepId);
      notifyListeners();
    }
  }
}
