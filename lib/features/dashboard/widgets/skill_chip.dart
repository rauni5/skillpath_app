import 'package:flutter/material.dart';

import '../../../core/models/skill.dart';
import '../../../core/theme/app_palette.dart';

enum SkillChipTone { indigo, green, amber, gray }

/// Small pill-shaped chip matching the mockup's `.skill-chip` variants.
class SkillChipWidget extends StatelessWidget {
  const SkillChipWidget({
    super.key,
    required this.skill,
    this.tone = SkillChipTone.indigo,
    this.trailing,
  });

  final Skill skill;
  final SkillChipTone tone;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colorsFor(AppPalette.of(context), tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            skill.name,
            style: TextStyle(
              color: fg,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 4), trailing!],
        ],
      ),
    );
  }

  (Color, Color) _colorsFor(AppPalette p, SkillChipTone tone) {
    switch (tone) {
      case SkillChipTone.indigo:
        return (p.indigoLight, p.indigo);
      case SkillChipTone.green:
        return (p.greenLight, p.greenText);
      case SkillChipTone.amber:
        return (p.amberLight, p.amberText);
      case SkillChipTone.gray:
        return (p.surface1, p.textSecondary);
    }
  }
}
