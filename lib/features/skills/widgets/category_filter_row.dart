import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../../core/models/skill.dart';
import '../../../core/theme/app_palette.dart';

/// A category chip filter driven entirely by [categories] — the distinct
/// raw category values present in the current catalog. Nothing here is
/// hardcoded, so a brand new admin-added category shows up automatically.
class CategoryFilterRow extends StatelessWidget {
  const CategoryFilterRow({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  /// Distinct raw categories to offer, in display order (see
  /// [SkillsProvider.availableCategories]). `null` ("All") is added
  /// automatically and doesn't need to be included here.
  final List<Skill> categories;
  final String? selected;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final rawCategory = index == 0 ? null : categories[index - 1].rawCategory;
          final label = index == 0
              ? 'All'
              : categories[index - 1].categoryLabel;
          final isSelected = rawCategory == selected;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) {
              HapticFeedback.selectionClick();
              onSelect(rawCategory);
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
