import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/skill.dart';
import '../../../core/theme/app_palette.dart';
import '../providers/admin_skills_provider.dart';
import '../widgets/admin_bits.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/shimmer_skeleton.dart';

enum _SortBy { name, category }

class AdminSkillsScreen extends StatefulWidget {
  const AdminSkillsScreen({super.key});

  @override
  State<AdminSkillsScreen> createState() => _AdminSkillsScreenState();
}

class _AdminSkillsScreenState extends State<AdminSkillsScreen> {
  final _searchCtrl = TextEditingController();

  /// `null` means "all categories" — the actual options come from whatever
  /// categories exist in the data, never a hardcoded list.
  String? _categoryFilter;
  _SortBy _sortBy = _SortBy.name;
  bool _sortAsc = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _load() => context.read<AdminSkillsProvider>().loadCatalog();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final skills = context.watch<AdminSkillsProvider>();

    return Scaffold(
      backgroundColor: p.surface2,
      body: Column(
        children: [
          AdminPageHeader(
            icon: Icons.psychology_outlined,
            title: 'Skills',
            subtitle:
                '${skills.catalog.length} skill${skills.catalog.length == 1 ? '' : 's'} in the catalogue.',
            trailing: FilledButton.icon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New skill'),
            ),
            bottom: LayoutBuilder(
              builder: (context, constraints) {
                final searchField = TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search skills…',
                    prefixIcon: Icon(Icons.search, size: 20),
                    isDense: true,
                  ),
                );
                final categoryDropdown = DropdownButtonFormField<String?>(
                  initialValue: _categoryFilter,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    for (final c in skills.knownCategories)
                      DropdownMenuItem(value: c, child: Text(_humanize(c))),
                  ],
                  onChanged: (v) => setState(() => _categoryFilter = v),
                );

                // Below ~460px (a phone-width web view) the two fields
                // side by side get too cramped to use — stack them
                // instead of squeezing.
                if (constraints.maxWidth < 460) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      searchField,
                      const SizedBox(height: 10),
                      categoryDropdown,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(flex: 2, child: searchField),
                    const SizedBox(width: 10),
                    Expanded(child: categoryDropdown),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _buildBody(context, p, skills),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppPalette p,
    AdminSkillsProvider skills,
  ) {
    switch (skills.listState) {
      case AdminSkillsLoadState.initial:
      case AdminSkillsLoadState.loading:
        return ListView(
          key: const ValueKey('loading'),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: List.generate(
            6,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: ShimmerListRow(),
            ),
          ),
        );
      case AdminSkillsLoadState.error:
        return InlineErrorState(
          key: const ValueKey('error'),
          message: skills.listError ?? 'Something went wrong.',
          onRetry: _load,
        );
      case AdminSkillsLoadState.loaded:
        if (skills.catalog.isEmpty) {
          return const EmptyState(
            key: ValueKey('empty'),
            icon: Icons.psychology_outlined,
            message: 'No skills yet.',
          );
        }

        final rows = _visibleSkills(skills.catalog);

        if (rows.isEmpty) {
          return const EmptyState(
            key: ValueKey('no-matches'),
            icon: Icons.search_off,
            message: 'No skills match your search/filter.',
          );
        }

        return RefreshIndicator(
          key: const ValueKey('loaded'),
          onRefresh: () async => _load(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            children: [
              Text(
                '${rows.length} of ${skills.catalog.length} skills',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: p.textMuted,
                ),
              ),
              const SizedBox(height: 14),
              AdminDataTable(
                sortColumnIndex: _sortBy == _SortBy.name ? 0 : 1,
                sortAscending: _sortAsc,
                columns: [
                  DataColumn(
                    label: const Text('Name'),
                    onSort: (_, asc) => setState(() {
                      _sortBy = _SortBy.name;
                      _sortAsc = asc;
                    }),
                  ),
                  DataColumn(
                    label: const Text('Category'),
                    onSort: (_, asc) => setState(() {
                      _sortBy = _SortBy.category;
                      _sortAsc = asc;
                    }),
                  ),
                  const DataColumn(label: Text('Description')),
                  const DataColumn(label: Text('')),
                ],
                rows: [
                  for (final skill in rows)
                    DataRow(
                      onSelectChanged: (_) =>
                          context.push('/admin/skills/${skill.id}'),
                      cells: [
                        DataCell(
                          Text(
                            skill.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                skill.categoryIcon,
                                size: 14,
                                color: p.indigo,
                              ),
                              const SizedBox(width: 6),
                              Text(skill.categoryLabel),
                            ],
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 260,
                            child: Text(
                              skill.description?.trim().isNotEmpty == true
                                  ? skill.description!
                                  : '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: p.textMuted),
                            ),
                          ),
                        ),
                        DataCell(
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: p.textMuted,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
    }
  }

  List<Skill> _visibleSkills(List<Skill> catalog) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = catalog.where((s) {
      if (_categoryFilter != null && s.rawCategory != _categoryFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      return s.name.toLowerCase().contains(query) ||
          s.categoryLabel.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      final cmp = _sortBy == _SortBy.name
          ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
          : a.categoryLabel.toLowerCase().compareTo(
              b.categoryLabel.toLowerCase(),
            );
      return _sortAsc ? cmp : -cmp;
    });
    return filtered;
  }

  static String _humanize(String raw) => raw
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0]}${w.substring(1).toLowerCase()}')
      .join(' ');

  Future<void> _showCreateDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String category = '';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final skills = context.watch<AdminSkillsProvider>();
          return AdminFormDialog(
            icon: Icons.psychology_outlined,
            title: 'New skill',
            subtitle: 'Add a skill to the catalogue.',
            submitLabel: 'Create',
            isSubmitting: skills.isCreating,
            errorText: skills.createError,
            onCancel: () => Navigator.of(ctx).pop(),
            onSubmit: () async {
              if (!formKey.currentState!.validate()) return;
              if (category.trim().isEmpty) return;
              final created = await skills.createSkill(
                name: nameCtrl.text.trim(),
                category: category.trim(),
                description: descCtrl.text.trim(),
              );
              if (created != null && ctx.mounted) {
                Navigator.of(ctx).pop();
              }
            },
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.psychology_outlined, size: 20),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  CategoryInputField(
                    knownCategories: skills.knownCategories,
                    initialValue: category,
                    onChanged: (v) => category = v,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      prefixIcon: Icon(Icons.notes_outlined, size: 20),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
