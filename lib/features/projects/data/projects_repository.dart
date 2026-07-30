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
  /// [q]: name search (prefix match, backed by the server-side trie).
  Future<Page<Project>> getProjects({
    int page = 0,
    int size = 20,
    String? difficulty,
    List<int>? skillIds,
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
    required int teamSize,
    required List<int> requiredSkillIds,
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
          'teamSize': teamSize,
          'requiredSkillIds': requiredSkillIds,
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

  /// GET /api/v1/projects/{id}/members — owner only. Pending + accepted.
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
}
