import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/skill.dart';
import '../../../core/theme/app_palette.dart';
import '../providers/admin_skills_provider.dart';
import '../widgets/admin_bits.dart';
import '../widgets/admin_card.dart';
import '../widgets/admin_page_header.dart';

class AdminSkillDetailScreen extends StatefulWidget {
  const AdminSkillDetailScreen({super.key, required this.skillId});

  final int skillId;

  @override
  State<AdminSkillDetailScreen> createState() => _AdminSkillDetailScreenState();
}

class _AdminSkillDetailScreenState extends State<AdminSkillDetailScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  SkillCategory _category = SkillCategory.backend;
  final _formKey = GlobalKey<FormState>();
  int? _loadedSkillId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminSkillsProvider>().loadDetail(widget.skillId);
      final skills = context.read<AdminSkillsProvider>();
      if (skills.catalog.isEmpty) skills.loadCatalog();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _hydrate(Skill skill) {
    if (_loadedSkillId == skill.id) return;
    _loadedSkillId = skill.id;
    _nameCtrl.text = skill.name;
    _descCtrl.text = skill.description ?? '';
    setState(() => _category = skill.category);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final skills = context.watch<AdminSkillsProvider>();

    return Scaffold(
      backgroundColor: p.surface2,
      body: Column(
        children: [
          const AdminPageHeader(
            icon: Icons.edit_outlined,
            title: 'Edit Skill',
            subtitle: 'Update this skill\'s name, category, and prerequisites.',
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
    switch (skills.detailState) {
      case AdminSkillDetailLoadState.initial:
      case AdminSkillDetailLoadState.loading:
        return const Center(
          key: ValueKey('loading'),
          child: CircularProgressIndicator(),
        );
      case AdminSkillDetailLoadState.error:
        return InlineErrorState(
          key: const ValueKey('error'),
          message: skills.detailError ?? 'Something went wrong.',
          onRetry: () =>
              context.read<AdminSkillsProvider>().loadDetail(widget.skillId),
        );
      case AdminSkillDetailLoadState.loaded:
        final skill = skills.selectedSkill!;
        _hydrate(skill);
        return Center(
          key: const ValueKey('loaded'),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Back to skills'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AdminCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<SkillCategory>(
                          initialValue: _category,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
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
                              setState(() => _category = v ?? _category),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _descCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Description (optional)',
                          ),
                          maxLines: 3,
                        ),
                        if (skills.detailError != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            skills.detailError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: skills.isSaving
                                    ? null
                                    : () => _save(context, skill.id),
                                child: skills.isSaving
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Save changes',
                                        style: TextStyle(fontSize: 14),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: p.red,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  side: BorderSide(color: p.red),
                                ),
                                onPressed: skills.isDeleting
                                    ? null
                                    : () => _confirmDelete(context, skill),
                                child: skills.isDeleting
                                    ? SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: p.red,
                                        ),
                                      )
                                    : const Text(
                                        'Delete skill',
                                        style: TextStyle(fontSize: 14),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const SectionLabel('Prerequisites'),
                const SizedBox(height: 4),
                Text(
                  'Skills a learner must know before this one.',
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
                const SizedBox(height: 12),
                if (skills.dependencies.isEmpty)
                  AdminCard(
                    child: Text(
                      'No prerequisites set.',
                      style: TextStyle(fontSize: 12.5, color: p.textMuted),
                    ),
                  )
                else
                  AdminCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final dep in skills.dependencies) ...[
                          _DependencyRow(
                            skill: dep,
                            isPending: skills.pendingDependencyIds.contains(
                              dep.id,
                            ),
                            onRemove: () => context
                                .read<AdminSkillsProvider>()
                                .removeDependency(skill.id, dep.id),
                            p: p,
                          ),
                          if (dep != skills.dependencies.last)
                            Divider(height: 1, color: p.border),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      _showAddDependencyDialog(context, skill, skills),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add prerequisite'),
                ),
              ],
            ),
          ),
        );
    }
  }

  Future<void> _save(BuildContext context, int skillId) async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AdminSkillsProvider>().updateSkill(
      skillId,
      name: _nameCtrl.text.trim(),
      category: _category,
      description: _descCtrl.text.trim(),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Skill skill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this skill?'),
        content: Text(
          'This removes "${skill.name}" from every user\'s skill inventory and every career '
          "role that requires it. If any project currently requires it, deletion will be blocked "
          'until it\'s removed from that project.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final ok = await context.read<AdminSkillsProvider>().deleteSkill(
        skill.id,
      );
      if (ok && context.mounted) {
        context.pop();
      } else if (context.mounted) {
        final err = context.read<AdminSkillsProvider>().detailError;
        if (err != null) {}
      }
    }
  }

  Future<void> _showAddDependencyDialog(
    BuildContext context,
    Skill skill,
    AdminSkillsProvider skills,
  ) async {
    final existingIds = {skill.id, ...skills.dependencies.map((d) => d.id)};
    final candidates = skills.catalog
        .where((s) => !existingIds.contains(s.id))
        .toList();
    final searchCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final query = searchCtrl.text.trim().toLowerCase();
          final filtered = query.isEmpty
              ? candidates
              : candidates
                    .where((s) => s.name.toLowerCase().contains(query))
                    .toList();
          return AlertDialog(
            title: const Text('Add prerequisite'),
            content: SizedBox(
              width: 380,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    controller: searchCtrl,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search skills…',
                      prefixIcon: Icon(Icons.search, size: 20),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No matching skills.'))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final s = filtered[i];
                              return ListTile(
                                dense: true,
                                title: Text(s.name),
                                subtitle: Text(s.categoryLabel),
                                onTap: () async {
                                  Navigator.of(ctx).pop();
                                  await context
                                      .read<AdminSkillsProvider>()
                                      .addDependency(skill.id, s.id);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DependencyRow extends StatelessWidget {
  const _DependencyRow({
    required this.skill,
    required this.isPending,
    required this.onRemove,
    required this.p,
  });

  final Skill skill;
  final bool isPending;
  final VoidCallback onRemove;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(skill.categoryIcon, size: 16, color: p.indigo),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              skill.name,
              style: TextStyle(fontSize: 13, color: p.textPrimary),
            ),
          ),
          if (isPending)
            const MiniSpinner(size: 16)
          else
            IconButton(
              tooltip: 'Remove',
              icon: Icon(Icons.close, size: 18, color: p.textMuted),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
