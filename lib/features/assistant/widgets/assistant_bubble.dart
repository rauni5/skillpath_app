import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import 'assistant_chat_sheet.dart';

class AssistantBubble extends StatefulWidget {
  const AssistantBubble({super.key, required this.bounds});

  final Size bounds;

  @override
  State<AssistantBubble> createState() => _AssistantBubbleState();
}

class _AssistantBubbleState extends State<AssistantBubble> {
  static const _size = 54.0;
  static const _margin = 12.0;
  // Below this total finger movement, a release counts as a tap (opens
  // the assistant) rather than a drag - without this, tiny jitter during
  // an intended tap would nudge the bubble instead of opening the sheet.
  static const _tapSlop = 6.0;

  // Fractional (0..1) position so it stays sensible across screen sizes
  // and orientation changes. Starts bottom-right.
  double _fx = 1.0;
  double _fy = 0.86;
  bool _dragging = false;
  double _dragDistance = 0;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final w = widget.bounds.width;
    final h = widget.bounds.height;

    final maxX = (w - _size - _margin).clamp(_margin, double.infinity);
    final maxY = (h - _size - _margin).clamp(_margin, double.infinity);
    final x = (_fx * w).clamp(_margin, maxX);
    final y = (_fy * h).clamp(_margin, maxY);

    return AnimatedPositioned(
      duration: _dragging ? Duration.zero : const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      left: x,
      top: y,
      child: GestureDetector(
        onPanStart: (_) {
          _dragDistance = 0;
          setState(() => _dragging = true);
        },
        onPanUpdate: (details) {
          _dragDistance += details.delta.distance;
          setState(() {
            _fx = ((x + details.delta.dx) / w).clamp(0.0, 1.0);
            _fy = ((y + details.delta.dy) / h).clamp(0.0, 1.0);
          });
        },
        onPanEnd: (_) {
          final wasTap = _dragDistance < _tapSlop;
          setState(() {
            _dragging = false;
            if (!wasTap) {
              _fx = _fx < 0.5 ? 0.0 : 1.0;
            }
          });
          if (wasTap) showAssistantChatSheet(context);
        },
        child: Material(
          color: p.indigo,
          shape: const CircleBorder(),
          elevation: _dragging ? 8 : 4,
          child: const Padding(
            padding: EdgeInsets.all(15),
            child: Icon(Icons.support_agent, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
