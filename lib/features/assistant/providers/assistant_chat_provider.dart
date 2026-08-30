import 'package:flutter/foundation.dart';

import '../../../core/models/assistant_chat_session.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/network/api_exception.dart';
import '../data/assistant_chat_repository.dart';

enum SessionsLoadState { initial, loading, loaded, error }

enum MessagesLoadState { initial, loading, loaded, error }

class AssistantChatProvider extends ChangeNotifier {
  AssistantChatProvider({AssistantChatRepository? repository})
    : _repo = repository ?? AssistantChatRepository();

  final AssistantChatRepository _repo;

  // --- Session list ---
  SessionsLoadState sessionsState = SessionsLoadState.initial;
  List<AssistantChatSession> sessions = [];
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

  Future<AssistantChatSession?> startNewSession(int userId) async {
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

  AssistantChatSession _deactivate(AssistantChatSession s) {
    return AssistantChatSession(
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

  /// True when the most recent send failed and hasn't been retried or
  /// superseded by a newer message yet — drives the inline error notice.
  bool hasError = false;
  String? _lastFailedMessage;

  Future<void> loadMessages(int userId, AssistantChatSession session) async {
    currentSessionId = session.id;
    currentSessionActive = session.active;
    messagesState = MessagesLoadState.loading;
    messages = [];
    hasError = false;
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

  /// Ensures there's an active session loaded, ready to receive a message —
  /// used by the floating bubble so tapping it never shows an empty screen
  /// waiting for the user to manually start a chat first. Reuses the
  /// existing active session if one is loaded and still active; otherwise
  /// loads the session list and either opens the latest one or creates a
  /// fresh one if this is the user's very first conversation.
  Future<void> ensureActiveSessionLoaded(int userId) async {
    if (currentSessionId != null &&
        currentSessionActive &&
        messagesState == MessagesLoadState.loaded) {
      return;
    }
    if (sessionsState != SessionsLoadState.loaded) {
      await loadSessions(userId);
    }
    final active = sessions.isNotEmpty ? sessions.first : null;
    if (active != null && active.active) {
      await loadMessages(userId, active);
    } else {
      final created = await startNewSession(userId);
      if (created != null) await loadMessages(userId, created);
    }
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
    await _attemptSend(userId, sessionId, text);
  }

  /// Resends the message from the most recent failed attempt, without
  /// adding another copy of it to the message list.
  Future<void> retryLastMessage(int userId) async {
    final sessionId = currentSessionId;
    final text = _lastFailedMessage;
    if (sessionId == null || text == null || !hasError) return;
    await _attemptSend(userId, sessionId, text);
  }

  Future<void> _attemptSend(int userId, int sessionId, String text) async {
    isSending = true;
    messagesError = null;
    hasError = false;
    notifyListeners();
    try {
      final reply = await _repo.sendMessage(userId, sessionId, text);
      messages = [...messages, reply];
      _lastFailedMessage = null;
    } catch (e) {
      messagesError = e is ApiException
          ? e.message
          : 'The assistant could not reply — please try again.';
      hasError = true;
      _lastFailedMessage = text;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }
}
