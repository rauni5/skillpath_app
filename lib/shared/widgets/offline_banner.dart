import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// Slim banner shown at the top of a screen's content when it's displaying
/// data from the on-device cache instead of a live request — used by any
/// screen with read-only offline support (Dashboard, Career, Portfolio).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.cachedAt});

  final DateTime? cachedAt;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 16, color: p.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cachedAt != null
                  ? "You're offline — showing saved data from ${_relativeTime(cachedAt!)}."
                  : "You're offline — showing saved data.",
              style: TextStyle(fontSize: 12, color: p.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
