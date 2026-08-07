import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
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
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _load() {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      context
          .read<TutorChatProvider>()
          .loadHistory(userId, widget.skillId)
          .then((_) {
            _scrollToBottom();
            final chat = context.read<TutorChatProvider>();
            if (chat.messages.isEmpty && chat.state == ChatLoadState.loaded) {
              chat
                  .startConversationIfEmpty(
                    userId,
                    widget.skillId,
                    widget.skillName,
                  )
                  .then((_) => _scrollToBottom());
            }
          });
    }
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

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    _inputCtrl.clear();
    await context.read<TutorChatProvider>().sendMessage(
      userId,
      widget.skillId,
      text,
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
          return ListView(
            key: const ValueKey('empty'),
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 60),
              Icon(Icons.forum_outlined, size: 36, color: p.textMuted),
              const SizedBox(height: 14),
              Text(
                'Ask the tutor anything about ${widget.skillName} — concepts, examples, or where to start.',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted, fontSize: 13),
              ),
            ],
          );
        }
        return ListView.builder(
          key: const ValueKey('messages'),
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          itemCount: chat.messages.length + (chat.isSending ? 1 : 0),
          itemBuilder: (context, i) {
            if (i >= chat.messages.length) {
              return const _TypingBubble();
            }
            return _MessageBubble(message: chat.messages[i]);
          },
        );
    }
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isUser = message.role == ChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? p.indigo : p.surface2,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
          border: isUser ? null : Border.all(color: p.border),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: isUser ? Colors.white : p.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: p.surface2,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(14),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: p.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 12,
              width: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: p.indigo),
            ),
            const SizedBox(width: 8),
            Text(
              'Tutor is thinking…',
              style: TextStyle(fontSize: 12, color: p.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.sending,
  });
  final TextEditingController controller;
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
