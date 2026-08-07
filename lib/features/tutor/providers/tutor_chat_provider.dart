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

  /// Guards against firing the auto-kickoff more than once per screen visit
  /// (e.g. if a rebuild calls startConversationIfEmpty again before the
  /// first reply has come back).
  bool _kickoffSent = false;

  Future<void> loadHistory(int userId, int skillId) async {
    currentSkillId = skillId;
    state = ChatLoadState.loading;
    messages = [];
    _kickoffSent = false;
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
  /// yet. Sends a starter prompt on the user's behalf so the tutor speaks
  /// first — the prompt itself is never added to [messages], only the
  /// assistant's reply is, so nothing appears to have been "typed" by the
  /// user.
  Future<void> startConversationIfEmpty(
    int userId,
    int skillId,
    String skillName,
  ) async {
    if (messages.isNotEmpty || isSending || _kickoffSent) return;
    _kickoffSent = true;
    isSending = true;
    errorMessage = null;
    notifyListeners();
    try {
      final reply = await _repo.sendChatMessage(
        userId,
        skillId,
        "Hi! I'm ready to start learning $skillName — please introduce "
        'the topic and suggest where we should begin.',
      );
      messages = [...messages, reply];
    } catch (e) {
      errorMessage = e is ApiException
          ? e.message
          : 'The tutor could not reply — please try again.';
      // Allow a retry (e.g. via pull-to-refresh) if the kickoff failed.
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
    isSending = true;
    errorMessage = null;
    notifyListeners();
    try {
      final reply = await _repo.sendChatMessage(userId, skillId, text);
      messages = [...messages, reply];
    } catch (e) {
      errorMessage = e is ApiException
          ? e.message
          : 'The tutor could not reply — please try again.';
    } finally {
      isSending = false;
      notifyListeners();
    }
  }
}
