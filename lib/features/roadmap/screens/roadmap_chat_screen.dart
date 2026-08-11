import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/models/roadmap_chat_session.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/roadmap_chat_provider.dart';

/// A single roadmap-chat conversation. If [session] isn't the active
/// (most recent) one, the input bar is replaced with a read-only notice.
class RoadmapChatScreen extends StatefulWidget {
  const RoadmapChatScreen({super.key, required this.session});

  final RoadmapChatSession session;

  @override
  State<RoadmapChatScreen> createState() => _RoadmapChatScreenState();
}

class _RoadmapChatScreenState extends State<RoadmapChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
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

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    _inputCtrl.clear();
    await context.read<RoadmapChatProvider>().sendMessage(userId, text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final chat = context.watch<RoadmapChatProvider>();
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
            _InputBar(
              controller: _inputCtrl,
              onSend: _send,
              sending: chat.isSending,
            )
          else
            _ReadOnlyNotice(p: p),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppPalette p,
    RoadmapChatProvider chat,
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
              const SizedBox(height: 60),
              Icon(Icons.map_outlined, size: 36, color: p.textMuted),
              const SizedBox(height: 14),
              Text(
                'Ask about your roadmap as a whole — what to focus on, how '
                'skills connect, or anything else on your mind.',
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
              'Thinking…',
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
                  hintText: 'Ask about your roadmap…',
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

/// Shown instead of the input bar for any session that isn't the active
/// (most recent) one — old chats stay readable but can't be continued.
class _ReadOnlyNotice extends StatelessWidget {
  const _ReadOnlyNotice({required this.p});
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface1,
          border: Border(top: BorderSide(color: p.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 15, color: p.textMuted),
            const SizedBox(width: 6),
            Text(
              'This chat is read-only — start a new chat to keep talking.',
              style: TextStyle(fontSize: 12, color: p.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
