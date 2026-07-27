import '../../../core/models/page_projects.dart';
import '../../../core/models/project.dart';
import '../../../core/models/recommended_member.dart';
import '../../../core/network/api_client.dart';

class ProjectsRepository {
  final ApiClient _api = ApiClient.instance;

  /// GET /api/v1/projects — paginated, 20 per page by default.
  Future<Page<Project>> getProjects({int page = 0, int size = 20}) {
    return _api.unwrap(
      (dio) => dio.get(
        '/api/v1/projects',
        queryParameters: {'page': page, 'size': size},
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

  /// GET /api/v1/projects/{id}/recommended-members
  Future<List<RecommendedMember>> getRecommendedMembers(int id) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/projects/$id/recommended-members'),
      (data) => (data as List<dynamic>)
          .map((e) => RecommendedMember.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
