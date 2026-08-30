import 'package:flutter/foundation.dart';

import '../../../core/models/skill.dart';
import '../../../core/network/api_exception.dart';
import '../data/skills_repository.dart';

enum SkillsLoadState { initial, loading, loaded, error }

class SkillsProvider extends ChangeNotifier {
  SkillsProvider({SkillsRepository? repository})
    : _repo = repository ?? SkillsRepository();

  final SkillsRepository _repo;

  SkillsLoadState catalogState = SkillsLoadState.initial;
  SkillsLoadState userSkillsState = SkillsLoadState.initial;
  String? errorMessage;

  List<Skill> catalog = [];
  List<Skill> userSkills = [];

  /// Skill ids currently being added/removed, so rows can show a small
  /// inline spinner instead of blocking the whole screen.
  final Set<int> pendingSkillIds = {};

  String searchQuery = '';
  SkillCategory? categoryFilter;

  Set<int> get userSkillIds => userSkills.map((s) => s.id).toSet();

  /// Catalog skills not yet in the user's inventory, filtered by the
  /// current search query and category chip.
  List<Skill> get filteredCatalog {
    final ownedIds = userSkillIds;
    return catalog.where((s) {
      if (ownedIds.contains(s.id)) return false;
      if (categoryFilter != null && s.category != categoryFilter) return false;
      if (searchQuery.trim().isEmpty) return true;
      return s.name.toLowerCase().contains(searchQuery.trim().toLowerCase());
    }).toList();
  }

  List<Skill> get filteredCatalogAll {
    return catalog.where((s) {
      if (categoryFilter != null && s.category != categoryFilter) return false;
      if (searchQuery.trim().isEmpty) return true;
      return s.name.toLowerCase().contains(searchQuery.trim().toLowerCase());
    }).toList();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(SkillCategory? category) {
    categoryFilter = category;
    notifyListeners();
  }

  Future<void> loadCatalog() async {
    catalogState = SkillsLoadState.loading;
    notifyListeners();
    try {
      catalog = await _repo.getAllSkills();
      catalogState = SkillsLoadState.loaded;
    } catch (e) {
      errorMessage = e is ApiException
          ? e.message
          : 'Could not load the skill catalog.';
      catalogState = SkillsLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadUserSkills(int userId) async {
    userSkillsState = SkillsLoadState.loading;
    notifyListeners();
    try {
      userSkills = await _repo.getUserSkills(userId);
      userSkillsState = SkillsLoadState.loaded;
    } catch (e) {
      errorMessage = e is ApiException
          ? e.message
          : 'Could not load your skills.';
      userSkillsState = SkillsLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadAll(int userId) async {
    await Future.wait([loadCatalog(), loadUserSkills(userId)]);
  }

  /// Optimistically adds [skill] to the user's inventory, rolling back if
  /// the request fails. On success, re-syncs from the server since adding a
  /// skill may also auto-add its prerequisites (e.g. Spring Boot -> Java).
  Future<bool> addSkill(
    int userId,
    Skill skill,
    SkillProficiency proficiency,
  ) async {
    pendingSkillIds.add(skill.id);
    userSkills = [...userSkills, skill.withProficiency(proficiency)];
    notifyListeners();
    try {
      await _repo.addSkill(userId, skill.id, proficiency);
      await loadUserSkills(userId);
      return true;
    } catch (e) {
      userSkills = userSkills.where((s) => s.id != skill.id).toList();
      errorMessage = e is ApiException
          ? e.message
          : 'Could not add that skill.';
      return false;
    } finally {
      pendingSkillIds.remove(skill.id);
      notifyListeners();
    }
  }

  Future<bool> removeSkill(int userId, int skillId) async {
    pendingSkillIds.add(skillId);
    final removed = userSkills.firstWhere((s) => s.id == skillId);
    userSkills = userSkills.where((s) => s.id != skillId).toList();
    notifyListeners();
    try {
      await _repo.removeSkill(userId, skillId);
      return true;
    } catch (e) {
      userSkills = [...userSkills, removed];
      errorMessage = e is ApiException
          ? e.message
          : 'Could not remove that skill.';
      return false;
    } finally {
      pendingSkillIds.remove(skillId);
      notifyListeners();
    }
  }
}
