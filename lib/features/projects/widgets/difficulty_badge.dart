import 'package:flutter/material.dart';

import '../../../core/models/skill.dart';
import '../../../core/theme/app_palette.dart';

class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({super.key, required this.difficulty});

  final String? difficulty;

  @override
  Widget build(BuildContext context) {
    if (difficulty == null || difficulty!.isEmpty) {
      return const SizedBox.shrink();
    }
    final p = AppPalette.of(context);
    final (bg, fg) = switch (difficulty!.toLowerCase()) {
      'beginner' => (p.greenLight, p.greenText),
      'advanced' => (p.redLight, p.red),
      _ => (p.amberLight, p.amberText),
    };
    final label = skillProficiencyFromString(difficulty!.toUpperCase()).label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
