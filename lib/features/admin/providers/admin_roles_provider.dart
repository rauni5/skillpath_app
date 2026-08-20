import 'package:flutter/foundation.dart';

import '../../../core/models/admin_role_summary.dart';
import '../../../core/models/branch_requirement.dart';
import '../../../core/models/career_role.dart';
import '../../../core/models/role_branch.dart';
import '../../../core/network/api_exception.dart';
import '../data/admin_repository.dart';

enum AdminRolesLoadState { initial, loading, loaded, error }

enum AdminRoleDetailLoadState { initial, loading, loaded, error }

enum AdminBranchDetailLoadState { initial, loading, loaded, error }

class AdminRolesProvider extends ChangeNotifier {
  AdminRolesProvider({AdminRepository? repository})
    : _repo = repository ?? AdminRepository();

  final AdminRepository _repo;

  // --- List ---
  AdminRolesLoadState listState = AdminRolesLoadState.initial;
  String? listError;
  List<AdminRoleSummary> roles = [];

  Future<void> loadRoles() async {
    listState = AdminRolesLoadState.loading;
    notifyListeners();
    try {
      roles = await _repo.getAdminCareerRoles();
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
      roles = [
        ...roles,
        AdminRoleSummary(
          id: created.id,
          name: created.name,
          description: created.description,
          requirementsCount: 0,
          popularity: 0,
        ),
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
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

  // --- Detail (edit name/description + branches) ---
  AdminRoleDetailLoadState detailState = AdminRoleDetailLoadState.initial;
  String? detailError;
  CareerRole? selectedRole;
  List<RoleBranch> branches = [];
  bool isSaving = false;
  bool isDeleting = false;
  bool isCreatingBranch = false;
  String? createBranchError;

  Future<void> loadDetail(int roleId) async {
    detailState = AdminRoleDetailLoadState.loading;
    detailState = AdminRoleDetailLoadState.loading;
    detailError = null;
    selectedRole = null;
    notifyListeners();
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.getCareerRole(roleId),
        _repo.getBranches(roleId),
      ]);
      selectedRole = results[0] as CareerRole;
      branches = results[1] as List<RoleBranch>;
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
      roles =
          roles
              .map(
                (r) => r.id == roleId
                    ? AdminRoleSummary(
                        id: updated.id,
                        name: updated.name,
                        description: updated.description,
                        requirementsCount: r.requirementsCount,
                        popularity: r.popularity,
                      )
                    : r,
              )
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
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

  // --- Branches (under a role) ---

  Future<RoleBranch?> createBranch(
    int roleId, {
    required String name,
    String? description,
  }) async {
    isCreatingBranch = true;
    createBranchError = null;
    notifyListeners();
    try {
      final created = await _repo.createBranch(
        roleId,
        name: name,
        description: description,
      );
      branches = [...branches, created]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return created;
    } catch (e) {
      createBranchError = e is ApiException
          ? e.message
          : 'Could not create that branch.';
      return null;
    } finally {
      isCreatingBranch = false;
      notifyListeners();
    }
  }

  // --- Branch detail (edit + requirements) ---
  AdminBranchDetailLoadState branchDetailState =
      AdminBranchDetailLoadState.initial;
  String? branchDetailError;
  RoleBranch? selectedBranch;
  List<BranchRequirement> branchRequirements = [];
  bool isSavingBranch = false;
  bool isDeletingBranch = false;
  final Set<int> pendingBranchRequirementSkillIds = {};

  Future<void> loadBranchDetail(int branchId) async {
    branchDetailError = null;
    selectedBranch = null;
    branchRequirements = [];
    branchDetailState = AdminBranchDetailLoadState.loading;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.getBranch(branchId),
        _repo.getBranchRequirements(branchId),
      ]);
      selectedBranch = results[0] as RoleBranch;
      branchRequirements = results[1] as List<BranchRequirement>;
      branchDetailState = AdminBranchDetailLoadState.loaded;
    } catch (e) {
      branchDetailError = e is ApiException
          ? e.message
          : 'Could not load this branch.';
      branchDetailState = AdminBranchDetailLoadState.error;
    }
    notifyListeners();
  }

  Future<bool> updateBranch(
    int branchId, {
    required String name,
    String? description,
  }) async {
    isSavingBranch = true;
    branchDetailError = null;
    notifyListeners();
    try {
      final updated = await _repo.updateBranch(
        branchId,
        name: name,
        description: description,
      );
      selectedBranch = updated;
      branches = branches.map((b) => b.id == branchId ? updated : b).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return true;
    } catch (e) {
      branchDetailError = e is ApiException
          ? e.message
          : 'Could not save changes.';
      return false;
    } finally {
      isSavingBranch = false;
      notifyListeners();
    }
  }

  Future<bool> deleteBranch(int branchId) async {
    isDeletingBranch = true;
    branchDetailError = null;
    notifyListeners();
    try {
      await _repo.deleteBranch(branchId);
      branches = branches.where((b) => b.id != branchId).toList();
      return true;
    } catch (e) {
      branchDetailError = e is ApiException
          ? e.message
          : 'Could not delete this branch.';
      return false;
    } finally {
      isDeletingBranch = false;
      notifyListeners();
    }
  }

  Future<bool> addBranchRequirement(
    int branchId,
    int skillId,
    int importance,
  ) async {
    pendingBranchRequirementSkillIds.add(skillId);
    notifyListeners();
    try {
      await _repo.addBranchRequirement(branchId, skillId, importance);
      await loadBranchDetail(branchId);
      return true;
    } catch (e) {
      branchDetailError = e is ApiException
          ? e.message
          : 'Could not add that requirement.';
      return false;
    } finally {
      pendingBranchRequirementSkillIds.remove(skillId);
      notifyListeners();
    }
  }

  Future<bool> updateBranchRequirementImportance(
    int branchId,
    int skillId,
    int importance,
  ) async {
    pendingBranchRequirementSkillIds.add(skillId);
    notifyListeners();
    try {
      await _repo.updateBranchRequirement(branchId, skillId, importance);
      branchRequirements = branchRequirements
          .map(
            (r) => r.skillId == skillId
                ? BranchRequirement(
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
      branchDetailError = e is ApiException
          ? e.message
          : 'Could not update importance.';
      return false;
    } finally {
      pendingBranchRequirementSkillIds.remove(skillId);
      notifyListeners();
    }
  }

  Future<bool> removeBranchRequirement(int branchId, int skillId) async {
    pendingBranchRequirementSkillIds.add(skillId);
    notifyListeners();
    try {
      await _repo.removeBranchRequirement(branchId, skillId);
      branchRequirements = branchRequirements
          .where((r) => r.skillId != skillId)
          .toList();
      return true;
    } catch (e) {
      branchDetailError = e is ApiException
          ? e.message
          : 'Could not remove that requirement.';
      return false;
    } finally {
      pendingBranchRequirementSkillIds.remove(skillId);
      notifyListeners();
    }
  }
}
