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
}
