import 'package:flutter/foundation.dart';

import '../../../core/models/project.dart';
import '../../../core/models/project_member.dart';
import '../../../core/models/recommended_member.dart';
import '../../../core/network/api_exception.dart';
import '../data/projects_repository.dart';

enum OwnedProjectsLoadState { initial, loading, loaded, error }

enum ManageLoadState { initial, loading, loaded, error }

enum MyInvitesLoadState { initial, loading, loaded, error }

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

  List<ProjectMember> get pendingRequests => members
      .where((m) => m.status == MemberStatus.pending && !m.invitedByOwner)
      .toList();
  List<ProjectMember> get pendingInvites => members
      .where((m) => m.status == MemberStatus.pending && m.invitedByOwner)
      .toList();
  List<ProjectMember> get acceptedMembers =>
      members.where((m) => m.status == MemberStatus.accepted).toList();

  // --- Invites (owner -> recommended candidate) ---
  final Set<int> invitedUserIds = {};

  Future<bool> invite(int projectId, int userId) async {
    invitedUserIds.add(userId);
    notifyListeners();
    try {
      await _repo.inviteMember(projectId, userId);
      await loadManageData(projectId);
      return true;
    } catch (e) {
      invitedUserIds.remove(userId);
      manageError = e is ApiException
          ? e.message
          : 'Could not send that invite.';
      notifyListeners();
      return false;
    }
  }

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

  bool isUpdating = false;
  String? updateError;

  Future<bool> updateProject({
    required int projectId,
    required String name,
    String? description,
    String? difficulty,
    String? link,
    required int teamSize,
    required List<int> requiredSkillIds,
    List<int>? requiredRoleIds,
  }) async {
    isUpdating = true;
    updateError = null;
    notifyListeners();
    try {
      managedProject = await _repo.updateProject(
        projectId: projectId,
        name: name,
        description: description,
        difficulty: difficulty?.toUpperCase(),
        link: link,
        teamSize: teamSize,
        requiredSkillIds: requiredSkillIds,
        requiredRoleIds: requiredRoleIds,
      );
      return true;
    } catch (e) {
      updateError = e is ApiException
          ? e.message
          : 'Could not update this project.';
      return false;
    } finally {
      isUpdating = false;
      notifyListeners();
    }
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

  // --- My Invites (invites I've received, as the invitee) ---
  MyInvitesLoadState myInvitesState = MyInvitesLoadState.initial;
  String? myInvitesError;
  List<ProjectInvite> myInvites = [];
  final Set<int> respondingProjectIds = {};

  Future<void> loadMyInvites(int userId) async {
    myInvitesState = MyInvitesLoadState.loading;
    notifyListeners();
    try {
      myInvites = await _repo.getMyInvites(userId);
      myInvitesState = MyInvitesLoadState.loaded;
    } catch (e) {
      myInvitesError = e is ApiException
          ? e.message
          : 'Could not load your invites.';
      myInvitesState = MyInvitesLoadState.error;
    }
    notifyListeners();
  }

  Future<bool> acceptInvite(int userId, int projectId) =>
      _respondToInvite(userId, projectId, 'ACCEPTED');
  Future<bool> declineInvite(int userId, int projectId) =>
      _respondToInvite(userId, projectId, 'REJECTED');

  Future<bool> _respondToInvite(
    int userId,
    int projectId,
    String status,
  ) async {
    respondingProjectIds.add(projectId);
    notifyListeners();
    try {
      await _repo.respondToInvite(userId, projectId, status);
      myInvites = myInvites.where((i) => i.projectId != projectId).toList();
      return true;
    } catch (e) {
      myInvitesError = e is ApiException
          ? e.message
          : 'Could not respond to that invite.';
      return false;
    } finally {
      respondingProjectIds.remove(projectId);
      notifyListeners();
    }
  }

  MyInvitesLoadState myJoinRequestsState = MyInvitesLoadState.initial;
  String? myJoinRequestsError;
  List<ProjectJoinRequest> myJoinRequests = [];

  Future<void> loadMyJoinRequests(int userId) async {
    myJoinRequestsState = MyInvitesLoadState.loading;
    notifyListeners();
    try {
      myJoinRequests = await _repo.getMyJoinRequests(userId);
      myJoinRequestsState = MyInvitesLoadState.loaded;
    } catch (e) {
      myJoinRequestsError = e is ApiException
          ? e.message
          : 'Could not load join requests.';
      myJoinRequestsState = MyInvitesLoadState.error;
    }
    notifyListeners();
  }

  Future<bool> acceptJoinRequest(int projectId, int requesterId) =>
      _respondToJoinRequest(projectId, requesterId, 'ACCEPTED');
  Future<bool> declineJoinRequest(int projectId, int requesterId) =>
      _respondToJoinRequest(projectId, requesterId, 'REJECTED');

  Future<bool> _respondToJoinRequest(
    int projectId,
    int requesterId,
    String status,
  ) async {
    respondingProjectIds.add(projectId);
    notifyListeners();
    try {
      await _repo.updateMemberStatus(projectId, requesterId, status);
      myJoinRequests = myJoinRequests
          .where(
            (r) => r.projectId != projectId || r.requesterId != requesterId,
          )
          .toList();
      return true;
    } catch (e) {
      myJoinRequestsError = e is ApiException
          ? e.message
          : 'Could not respond to that request.';
      return false;
    } finally {
      respondingProjectIds.remove(projectId);
      notifyListeners();
    }
  }
}
