import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../providers/admin_roles_provider.dart';

class AdminRolesScreen extends StatefulWidget {
  const AdminRolesScreen({super.key});

  @override
  State<AdminRolesScreen> createState() => _AdminRolesScreenState();
}

class _AdminRolesScreenState extends State<AdminRolesScreen> {
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

  void _load() => context.read<AdminRolesProvider>().loadRoles();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final roles = context.watch<AdminRolesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Roles'),
        actions: [
          IconButton(
            tooltip: 'New role',
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
                hintText: 'Search roles…',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
            ),
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
    switch (roles.listState) {
      case AdminRolesLoadState.initial:
      case AdminRolesLoadState.loading:
        return const LoadingView(key: ValueKey('loading'));
      case AdminRolesLoadState.error:
        return ErrorView(
          key: const ValueKey('error'),
          message: roles.listError ?? 'Something went wrong.',
          onRetry: _load,
        );
      case AdminRolesLoadState.loaded:
        final query = _searchCtrl.text.trim().toLowerCase();
        final filtered = query.isEmpty
            ? roles.roles
            : roles.roles
                  .where((r) => r.name.toLowerCase().contains(query))
                  .toList();

        if (filtered.isEmpty) {
          return Center(
            key: const ValueKey('empty'),
            child: Text(
              query.isEmpty
                  ? 'No career roles yet.'
                  : 'No roles match "$query".',
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
              final role = filtered[i];
              return Material(
                color: p.surface2,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => context.go('/admin/roles/${role.id}'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: p.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.badge_outlined, size: 18, color: p.indigo),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                role.name,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: p.textPrimary,
                                ),
                              ),
                              if (role.description != null &&
                                  role.description!.isNotEmpty)
                                Text(
                                  role.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final roles = context.watch<AdminRolesProvider>();
          return AlertDialog(
            title: const Text('New career role'),
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
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                      ),
                      maxLines: 2,
                    ),
                    if (roles.createError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        roles.createError!,
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
                onPressed: roles.isCreating
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final created = await roles.createRole(
                          name: nameCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                        );
                        if (created != null && ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                      },
                child: roles.isCreating
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
