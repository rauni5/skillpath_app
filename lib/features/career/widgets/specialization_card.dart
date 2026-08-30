import 'package:flutter/material.dart';

import '../../../core/models/branch_recommendation.dart';
import '../../../core/models/role_branch.dart';
import '../../../core/theme/app_palette.dart';

class SpecializationCard extends StatelessWidget {
  const SpecializationCard({
    super.key,
    required this.branch,
    required this.onTap,
    this.recommendation,
    this.isTopMatch = false,
  });

  final RoleBranch branch;
  final VoidCallback onTap;
  final BranchRecommendation? recommendation;
  final bool isTopMatch;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final score = recommendation?.matchScore;
    final known = recommendation?.knownSkills ?? const [];
    final missing = recommendation?.missingSkills ?? const [];

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.border, width: 0.75),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        branch.name,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary,
                        ),
                      ),
                      if (isTopMatch) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: p.greenLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Best match',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: p.greenText,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: p.textMuted, size: 20),
              ],
            ),
            if (branch.description != null &&
                branch.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                branch.description!,
                style: TextStyle(fontSize: 12, color: p.textMuted),
              ),
            ],
            if (score != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (score / 100).clamp(0, 1),
                        minHeight: 4,
                        backgroundColor: p.border,
                        color: p.indigo,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${score.round()}% match',
                    style: TextStyle(
                      fontSize: 11,
                      color: p.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            if (known.isNotEmpty || missing.isNotEmpty) ...[
              const SizedBox(height: 10),
              if (known.isNotEmpty) ...[
                Text(
                  'You know',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: p.textMuted,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: known
                      .map((s) => _chip(s.name, p.greenLight, p.greenText))
                      .toList(),
                ),
                if (missing.isNotEmpty) const SizedBox(height: 8),
              ],
              if (missing.isNotEmpty) ...[
                Text(
                  "You'll need",
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: p.textMuted,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: missing
                      .map((s) => _chip(s.name, p.amberLight, p.amberText))
                      .toList(),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500),
      ),
    );
  }
}
