import 'package:flutter/material.dart';

import '../../../core/models/role_branch.dart';
import '../../../core/theme/app_palette.dart';

class BranchCard extends StatelessWidget {
  const BranchCard({
    super.key,
    required this.branch,
    required this.isSelected,
    required this.onTap,
    this.matchScore,
    this.isTopMatch = false,
  });

  final RoleBranch branch;
  final bool isSelected;
  final VoidCallback onTap;
  final double? matchScore;
  final bool isTopMatch;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? p.indigoLight : p.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? p.indigo : p.border,
            width: isSelected ? 1.5 : 0.75,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        branch.name,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? p.indigo : p.textPrimary,
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
                  if (branch.description != null &&
                      branch.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      branch.description!,
                      style: TextStyle(fontSize: 12, color: p.textMuted),
                    ),
                  ],
                  if (matchScore != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (matchScore! / 100).clamp(0, 1),
                              minHeight: 4,
                              backgroundColor: p.border,
                              color: p.indigo,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${matchScore!.round()}% match',
                          style: TextStyle(
                            fontSize: 11,
                            color: p.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                key: ValueKey(isSelected),
                color: isSelected ? p.indigo : p.border,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
