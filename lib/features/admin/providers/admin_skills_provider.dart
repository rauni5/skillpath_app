import 'package:flutter/foundation.dart';

import '../../../core/models/skill.dart';
import '../../../core/network/api_exception.dart';
import '../data/admin_repository.dart';

enum AdminSkillsLoadState { initial, loading, loaded, error }

enum AdminSkillDetailLoadState { initial, loading, loaded, error }

class AdminSkillsProvider extends ChangeNotifier {
  AdminSkillsProvider({AdminRepository? repository})
    : _repo = repository ?? AdminRepository();

  final AdminRepository _repo;

  // --- Catalog list ---
  AdminSkillsLoadState listState = AdminSkillsLoadState.initial;
  String? listError;
  List<Skill> catalog = [];

  Future<void> loadCatalog() async {
    listState = AdminSkillsLoadState.loading;
    notifyListeners();
    try {
      catalog = await _repo.getSkills();
      catalog.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      listState = AdminSkillsLoadState.loaded;
    } catch (e) {
      listError = e is ApiException ? e.message : 'Could not load skills.';
      listState = AdminSkillsLoadState.error;
    }
    notifyListeners();
  }

  bool isCreating = false;
  String? createError;

  Future<Skill?> createSkill({
    required String name,
    required SkillCategory category,
    String? description,
  }) async {
    isCreating = true;
    createError = null;
    notifyListeners();
    try {
      final created = await _repo.createSkill(
        name: name,
        category: category,
        description: description,
      );
      catalog = [...catalog, created]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return created;
    } catch (e) {
      createError = e is ApiException
          ? e.message
          : 'Could not create that skill.';
      return null;
    } finally {
      isCreating = false;
      notifyListeners();
    }
  }

  // --- Single skill detail (edit + dependencies) ---
  AdminSkillDetailLoadState detailState = AdminSkillDetailLoadState.initial;
  String? detailError;
  Skill? selectedSkill;
  List<Skill> dependencies = [];
  bool isSaving = false;
  bool isDeleting = false;
  final Set<int> pendingDependencyIds = {};

  Future<void> loadDetail(int skillId) async {
    detailState = AdminSkillDetailLoadState.loading;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.getSkill(skillId),
        _repo.getDependencies(skillId),
      ]);
      selectedSkill = results[0] as Skill;
      dependencies = results[1] as List<Skill>;
      detailState = AdminSkillDetailLoadState.loaded;
    } catch (e) {
      detailError = e is ApiException
          ? e.message
          : 'Could not load this skill.';
      detailState = AdminSkillDetailLoadState.error;
    }
    notifyListeners();
  }

  Future<bool> updateSkill(
    int skillId, {
    required String name,
    required SkillCategory category,
    String? description,
  }) async {
    isSaving = true;
    detailError = null;
    notifyListeners();
    try {
      final updated = await _repo.updateSkill(
        skillId,
        name: name,
        category: category,
        description: description,
      );
      selectedSkill = updated;
      catalog = catalog.map((s) => s.id == skillId ? updated : s).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return true;
    } catch (e) {
      detailError = e is ApiException ? e.message : 'Could not save changes.';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSkill(int skillId) async {
    isDeleting = true;
    detailError = null;
    notifyListeners();
    try {
      await _repo.deleteSkill(skillId);
      catalog = catalog.where((s) => s.id != skillId).toList();
      return true;
    } catch (e) {
      detailError = e is ApiException
          ? e.message
          : 'Could not delete this skill.';
      return false;
    } finally {
      isDeleting = false;
      notifyListeners();
    }
  }

  Future<bool> addDependency(int skillId, int prerequisiteId) async {
    pendingDependencyIds.add(prerequisiteId);
    notifyListeners();
    try {
      await _repo.addDependency(skillId, prerequisiteId);
      await loadDetail(skillId);
      return true;
    } catch (e) {
      detailError = e is ApiException
          ? e.message
          : 'Could not add that dependency.';
      return false;
    } finally {
      pendingDependencyIds.remove(prerequisiteId);
      notifyListeners();
    }
  }

  Future<bool> removeDependency(int skillId, int prerequisiteId) async {
    pendingDependencyIds.add(prerequisiteId);
    notifyListeners();
    try {
      await _repo.removeDependency(skillId, prerequisiteId);
      dependencies = dependencies.where((d) => d.id != prerequisiteId).toList();
      return true;
    } catch (e) {
      detailError = e is ApiException
          ? e.message
          : 'Could not remove that dependency.';
      return false;
    } finally {
      pendingDependencyIds.remove(prerequisiteId);
      notifyListeners();
    }
  }
}
