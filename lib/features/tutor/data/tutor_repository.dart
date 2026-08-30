import '../../../core/models/chat_message.dart';
import '../../../core/models/skill_check_question.dart';
import '../../../core/models/skill_check_result.dart';
import '../../../core/network/api_client.dart';

class TutorRepository {
  final ApiClient _api = ApiClient.instance;

  /// GET /api/v1/users/{userId}/skills/{skillId}/chat
  Future<List<ChatMessage>> getChatHistory(int userId, int skillId) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/users/$userId/skills/$skillId/chat'),
      (data) => (data as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// POST /api/v1/users/{userId}/skills/{skillId}/chat/intro — serves a
  /// cached "welcome to this skill" message (or generates + caches one if
  /// this is the first time anyone's opened this skill's tutor chat).
  Future<ChatMessage> getIntro(int userId, int skillId) {
    return _api.unwrap(
      (dio) => dio.post('/api/v1/users/$userId/skills/$skillId/chat/intro'),
      (data) => ChatMessage.fromJson(data as Map<String, dynamic>),
    );
  }

  /// POST /api/v1/users/{userId}/skills/{skillId}/chat
  Future<ChatMessage> sendChatMessage(int userId, int skillId, String message) {
    return _api.unwrap(
      (dio) => dio.post(
        '/api/v1/users/$userId/skills/$skillId/chat',
        data: {'message': message},
      ),
      (data) => ChatMessage.fromJson(data as Map<String, dynamic>),
    );
  }

  /// POST /api/v1/users/{userId}/skills/{skillId}/skill-check/generate
  Future<SkillCheckGenerateResult> generateSkillCheck(int userId, int skillId) {
    return _api.unwrap(
      (dio) => dio.post(
        '/api/v1/users/$userId/skills/$skillId/skill-check/generate',
      ),
      (data) => SkillCheckGenerateResult.fromJson(data as Map<String, dynamic>),
    );
  }

  /// POST /api/v1/users/{userId}/skills/{skillId}/skill-check/submit
  Future<SkillCheckResult> submitSkillCheck(
    int userId,
    int skillId, {
    required int attemptId,
    required List<int> answers,
  }) {
    return _api.unwrap(
      (dio) => dio.post(
        '/api/v1/users/$userId/skills/$skillId/skill-check/submit',
        data: {'attemptId': attemptId, 'answers': answers},
      ),
      (data) => SkillCheckResult.fromJson(data as Map<String, dynamic>),
    );
  }
}
