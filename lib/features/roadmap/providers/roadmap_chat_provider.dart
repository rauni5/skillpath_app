import 'package:flutter/foundation.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/models/roadmap_chat_session.dart';
import '../../../core/network/api_exception.dart';
import '../data/roadmap_chat_repository.dart';

enum SessionsLoadState { initial, loading, loaded, error }

enum MessagesLoadState { initial, loading, loaded, error }

class RoadmapChatProvider extends ChangeNotifier {
  RoadmapChatProvider({RoadmapChatRepository? repository})
    : _repo = repository ?? RoadmapChatRepository();

  final RoadmapChatRepository _repo;

  // --- Session list ---
  SessionsLoadState sessionsState = SessionsLoadState.initial;
  List<RoadmapChatSession> sessions = [];
  String? sessionsError;

  Future<void> loadSessions(int userId) async {
    sessionsState = SessionsLoadState.loading;
    notifyListeners();
    try {
      sessions = await _repo.listSessions(userId);
      sessionsState = SessionsLoadState.loaded;
    } catch (e) {
      sessionsError = e is ApiException
          ? e.message
          : 'Could not load your chats.';
      sessionsState = SessionsLoadState.error;
    }
    notifyListeners();
  }

  Future<RoadmapChatSession?> startNewSession(int userId) async {
    try {
      final session = await _repo.createSession(userId);
      sessions = [session, ...sessions.map((s) => _deactivate(s))];
      notifyListeners();
      return session;
    } catch (e) {
      sessionsError = e is ApiException
          ? e.message
          : 'Could not start a new chat.';
      notifyListeners();
      return null;
    }
  }

  RoadmapChatSession _deactivate(RoadmapChatSession s) {
    return RoadmapChatSession(
      id: s.id,
      title: s.title,
      createdAt: s.createdAt,
      active: false,
      lastMessagePreview: s.lastMessagePreview,
    );
  }

  // --- Active conversation ---
  MessagesLoadState messagesState = MessagesLoadState.initial;
  int? currentSessionId;
  bool currentSessionActive = true;
  List<ChatMessage> messages = [];
  bool isSending = false;
  String? messagesError;

  Future<void> loadMessages(int userId, RoadmapChatSession session) async {
    currentSessionId = session.id;
    currentSessionActive = session.active;
    messagesState = MessagesLoadState.loading;
    messages = [];
    notifyListeners();
    try {
      messages = await _repo.getMessages(userId, session.id);
      messagesState = MessagesLoadState.loaded;
    } catch (e) {
      messagesError = e is ApiException
          ? e.message
          : 'Could not load this conversation.';
      messagesState = MessagesLoadState.error;
    }
    notifyListeners();
  }

  Future<void> sendMessage(int userId, String text) async {
    final sessionId = currentSessionId;
    if (sessionId == null || !currentSessionActive) return;

    final tempId = -DateTime.now().millisecondsSinceEpoch;
    messages = [
      ...messages,
      ChatMessage(
        id: tempId,
        role: ChatRole.user,
        content: text,
        createdAt: DateTime.now(),
      ),
    ];
    isSending = true;
    messagesError = null;
    notifyListeners();
    try {
      final reply = await _repo.sendMessage(userId, sessionId, text);
      messages = [...messages, reply];
    } catch (e) {
      messagesError = e is ApiException
          ? e.message
          : 'The AI could not reply — please try again.';
    } finally {
      isSending = false;
      notifyListeners();
    }
  }
}
