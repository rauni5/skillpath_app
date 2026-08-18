import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/chat_error_notice.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/assistant_chat_provider.dart';
import 'assistant_message_widget.dart';

/// Opens the quick-access assistant chat as a near-fullscreen modal sheet
/// over whatever screen the user is currently on. Always binds to the
/// user's active session, auto-creating one on first use — this is meant
/// to feel instant, not like navigating to a new page.
void showAssistantChatSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AssistantChatSheet(),
  );
}

class _AssistantChatSheet extends StatefulWidget {
  const _AssistantChatSheet();

  @override
  State<_AssistantChatSheet> createState() => _AssistantChatSheetState();
}

class _AssistantChatSheetState extends State<_AssistantChatSheet> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _inputFocusNode = FocusNode();
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    await context.read<AssistantChatProvider>().ensureActiveSessionLoaded(
      userId,
    );
    if (mounted) setState(() => _initializing = false);
    _scrollToBottom();
  }

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

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    _inputFocusNode.unfocus();
    _inputCtrl.clear();
    await context.read<AssistantChatProvider>().sendMessage(userId, text);
    _scrollToBottom();
  }

  void _openHistory() {
    Navigator.of(context).pop(); // close the sheet first
    context.push('/assistant');
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final chat = context.watch<AssistantChatProvider>();
    final mq = MediaQuery.of(context);
    final keyboardInset = mq.viewInsets.bottom;
    // Shrinking the sheet by exactly the keyboard height (instead of
    // leaving it a fixed size and letting the keyboard cover the bottom
    // of it) keeps the header pinned in place and the input bar sitting
    // right above the keyboard rather than hidden underneath it —
    // showModalBottomSheet doesn't apply keyboard insets automatically,
    // unlike a normal Scaffold.
    final sheetHeight = (mq.size.height * 0.85 - keyboardInset).clamp(
      mq.size.height * 0.4,
      mq.size.height * 0.85,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: p.surface1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: p.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.support_agent, size: 18, color: p.indigo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SkillPath Assistant',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Chat history',
                    icon: const Icon(Icons.history, size: 20),
                    onPressed: _openHistory,
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildBody(context, p, chat)),
            AssistantInputBar(
              controller: _inputCtrl,
              onSend: _send,
              sending: chat.isSending,
              hintText: 'Ask how to use SkillPath…',
              focusNode: _inputFocusNode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppPalette p,
    AssistantChatProvider chat,
  ) {
    if (_initializing || chat.messagesState == MessagesLoadState.loading) {
      return const Center(
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (chat.messagesState == MessagesLoadState.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            chat.messagesError ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textMuted, fontSize: 13),
          ),
        ),
      );
    }
    if (chat.messages.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 30),
          Icon(Icons.support_agent, size: 32, color: p.textMuted),
          const SizedBox(height: 12),
          Text(
            'Ask me anything about using SkillPath — how a feature works, '
            'or for help with your own roadmap and progress.',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textMuted, fontSize: 13),
          ),
        ],
      );
    }
    return ListView.builder(
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
                context.read<AssistantChatProvider>().retryLastMessage(userId);
              }
            },
          );
        }
        if (i >= chat.messages.length) {
          return const AssistantTypingBubble();
        }
        return AssistantMessageBubble(message: chat.messages[i]);
      },
    );
  }
}
