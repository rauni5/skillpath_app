import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'chat_action_routes.dart';

class ChatAction {
  const ChatAction(this.route, this.label);
  final String route;
  final String label;
}

class ParsedChatMessage {
  const ParsedChatMessage(this.text, this.actions);
  final String text;
  final List<ChatAction> actions;
}

final _actionTokenPattern = RegExp(r'\[\[action:([^\|\]]+)\|([^\]]+)\]\]');

/// Extracts `[[action:/route|Button label]]` tokens from a raw message,
/// returning the cleaned display text plus the list of valid actions.
///
/// Only routes present in [kChatActionRoutes] are kept — an unrecognized
/// route is dropped (but its token is still stripped from the visible
/// text) rather than risking a button that leads nowhere.
ParsedChatMessage parseChatActions(String content) {
  final actions = <ChatAction>[];
  for (final match in _actionTokenPattern.allMatches(content)) {
    final route = match.group(1)!.trim();
    final label = match.group(2)!.trim();
    if (kChatActionRoutes.containsKey(route) && label.isNotEmpty) {
      actions.add(ChatAction(route, label));
    }
  }
  final cleaned = content.replaceAll(_actionTokenPattern, '').trimRight();
  return ParsedChatMessage(cleaned, actions);
}

/// Navigates to a chat action's route the "correct" way for what it is: a
/// bottom-nav tab switches the active tab in place via `go()`, while
/// anything else is a normal standalone screen reached via `push()` (so it
/// gets its own back arrow, same as everywhere else it's linked to).
void navigateToChatAction(BuildContext context, String route) {
  if (kChatActionShellTabs.contains(route)) {
    goToShellRoute(context, route);
  } else {
    context.push(route);
  }
}

void goToShellRoute(BuildContext context, String route) {
  Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
  context.go(route);
}
