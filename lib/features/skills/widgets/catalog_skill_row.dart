import 'package:flutter/material.dart';

import '../../../core/models/skill.dart';
import '../../../core/theme/app_colors.dart';
import 'add_skill_sheet.dart';

class CatalogSkillRow extends StatelessWidget {
  const CatalogSkillRow({
    super.key,
    required this.skill,
    required this.isPending,
    required this.onAdd,
  });

  final Skill skill;
  final bool isPending;
  final void Function(SkillProficiency proficiency) onAdd;

  Future<void> _handleTap(BuildContext context) async {
    final level = await showAddSkillSheet(context, skill);
    if (level != null) onAdd(level);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: isPending ? null : () => _handleTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(skill.category.icon, size: 17, color: AppColors.indigo),
            const SizedBox(width: 10),
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
            const SizedBox(width: 8),
            if (isPending)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.indigo),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.indigoLight, borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: AppColors.indigo),
                    SizedBox(width: 3),
                    Text('Add', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.indigo)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
