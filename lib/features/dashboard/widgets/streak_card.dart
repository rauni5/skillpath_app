import 'package:flutter/material.dart';

import '../../../core/models/streak.dart';
import '../../../core/theme/app_palette.dart';

/// Small stat card showing the user's current/longest daily activity streak.
/// Tappable — since the streak is built by roadmap activity, it deep-links
/// there via [onTap] rather than just sitting as a static number.
class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.streak, this.onTap});

  final Streak streak;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isActive = streak.currentStreak > 0;

    return Material(
      color: isActive ? p.amberLight : p.surface1,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
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
              if (onTap != null)
                Icon(Icons.chevron_right, size: 18, color: p.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
