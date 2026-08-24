import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/assistant_chat_session.dart';
import '../../../core/router/chat_action_parser.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/chat_error_notice.dart';
import '../../../shared/widgets/chat_message_bubble.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/suggested_prompts.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/assistant_chat_provider.dart';
import '../widgets/assistant_message_widget.dart';

/// A single assistant chat conversation, full screen. If [session] isn't
/// the active (most recent) one, the input bar is replaced with a
/// read-only notice — old sessions stay readable but can't be continued.
class AssistantChatScreen extends StatefulWidget {
  const AssistantChatScreen({super.key, required this.session});

  final AssistantChatSession session;

  @override
  State<AssistantChatScreen> createState() => _AssistantChatScreenState();
}

class _AssistantChatScreenState extends State<AssistantChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _inputFocusNode = FocusNode();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _inputFocusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send({String? text}) async {
    final message = (text ?? _inputCtrl.text).trim();
    if (message.isEmpty) return;
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    _inputCtrl.clear();
    _inputFocusNode.unfocus();
    // Scroll immediately so the user's own message (and the typing bubble)
    // are visible right away, then again once the reply lands — otherwise
    // the view sits still until the whole round trip finishes.
    _scrollToBottom();
    await context.read<AssistantChatProvider>().sendMessage(userId, message);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final chat = context.watch<AssistantChatProvider>();
    final isActive = chat.currentSessionActive;

    return Scaffold(
      appBar: AppBar(title: Text(widget.session.title)),
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _buildBody(context, p, chat),
            ),
          ),
          if (isActive)
            AssistantInputBar(
              controller: _inputCtrl,
              onSend: _send,
              sending: chat.isSending,
              focusNode: _inputFocusNode,
            )
          else
            AssistantReadOnlyNotice(p: p),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppPalette p,
    AssistantChatProvider chat,
  ) {
    switch (chat.messagesState) {
      case MessagesLoadState.initial:
      case MessagesLoadState.loading:
        return const LoadingView(key: ValueKey('loading'));
      case MessagesLoadState.error:
        return ErrorView(
          key: const ValueKey('error'),
          message: chat.messagesError ?? 'Something went wrong.',
          onRetry: () {},
        );
      case MessagesLoadState.loaded:
        if (chat.messages.isEmpty) {
          return ListView(
            key: const ValueKey('empty'),
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 50),
              Icon(Icons.support_agent, size: 36, color: p.textMuted),
              const SizedBox(height: 14),
              Text(
                'Ask how to use any part of the app, or for help with your '
                'own roadmap and progress.',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              SuggestedPrompts(
                prompts: const [
                  'What should I focus on next?',
                  'How do I change my career path?',
                  'How do projects work?',
                ],
                onSelect: (prompt) => _send(text: prompt),
              ),
            ],
          );
        }
        return ListView.builder(
          key: const ValueKey('messages'),
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          itemCount:
              chat.messages.length +
              (chat.isSending ? 1 : 0) +
              (chat.hasError && !chat.isSending ? 1 : 0),
          itemBuilder: (context, i) {
            if (chat.hasError && !chat.isSending && i == chat.messages.length) {
              return ChatErrorNotice(
                message: chat.messagesError ?? 'The assistant could not reply.',
                onRetry: () {
                  final userId = context.read<AuthProvider>().currentUser?.id;
                  if (userId != null) {
                    context.read<AssistantChatProvider>().retryLastMessage(
                      userId,
                    );
                  }
                },
              );
            }
            if (i >= chat.messages.length) {
              return const ChatTypingBubble();
            }
            final user = context.watch<AuthProvider>().currentUser;
            return ChatMessageBubble(
              message: chat.messages[i],
              userAvatarUrl: user?.avatarUrl,
              userName: user?.name,
              onActionTap: (route) => navigateToChatAction(context, route),
            );
          },
        );
    }
  }
}
