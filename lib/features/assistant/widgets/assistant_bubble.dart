import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import 'assistant_chat_sheet.dart';

class AssistantBubble extends StatelessWidget {
  const AssistantBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Positioned(
      right: 16,
      bottom: 16,
      child: Material(
        color: p.indigo,
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => showAssistantChatSheet(context),
          child: const Padding(
            padding: EdgeInsets.all(15),
            child: Icon(Icons.support_agent, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
