import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/admin_role_summary.dart';
import '../../../core/theme/app_palette.dart';
import '../providers/admin_roles_provider.dart';
import '../widgets/admin_bits.dart';
import '../widgets/admin_card.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/responsive_card_grid.dart';
import '../widgets/shimmer_skeleton.dart';

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
      backgroundColor: p.surface2,
      body: Column(
        children: [
          AdminPageHeader(
            icon: Icons.badge_outlined,
            title: 'Career Roles',
            subtitle:
                '${roles.roles.length} role${roles.roles.length == 1 ? '' : 's'} configured.',
            trailing: FilledButton.icon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New role'),
            ),
            bottom: TextField(
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
        return ListView(
          key: const ValueKey('loading'),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: List.generate(
            6,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: ShimmerListRow(),
            ),
          ),
        );
      case AdminRolesLoadState.error:
        return InlineErrorState(
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
          return EmptyState(
            key: const ValueKey('empty'),
            icon: Icons.badge_outlined,
            message: query.isEmpty
                ? 'No career roles yet.'
                : 'No roles match "$query".',
          );
        }

        return RefreshIndicator(
          key: const ValueKey('loaded'),
          onRefresh: () async => _load(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            children: [
              ResponsiveCardGrid(
                children: [
                  for (final role in filtered) _RoleCard(role: role, p: p),
                ],
              ),
            ],
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.role, required this.p});

  final AdminRoleSummary role;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.push('/admin/roles/${role.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: p.indigoLight,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.badge_outlined, size: 17, color: p.indigo),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: p.textMuted, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            role.name,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
          if (role.description != null && role.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              role.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: p.textMuted, height: 1.35),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Pill(
                icon: Icons.alt_route,
                label:
                    '${role.branchCount} branch${role.branchCount == 1 ? '' : 'es'}',
                color: role.branchCount == 0 ? p.red : p.textMuted,
                filled: role.branchCount == 0,
              ),
              Pill(
                icon: Icons.psychology_outlined,
                label: '${role.requirementsCount} skills',
              ),
              Pill(
                icon: Icons.flag_outlined,
                label: '${role.popularity} chose this',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
