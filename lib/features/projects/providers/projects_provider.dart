import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/models/project.dart';
import '../../../core/models/project_member.dart';
import '../../../core/network/api_exception.dart';
import '../data/projects_repository.dart';

enum ProjectsLoadState { initial, loading, loaded, error }

enum ProjectDetailLoadState { initial, loading, loaded, error }

class ProjectsProvider extends ChangeNotifier {
  ProjectsProvider({ProjectsRepository? repository})
    : _repo = repository ?? ProjectsRepository();

  final ProjectsRepository _repo;

  // --- List ---
  ProjectsLoadState listState = ProjectsLoadState.initial;
  String? listError;
  List<Project> projects = [];
  int _page = 0;
  bool hasMore = true;
  bool isLoadingMore = false;

  // --- Name search ---
  String searchQuery = '';
  Timer? _searchDebounce;

  void setSearchQuery(String query) {
    searchQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), loadProjects);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  // --- Filters ---
  String? filterDifficulty;
  final Set<int> filterSkillIds = {};
  final Set<int> filterRoleIds = {};

  bool get hasActiveFilters =>
      filterDifficulty != null ||
      filterSkillIds.isNotEmpty ||
      filterRoleIds.isNotEmpty;

  void setDifficultyFilter(String? difficulty) {
    filterDifficulty = difficulty;
    loadProjects();
  }

  void toggleSkillFilter(int skillId) {
    if (!filterSkillIds.remove(skillId)) filterSkillIds.add(skillId);
    loadProjects();
  }

  void toggleRoleFilter(int roleId) {
    if (!filterRoleIds.remove(roleId)) filterRoleIds.add(roleId);
    loadProjects();
  }

  void clearFilters() {
    filterDifficulty = null;
    filterSkillIds.clear();
    filterRoleIds.clear();
    loadProjects();
  }

  void clearSearchAndFilters() {
    _searchDebounce?.cancel();
    searchQuery = '';
    filterDifficulty = null;
    filterSkillIds.clear();
    filterRoleIds.clear();
    loadProjects();
  }

  Future<void> loadProjects() async {
    listState = ProjectsLoadState.loading;
    _page = 0;
    notifyListeners();
    try {
      final result = await _repo.getProjects(
        page: 0,
        difficulty: filterDifficulty,
        skillIds: filterSkillIds.isEmpty ? null : filterSkillIds.toList(),
        roleIds: filterRoleIds.isEmpty ? null : filterRoleIds.toList(),
        q: searchQuery,
      );
      projects = result.content;
      hasMore = !result.last;
      listState = ProjectsLoadState.loaded;
    } catch (e) {
      listError = e is ApiException ? e.message : 'Could not load projects.';
      listState = ProjectsLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoadingMore) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      final nextPage = _page + 1;
      final result = await _repo.getProjects(
        page: nextPage,
        difficulty: filterDifficulty,
        skillIds: filterSkillIds.isEmpty ? null : filterSkillIds.toList(),
        roleIds: filterRoleIds.isEmpty ? null : filterRoleIds.toList(),
        q: searchQuery,
      );
      projects = [...projects, ...result.content];
      hasMore = !result.last;
      _page = nextPage;
    } catch (_) {
      // Silently stop paginating — the list they already have stays usable.
      hasMore = false;
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  // --- Detail ---
  ProjectDetailLoadState detailState = ProjectDetailLoadState.initial;
  String? detailError;
  Project? selectedProject;
  final Set<int> pendingJoinIds = {};

  // --- Team (accepted members only, includes owner + emails) ---
  List<ProjectMember> team = [];
  bool teamLoading = false;

  Future<void> loadProjectDetail(int id) async {
    detailState = ProjectDetailLoadState.loading;
    team = [];
    notifyListeners();
    try {
      selectedProject = await _repo.getProject(id);
      detailState = ProjectDetailLoadState.loaded;
      if (selectedProject!.viewerMembershipStatus == MemberStatus.accepted) {
        _loadTeam(id);
      }
    } catch (e) {
      detailError = e is ApiException
          ? e.message
          : 'Could not load this project.';
      detailState = ProjectDetailLoadState.error;
    }
    notifyListeners();
  }

  Future<void> _loadTeam(int projectId) async {
    teamLoading = true;
    notifyListeners();
    try {
      team = await _repo.getTeam(projectId);
    } catch (_) {
      team = [];
    } finally {
      teamLoading = false;
      notifyListeners();
    }
  }

  Future<bool> joinProject(int id) async {
    pendingJoinIds.add(id);
    notifyListeners();
    try {
      await _repo.joinProject(id);
      // Re-fetch so viewerMembershipStatus reflects the real server state.
      await loadProjectDetail(id);
      return true;
    } catch (e) {
      detailError = e is ApiException
          ? e.message
          : 'Could not join this project.';
      return false;
    } finally {
      pendingJoinIds.remove(id);
      notifyListeners();
    }
  }

  // --- Create ---
  bool isCreating = false;
  String? createError;

  Future<Project?> createProject({
    required String name,
    String? description,
    String? difficulty,
    String? link,
    required int teamSize,
    required List<int> requiredSkillIds,
    List<int>? requiredRoleIds,
  }) async {
    isCreating = true;
    createError = null;
    notifyListeners();
    try {
      final created = await _repo.createProject(
        name: name,
        description: description,
        difficulty: difficulty?.toUpperCase(),
        link: link,
        teamSize: teamSize,
        requiredSkillIds: requiredSkillIds,
        requiredRoleIds: requiredRoleIds,
      );
      // New project should show up at the top of the list immediately.
      projects = [created, ...projects];
      return created;
    } catch (e) {
      createError = e is ApiException
          ? e.message
          : 'Could not create this project.';
      return null;
    } finally {
      isCreating = false;
      notifyListeners();
    }
  }
}
