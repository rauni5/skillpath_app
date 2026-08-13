import 'package:flutter/material.dart';

import '../../../core/models/streak.dart';
import '../../../core/theme/app_palette.dart';

/// Small stat card showing the user's current/longest daily activity streak.
class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.streak});

  final Streak streak;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isActive = streak.currentStreak > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive ? p.amberLight : p.surface1,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department,
            size: 26,
            color: isActive ? p.amber : p.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${streak.currentStreak} day${streak.currentStreak == 1 ? '' : 's'} streak',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isActive ? p.amberText : p.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  streak.longestStreak > streak.currentStreak
                      ? 'Best: ${streak.longestStreak} days'
                      : isActive
                      ? "That's your best yet!"
                      : 'Complete a step today to start one',
                  style: TextStyle(fontSize: 11, color: p.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
