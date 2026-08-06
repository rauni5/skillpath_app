import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/skill.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../providers/admin_skills_provider.dart';

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
    setState(() {
      _category = skill.category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final skills = context.watch<AdminSkillsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Skill')),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _buildBody(context, p, skills),
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
        return const LoadingView(key: ValueKey('loading'));
      case AdminSkillDetailLoadState.error:
        return ErrorView(
          key: const ValueKey('error'),
          message: skills.detailError ?? 'Something went wrong.',
          onRetry: () =>
              context.read<AdminSkillsProvider>().loadDetail(widget.skillId),
        );
      case AdminSkillDetailLoadState.loaded:
        final skill = skills.selectedSkill!;
        _hydrate(skill);
        return ListView(
          key: const ValueKey('loaded'),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<SkillCategory>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: SkillCategory.values
                        .where((c) => c != SkillCategory.unknown)
                        .map(
                          (c) =>
                              DropdownMenuItem(value: c, child: Text(c.label)),
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
                      style: const TextStyle(color: Colors.red, fontSize: 12.5),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    children: [
                      FilledButton(
                        onPressed: skills.isSaving
                            ? null
                            : () => _save(context, skill.id),
                        child: skills.isSaving
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save changes'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: skills.isDeleting
                            ? null
                            : () => _confirmDelete(context, skill),
                        style: OutlinedButton.styleFrom(foregroundColor: p.red),
                        child: skills.isDeleting
                            ? SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: p.red,
                                ),
                              )
                            : const Text('Delete skill'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'PREREQUISITES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: p.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Skills a learner must know before this one.',
              style: TextStyle(fontSize: 12, color: p.textMuted),
            ),
            const SizedBox(height: 12),
            if (skills.dependencies.isEmpty)
              Text(
                'No prerequisites set.',
                style: TextStyle(fontSize: 12.5, color: p.textMuted),
              )
            else
              ...skills.dependencies.map((dep) {
                final isPending = skills.pendingDependencyIds.contains(dep.id);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: p.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: p.border),
                  ),
                  child: Row(
                    children: [
                      Icon(dep.categoryIcon, size: 16, color: p.indigo),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dep.name,
                          style: TextStyle(fontSize: 13, color: p.textPrimary),
                        ),
                      ),
                      if (isPending)
                        const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        IconButton(
                          tooltip: 'Remove',
                          icon: Icon(Icons.close, size: 18, color: p.textMuted),
                          onPressed: () => context
                              .read<AdminSkillsProvider>()
                              .removeDependency(skill.id, dep.id),
                        ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showAddDependencyDialog(context, skill, skills),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add prerequisite'),
            ),
          ],
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
        context.go('/admin/skills');
      } else if (context.mounted) {
        final err = context.read<AdminSkillsProvider>().detailError;
        if (err != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(err)));
        }
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
