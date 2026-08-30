import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../providers/admin_roles_provider.dart';

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
  int? _hydratedRoleId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void didUpdateWidget(covariant AdminRoleDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roleId != widget.roleId) {
      _hydratedRoleId = null;
      _nameCtrl.clear();
      _descCtrl.clear();
      _fetchData();
    }
  }

  void _fetchData() {
    context.read<AdminRolesProvider>().loadDetail(widget.roleId);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _hydrate(dynamic role) {
    // Only skip if the controller fields are already populated for THIS specific role ID
    if (_hydratedRoleId == role.id) return;
    _nameCtrl.text = role.name;
    _descCtrl.text = role.description ?? '';
    _hydratedRoleId = role.id;
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final roles = context.watch<AdminRolesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Career Role')),
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
    switch (roles.detailState) {
      case AdminRoleDetailLoadState.initial:
      case AdminRoleDetailLoadState.loading:
        return const LoadingView(key: ValueKey('loading'));
      case AdminRoleDetailLoadState.error:
        return ErrorView(
          key: const ValueKey('error'),
          message: roles.detailError ?? 'Something went wrong.',
          onRetry: () =>
              context.read<AdminRolesProvider>().loadDetail(widget.roleId),
        );
      case AdminRoleDetailLoadState.loaded:
        final role = roles.selectedRole;
        if (role == null) {
          return const LoadingView(key: ValueKey('loading_null_guard'));
        }

        _hydrate(role);
        return ListView(
          key: ValueKey('loaded_${role.id}'),
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
                  if (roles.detailError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      roles.detailError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12.5),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    children: [
                      FilledButton(
                        onPressed: roles.isSaving
                            ? null
                            : () => _save(context, role.id),
                        child: roles.isSaving
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
                        onPressed: roles.isDeleting
                            ? null
                            : () => _confirmDelete(context, role),
                        style: OutlinedButton.styleFrom(foregroundColor: p.red),
                        child: roles.isDeleting
                            ? SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: p.red,
                                ),
                              )
                            : const Text('Delete role'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'BRANCHES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: p.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Specializations under this role (e.g. MERN, Django, Spring under Full Stack). '
              "Every role's required skills live on its branches — a role needs at least one "
              "branch before users can select it as a career goal.",
              style: TextStyle(fontSize: 12, color: p.textMuted, height: 1.4),
            ),
            const SizedBox(height: 12),
            if (roles.branches.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.amberLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: p.amberText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No branches yet — this role can\'t be selected as a career goal until one is added.',
                        style: TextStyle(fontSize: 12, color: p.amberText),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...roles.branches.map(
                (branch) => Material(
                  color: p.surface2,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => context.go(
                      '/admin/roles/${role.id}/branches/${branch.id}',
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: p.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.alt_route, size: 18, color: p.indigo),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              branch.name,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
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
                  ),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _showCreateBranchDialog(context, role.id),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add branch'),
            ),
          ],
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

  Future<void> _confirmDelete(BuildContext context, dynamic role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this career role?'),
        content: Text(
          'This removes "${role.name}" and all of its branches. If any user currently has it as '
          'their career goal, or a project requires it, deletion will be blocked until that changes.',
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
        context.go('/admin/roles');
      } else if (context.mounted) {
        final err = context.read<AdminRolesProvider>().detailError;
        if (err != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(err)));
        }
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
            title: const Text('New branch'),
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
                        hintText: 'e.g. MERN',
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
