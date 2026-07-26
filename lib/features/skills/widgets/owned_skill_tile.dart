import 'package:flutter/material.dart';

import '../../../core/models/skill.dart';
import '../../../core/theme/app_colors.dart';

class OwnedSkillTile extends StatelessWidget {
  const OwnedSkillTile({super.key, required this.skill, required this.isPending, required this.onRemove});

  final Skill skill;
  final bool isPending;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(skill.category.icon, size: 16, color: AppColors.indigo),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(skill.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(skill.category.label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (isPending)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.indigo),
            )
          else
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 18, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}
