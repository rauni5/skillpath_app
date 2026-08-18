import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/theme/app_palette.dart';

class AssistantMessageBubble extends StatelessWidget {
  const AssistantMessageBubble({super.key, required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isUser = message.role == ChatRole.user;
    final textColor = isUser ? Colors.white : p.textPrimary;

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
        child: MarkdownBody(
          data: message.content,
          shrinkWrap: true,
          selectable: true,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: TextStyle(fontSize: 13.5, height: 1.4, color: textColor),
            strong: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
            em: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: textColor,
              fontStyle: FontStyle.italic,
            ),
            listBullet: TextStyle(fontSize: 13.5, color: textColor),
            code: TextStyle(
              fontSize: 12.5,
              color: isUser ? Colors.white : p.indigo,
              backgroundColor: isUser ? Colors.white12 : p.surface1,
            ),
            codeblockDecoration: BoxDecoration(
              color: isUser ? Colors.white10 : p.surface1,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isUser ? Colors.white24 : p.border),
            ),
          ),
        ),
      ),
    );
  }
}

class AssistantTypingBubble extends StatelessWidget {
  const AssistantTypingBubble({super.key});

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

class AssistantInputBar extends StatelessWidget {
  const AssistantInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.sending,
    this.hintText = 'Ask the assistant…',
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool sending;
  final String hintText;

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
                decoration: InputDecoration(
                  hintText: hintText,
                  isDense: true,
                  border: const OutlineInputBorder(),
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

class AssistantReadOnlyNotice extends StatelessWidget {
  const AssistantReadOnlyNotice({super.key, required this.p});
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
