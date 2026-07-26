import 'package:flutter/foundation.dart';

import '../../../core/models/career_role.dart';
import '../../../core/models/gap_analysis.dart';
import '../../../core/network/api_exception.dart';
import '../data/career_repository.dart';

enum CareerLoadState { initial, loading, loaded, error }

class CareerProvider extends ChangeNotifier {
  CareerProvider({CareerRepository? repository}) : _repo = repository ?? CareerRepository();

  final CareerRepository _repo;

  CareerLoadState rolesState = CareerLoadState.initial;
  CareerLoadState gapState = CareerLoadState.initial;
  String? errorMessage;
  bool isSubmitting = false;

  List<CareerRole> roles = [];
  GapAnalysis gap = GapAnalysis.empty();

  Future<void> loadRoles() async {
    rolesState = CareerLoadState.loading;
    notifyListeners();
    try {
      roles = await _repo.getCareerRoles();
      rolesState = CareerLoadState.loaded;
    } catch (e) {
      errorMessage = e is ApiException ? e.message : 'Could not load career roles.';
      rolesState = CareerLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadGap(int userId) async {
    gapState = CareerLoadState.loading;
    notifyListeners();
    try {
      gap = await _repo.getGapAnalysis(userId);
      gapState = CareerLoadState.loaded;
    } catch (e) {
      errorMessage = e is ApiException ? e.message : 'Could not load your gap analysis.';
      gapState = CareerLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadAll(int userId) async {
    await Future.wait([loadRoles(), loadGap(userId)]);
  }

  Future<bool> setGoal(int userId, int roleId) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repo.setCareerGoal(userId, roleId);
      gap = await _repo.getGapAnalysis(userId);
      return true;
    } catch (e) {
      errorMessage = e is ApiException ? e.message : 'Could not set your career goal.';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
