import '../../../core/models/branch_requirement.dart';
import '../../../core/models/admin_achievement.dart';
import '../../../core/models/admin_dashboard_stats.dart';
import '../../../core/models/admin_role_summary.dart';
import '../../../core/models/admin_user_analytics.dart';
import '../../../core/models/admin_user_summary.dart';
import '../../../core/models/admin_users_query.dart';
import '../../../core/models/career_role.dart';
import '../../../core/models/daily_count.dart';
import '../../../core/models/page_projects.dart';
import '../../../core/models/role_branch.dart';
import '../../../core/models/skill.dart';
import '../../../core/models/user.dart';
import '../../../core/network/api_client.dart';

class AdminRepository {
  final ApiClient _api = ApiClient.instance;

  // --- Users ---

  /// GET /api/v1/admin/users — paginated, 20 per page by default. [q]
  /// searches by name or email (case-insensitive). [status] filters by
  /// admin/active/inactive. Sortable by [sortBy]/[sortDir].
  /// Each row includes per-user stats (skills/projects/achievements counts).
  Future<Page<AdminUserSummary>> getUsers({
    int page = 0,
    int size = 20,
    String? q,
    UserStatusFilter status = UserStatusFilter.all,
    UserSortBy sortBy = UserSortBy.createdAt,
    SortDir sortDir = SortDir.desc,
  }) {
    return _api.unwrap(
      (dio) => dio.get(
        '/api/v1/admin/users',
        queryParameters: {
          'page': page,
          'size': size,
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
          'status': status.apiValue,
          'sortBy': sortBy.apiValue,
          'sortDir': sortDir.apiValue,
        },
      ),
      (data) => Page<AdminUserSummary>.fromJson(
        data as Map<String, dynamic>,
        AdminUserSummary.fromJson,
      ),
    );
  }

