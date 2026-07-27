import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../../core/models/skill.dart';
import '../../../core/theme/app_palette.dart';

/// Opens a bottom sheet asking the user to pick a proficiency level for
/// [skill], returning the chosen level (or null if dismissed). Replaces a
/// row of tiny inline buttons with clearly-labelled, easy-to-tap options.
Future<SkillProficiency?> showAddSkillSheet(BuildContext context, Skill skill) {
  return showModalBottomSheet<SkillProficiency>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _AddSkillSheet(skill: skill),
  );
}

class _AddSkillSheet extends StatelessWidget {
  const _AddSkillSheet({required this.skill});

  final Skill skill;

  static const _descriptions = {
    SkillProficiency.beginner:
        "I've done some tutorials or small exercises with this.",
    SkillProficiency.intermediate:
        "I've built real things with this and I'm comfortable using it.",
    SkillProficiency.advanced:
        "I could mentor someone else or debug this at a deep level.",
  };

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        decoration: BoxDecoration(
          color: p.surface2,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: p.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(skill.category.icon, size: 18, color: p.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    skill.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'How comfortable are you with this?',
              style: TextStyle(fontSize: 12.5, color: p.textMuted),
            ),
            const SizedBox(height: 16),
            for (final level in SkillProficiency.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop(level);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      border: Border.all(color: p.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                level.label,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: p.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _descriptions[level]!,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: p.textMuted,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 18, color: p.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
