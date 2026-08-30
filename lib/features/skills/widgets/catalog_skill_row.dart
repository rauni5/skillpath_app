import 'package:flutter/material.dart';

import '../../../core/models/skill.dart';
import '../../../core/theme/app_palette.dart';
import 'add_skill_sheet.dart';

class CatalogSkillRow extends StatelessWidget {
  const CatalogSkillRow({
    super.key,
    required this.skill,
    required this.isPending,
    this.onAdd,
    this.onAddDirect,
    this.isSelected = false,
    this.onRemove,
  }) : assert(
         onAdd != null || onAddDirect != null,
         'Provide either onAdd (proficiency sheet) or onAddDirect (custom tap handler).',
       );

  final Skill skill;
  final bool isPending;
  final void Function(SkillProficiency proficiency)? onAdd;
  final VoidCallback? onAddDirect;
  final bool isSelected;
  final VoidCallback? onRemove;

  Future<void> _handleTap(BuildContext context) async {
    if (onAddDirect != null) {
      onAddDirect!();
      return;
    }
    final level = await showAddSkillSheet(context, skill);
    if (level != null) onAdd!(level);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final VoidCallback? tapHandler = isPending
        ? null
        : isSelected
        ? onRemove
        : () => _handleTap(context);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: tapHandler,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? p.indigoLight : p.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? p.indigo : p.border,
            width: isSelected ? 1.25 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(skill.category.icon, size: 17, color: p.indigo),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.name,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? p.indigo : p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    skill.category.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? p.indigo.withValues(alpha: 0.7)
                          : p.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isPending)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: p.indigo,
                ),
              )
            else if (isSelected)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16, color: p.indigo),
                  const SizedBox(width: 4),
                  Text(
                    'Added',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: p.indigo,
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: p.indigoLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: p.indigo),
                    const SizedBox(width: 3),
                    Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: p.indigo,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
