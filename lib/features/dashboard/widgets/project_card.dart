import 'package:flutter/material.dart';

import '../../../core/models/project.dart';
import '../../../core/theme/app_colors.dart';
import 'skill_chip.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.project, this.onTap});

  final Project project;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _statusBadge(project.status),
                ],
              ),
              if (project.description != null && project.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  project.description!,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (project.requiredSkills.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: project.requiredSkills
                      .take(4)
                      .map((s) => SkillChipWidget(skill: s, tone: SkillChipTone.gray))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(ProjectStatus status) {
    final (bg, fg, label) = switch (status) {
      ProjectStatus.open => (AppColors.greenLight, AppColors.greenText, 'Open'),
      ProjectStatus.full => (AppColors.amberLight, AppColors.amberText, 'Full'),
      ProjectStatus.completed => (AppColors.surface1, AppColors.textSecondary, 'Completed'),
      ProjectStatus.cancelled => (AppColors.redLight, AppColors.red, 'Cancelled'),
      ProjectStatus.unknown => (AppColors.surface1, AppColors.textSecondary, '—'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
