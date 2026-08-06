import 'package:flutter/material.dart';

import '../../../core/models/gap_analysis.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/animated_progress_bar.dart';

class GapSummaryCard extends StatelessWidget {
  const GapSummaryCard({super.key, required this.gap});

  final GapAnalysis gap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    if (!gap.hasGoalSet) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.surface1,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.flag_outlined, size: 20, color: p.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No career goal set yet.',
                style: TextStyle(fontSize: 12.5, color: p.textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.indigo,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.flag, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      gap.careerRoleName!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${gap.knownSkillCount} of ${gap.requiredSkillCount} required skills covered',

                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedProgressBar(
                value: gap.progressPercent.clamp(0, 100) / 100,
                height: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor: Colors.white,
              ),
              const SizedBox(height: 6),
              TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 0,
                  end: gap.progressPercent.clamp(0, 100).toDouble(),
                ),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Text(
                  '${value.round()}% ready',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.checklist_outlined, size: 14, color: p.textMuted),
            const SizedBox(width: 6),
            Text(
              'MISSING SKILLS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: p.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (gap.missingSkills.isEmpty)
          Row(
            children: [
              Icon(Icons.celebration_outlined, size: 16, color: p.green),
              const SizedBox(width: 6),
              Text(
                "You've got every required skill covered",
                style: TextStyle(fontSize: 12.5, color: p.textMuted),
              ),
            ],
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: gap.missingSkills.map((s) {
              // Higher importance skills get a slightly stronger visual weight.
              final isCritical = s.importance >= 4;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: isCritical ? p.redLight : p.amberLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCritical)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.priority_high,
                          size: 11,
                          color: p.red,
                        ),
                      ),
                    Text(
                      s.name,
                      style: TextStyle(
                        color: isCritical ? p.red : p.amberText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
