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

  /// Error for the role-list load specifically. Kept separate from
  /// [gapErrorMessage] because loadRoles() and loadGap() run concurrently
  /// in [loadAll] — sharing one field meant whichever finished last silently
  /// overwrote the other's message, and neither cleared it on success.
  String? rolesErrorMessage;
  String? gapErrorMessage;

  /// Error for setGoal()/switchBranch()/loadBranchesForRole() — these run
  /// one at a time (never concurrently with each other or with the loads
  /// above), so a single shared field is safe here.
  String? errorMessage;
  bool isSubmitting = false;

  List<CareerRole> roles = [];
  GapAnalysis gap = GapAnalysis.empty();

  bool isRolesShowingCachedData = false;
  DateTime? rolesCachedAt;
  bool isGapShowingCachedData = false;
  DateTime? gapCachedAt;
  bool hasLoadedOnce = false;

  bool get isShowingCachedData =>
      isRolesShowingCachedData || isGapShowingCachedData;
  DateTime? get cachedAt => rolesCachedAt ?? gapCachedAt;

  // --- Specializations (branches) for whichever role is being picked/viewed ---
  CareerLoadState branchesState = CareerLoadState.initial;
  List<RoleBranch> branches = [];
  List<BranchRecommendation> branchRecommendations = [];

  Future<void> loadRoles() async {
    rolesState = CareerLoadState.loading;
    notifyListeners();
    try {
      final result = await _repo.getCareerRoles();
      roles = result.data;
      isRolesShowingCachedData = result.fromCache;
      rolesCachedAt = result.cachedAt;
      rolesErrorMessage = null;
      rolesState = CareerLoadState.loaded;
    } catch (e) {
      rolesErrorMessage = e is ApiException
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
      final result = await _repo.getGapAnalysis(userId);
      gap = result.data;
      isGapShowingCachedData = result.fromCache;
      gapCachedAt = result.cachedAt;
      gapErrorMessage = null;
      gapState = CareerLoadState.loaded;
    } catch (e) {
      gapErrorMessage = e is ApiException
          ? e.message
          : 'Could not load your gap analysis.';
      gapState = CareerLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadAll(int userId) async {
    await Future.wait([loadRoles(), loadGap(userId)]);
    hasLoadedOnce = true;
    notifyListeners();
  }

  /// Loads a role's specializations and, if the user has any current skills,
  /// ranks them by match score in the same call. Call before showing the
  /// specialization-picker step for a role (skip entirely if it ends up
  /// empty — that role just doesn't have any).
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
          : 'Could not load specializations for this role.';
      branchesState = CareerLoadState.error;
    }
    notifyListeners();
  }

  /// Convenience: match score for a specialization, or null if not yet loaded/ranked.
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
      final result = await _repo.getGapAnalysis(userId);
      gap = result.data;
      isGapShowingCachedData = result.fromCache;
      gapCachedAt = result.cachedAt;
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

  /// Changes specialization without changing role — for an already-set career goal.
  Future<bool> switchBranch(int userId, int branchId) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repo.switchBranch(userId, branchId);
      final result = await _repo.getGapAnalysis(userId);
      gap = result.data;
      isGapShowingCachedData = result.fromCache;
      gapCachedAt = result.cachedAt;
      return true;
    } catch (e) {
      errorMessage = e is ApiException
          ? e.message
          : 'Could not switch specialization.';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void reset() {
    rolesState = CareerLoadState.initial;
    gapState = CareerLoadState.initial;
    rolesErrorMessage = null;
    gapErrorMessage = null;
    errorMessage = null;
    isSubmitting = false;
    roles = [];
    gap = GapAnalysis.empty();
    isRolesShowingCachedData = false;
    rolesCachedAt = null;
    isGapShowingCachedData = false;
    gapCachedAt = null;
    hasLoadedOnce = false;
    branchesState = CareerLoadState.initial;
    branches = [];
    branchRecommendations = [];
    notifyListeners();
  }
}
