import '../../../core/models/assistant_chat_session.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/network/api_client.dart';

class AssistantChatRepository {
  final ApiClient _api = ApiClient.instance;

  /// GET /api/v1/users/{userId}/assistant-chat/sessions
  Future<List<AssistantChatSession>> listSessions(int userId) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/users/$userId/assistant-chat/sessions'),
      (data) => (data as List<dynamic>)
          .map((e) => AssistantChatSession.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// POST /api/v1/users/{userId}/assistant-chat/sessions
  Future<AssistantChatSession> createSession(int userId) {
    return _api.unwrap(
      (dio) => dio.post('/api/v1/users/$userId/assistant-chat/sessions'),
      (data) => AssistantChatSession.fromJson(data as Map<String, dynamic>),
    );
  }

  /// GET /api/v1/users/{userId}/assistant-chat/sessions/{sessionId}/messages
  Future<List<ChatMessage>> getMessages(int userId, int sessionId) {
    return _api.unwrap(
      (dio) => dio.get(
        '/api/v1/users/$userId/assistant-chat/sessions/$sessionId/messages',
      ),
      (data) => (data as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// POST /api/v1/users/{userId}/assistant-chat/sessions/{sessionId}/messages
  Future<ChatMessage> sendMessage(int userId, int sessionId, String message) {
    return _api.unwrap(
      (dio) => dio.post(
        '/api/v1/users/$userId/assistant-chat/sessions/$sessionId/messages',
        data: {'message': message},
      ),
      (data) => ChatMessage.fromJson(data as Map<String, dynamic>),
    );
  }
}
