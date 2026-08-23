import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../../core/models/skill.dart';
import '../../../core/theme/app_palette.dart';

class CategoryFilterRow extends StatelessWidget {
  const CategoryFilterRow({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final SkillCategory? selected;
  final void Function(SkillCategory?) onSelect;

  static const _categories = [
    null,
    SkillCategory.frontend,
    SkillCategory.backend,
    SkillCategory.mobile,
    SkillCategory.devops,
    SkillCategory.cloud,
    SkillCategory.database,
    SkillCategory.dataEngineering,
    SkillCategory.uiUx,
  ];

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == selected;
          final label = category?.label ?? 'All';
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) {
              HapticFeedback.selectionClick();
              onSelect(category);
            },
            selectedColor: p.indigoLight,
            backgroundColor: p.surface1,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? p.indigo : p.textSecondary,
            ),
            side: BorderSide(color: isSelected ? p.indigo : Colors.transparent),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            labelPadding: const EdgeInsets.symmetric(horizontal: 2),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }
}
