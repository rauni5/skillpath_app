import '../../../core/models/skill.dart';
import '../../../core/network/api_client.dart';

class SkillsRepository {
  final ApiClient _api = ApiClient.instance;

  /// GET /api/v1/skills — the full catalog, used for search/browse when
  /// adding skills.
  Future<List<Skill>> getAllSkills() {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/skills'),
      (data) => (data as List<dynamic>).map((e) => Skill.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  /// GET /api/v1/users/{userId}/skills — the user's current skill
  /// inventory.
  Future<List<Skill>> getUserSkills(int userId) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/users/$userId/skills'),
      (data) => (data as List<dynamic>).map((e) => Skill.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  /// POST /api/v1/users/{userId}/skills
  Future<void> addSkill(int userId, int skillId, SkillProficiency proficiency) {
    return _api.unwrap(
      (dio) => dio.post(
        '/api/v1/users/$userId/skills',
        data: {'skillId': skillId, 'proficiency': skillProficiencyToApiString(proficiency)},
      ),
      (_) {},
    );
  }

  /// DELETE /api/v1/users/{userId}/skills/{skillId}
  Future<void> removeSkill(int userId, int skillId) {
    return _api.unwrap(
      (dio) => dio.delete('/api/v1/users/$userId/skills/$skillId'),
      (_) {},
    );
  }
}
