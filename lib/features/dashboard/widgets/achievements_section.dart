import 'package:flutter/material.dart';

import '../../../core/models/achievement.dart';
import '../../../core/theme/app_palette.dart';
import 'achievement_badge.dart';

/// Horizontal row of achievement badges with an "X / Y unlocked" header.
class AchievementsSection extends StatelessWidget {
  const AchievementsSection({super.key, required this.achievements});

  final List<Achievement> achievements;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final unlocked = achievements.where((a) => a.unlocked).length;

    // Show unlocked achievements first, then locked ones.
    final sorted = [...achievements]
      ..sort((a, b) {
        if (a.unlocked == b.unlocked) return 0;
        return a.unlocked ? -1 : 1;
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Achievements',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '$unlocked / ${achievements.length}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: p.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) =>
                AchievementBadge(achievement: sorted[i]),
          ),
        ),
      ],
    );
  }
}
