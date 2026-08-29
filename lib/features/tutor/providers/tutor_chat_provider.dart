import 'package:flutter/foundation.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/network/api_exception.dart';
import '../data/tutor_repository.dart';

enum ChatLoadState { initial, loading, loaded, error }

class TutorChatProvider extends ChangeNotifier {
  TutorChatProvider({TutorRepository? repository})
    : _repo = repository ?? TutorRepository();

  final TutorRepository _repo;

  int? currentSkillId;
  ChatLoadState state = ChatLoadState.initial;
  String? errorMessage;
  List<ChatMessage> messages = [];
  bool isSending = false;

  /// True when the most recent send/kickoff attempt failed and hasn't
  /// been retried or superseded by a newer message yet — drives the
  /// inline error notice with a "Try again" action.
  bool hasError = false;

  /// The prompt text behind the failed attempt, if any — kept separate
  /// from the kickoff prompt (which is never added to [messages]) so
  /// retrying resends the exact same thing rather than a fresh message.
  String? _lastFailedMessage;
  String? _kickoffSkillName;

  /// Guards against firing the auto-kickoff more than once per screen visit
  /// (e.g. if a rebuild calls startConversationIfEmpty again before the
  /// first reply has come back).
  bool _kickoffSent = false;

  Future<void> loadHistory(int userId, int skillId) async {
    currentSkillId = skillId;
    state = ChatLoadState.loading;
    messages = [];
    _kickoffSent = false;
    hasError = false;
    notifyListeners();
    try {
      messages = await _repo.getChatHistory(userId, skillId);
      state = ChatLoadState.loaded;
    } catch (e) {
      errorMessage = e is ApiException
          ? e.message
          : 'Could not load this conversation.';
      state = ChatLoadState.error;
    }
    notifyListeners();
  }

  /// Called once, right after history loads, when there's no conversation
  /// yet. Fetches the tutor's cached "welcome to this skill" message (or
  /// triggers generating + caching one, if this is the first visit anyone's
  /// made to this skill) so the tutor speaks first. If it fails, [hasError]
  /// is set so the screen can offer a retry instead of silently showing an
  /// empty chat.
  Future<void> startConversationIfEmpty(
    int userId,
    int skillId,
    String skillName,
  ) async {
    if (messages.isNotEmpty || isSending || _kickoffSent) return;
    _kickoffSkillName = skillName;
    _kickoffSent = true;
    isSending = true;
    errorMessage = null;
    hasError = false;
    notifyListeners();
    try {
      final reply = await _repo.getIntro(userId, skillId);
      messages = [...messages, reply];
    } catch (e) {
      errorMessage = e is ApiException
          ? e.message
          : 'The tutor could not reply — please try again.';
      hasError = true;
      // Allow a retry — either the explicit button or another call to
      // startConversationIfEmpty (e.g. pull-to-refresh) will re-attempt it.
      _kickoffSent = false;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(int userId, int skillId, String text) async {
    // Optimistically show the user's message — the endpoint only returns
    // the assistant's reply, so the client adds its own side of the turn.
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
    await _attemptSend(userId, skillId, text);
  }

  /// Resends the message from the most recent failed attempt, without
  /// adding another copy of it to the message list.
  Future<void> retryLastMessage(int userId, int skillId) async {
    if (!hasError) return;
    if (_lastFailedMessage != null) {
      await _attemptSend(userId, skillId, _lastFailedMessage!);
    } else if (_kickoffSkillName != null) {
      _kickoffSent = false;
      await startConversationIfEmpty(userId, skillId, _kickoffSkillName!);
    }
  }

  Future<void> _attemptSend(int userId, int skillId, String text) async {
    isSending = true;
    errorMessage = null;
    hasError = false;
    notifyListeners();
    try {
      final reply = await _repo.sendChatMessage(userId, skillId, text);
      messages = [...messages, reply];
      _lastFailedMessage = null;
    } catch (e) {
      errorMessage = e is ApiException
          ? e.message
          : 'The tutor could not reply — please try again.';
      hasError = true;
      _lastFailedMessage = text;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }
}
