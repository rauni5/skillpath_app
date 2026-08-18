import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/branch_requirement.dart';
import '../../../core/models/role_branch.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../skills/providers/skills_provider.dart';
import '../providers/admin_roles_provider.dart';

class AdminBranchDetailScreen extends StatefulWidget {
  const AdminBranchDetailScreen({
    super.key,
    required this.roleId,
    required this.branchId,
  });

  final int roleId;
  final int branchId;

  @override
  State<AdminBranchDetailScreen> createState() =>
      _AdminBranchDetailScreenState();
}

class _AdminBranchDetailScreenState extends State<AdminBranchDetailScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int? _hydratedBranchId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void didUpdateWidget(covariant AdminBranchDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branchId != widget.branchId) {
      _hydratedBranchId = null;
      _nameCtrl.clear();
      _descCtrl.clear();
      _fetchData();
    }
  }

  void _fetchData() {
    context.read<AdminRolesProvider>().loadBranchDetail(widget.branchId);
    final skills = context.read<SkillsProvider>();
    if (skills.catalog.isEmpty) skills.loadCatalog();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _hydrate(RoleBranch branch) {
    if (_hydratedBranchId == branch.id) return;
    _nameCtrl.text = branch.name;
    _descCtrl.text = branch.description ?? '';
    _hydratedBranchId = branch.id;
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final roles = context.watch<AdminRolesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Branch')),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _buildBody(context, p, roles),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppPalette p,
    AdminRolesProvider roles,
  ) {
    switch (roles.branchDetailState) {
      case AdminBranchDetailLoadState.initial:
      case AdminBranchDetailLoadState.loading:
        return const LoadingView(key: ValueKey('loading'));
      case AdminBranchDetailLoadState.error:
        return ErrorView(
          key: const ValueKey('error'),
          message: roles.branchDetailError ?? 'Something went wrong.',
          onRetry: () => context.read<AdminRolesProvider>().loadBranchDetail(
            widget.branchId,
          ),
        );
      case AdminBranchDetailLoadState.loaded:
        final branch = roles.selectedBranch;
        if (branch == null) {
          return const LoadingView(key: ValueKey('loading_null_guard'));
        }

        _hydrate(branch);
        return ListView(
          key: ValueKey('loaded_${branch.id}'),
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
                  TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                    ),
                    maxLines: 3,
                  ),
                  if (roles.branchDetailError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      roles.branchDetailError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12.5),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    children: [
                      FilledButton(
                        onPressed: roles.isSavingBranch
                            ? null
                            : () => _save(context, branch.id),
                        child: roles.isSavingBranch
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
                        onPressed: roles.isDeletingBranch
                            ? null
                            : () => _confirmDelete(context, branch),
                        style: OutlinedButton.styleFrom(foregroundColor: p.red),
                        child: roles.isDeletingBranch
                            ? SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: p.red,
                                ),
                              )
                            : const Text('Delete branch'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'REQUIRED SKILLS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: p.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Skills someone needs for this branch, weighted by importance (1–10). '
              "Users on this branch see this list — roles no longer have their own separate list.",
              style: TextStyle(fontSize: 12, color: p.textMuted, height: 1.4),
            ),
            const SizedBox(height: 12),
            if (roles.branchRequirements.isEmpty)
              Text(
                'No required skills set.',
                style: TextStyle(fontSize: 12.5, color: p.textMuted),
              )
            else
              ...roles.branchRequirements.map(
                (req) => _BranchRequirementRow(
                  branchId: branch.id,
                  requirement: req,
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () =>
                  _showAddRequirementDialog(context, branch.id, roles),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add required skill'),
            ),
          ],
        );
    }
  }

  Future<void> _save(BuildContext context, int branchId) async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AdminRolesProvider>().updateBranch(
      branchId,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
    );
  }

  Future<void> _confirmDelete(BuildContext context, dynamic branch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this branch?'),
        content: Text(
          'This removes "${branch.name}" and its required-skill list. If any user currently has '
          'it selected as their career goal branch, deletion will be blocked until that changes.',
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
      final ok = await context.read<AdminRolesProvider>().deleteBranch(
        branch.id,
      );
      if (ok && context.mounted) {
        context.go('/admin/roles/${widget.roleId}');
      } else if (context.mounted) {
        final err = context.read<AdminRolesProvider>().branchDetailError;
        if (err != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(err)));
        }
      }
    }
  }

  Future<void> _showAddRequirementDialog(
    BuildContext context,
    int branchId,
    AdminRolesProvider roles,
  ) async {
    final skillsProvider = context.read<SkillsProvider>();
    final existingIds = roles.branchRequirements.map((r) => r.skillId).toSet();
    final candidates = skillsProvider.catalog
        .where((s) => !existingIds.contains(s.id))
        .toList();
    final searchCtrl = TextEditingController();
    int importance = 5;
    int? selectedSkillId;
    String? selectedSkillName;

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
          final adminRoles = context.watch<AdminRolesProvider>();

          return AlertDialog(
            title: const Text('Add required skill'),
            content: SizedBox(
              width: 380,
              child: selectedSkillId == null
                  ? SizedBox(
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
                                ? const Center(
                                    child: Text('No matching skills.'),
                                  )
                                : ListView.builder(
                                    itemCount: filtered.length,
                                    itemBuilder: (context, i) {
                                      final s = filtered[i];
                                      return ListTile(
                                        dense: true,
                                        title: Text(s.name),
                                        subtitle: Text(s.categoryLabel),
                                        onTap: () => setDialogState(() {
                                          selectedSkillId = s.id;
                                          selectedSkillName = s.name;
                                        }),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedSkillName!,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Importance: $importance',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Slider(
                          value: importance.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: '$importance',
                          onChanged: (v) =>
                              setDialogState(() => importance = v.round()),
                        ),
                        if (adminRoles.branchDetailError != null)
                          Text(
                            adminRoles.branchDetailError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
            ),
            actions: [
              if (selectedSkillId != null)
                TextButton(
                  onPressed: () => setDialogState(() {
                    selectedSkillId = null;
                    selectedSkillName = null;
                  }),
                  child: const Text('Back'),
                ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              if (selectedSkillId != null)
                FilledButton(
                  onPressed: () async {
                    final ok = await context
                        .read<AdminRolesProvider>()
                        .addBranchRequirement(
                          branchId,
                          selectedSkillId!,
                          importance,
                        );
                    if (ok && ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: const Text('Add'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BranchRequirementRow extends StatelessWidget {
  const _BranchRequirementRow({
    required this.branchId,
    required this.requirement,
  });

  final int branchId;
  final BranchRequirement requirement;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final roles = context.watch<AdminRolesProvider>();
    final isPending = roles.pendingBranchRequirementSkillIds.contains(
      requirement.skillId,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              requirement.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: isPending
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Slider(
                    value: requirement.importance.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '${requirement.importance}',
                    onChanged: (v) => context
                        .read<AdminRolesProvider>()
                        .updateBranchRequirementImportance(
                          branchId,
                          requirement.skillId,
                          v.round(),
                        ),
                  ),
          ),
          SizedBox(
            width: 22,
            child: Text(
              '${requirement.importance}',
              style: TextStyle(fontSize: 12, color: p.textMuted),
            ),
          ),
          if (!isPending)
            IconButton(
              tooltip: 'Remove',
              icon: Icon(Icons.close, size: 18, color: p.textMuted),
              onPressed: () => context
                  .read<AdminRolesProvider>()
                  .removeBranchRequirement(branchId, requirement.skillId),
            ),
        ],
      ),
    );
  }
}
