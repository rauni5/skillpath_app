import 'package:flutter/foundation.dart';

import '../../../core/models/roadmap_step.dart';
import '../../../core/network/api_exception.dart';
import '../data/roadmap_repository.dart';

enum RoadmapLoadState { initial, loading, loaded, error }

class RoadmapProvider extends ChangeNotifier {
  RoadmapProvider({RoadmapRepository? repository})
    : _repo = repository ?? RoadmapRepository();

  final RoadmapRepository _repo;

  RoadmapLoadState state = RoadmapLoadState.initial;
  List<RoadmapStep> steps = [];
  String? errorMessage;

  /// True if [steps] came from the on-device cache rather than a live
  /// request.
  bool isShowingCachedData = false;
  DateTime? cachedAt;

  Future<void> load(int userId) async {
    state = RoadmapLoadState.loading;
    notifyListeners();
    try {
      final result = await _repo.getRoadmap(userId);
      steps = result.data;
      isShowingCachedData = result.fromCache;
      cachedAt = result.cachedAt;
      state = RoadmapLoadState.loaded;
    } catch (e) {
      errorMessage = e is ApiException
          ? e.message
          : 'Could not load your roadmap.';
      state = RoadmapLoadState.error;
    }
    notifyListeners();
  }

  void reset() {
    state = RoadmapLoadState.initial;
    steps = [];
    errorMessage = null;
    isShowingCachedData = false;
    cachedAt = null;
    notifyListeners();
  }
}
