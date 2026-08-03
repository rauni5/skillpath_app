import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../career/providers/career_provider.dart';
import '../../skills/providers/skills_provider.dart';
import '../providers/projects_provider.dart';

/// Opens the filter bottom sheet. Call this from a filter icon/button.
Future<void> showProjectFilterSheet(BuildContext context) {
  final skills = context.read<SkillsProvider>();
  if (skills.catalog.isEmpty) skills.loadCatalog();
  final career = context.read<CareerProvider>();
  if (career.roles.isEmpty) career.loadRoles();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _ProjectFilterSheet(),
  );
}

class _ProjectFilterSheet extends StatefulWidget {
  const _ProjectFilterSheet();

  @override
  State<_ProjectFilterSheet> createState() => _ProjectFilterSheetState();
}

class _ProjectFilterSheetState extends State<_ProjectFilterSheet> {
  final _skillSearchCtrl = TextEditingController();

  static const _difficulties = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  void dispose() {
    _skillSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final projects = context.watch<ProjectsProvider>();
    final skills = context.watch<SkillsProvider>();
    final career = context.watch<CareerProvider>();

    final query = _skillSearchCtrl.text.trim().toLowerCase();
    final filteredCatalog = query.isEmpty
        ? skills.catalog
        : skills.catalog
              .where((s) => s.name.toLowerCase().contains(query))
              .toList();

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
            TextField(
              controller: _skillSearchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search skills…',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            if (skills.catalogState == SkillsLoadState.loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: p.indigo,
                  ),
                ),
              )
            else if (filteredCatalog.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No skills match "$query".',
                  style: TextStyle(color: p.textMuted, fontSize: 12.5),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: filteredCatalog.map((s) {
                      final selected = projects.filterSkillIds.contains(s.id);
                      return FilterChip(
                        label: Text(s.name),
                        selected: selected,
                        onSelected: (_) => projects.toggleSkillFilter(s.id),
                        selectedColor: p.indigoLight,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: selected ? p.indigo : p.textSecondary,
                        ),
                        side: BorderSide(color: selected ? p.indigo : p.border),
                      );
                    }).toList(),
                  ),
                ),
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
