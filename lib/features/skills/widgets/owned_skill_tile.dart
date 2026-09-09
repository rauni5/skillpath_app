import 'package:flutter/material.dart';

import '../../../core/models/skill.dart';
import '../../../core/theme/app_palette.dart';

extension _ProficiencyColor on SkillProficiency {
  Color color(AppPalette p) {
    switch (this) {
      case SkillProficiency.beginner:
        return p.amber;
      case SkillProficiency.intermediate:
        return p.indigo;
      case SkillProficiency.advanced:
        return p.green;
    }
  }
}

class OwnedSkillTile extends StatelessWidget {
  const OwnedSkillTile({
    super.key,
    required this.skill,
    required this.isPending,
    required this.onRemove,
    this.onChat,
  });

  final Skill skill;
  final bool isPending;
  final VoidCallback onRemove;

  /// Opens a tutor chat about this skill. Available for owned skills so a
  /// user can keep talking to the tutor about something they already
  /// know, switched away from, or picked up outside their roadmap
  /// entirely — not just while it's an active roadmap step.
  final VoidCallback? onChat;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final level = skill.proficiency;
    final accent = level?.color(p) ?? p.indigo;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Proficiency-colored accent bar instead of a plain icon, so the
          // level reads at a glance across a whole grid of tiles.
          Container(
            width: 3,
            height: 34,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Icon(skill.categoryIcon, size: 16, color: p.indigo),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                if (level != null)
                  Text(
                    level.shortLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  )
                else
                  Text(
                    skill.categoryLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: p.textMuted),
                  ),
              ],
            ),
          ),
          if (isPending)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: p.indigo),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onChat != null)
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onChat,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        size: 17,
                        color: p.textMuted,
                      ),
                    ),
                  ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onRemove,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 18, color: p.textMuted),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