  /// GET /api/v1/admin/users/analytics
  Future<AdminUserAnalytics> getUserAnalytics() {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/admin/users/analytics'),
      (data) => AdminUserAnalytics.fromJson(data as Map<String, dynamic>),
    );
  }

  /// GET /api/v1/admin/dashboard/stats?days= — [trendDays] controls the
  /// signup-trend chart window (7/30/90…), defaults to 30.
  Future<AdminDashboardStats> getDashboardStats({int trendDays = 30}) {
    return _api.unwrap(
      (dio) => dio.get(
        '/api/v1/admin/dashboard/stats',
        queryParameters: {'days': trendDays},
      ),
      (data) => AdminDashboardStats.fromJson(data as Map<String, dynamic>),
    );
  }

  /// GET /api/v1/admin/dashboard/signup-trend?days= — just the chart data,
  /// so switching the day range doesn't require reloading every stat.
  Future<List<DailyCount>> getSignupTrend({int days = 30}) {
    return _api.unwrap(
      (dio) => dio.get(
        '/api/v1/admin/dashboard/signup-trend',
        queryParameters: {'days': days},
      ),
      (data) => (data as List<dynamic>)
          .map((e) => DailyCount.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// PATCH /api/v1/admin/users/{userId}/admin
  Future<AppUser> setAdmin(int userId, bool isAdmin) {
    return _api.unwrap(
      (dio) => dio.patch(
        '/api/v1/admin/users/$userId/admin',
        data: {'admin': isAdmin},
      ),
      (data) => AppUser.fromJson(data as Map<String, dynamic>),
    );
  }

  /// PATCH /api/v1/admin/users/{userId}/active — deactivate/reactivate a
  /// user. Deactivated users are rejected at sign-in but keep their data.
  Future<AppUser> setActive(int userId, bool active) {
    return _api.unwrap(
      (dio) => dio.patch(
        '/api/v1/admin/users/$userId/active',
        data: {'active': active},
      ),
      (data) => AppUser.fromJson(data as Map<String, dynamic>),
    );
  }

  // --- Skills ---

  /// GET /api/v1/skills — full catalogue (public read endpoint, reused here).
  Future<List<Skill>> getSkills() {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/skills'),
      (data) => (data as List<dynamic>)
          .map((e) => Skill.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// GET /api/v1/admin/skills/{id}
  Future<Skill> getSkill(int id) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/admin/skills/$id'),
      (data) => Skill.fromJson(data as Map<String, dynamic>),
    );
  }

  /// POST /api/v1/admin/skills
  Future<Skill> createSkill({
    required String name,
    required SkillCategory category,
    String? description,
  }) {
    return _api.unwrap(
      (dio) => dio.post(
        '/api/v1/admin/skills',
        data: {
          'name': name,
          'category': skillCategoryToApiString(category),
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      ),
      (data) => Skill.fromJson(data as Map<String, dynamic>),
    );
  }

  /// PUT /api/v1/admin/skills/{id}
  Future<Skill> updateSkill(
    int id, {
    required String name,
    required SkillCategory category,
    String? description,
  }) {
    return _api.unwrap(
      (dio) => dio.put(
        '/api/v1/admin/skills/$id',
        data: {
          'name': name,
          'category': skillCategoryToApiString(category),
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      ),
      (data) => Skill.fromJson(data as Map<String, dynamic>),
    );
  }

  /// DELETE /api/v1/admin/skills/{id}
  Future<void> deleteSkill(int id) {
    return _api.unwrap((dio) => dio.delete('/api/v1/admin/skills/$id'), (_) {});
  }

  /// GET /api/v1/admin/skills/{id}/dependencies — this skill's prerequisites.
  Future<List<Skill>> getDependencies(int skillId) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/admin/skills/$skillId/dependencies'),
      (data) => (data as List<dynamic>)
          .map((e) => Skill.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// POST /api/v1/admin/skills/{id}/dependencies
  Future<void> addDependency(int skillId, int prerequisiteId) {
    return _api.unwrap(
      (dio) => dio.post(
        '/api/v1/admin/skills/$skillId/dependencies',
        data: {'prerequisiteId': prerequisiteId},
      ),
      (_) {},
    );
  }

  /// DELETE /api/v1/admin/skills/{id}/dependencies/{prereqId}
  Future<void> removeDependency(int skillId, int prerequisiteId) {
    return _api.unwrap(
      (dio) => dio.delete(
        '/api/v1/admin/skills/$skillId/dependencies/$prerequisiteId',
      ),
      (_) {},
    );
  }

  // --- Career Roles ---

  /// GET /api/v1/career-roles — full list (public read endpoint, reused here).
  Future<List<CareerRole>> getCareerRoles() {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/career-roles'),
      (data) => (data as List<dynamic>)
          .map((e) => CareerRole.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// GET /api/v1/admin/career-roles — enriched with per-role stats
  /// (required-skill count, popularity) for the admin Roles screen.
  Future<List<AdminRoleSummary>> getAdminCareerRoles() {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/admin/career-roles'),
      (data) => (data as List<dynamic>)
          .map((e) => AdminRoleSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// GET /api/v1/admin/career-roles/{id}
  Future<CareerRole> getCareerRole(int id) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/admin/career-roles/$id'),
      (data) => CareerRole.fromJson(data as Map<String, dynamic>),
    );
  }

  /// POST /api/v1/admin/career-roles
  Future<CareerRole> createCareerRole({
    required String name,
    String? description,
  }) {
    return _api.unwrap(
      (dio) => dio.post(
        '/api/v1/admin/career-roles',
        data: {
          'name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      ),
      (data) => CareerRole.fromJson(data as Map<String, dynamic>),
    );
  }

  /// PUT /api/v1/admin/career-roles/{id}
  Future<CareerRole> updateCareerRole(
    int id, {
    required String name,
    String? description,
  }) {
    return _api.unwrap(
      (dio) => dio.put(
        '/api/v1/admin/career-roles/$id',
        data: {
          'name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      ),
      (data) => CareerRole.fromJson(data as Map<String, dynamic>),
    );
  }

  /// DELETE /api/v1/admin/career-roles/{id}
  Future<void> deleteCareerRole(int id) {
    return _api.unwrap(
      (dio) => dio.delete('/api/v1/admin/career-roles/$id'),
      (_) {},
    );
  }

  // --- Role Branches (a role's required skills live here, not on the role) ---

  /// GET /api/v1/admin/career-roles/{roleId}/branches
  Future<List<RoleBranch>> getBranches(int roleId) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/admin/career-roles/$roleId/branches'),
      (data) => (data as List<dynamic>)
          .map((e) => RoleBranch.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// GET /api/v1/admin/branches/{branchId}
  Future<RoleBranch> getBranch(int branchId) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/admin/branches/$branchId'),
      (data) => RoleBranch.fromJson(data as Map<String, dynamic>),
    );
  }

  /// POST /api/v1/admin/career-roles/{roleId}/branches
  Future<RoleBranch> createBranch(
    int roleId, {
    required String name,
    String? description,
  }) {
    return _api.unwrap(
      (dio) => dio.post(
        '/api/v1/admin/career-roles/$roleId/branches',
        data: {
          'name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      ),
      (data) => RoleBranch.fromJson(data as Map<String, dynamic>),
    );
  }

  /// PUT /api/v1/admin/branches/{branchId}
  Future<RoleBranch> updateBranch(
    int branchId, {
    required String name,
    String? description,
  }) {
    return _api.unwrap(
      (dio) => dio.put(
        '/api/v1/admin/branches/$branchId',
        data: {
          'name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      ),
      (data) => RoleBranch.fromJson(data as Map<String, dynamic>),
    );
  }

  /// DELETE /api/v1/admin/branches/{branchId}
  Future<void> deleteBranch(int branchId) {
    return _api.unwrap(
      (dio) => dio.delete('/api/v1/admin/branches/$branchId'),
      (_) {},
    );
  }

  /// GET /api/v1/admin/branches/{branchId}/requirements
  Future<List<BranchRequirement>> getBranchRequirements(int branchId) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/admin/branches/$branchId/requirements'),
      (data) => (data as List<dynamic>)
          .map((e) => BranchRequirement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// POST /api/v1/admin/branches/{branchId}/requirements
  Future<void> addBranchRequirement(int branchId, int skillId, int importance) {
    return _api.unwrap(
      (dio) => dio.post(
        '/api/v1/admin/branches/$branchId/requirements',
        data: {'skillId': skillId, 'importance': importance},
      ),
      (_) {},
    );
  }

  /// PUT /api/v1/admin/branches/{branchId}/requirements/{skillId}
  Future<void> updateBranchRequirement(
    int branchId,
    int skillId,
    int importance,
  ) {
    return _api.unwrap(
      (dio) => dio.put(
        '/api/v1/admin/branches/$branchId/requirements/$skillId',
        data: {'skillId': skillId, 'importance': importance},
      ),
      (_) {},
    );
  }

  /// DELETE /api/v1/admin/branches/{branchId}/requirements/{skillId}
  Future<void> removeBranchRequirement(int branchId, int skillId) {
    return _api.unwrap(
      (dio) =>
          dio.delete('/api/v1/admin/branches/$branchId/requirements/$skillId'),
      (_) {},
    );
  }

  // --- Achievements ---

  /// GET /api/v1/admin/achievements
  Future<List<AdminAchievement>> getAchievements() {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/admin/achievements'),
      (data) => (data as List<dynamic>)
          .map((e) => AdminAchievement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// GET /api/v1/admin/achievements/{id}
  Future<AdminAchievement> getAchievement(int id) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/admin/achievements/$id'),
      (data) => AdminAchievement.fromJson(data as Map<String, dynamic>),
    );
  }

  /// POST /api/v1/admin/achievements
  Future<AdminAchievement> createAchievement({
    required String code,
    required String title,
    required String description,
    required String icon,
    required String category,
    required AchievementCriteriaType criteriaType,
    required int criteriaValue,
  }) {
    return _api.unwrap(
      (dio) => dio.post(
        '/api/v1/admin/achievements',
        data: {
          'code': code,
          'title': title,
          'description': description,
          'icon': icon,
          'category': category,
          'criteriaType': achievementCriteriaTypeToApiString(criteriaType),
          'criteriaValue': criteriaValue,
        },
      ),
      (data) => AdminAchievement.fromJson(data as Map<String, dynamic>),
    );
  }

  /// PUT /api/v1/admin/achievements/{id}
  Future<AdminAchievement> updateAchievement(
    int id, {
    required String title,
    required String description,
    required String icon,
    required String category,
    required AchievementCriteriaType criteriaType,
    required int criteriaValue,
    required bool enabled,
  }) {
    return _api.unwrap(
      (dio) => dio.put(
        '/api/v1/admin/achievements/$id',
        data: {
          'title': title,
          'description': description,
          'icon': icon,
          'category': category,
          'criteriaType': achievementCriteriaTypeToApiString(criteriaType),
          'criteriaValue': criteriaValue,
          'enabled': enabled,
        },
      ),
      (data) => AdminAchievement.fromJson(data as Map<String, dynamic>),
    );
  }

  /// DELETE /api/v1/admin/achievements/{id} — may disable instead of
  /// deleting; see [AchievementDeletionResult].
  Future<AchievementDeletionResult> deleteAchievement(int id) {
    return _api.unwrap(
      (dio) => dio.delete('/api/v1/admin/achievements/$id'),
      (data) =>
          AchievementDeletionResult.fromJson(data as Map<String, dynamic>),
    );
  }
}
