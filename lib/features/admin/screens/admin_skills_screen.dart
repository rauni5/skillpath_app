import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/skill.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../providers/admin_skills_provider.dart';

class AdminSkillsScreen extends StatefulWidget {
  const AdminSkillsScreen({super.key});

  @override
  State<AdminSkillsScreen> createState() => _AdminSkillsScreenState();
}

class _AdminSkillsScreenState extends State<AdminSkillsScreen> {
  final _searchCtrl = TextEditingController();

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
      appBar: AppBar(
        title: const Text('Skills'),
        actions: [
          IconButton(
            tooltip: 'New skill',
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
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
        return const LoadingView(key: ValueKey('loading'));
      case AdminSkillsLoadState.error:
        return ErrorView(
          key: const ValueKey('error'),
          message: skills.listError ?? 'Something went wrong.',
          onRetry: _load,
        );
      case AdminSkillsLoadState.loaded:
        final query = _searchCtrl.text.trim().toLowerCase();
        final filtered = query.isEmpty
            ? skills.catalog
            : skills.catalog
                  .where((s) => s.name.toLowerCase().contains(query))
                  .toList();

        if (filtered.isEmpty) {
          return Center(
            key: const ValueKey('empty'),
            child: Text(
              query.isEmpty ? 'No skills yet.' : 'No skills match "$query".',
              style: TextStyle(color: p.textMuted, fontSize: 13),
            ),
          );
        }

        return RefreshIndicator(
          key: const ValueKey('loaded'),
          onRefresh: () async => _load(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final skill = filtered[i];
              return Material(
                color: p.surface2,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => context.go('/admin/skills/${skill.id}'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: p.border),
                    ),
                    child: Row(
                      children: [
                        Icon(skill.categoryIcon, size: 18, color: p.indigo),
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
                                  color: p.textPrimary,
                                ),
                              ),
                              Text(
                                skill.categoryLabel,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: p.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: p.textMuted, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
    }
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
