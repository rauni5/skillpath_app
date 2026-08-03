import '../../../core/models/page_projects.dart';
import '../../../core/models/project.dart';
import '../../../core/models/project_member.dart';
import '../../../core/models/recommended_member.dart';
import '../../../core/network/api_client.dart';

class ProjectsRepository {
  final ApiClient _api = ApiClient.instance;

  /// GET /api/v1/projects — paginated, 20 per page by default.
  /// [difficulty]: 'BEGINNER' | 'INTERMEDIATE' | 'ADVANCED' (uppercase, matches stored values).
  /// [skillIds]: returns projects requiring at least one of these skills.
  /// [roleIds]: returns projects targeting at least one of these career roles.
  /// [q]: name search (case-insensitive substring match).
  Future<Page<Project>> getProjects({
    int page = 0,
    int size = 20,
    String? difficulty,
    List<int>? skillIds,
    List<int>? roleIds,
    String? q,
  }) {
    return _api.unwrap(
      (dio) => dio.get(
        '/api/v1/projects',
        queryParameters: {
          'page': page,
          'size': size,
          if (difficulty != null && difficulty.isNotEmpty)
            'difficulty': difficulty,
          if (skillIds != null && skillIds.isNotEmpty) 'skillIds': skillIds,
          if (roleIds != null && roleIds.isNotEmpty) 'roleIds': roleIds,
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        },
      ),
      (data) => Page<Project>.fromJson(
        data as Map<String, dynamic>,
        Project.fromJson,
      ),
    );
  }

  /// GET /api/v1/projects/{id}
  Future<Project> getProject(int id) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/projects/$id'),
      (data) => Project.fromJson(data as Map<String, dynamic>),
    );
  }

  /// POST /api/v1/projects
  Future<Project> createProject({
    required String name,
    String? description,
    String? difficulty,
    String? link,
    required int teamSize,
    required List<int> requiredSkillIds,
    List<int>? requiredRoleIds,
  }) {
    return _api.unwrap(
      (dio) => dio.post(
        '/api/v1/projects',
        data: {
          'name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (difficulty != null && difficulty.isNotEmpty)
            'difficulty': difficulty,
          if (link != null && link.trim().isNotEmpty) 'link': link.trim(),
          'teamSize': teamSize,
          'requiredSkillIds': requiredSkillIds,
          if (requiredRoleIds != null && requiredRoleIds.isNotEmpty)
            'requiredRoleIds': requiredRoleIds,
        },
      ),
      (data) => Project.fromJson(data as Map<String, dynamic>),
    );
  }

  /// PUT /api/v1/projects/{id} — owner only. Full replace of skills/roles.
  Future<Project> updateProject({
    required int projectId,
    required String name,
    String? description,
    String? difficulty,
    String? link,
    required int teamSize,
    required List<int> requiredSkillIds,
    List<int>? requiredRoleIds,
  }) {
    return _api.unwrap(
      (dio) => dio.put(
        '/api/v1/projects/$projectId',
        data: {
          'name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (difficulty != null && difficulty.isNotEmpty)
            'difficulty': difficulty,
          if (link != null && link.trim().isNotEmpty) 'link': link.trim(),
          'teamSize': teamSize,
          'requiredSkillIds': requiredSkillIds,
          if (requiredRoleIds != null) 'requiredRoleIds': requiredRoleIds,
        },
      ),
      (data) => Project.fromJson(data as Map<String, dynamic>),
    );
  }

  /// POST /api/v1/projects/{id}/join
  Future<void> joinProject(int id) {
    return _api.unwrap((dio) => dio.post('/api/v1/projects/$id/join'), (_) {});
  }

  /// GET /api/v1/projects/{id}/recommended-members — owner only.
  Future<List<RecommendedMember>> getRecommendedMembers(int id) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/projects/$id/recommended-members'),
      (data) => (data as List<dynamic>)
          .map((e) => RecommendedMember.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// GET /api/v1/users/{userId}/projects — projects owned by this user.
  Future<Page<Project>> getOwnedProjects(
    int userId, {
    int page = 0,
    int size = 20,
  }) {
    return _api.unwrap(
      (dio) => dio.get(
        '/api/v1/users/$userId/projects',
        queryParameters: {'page': page, 'size': size},
      ),
      (data) => Page<Project>.fromJson(
        data as Map<String, dynamic>,
        Project.fromJson,
      ),
    );
  }

  /// GET /api/v1/projects/{id}/members — owner only. Pending + accepted,
  /// excluding the owner's own row (they always appear separately).
  Future<List<ProjectMember>> getMembers(int projectId) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/projects/$projectId/members'),
      (data) => (data as List<dynamic>)
          .map((e) => ProjectMember.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// PATCH /api/v1/projects/{id}/members/{userId} — owner only.
  Future<void> updateMemberStatus(int projectId, int userId, String status) {
    return _api.unwrap(
      (dio) => dio.patch(
        '/api/v1/projects/$projectId/members/$userId',
        data: {'status': status},
      ),
      (_) {},
    );
  }

  /// DELETE /api/v1/projects/{id}/members/{userId} — owner only. Removes an
  /// accepted member or rejects/withdraws a pending request outright.
  Future<void> removeMember(int projectId, int userId) {
    return _api.unwrap(
      (dio) => dio.delete('/api/v1/projects/$projectId/members/$userId'),
      (_) {},
    );
  }

  /// GET /api/v1/projects/{id}/team — accepted members + owner, visible to
  /// the owner or any accepted member. Emails are included only when the
  /// viewer is the owner (null for everyone else).
  Future<List<ProjectMember>> getTeam(int projectId) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/projects/$projectId/team'),
      (data) => (data as List<dynamic>)
          .map((e) => ProjectMember.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// POST /api/v1/projects/{id}/invite/{userId} — owner only.
  Future<void> inviteMember(int projectId, int userId) {
    return _api.unwrap(
      (dio) => dio.post('/api/v1/projects/$projectId/invite/$userId'),
      (_) {},
    );
  }

  /// GET /api/v1/users/{userId}/invites — pending invites for this user.
  Future<List<ProjectInvite>> getMyInvites(int userId) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/users/$userId/invites'),
      (data) => (data as List<dynamic>)
          .map((e) => ProjectInvite.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// PATCH /api/v1/users/{userId}/invites/{projectId}
  Future<void> respondToInvite(int userId, int projectId, String status) {
    return _api.unwrap(
      (dio) => dio.patch(
        '/api/v1/users/$userId/invites/$projectId',
        data: {'status': status},
      ),
      (_) {},
    );
  }

  /// GET /api/v1/users/{userId}/memberships — this user's own join
  /// requests/invites at any status, used to detect accept/reject changes.
  Future<List<MembershipStatusEntry>> getMyMemberships(int userId) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/users/$userId/memberships'),
      (data) => (data as List<dynamic>)
          .map((e) => MembershipStatusEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
