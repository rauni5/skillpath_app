import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/skill.dart';
import '../../../core/theme/app_palette.dart';
import '../providers/admin_skills_provider.dart';
import '../widgets/admin_bits.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/shimmer_skeleton.dart';

class AdminSkillsScreen extends StatefulWidget {
  const AdminSkillsScreen({super.key});

  @override
  State<AdminSkillsScreen> createState() => _AdminSkillsScreenState();
}

class _AdminSkillsScreenState extends State<AdminSkillsScreen> {
  final _searchCtrl = TextEditingController();

  /// Manually collapsed sections — categories not in here are expanded.
  /// While searching, everything with a match is force-expanded regardless
  /// of this set, so results are never hidden behind a collapsed header.
  final Set<SkillCategory> _collapsed = {};

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
            bottom: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search skills…',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
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

        final query = _searchCtrl.text.trim().toLowerCase();
        final isSearching = query.isNotEmpty;
        final grouped = _groupByCategory(skills.catalog, query);

        if (grouped.isEmpty) {
          return EmptyState(
            key: const ValueKey('no-matches'),
            icon: Icons.search_off,
            message: 'No skills match "$query".',
          );
        }

        final categories = grouped.keys.toList()
          ..sort((a, b) {
            if (a == SkillCategory.unknown) return 1;
            if (b == SkillCategory.unknown) return -1;
            return a.label.compareTo(b.label);
          });

        return RefreshIndicator(
          key: const ValueKey('loaded'),
          onRefresh: () async => _load(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            children: [
              Text(
                '${skills.catalog.length} skills across ${categories.length} '
                'categor${categories.length == 1 ? 'y' : 'ies'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: p.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < categories.length; i++) ...[
                FadeSlideIn(
                  index: i,
                  child: _CategorySection(
                    category: categories[i],
                    skills: grouped[categories[i]]!,
                    expanded:
                        isSearching || !_collapsed.contains(categories[i]),
                    onExpansionChanged: isSearching
                        ? null
                        : (expanded) => setState(() {
                            if (expanded) {
                              _collapsed.remove(categories[i]);
                            } else {
                              _collapsed.add(categories[i]);
                            }
                          }),
                    p: p,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
    }
  }

  Map<SkillCategory, List<Skill>> _groupByCategory(
    List<Skill> catalog,
    String query,
  ) {
    final filtered = query.isEmpty
        ? catalog
        : catalog
              .where(
                (s) =>
                    s.name.toLowerCase().contains(query) ||
                    s.categoryLabel.toLowerCase().contains(query),
              )
              .toList();

    final grouped = <SkillCategory, List<Skill>>{};
    for (final skill in filtered) {
      grouped.putIfAbsent(skill.category, () => []).add(skill);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return grouped;
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    SkillCategory category = SkillCategory.backend;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final skills = context.watch<AdminSkillsProvider>();
          return AlertDialog(
            title: const Text('New skill'),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<SkillCategory>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: SkillCategory.values
                          .where((c) => c != SkillCategory.unknown)
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => category = v ?? category),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                      ),
                      maxLines: 2,
                    ),
                    if (skills.createError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        skills.createError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: skills.isCreating
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final created = await skills.createSkill(
                          name: nameCtrl.text.trim(),
                          category: category,
                          description: descCtrl.text.trim(),
                        );
                        if (created != null && ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                      },
                child: skills.isCreating
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.skills,
    required this.expanded,
    required this.onExpansionChanged,
    required this.p,
  });

  final SkillCategory category;
  final List<Skill> skills;
  final bool expanded;
  final ValueChanged<bool>? onExpansionChanged;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(category, p);

    return Container(
      decoration: BoxDecoration(
        color: p.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: expanded,
          key: ValueKey('${category.name}-$expanded'),
          onExpansionChanged: onExpansionChanged,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(category.icon, size: 17, color: accent),
          ),
          title: Text(
            category.label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Pill(label: '${skills.length}'),
              const SizedBox(width: 4),
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: p.textMuted,
              ),
            ],
          ),
          children: [
            for (final skill in skills)
              _SkillRow(skill: skill, accent: accent, p: p),
          ],
        ),
      ),
    );
  }

  static Color _accentFor(SkillCategory category, AppPalette p) {
    final palette = [p.indigo, p.green, p.amber, p.red];
    return palette[category.index % palette.length];
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.skill, required this.accent, required this.p});

  final Skill skill;
  final Color accent;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/admin/skills/${skill.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: p.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                  if (skill.description != null &&
                      skill.description!.trim().isNotEmpty)
                    Text(
                      skill.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: p.textMuted),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: p.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
