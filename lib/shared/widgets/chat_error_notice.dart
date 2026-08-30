import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Shown inline in a chat's message list when an AI reply fails to come
/// back — instead of the conversation just going silent. Used by both the
/// per-skill tutor chat and the app-wide assistant chat.
class ChatErrorNotice extends StatelessWidget {
  const ChatErrorNotice({
    super.key,
    required this.message,
    required this.onRetry,
    this.isRetrying = false,
  });

  final String message;
  final VoidCallback onRetry;
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.redLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 17, color: p.red),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(fontSize: 12.5, color: p.red, height: 1.35),
                ),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: isRetrying ? null : onRetry,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isRetrying)
                          SizedBox(
                            height: 12,
                            width: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: p.red,
                            ),
                          )
                        else
                          Icon(Icons.refresh, size: 14, color: p.red),
                        const SizedBox(width: 6),
                        Text(
                          'Try again',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: p.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
