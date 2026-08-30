import 'package:flutter/foundation.dart';

import '../../../core/models/admin_achievement.dart';
import '../../../core/network/api_exception.dart';
import '../data/admin_repository.dart';

enum AdminAchievementsLoadState { initial, loading, loaded, error }

enum AdminAchievementDetailLoadState { initial, loading, loaded, error }

class AdminAchievementsProvider extends ChangeNotifier {
  AdminAchievementsProvider({AdminRepository? repository})
    : _repo = repository ?? AdminRepository();

  final AdminRepository _repo;

  // --- Catalog list ---
  AdminAchievementsLoadState listState = AdminAchievementsLoadState.initial;
  String? listError;
  List<AdminAchievement> catalog = [];

  Future<void> loadCatalog() async {
    listState = AdminAchievementsLoadState.loading;
    notifyListeners();
    try {
      catalog = await _repo.getAchievements();
      listState = AdminAchievementsLoadState.loaded;
    } catch (e) {
      listError = e is ApiException
          ? e.message
          : 'Could not load achievements.';
      listState = AdminAchievementsLoadState.error;
    }
    notifyListeners();
  }

  bool isCreating = false;
  String? createError;

  Future<AdminAchievement?> createAchievement({
    required String code,
    required String title,
    required String description,
    required String icon,
    required String category,
    required AchievementCriteriaType criteriaType,
    required int criteriaValue,
  }) async {
    isCreating = true;
    createError = null;
    notifyListeners();
    try {
      final created = await _repo.createAchievement(
        code: code,
        title: title,
        description: description,
        icon: icon,
        category: category,
        criteriaType: criteriaType,
        criteriaValue: criteriaValue,
      );
      catalog = [...catalog, created];
      return created;
    } catch (e) {
      createError = e is ApiException
          ? e.message
          : 'Could not create that achievement.';
      return null;
    } finally {
      isCreating = false;
      notifyListeners();
    }
  }

  // --- Single achievement detail (edit) ---
  AdminAchievementDetailLoadState detailState =
      AdminAchievementDetailLoadState.initial;
  String? detailError;
  AdminAchievement? selected;
  bool isSaving = false;
  bool isDeleting = false;

  Future<void> loadDetail(int id) async {
    detailState = AdminAchievementDetailLoadState.loading;
    detailError = null;
    selected = null;
    notifyListeners();
    try {
      selected = await _repo.getAchievement(id);
      detailState = AdminAchievementDetailLoadState.loaded;
    } catch (e) {
      detailError = e is ApiException
          ? e.message
          : 'Could not load this achievement.';
      detailState = AdminAchievementDetailLoadState.error;
    }
    notifyListeners();
  }

  Future<bool> updateAchievement(
    int id, {
    required String title,
    required String description,
    required String icon,
    required String category,
    required AchievementCriteriaType criteriaType,
    required int criteriaValue,
    required bool enabled,
  }) async {
    isSaving = true;
    detailError = null;
    notifyListeners();
    try {
      final updated = await _repo.updateAchievement(
        id,
        title: title,
        description: description,
        icon: icon,
        category: category,
        criteriaType: criteriaType,
        criteriaValue: criteriaValue,
        enabled: enabled,
      );
      selected = updated;
      catalog = catalog.map((a) => a.id == id ? updated : a).toList();
      return true;
    } catch (e) {
      detailError = e is ApiException ? e.message : 'Could not save changes.';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Returns the deletion result on success (caller decides how to message
  /// "deleted" vs "disabled instead"), or null on failure (see [detailError]).
  Future<AchievementDeletionResult?> deleteAchievement(int id) async {
    isDeleting = true;
    detailError = null;
    notifyListeners();
    try {
      final result = await _repo.deleteAchievement(id);
      if (result.deleted) {
        catalog = catalog.where((a) => a.id != id).toList();
      } else if (result.achievement != null) {
        final updated = result.achievement!;
        catalog = catalog.map((a) => a.id == id ? updated : a).toList();
        selected = updated;
      }
      return result;
    } catch (e) {
      detailError = e is ApiException
          ? e.message
          : 'Could not delete this achievement.';
      return null;
    } finally {
      isDeleting = false;
      notifyListeners();
    }
  }
}
