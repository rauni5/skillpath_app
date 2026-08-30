import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/skill.dart';
import '../../../core/theme/app_palette.dart';
import '../../skills/providers/skills_provider.dart';

/// Compact trigger showing a summary of the selected skills (never grows
/// past a couple of lines) - opens a fixed-height bottom sheet for actual
/// picking, so filling in a form with a large skill catalog doesn't push
/// the rest of the page - and the submit button - further down every
/// time a chip is tapped. Shared by CreateProjectScreen and
/// EditProjectScreen.
class SkillPickerField extends StatelessWidget {
  const SkillPickerField({
    super.key,
    required this.selectedSkillIds,
    required this.onChanged,
  });

  final Set<int> selectedSkillIds;
  final ValueChanged<Set<int>> onChanged;

  Future<void> _openPicker(BuildContext context) async {
    final result = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SkillPickerSheet(initialSelection: selectedSkillIds),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Consumer<SkillsProvider>(
      builder: (context, skills, _) {
        final selected = skills.catalog
            .where((s) => selectedSkillIds.contains(s.id))
            .toList();
        const previewCount = 6;
        final overflow = selected.length - previewCount;

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openPicker(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: p.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: selected.isEmpty
                ? Row(
                    children: [
                      Icon(Icons.add_circle_outline, size: 18, color: p.indigo),
                      const SizedBox(width: 8),
                      Text(
                        'Select skills',
                        style: TextStyle(color: p.textMuted, fontSize: 13),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: p.textMuted),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${selected.length} skill${selected.length == 1 ? '' : 's'} selected',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: p.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.edit_outlined, size: 16, color: p.indigo),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ...selected
                              .take(previewCount)
                              .map(
                                (s) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: p.indigoLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    s.name,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: p.indigo,
                                    ),
                                  ),
                                ),
                              ),
                          if (overflow > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: p.surface1,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '+$overflow',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: p.textMuted,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

/// The actual search + category-grouped picker, contained to a fixed
/// share of the screen height so it never affects layout outside the
/// sheet. Changes only take effect if confirmed via "Done" - swiping the
/// sheet away discards them, same as the trigger's field never changing
/// until the sheet reports a result.
class _SkillPickerSheet extends StatefulWidget {
  const _SkillPickerSheet({required this.initialSelection});
  final Set<int> initialSelection;

  @override
  State<_SkillPickerSheet> createState() => _SkillPickerSheetState();
}

class _SkillPickerSheetState extends State<_SkillPickerSheet> {
  late final Set<int> _selection = Set.of(widget.initialSelection);
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final skills = context.read<SkillsProvider>();
      if (skills.catalog.isEmpty) skills.loadCatalog();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggle(int id) {
    setState(() {
      if (!_selection.remove(id)) _selection.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final skills = context.watch<SkillsProvider>();
    final query = _searchCtrl.text.trim().toLowerCase();

    final filtered = query.isEmpty
        ? skills.catalog
        : skills.catalog
              .where((s) => s.name.toLowerCase().contains(query))
              .toList();

    final byCategory = <SkillCategory, List<Skill>>{};
    for (final s in filtered) {
      byCategory.putIfAbsent(s.category, () => []).add(s);
    }
    final categories = byCategory.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 2),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: p.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select skills',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                  if (_selection.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(_selection.clear),
                      child: const Text('Clear'),
                    ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: p.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(_selection),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                autofocus: false,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search skills…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(_searchCtrl.clear),
                        ),
                ),
              ),
            ),
            Expanded(
              child: skills.catalogState == SkillsLoadState.loading
                  ? Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: p.indigo,
                      ),
                    )
                  : filtered.isEmpty
                  ? Center(
                      child: Text(
                        query.isEmpty
                            ? 'No skills available.'
                            : 'No skills match "$query".',
                        style: TextStyle(fontSize: 12.5, color: p.textMuted),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        for (final cat in categories) ...[
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: 8,
                              top: cat == categories.first ? 4 : 18,
                            ),
                            child: Row(
                              children: [
                                Icon(cat.icon, size: 14, color: p.textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  cat.label,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: p.textMuted,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(${byCategory[cat]!.length})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: p.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: byCategory[cat]!.map((s) {
                              final isSelected = _selection.contains(s.id);
                              return FilterChip(
                                label: Text(s.name),
                                selected: isSelected,
                                onSelected: (_) => _toggle(s.id),
                                selectedColor: p.indigoLight,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? p.indigo
                                      : p.textSecondary,
                                ),
                                side: BorderSide(
                                  color: isSelected ? p.indigo : p.border,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
