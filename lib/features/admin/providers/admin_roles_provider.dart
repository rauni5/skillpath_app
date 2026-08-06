import 'package:flutter/foundation.dart';

import '../../../core/models/career_role.dart';
import '../../../core/models/role_requirement.dart';
import '../../../core/network/api_exception.dart';
import '../data/admin_repository.dart';

enum AdminRolesLoadState { initial, loading, loaded, error }

enum AdminRoleDetailLoadState { initial, loading, loaded, error }

class AdminRolesProvider extends ChangeNotifier {
  AdminRolesProvider({AdminRepository? repository})
    : _repo = repository ?? AdminRepository();

  final AdminRepository _repo;

  // --- List ---
  AdminRolesLoadState listState = AdminRolesLoadState.initial;
  String? listError;
  List<CareerRole> roles = [];

  Future<void> loadRoles() async {
    listState = AdminRolesLoadState.loading;
    notifyListeners();
    try {
      roles = await _repo.getCareerRoles();
      roles.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      listState = AdminRolesLoadState.loaded;
    } catch (e) {
      listError = e is ApiException
          ? e.message
          : 'Could not load career roles.';
      listState = AdminRolesLoadState.error;
    }
    notifyListeners();
  }

  bool isCreating = false;
  String? createError;

  Future<CareerRole?> createRole({
    required String name,
    String? description,
  }) async {
    isCreating = true;
    createError = null;
    notifyListeners();
    try {
      final created = await _repo.createCareerRole(
        name: name,
        description: description,
      );
      roles = [...roles, created]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return created;
    } catch (e) {
      createError = e is ApiException
          ? e.message
          : 'Could not create that role.';
      return null;
    } finally {
      isCreating = false;
      notifyListeners();
    }
  }

  // --- Detail (edit + requirements) ---
  AdminRoleDetailLoadState detailState = AdminRoleDetailLoadState.initial;
  String? detailError;
  CareerRole? selectedRole;
  List<RoleRequirement> requirements = [];
  bool isSaving = false;
  bool isDeleting = false;
  final Set<int> pendingRequirementSkillIds = {};

  Future<void> loadDetail(int roleId) async {
    detailState = AdminRoleDetailLoadState.loading;
    detailState = AdminRoleDetailLoadState.loading;
    detailError = null;
    selectedRole = null;
    requirements = [];
    notifyListeners();
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.getCareerRole(roleId),
        _repo.getRoleRequirements(roleId),
      ]);
      selectedRole = results[0] as CareerRole;
      requirements = results[1] as List<RoleRequirement>;
      detailState = AdminRoleDetailLoadState.loaded;
    } catch (e) {
      detailError = e is ApiException ? e.message : 'Could not load this role.';
      detailState = AdminRoleDetailLoadState.error;
    }
    notifyListeners();
  }

  Future<bool> updateRole(
    int roleId, {
    required String name,
    String? description,
  }) async {
    isSaving = true;
    detailError = null;
    notifyListeners();
    try {
      final updated = await _repo.updateCareerRole(
        roleId,
        name: name,
        description: description,
      );
      selectedRole = updated;
      roles = roles.map((r) => r.id == roleId ? updated : r).toList()
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

  Future<bool> deleteRole(int roleId) async {
    isDeleting = true;
    detailError = null;
    notifyListeners();
    try {
      await _repo.deleteCareerRole(roleId);
      roles = roles.where((r) => r.id != roleId).toList();
      return true;
    } catch (e) {
      detailError = e is ApiException
          ? e.message
          : 'Could not delete this role.';
      return false;
    } finally {
      isDeleting = false;
      notifyListeners();
    }
  }

  Future<bool> addRequirement(int roleId, int skillId, int importance) async {
    pendingRequirementSkillIds.add(skillId);
    notifyListeners();
    try {
      await _repo.addRoleRequirement(roleId, skillId, importance);
      await loadDetail(roleId);
      return true;
    } catch (e) {
      detailError = e is ApiException
          ? e.message
          : 'Could not add that requirement.';
      return false;
    } finally {
      pendingRequirementSkillIds.remove(skillId);
      notifyListeners();
    }
  }

  Future<bool> updateRequirementImportance(
    int roleId,
    int skillId,
    int importance,
  ) async {
    pendingRequirementSkillIds.add(skillId);
    notifyListeners();
    try {
      await _repo.updateRoleRequirement(roleId, skillId, importance);
      requirements = requirements
          .map(
            (r) => r.skillId == skillId
                ? RoleRequirement(
                    skillId: r.skillId,
                    name: r.name,
                    category: r.category,
                    importance: importance,
                  )
                : r,
          )
          .toList();
      return true;
    } catch (e) {
      detailError = e is ApiException
          ? e.message
          : 'Could not update importance.';
      return false;
    } finally {
      pendingRequirementSkillIds.remove(skillId);
      notifyListeners();
    }
  }

  Future<bool> removeRequirement(int roleId, int skillId) async {
    pendingRequirementSkillIds.add(skillId);
    notifyListeners();
    try {
      await _repo.removeRoleRequirement(roleId, skillId);
      requirements = requirements.where((r) => r.skillId != skillId).toList();
      return true;
    } catch (e) {
      detailError = e is ApiException
          ? e.message
          : 'Could not remove that requirement.';
      return false;
    } finally {
      pendingRequirementSkillIds.remove(skillId);
      notifyListeners();
    }
  }
}
