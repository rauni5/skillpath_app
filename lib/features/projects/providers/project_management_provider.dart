import 'package:flutter/foundation.dart';

import '../../../core/models/project.dart';
import '../../../core/models/project_member.dart';
import '../../../core/models/recommended_member.dart';
import '../../../core/network/api_exception.dart';
import '../data/projects_repository.dart';

enum OwnedProjectsLoadState { initial, loading, loaded, error }

enum ManageLoadState { initial, loading, loaded, error }

class ProjectManagementProvider extends ChangeNotifier {
  ProjectManagementProvider({ProjectsRepository? repository})
    : _repo = repository ?? ProjectsRepository();

  final ProjectsRepository _repo;

  // --- My Projects (owned) ---
  OwnedProjectsLoadState ownedState = OwnedProjectsLoadState.initial;
  String? ownedError;
  List<Project> ownedProjects = [];

  Future<void> loadOwnedProjects(int userId) async {
    ownedState = OwnedProjectsLoadState.loading;
    notifyListeners();
    try {
      final result = await _repo.getOwnedProjects(userId);
      ownedProjects = result.content;
      ownedState = OwnedProjectsLoadState.loaded;
    } catch (e) {
      ownedError = e is ApiException
          ? e.message
          : 'Could not load your projects.';
      ownedState = OwnedProjectsLoadState.error;
    }
    notifyListeners();
  }

  // --- Manage a single project ---
  ManageLoadState manageState = ManageLoadState.initial;
  String? manageError;
  Project? managedProject;
  List<ProjectMember> members = [];
  List<RecommendedMember> recommendedMembers = [];
  final Set<int> pendingActionUserIds = {};

  List<ProjectMember> get pendingRequests =>
      members.where((m) => m.status == MemberStatus.pending).toList();
  List<ProjectMember> get acceptedMembers =>
      members.where((m) => m.status == MemberStatus.accepted).toList();

  Future<void> loadManageData(int projectId) async {
    manageState = ManageLoadState.loading;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.getProject(projectId),
        _repo.getMembers(projectId),
      ]);
      managedProject = results[0] as Project;
      members = results[1] as List<ProjectMember>;
      manageState = ManageLoadState.loaded;
      // Best-effort — recommendations are a nice-to-have, don't fail the
      // whole screen if this particular call errors.
      try {
        recommendedMembers = await _repo.getRecommendedMembers(projectId);
      } catch (_) {
        recommendedMembers = [];
      }
    } catch (e) {
      manageError = e is ApiException
          ? e.message
          : 'Could not load this project.';
      manageState = ManageLoadState.error;
    }
    notifyListeners();
  }

  Future<bool> acceptRequest(int projectId, int userId) =>
      _updateStatus(projectId, userId, 'ACCEPTED');
  Future<bool> rejectRequest(int projectId, int userId) =>
      _updateStatus(projectId, userId, 'REJECTED');

  Future<bool> _updateStatus(int projectId, int userId, String status) async {
    pendingActionUserIds.add(userId);
    notifyListeners();
    try {
      await _repo.updateMemberStatus(projectId, userId, status);
      await loadManageData(projectId);
      return true;
    } catch (e) {
      manageError = e is ApiException
          ? e.message
          : 'Could not update that request.';
      return false;
    } finally {
      pendingActionUserIds.remove(userId);
      notifyListeners();
    }
  }

  Future<bool> removeMember(int projectId, int userId) async {
    pendingActionUserIds.add(userId);
    notifyListeners();
    try {
      await _repo.removeMember(projectId, userId);
      members = members.where((m) => m.userId != userId).toList();
      return true;
    } catch (e) {
      manageError = e is ApiException
          ? e.message
          : 'Could not remove that member.';
      return false;
    } finally {
      pendingActionUserIds.remove(userId);
      notifyListeners();
    }
  }
}
