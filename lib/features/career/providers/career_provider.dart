import 'package:flutter/foundation.dart';

import '../../../core/models/branch_recommendation.dart';
import '../../../core/models/career_role.dart';
import '../../../core/models/gap_analysis.dart';
import '../../../core/models/role_branch.dart';
import '../../../core/network/api_exception.dart';
import '../data/career_repository.dart';

enum CareerLoadState { initial, loading, loaded, error }

class CareerProvider extends ChangeNotifier {
  CareerProvider({CareerRepository? repository})
    : _repo = repository ?? CareerRepository();

  final CareerRepository _repo;

  CareerLoadState rolesState = CareerLoadState.initial;
  CareerLoadState gapState = CareerLoadState.initial;
  String? errorMessage;
  bool isSubmitting = false;

  List<CareerRole> roles = [];
  GapAnalysis gap = GapAnalysis.empty();

  // --- Branches for whichever role is currently being picked/viewed ---
  CareerLoadState branchesState = CareerLoadState.initial;
  List<RoleBranch> branches = [];
  List<BranchRecommendation> branchRecommendations = [];

  Future<void> loadRoles() async {
    rolesState = CareerLoadState.loading;
    notifyListeners();
    try {
      roles = await _repo.getCareerRoles();
      rolesState = CareerLoadState.loaded;
    } catch (e) {
      errorMessage = e is ApiException
          ? e.message
          : 'Could not load career roles.';
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
      errorMessage = e is ApiException
          ? e.message
          : 'Could not load your gap analysis.';
      gapState = CareerLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadAll(int userId) async {
    await Future.wait([loadRoles(), loadGap(userId)]);
  }

  /// Loads a role's branches and, if the user has any current skills, ranks
  /// them by match score in the same call. Call this before showing the
  /// branch-picker step for a role (skip entirely if branches ends up empty
  /// — that role just doesn't have any).
  Future<void> loadBranchesForRole(int userId, int roleId) async {
    branchesState = CareerLoadState.loading;
    branches = [];
    branchRecommendations = [];
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.getBranches(roleId),
        _repo.getBranchRecommendations(userId, roleId),
      ]);
      branches = results[0] as List<RoleBranch>;
      branchRecommendations = results[1] as List<BranchRecommendation>;
      branchesState = CareerLoadState.loaded;
    } catch (e) {
      errorMessage = e is ApiException
          ? e.message
          : 'Could not load branches for this role.';
      branchesState = CareerLoadState.error;
    }
    notifyListeners();
  }

  /// Convenience: match score for a branch, or null if not yet loaded/ranked.
  double? scoreForBranch(int branchId) {
    for (final r in branchRecommendations) {
      if (r.branchId == branchId) return r.matchScore;
    }
    return null;
  }

  Future<bool> setGoal(int userId, int roleId, {int? branchId}) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repo.setCareerGoal(userId, roleId, branchId: branchId);
      gap = await _repo.getGapAnalysis(userId);
      return true;
    } catch (e) {
      errorMessage = e is ApiException
          ? e.message
          : 'Could not set your career goal.';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  /// Changes branch without changing role — for an already-set career goal.
  Future<bool> switchBranch(int userId, int branchId) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repo.switchBranch(userId, branchId);
      gap = await _repo.getGapAnalysis(userId);
      return true;
    } catch (e) {
      errorMessage = e is ApiException ? e.message : 'Could not switch branch.';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
