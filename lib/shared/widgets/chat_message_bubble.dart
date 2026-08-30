import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../core/models/chat_message.dart';
import '../../core/router/chat_action_parser.dart';
import '../../core/theme/app_palette.dart';
import 'chat_avatar.dart';

/// A single chat bubble, shared by the Assistant and Tutor chats. Shows an
/// avatar beside the bubble (the user's photo/initials, or a bot icon), and
/// — for assistant replies that include one — a row of "go to" buttons for
/// any `[[action:...]]` tokens found in the message.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.userAvatarUrl,
    this.userName,
    this.botIcon = Icons.support_agent,
    this.onActionTap,
  });

  final ChatMessage message;
  final String? userAvatarUrl;
  final String? userName;
  final IconData botIcon;
  final void Function(String route)? onActionTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isUser = message.role == ChatRole.user;
    final textColor = isUser ? Colors.white : p.textPrimary;
    final parsed = isUser
        ? ParsedChatMessage(message.content, const [])
        : parseChatActions(message.content);

    final avatar = ChatAvatar(
      isUser: isUser,
      avatarUrl: userAvatarUrl,
      name: userName,
      icon: botIcon,
    );

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(isUser ? 14 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 14),
    );

    // Text and any action buttons render inside one shared container —
    // same background, same border, same rounded corners — clipped as a
    // single card rather than a bubble with a separate floating pill
    // underneath, so a reply-with-button reads as one piece.
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      decoration: BoxDecoration(
        color: isUser ? p.indigo : p.surface2,
        borderRadius: borderRadius,
        border: isUser ? null : Border.all(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: MarkdownBody(
              data: parsed.text,
              shrinkWrap: true,
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                  .copyWith(
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
                      border: Border.all(
                        color: isUser ? Colors.white24 : p.border,
                      ),
                    ),
                  ),
            ),
          ),
          for (final action in parsed.actions) ...[
            Divider(height: 1, thickness: 1, color: p.border),
            _ActionRow(
              action: action,
              onTap: () => onActionTap?.call(action.route),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[avatar, const SizedBox(width: 8)],
          Flexible(child: bubble),
          if (isUser) ...[const SizedBox(width: 8), avatar],
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action, required this.onTap});

  final ChatAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        color: p.indigoLight,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              action.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: p.indigo,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward, size: 14, color: p.indigo),
          ],
        ),
      ),
    );
  }
}

/// "Typing…" bubble, matching layout so it lines up with real replies.
class ChatTypingBubble extends StatelessWidget {
  const ChatTypingBubble({
    super.key,
    this.botIcon = Icons.support_agent,
    this.label = 'Thinking…',
  });

  final IconData botIcon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChatAvatar(icon: botIcon),
          const SizedBox(width: 8),
          Container(
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
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: p.indigo,
                  ),
                ),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontSize: 12, color: p.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
