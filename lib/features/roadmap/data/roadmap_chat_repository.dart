import '../../../core/models/chat_message.dart';
import '../../../core/models/roadmap_chat_session.dart';
import '../../../core/network/api_client.dart';

/// General, roadmap-wide AI chat (as opposed to the per-skill tutor chat),
/// organized into multiple sessions. Only the most recently created session
/// accepts new messages — older ones are readable history.
class RoadmapChatRepository {
  final ApiClient _api = ApiClient.instance;

  /// GET /api/v1/users/{userId}/roadmap-chat/sessions
  Future<List<RoadmapChatSession>> listSessions(int userId) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/users/$userId/roadmap-chat/sessions'),
      (data) => (data as List<dynamic>)
          .map((e) => RoadmapChatSession.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// POST /api/v1/users/{userId}/roadmap-chat/sessions
  Future<RoadmapChatSession> createSession(int userId) {
    return _api.unwrap(
      (dio) => dio.post('/api/v1/users/$userId/roadmap-chat/sessions'),
      (data) => RoadmapChatSession.fromJson(data as Map<String, dynamic>),
    );
  }

  /// GET /api/v1/users/{userId}/roadmap-chat/sessions/{sessionId}/messages
  Future<List<ChatMessage>> getMessages(int userId, int sessionId) {
    return _api.unwrap(
      (dio) => dio.get(
        '/api/v1/users/$userId/roadmap-chat/sessions/$sessionId/messages',
      ),
      (data) => (data as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// POST /api/v1/users/{userId}/roadmap-chat/sessions/{sessionId}/messages
  Future<ChatMessage> sendMessage(int userId, int sessionId, String message) {
    return _api.unwrap(
      (dio) => dio.post(
        '/api/v1/users/$userId/roadmap-chat/sessions/$sessionId/messages',
        data: {'message': message},
      ),
      (data) => ChatMessage.fromJson(data as Map<String, dynamic>),
    );
  }
}
