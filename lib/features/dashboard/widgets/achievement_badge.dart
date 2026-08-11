import 'package:flutter/material.dart';

import '../../../core/models/achievement.dart';
import '../../../core/theme/app_palette.dart';

/// Single achievement badge — filled/colored when unlocked, greyed out
/// when still locked. Tap to see the description.
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({super.key, required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final unlocked = achievement.unlocked;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showDetail(context, p),
      child: Container(
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: unlocked ? p.indigoLight : p.surface1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: unlocked ? p.indigo.withValues(alpha: 0.25) : p.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              achievement.iconData,
              size: 26,
              color: unlocked ? p.indigo : p.textMuted,
            ),
            const SizedBox(height: 6),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: unlocked ? p.textPrimary : p.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, AppPalette p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: achievement.unlocked ? p.indigoLight : p.surface1,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    achievement.iconData,
                    color: achievement.unlocked ? p.indigo : p.textMuted,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                      Text(
                        achievement.unlocked ? 'Unlocked' : 'Locked',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: achievement.unlocked
                              ? p.greenText
                              : p.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              achievement.description,
              style: TextStyle(
                fontSize: 13,
                color: p.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
