import 'package:flutter/foundation.dart';

import '../../../core/models/project.dart';
import '../../../core/models/recommended_member.dart';
import '../../../core/network/api_exception.dart';
import '../data/projects_repository.dart';

enum ProjectsLoadState { initial, loading, loaded, error }
enum ProjectDetailLoadState { initial, loading, loaded, error }

class ProjectsProvider extends ChangeNotifier {
  ProjectsProvider({ProjectsRepository? repository}) : _repo = repository ?? ProjectsRepository();

  final ProjectsRepository _repo;

  // --- List ---
  ProjectsLoadState listState = ProjectsLoadState.initial;
  String? listError;
  List<Project> projects = [];
  int _page = 0;
  bool hasMore = true;
  bool isLoadingMore = false;

  Future<void> loadProjects() async {
    listState = ProjectsLoadState.loading;
    _page = 0;
    notifyListeners();
    try {
      final result = await _repo.getProjects(page: 0);
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
      final result = await _repo.getProjects(page: nextPage);
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
  List<RecommendedMember> recommendedMembers = [];
  final Set<int> pendingJoinIds = {};
  final Set<int> joinedIds = {};

  Future<void> loadProjectDetail(int id) async {
    detailState = ProjectDetailLoadState.loading;
    notifyListeners();
    try {
      selectedProject = await _repo.getProject(id);
      // Best-effort — recommended members is a nice-to-have, don't fail
      // the whole detail screen if this particular call errors.
      try {
        recommendedMembers = await _repo.getRecommendedMembers(id);
      } catch (_) {
        recommendedMembers = [];
      }
      detailState = ProjectDetailLoadState.loaded;
    } catch (e) {
      detailError = e is ApiException ? e.message : 'Could not load this project.';
      detailState = ProjectDetailLoadState.error;
    }
    notifyListeners();
  }

  Future<bool> joinProject(int id) async {
    pendingJoinIds.add(id);
    notifyListeners();
    try {
      await _repo.joinProject(id);
      joinedIds.add(id);
      return true;
    } catch (e) {
      detailError = e is ApiException ? e.message : 'Could not join this project.';
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
    required int teamSize,
    required List<int> requiredSkillIds,
  }) async {
    isCreating = true;
    createError = null;
    notifyListeners();
    try {
      final created = await _repo.createProject(
        name: name,
        description: description,
        difficulty: difficulty,
        teamSize: teamSize,
        requiredSkillIds: requiredSkillIds,
      );
      // New project should show up at the top of the list immediately.
      projects = [created, ...projects];
      return created;
    } catch (e) {
      createError = e is ApiException ? e.message : 'Could not create this project.';
      return null;
    } finally {
      isCreating = false;
      notifyListeners();
    }
  }
}
