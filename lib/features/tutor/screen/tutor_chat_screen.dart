import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/chat_error_notice.dart';
import '../../../shared/widgets/chat_message_bubble.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/suggested_prompts.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/tutor_chat_provider.dart';

class TutorChatScreen extends StatefulWidget {
  const TutorChatScreen({
    super.key,
    required this.skillId,
    required this.skillName,
  });

  final int skillId;
  final String skillName;

  @override
  State<TutorChatScreen> createState() => _TutorChatScreenState();
}

class _TutorChatScreenState extends State<TutorChatScreen> {
  final _inputCtrl = TextEditingController();
  final _inputFocusNode = FocusNode();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _inputFocusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _load() {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    final chat = context.read<TutorChatProvider>();

    chat.loadHistory(userId, widget.skillId).then((_) {
      if (!mounted) return;
      _scrollToBottom();
      if (chat.messages.isEmpty && chat.state == ChatLoadState.loaded) {
        chat
            .startConversationIfEmpty(userId, widget.skillId, widget.skillName)
            .then((_) {
              if (mounted) _scrollToBottom();
            });
      }
    });
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
    await context.read<TutorChatProvider>().sendMessage(
      userId,
      widget.skillId,
      message,
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final chat = context.watch<TutorChatProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('Tutor · ${widget.skillName}')),
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _buildBody(context, p, chat),
            ),
          ),
          _InputBar(
            controller: _inputCtrl,
            focusNode: _inputFocusNode,
            onSend: _send,
            sending: chat.isSending,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppPalette p,
    TutorChatProvider chat,
  ) {
    switch (chat.state) {
      case ChatLoadState.initial:
      case ChatLoadState.loading:
        return const LoadingView(key: ValueKey('loading'));
      case ChatLoadState.error:
        return ErrorView(
          key: const ValueKey('error'),
          message: chat.errorMessage ?? 'Something went wrong.',
          onRetry: _load,
        );
      case ChatLoadState.loaded:
        if (chat.messages.isEmpty && !chat.isSending) {
          if (chat.hasError) {
            return ListView(
              key: const ValueKey('kickoff-error'),
              padding: const EdgeInsets.all(14),
              children: [
                ChatErrorNotice(
                  message: chat.errorMessage ?? 'The tutor could not reply.',
                  onRetry: () {
                    final userId = context.read<AuthProvider>().currentUser?.id;
                    if (userId != null) {
                      context.read<TutorChatProvider>().retryLastMessage(
                        userId,
                        widget.skillId,
                      );
                    }
                  },
                  isRetrying: chat.isSending,
                ),
              ],
            );
          }
          return ListView(
            key: const ValueKey('empty'),
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 50),
              Icon(Icons.forum_outlined, size: 36, color: p.textMuted),
              const SizedBox(height: 14),
              Text(
                'Ask the tutor anything about ${widget.skillName} — concepts, examples, or where to start.',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              SuggestedPrompts(
                prompts: [
                  'Explain ${widget.skillName} like I\'m new to it',
                  'What should I practice first?',
                  'Give me a quick example',
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
                message: chat.errorMessage ?? 'The tutor could not reply.',
                onRetry: () {
                  final userId = context.read<AuthProvider>().currentUser?.id;
                  if (userId != null) {
                    context.read<TutorChatProvider>().retryLastMessage(
                      userId,
                      widget.skillId,
                    );
                  }
                },
              );
            }
            if (i >= chat.messages.length) {
              return const ChatTypingBubble(
                botIcon: Icons.school_outlined,
                label: 'Tutor is thinking…',
              );
            }
            final user = context.watch<AuthProvider>().currentUser;
            return ChatMessageBubble(
              message: chat.messages[i],
              userAvatarUrl: user?.avatarUrl,
              userName: user?.name,
              botIcon: Icons.school_outlined,
            );
          },
        );
    }
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.sending,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: p.surface1,
          border: Border(top: BorderSide(color: p.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => sending ? null : onSend(),
                decoration: const InputDecoration(
                  hintText: 'Ask the tutor…',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: sending ? null : onSend,
              style: IconButton.styleFrom(
                backgroundColor: p.indigo,
                disabledBackgroundColor: p.border,
              ),
              icon: const Icon(Icons.arrow_upward, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
