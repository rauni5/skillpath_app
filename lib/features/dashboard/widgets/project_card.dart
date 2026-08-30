import 'package:flutter/material.dart';

import '../../../core/models/project.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/elevated_card.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../projects/widgets/difficulty_badge.dart';
import 'skill_chip.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.project, this.onTap});

  final Project project;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final visibleSkills = project.requiredSkills.take(4).toList();
    final extraSkillCount =
        project.requiredSkills.length - visibleSkills.length;

    return ElevatedCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                    color: p.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(p, project.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              UserAvatar(
                avatarUrl: project.ownerAvatarUrl,
                initials: project.ownerInitials,
                radius: 10,
              ),
              const SizedBox(width: 6),
              if (project.ownerName != null && project.ownerName!.isNotEmpty)
                Flexible(
                  child: Text(
                    project.ownerName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: p.textMuted),
                  ),
                ),
              const SizedBox(width: 8),
              if (project.difficulty != null && project.difficulty!.isNotEmpty)
                DifficultyBadge(difficulty: project.difficulty),
              const SizedBox(width: 6),
              Icon(Icons.groups_outlined, size: 12, color: p.textMuted),
              const SizedBox(width: 2),
              Text(
                '${project.teamSize}',
                style: TextStyle(fontSize: 11, color: p.textMuted),
              ),
            ],
          ),
          if (project.description != null &&
              project.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              project.description!,
              style: TextStyle(
                fontSize: 12.5,
                color: p.textSecondary,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (visibleSkills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                ...visibleSkills.map(
                  (s) => SkillChipWidget(skill: s, tone: SkillChipTone.gray),
                ),
                if (extraSkillCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: p.surface1,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+$extraSkillCount',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: p.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(AppPalette p, ProjectStatus status) {
    final (bg, fg, label) = switch (status) {
      ProjectStatus.open => (p.greenLight, p.greenText, 'Open'),
      ProjectStatus.full => (p.amberLight, p.amberText, 'Full'),
      ProjectStatus.completed => (p.surface1, p.textSecondary, 'Completed'),
      ProjectStatus.cancelled => (p.redLight, p.red, 'Cancelled'),
      ProjectStatus.unknown => (p.surface1, p.textSecondary, '—'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
