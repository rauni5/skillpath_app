import '../../../core/models/career_role.dart';
import '../../../core/models/role_requirement.dart';
import '../../../core/models/skill.dart';
import '../../../core/models/user.dart';
import '../../../core/network/api_client.dart';

class AdminRepository {
  final ApiClient _api = ApiClient.instance;

  /// GET /api/v1/admin/users
  Future<List<AppUser>> getUsers() {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/admin/users'),
      (data) => (data as List<dynamic>)
          .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
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

  /// GET /api/v1/admin/career-roles/{id}/requirements
  Future<List<RoleRequirement>> getRoleRequirements(int roleId) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/admin/career-roles/$roleId/requirements'),
      (data) => (data as List<dynamic>)
          .map((e) => RoleRequirement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// POST /api/v1/admin/career-roles/{id}/requirements
  Future<void> addRoleRequirement(int roleId, int skillId, int importance) {
    return _api.unwrap(
      (dio) => dio.post(
        '/api/v1/admin/career-roles/$roleId/requirements',
        data: {'skillId': skillId, 'importance': importance},
      ),
      (_) {},
    );
  }

  /// PUT /api/v1/admin/career-roles/{id}/requirements/{skillId}
  Future<void> updateRoleRequirement(int roleId, int skillId, int importance) {
    return _api.unwrap(
      (dio) => dio.put(
        '/api/v1/admin/career-roles/$roleId/requirements/$skillId',
        data: {'skillId': skillId, 'importance': importance},
      ),
      (_) {},
    );
  }

  /// DELETE /api/v1/admin/career-roles/{id}/requirements/{skillId}
  Future<void> removeRoleRequirement(int roleId, int skillId) {
    return _api.unwrap(
      (dio) => dio.delete(
        '/api/v1/admin/career-roles/$roleId/requirements/$skillId',
      ),
      (_) {},
    );
  }
}
