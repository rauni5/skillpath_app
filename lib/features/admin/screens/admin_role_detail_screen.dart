import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/career_role.dart';
import '../../../core/theme/app_palette.dart';
import '../providers/admin_roles_provider.dart';
import '../widgets/admin_bits.dart';
import '../widgets/admin_card.dart';
import '../widgets/admin_page_header.dart';

const _kFormMaxWidth = 720.0;

class AdminRoleDetailScreen extends StatefulWidget {
  const AdminRoleDetailScreen({super.key, required this.roleId});

  final int roleId;

  @override
  State<AdminRoleDetailScreen> createState() => _AdminRoleDetailScreenState();
}

class _AdminRoleDetailScreenState extends State<AdminRoleDetailScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int? _loadedRoleId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminRolesProvider>().loadDetail(widget.roleId);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _hydrate(CareerRole role) {
    if (_loadedRoleId == role.id) return;
    _loadedRoleId = role.id;
    _nameCtrl.text = role.name;
    _descCtrl.text = role.description ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final roles = context.watch<AdminRolesProvider>();

    return Scaffold(
      backgroundColor: p.surface2,
      body: Column(
        children: [
          const AdminPageHeader(
            icon: Icons.edit_outlined,
            title: 'Edit Career Role',
            subtitle: 'Update details and manage this role\'s branches.',
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _buildBody(context, p, roles),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppPalette p,
    AdminRolesProvider roles,
  ) {
    switch (roles.detailState) {
      case AdminRoleDetailLoadState.initial:
      case AdminRoleDetailLoadState.loading:
        return const Center(
          key: ValueKey('loading'),
          child: CircularProgressIndicator(),
        );
      case AdminRoleDetailLoadState.error:
        return InlineErrorState(
          key: const ValueKey('error'),
          message: roles.detailError ?? 'Something went wrong.',
          onRetry: () =>
              context.read<AdminRolesProvider>().loadDetail(widget.roleId),
        );
      case AdminRoleDetailLoadState.loaded:
        final role = roles.selectedRole!;
        _hydrate(role);
        return Center(
          key: const ValueKey('loaded'),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kFormMaxWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Back to roles'),
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
                        TextFormField(
                          controller: _descCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Description (optional)',
                          ),
                          maxLines: 3,
                        ),
                        if (roles.detailError != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            roles.detailError!,
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
                                onPressed: roles.isSaving
                                    ? null
                                    : () => _save(context, role.id),
                                child: roles.isSaving
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
                                onPressed: roles.isDeleting
                                    ? null
                                    : () => _confirmDelete(context, role),
                                child: roles.isDeleting
                                    ? SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: p.red,
                                        ),
                                      )
                                    : const Text(
                                        'Delete role',
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
                const SectionLabel('Branches'),
                const SizedBox(height: 4),
                Text(
                  'Specializations under this role — required skills live here, '
                  'not directly on the role. It needs at least one branch before '
                  'anyone can pick it as a career goal.',
                  style: TextStyle(
                    fontSize: 12,
                    color: p.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                if (roles.branches.isEmpty)
                  AdminCard(
                    child: Text(
                      'No branches yet.',
                      style: TextStyle(fontSize: 12.5, color: p.textMuted),
                    ),
                  )
                else
                  Column(
                    children: [
                      for (final branch in roles.branches) ...[
                        AdminCard(
                          padding: const EdgeInsets.all(14),
                          onTap: () => context.push(
                            '/admin/roles/${role.id}/branches/${branch.id}',
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.alt_route, size: 18, color: p.indigo),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  branch.name,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: p.textPrimary,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: p.textMuted,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: () => _showCreateBranchDialog(context, role.id),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add branch'),
                ),
              ],
            ),
          ),
        );
    }
  }

  Future<void> _save(BuildContext context, int roleId) async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AdminRolesProvider>().updateRole(
      roleId,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
    );
  }

  Future<void> _confirmDelete(BuildContext context, CareerRole role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this career role?'),
        content: Text(
          'This removes "${role.name}" and all of its branches. If any user currently has '
          'it as their career goal, or any project requires it, deletion will be blocked '
          'until that changes.',
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
      final ok = await context.read<AdminRolesProvider>().deleteRole(role.id);
      if (ok && context.mounted) {
        context.pop();
      } else if (context.mounted) {
        final err = context.read<AdminRolesProvider>().detailError;
        if (err != null) {}
      }
    }
  }

  Future<void> _showCreateBranchDialog(BuildContext context, int roleId) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final roles = context.watch<AdminRolesProvider>();
          return AlertDialog(
            title: const Text('Add branch'),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        helperText: 'e.g. "MERN", "Django", "Spring"',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                      ),
                      maxLines: 2,
                    ),
                    if (roles.createBranchError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        roles.createBranchError!,
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
                onPressed: roles.isCreatingBranch
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final created = await roles.createBranch(
                          roleId,
                          name: nameCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                        );
                        if (created != null && ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                      },
                child: roles.isCreatingBranch
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
