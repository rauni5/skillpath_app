import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../career/providers/career_provider.dart';
import '../../skills/providers/skills_provider.dart';
import '../providers/projects_provider.dart';
import '../widgets/skill_picker_field.dart';

/// Opens the filter bottom sheet. Call this from a filter icon/button.
Future<void> showProjectFilterSheet(BuildContext context) {
  final skills = context.read<SkillsProvider>();
  if (skills.catalog.isEmpty) skills.loadCatalog();
  final career = context.read<CareerProvider>();
  if (career.roles.isEmpty) career.loadRoles();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _ProjectFilterSheet(),
  );
}

class _ProjectFilterSheet extends StatefulWidget {
  const _ProjectFilterSheet();

  @override
  State<_ProjectFilterSheet> createState() => _ProjectFilterSheetState();
}

class _ProjectFilterSheetState extends State<_ProjectFilterSheet> {
  static const _difficulties = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final projects = context.watch<ProjectsProvider>();
    final career = context.watch<CareerProvider>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter projects',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                if (projects.hasActiveFilters)
                  TextButton(
                    onPressed: () => projects.clearFilters(),
                    child: const Text('Clear all'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'DIFFICULTY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: p.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _difficulties.map((d) {
                final selected =
                    projects.filterDifficulty?.toLowerCase() == d.toLowerCase();
                return ChoiceChip(
                  label: Text(d),
                  selected: selected,
                  onSelected: (_) =>
                      projects.setDifficultyFilter(selected ? null : d),
                  selectedColor: p.indigoLight,
                  labelStyle: TextStyle(
                    color: selected ? p.indigo : p.textSecondary,
                    fontSize: 12.5,
                  ),
                  side: BorderSide(color: selected ? p.indigo : p.border),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              'REQUIRED SKILLS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: p.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            SkillPickerField(
              selectedSkillIds: projects.filterSkillIds,
              onChanged: (ids) {
                projects.filterSkillIds
                  ..clear()
                  ..addAll(ids);
                projects.loadProjects();
              },
            ),
            const SizedBox(height: 20),
            Text(
              'REQUIRED ROLES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: p.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            if (career.rolesState == CareerLoadState.loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: p.indigo,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: career.roles.map((r) {
                  final selected = projects.filterRoleIds.contains(r.id);
                  return FilterChip(
                    label: Text(r.name),
                    selected: selected,
                    onSelected: (_) => projects.toggleRoleFilter(r.id),
                    selectedColor: p.indigoLight,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: selected ? p.indigo : p.textSecondary,
                    ),
                    side: BorderSide(color: selected ? p.indigo : p.border),
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: p.indigo,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
