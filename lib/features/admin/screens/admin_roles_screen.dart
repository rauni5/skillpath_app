import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/admin_role_summary.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../providers/admin_roles_provider.dart';
import '../widgets/admin_card.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/stat_card.dart';
import '../widgets/stat_card_grid.dart';

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
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _AnalyticsHeader(roles: roles, p: p),
            const SizedBox(height: 20),
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search roles…',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            _buildBody(context, p, roles),
          ],
        ),
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
        return Column(
          key: const ValueKey('loading'),
          children: List.generate(
            5,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: ShimmerListRow(),
            ),
          ),
        );
      case AdminRolesLoadState.error:
        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: ErrorView(
            key: const ValueKey('error'),
            message: roles.listError ?? 'Something went wrong.',
            onRetry: _load,
          ),
        );
      case AdminRolesLoadState.loaded:
        final query = _searchCtrl.text.trim().toLowerCase();
        final filtered = query.isEmpty
            ? roles.roles
            : roles.roles
                  .where((r) => r.name.toLowerCase().contains(query))
                  .toList();

        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              key: const ValueKey('empty'),
              child: Text(
                query.isEmpty
                    ? 'No career roles yet.'
                    : 'No roles match "$query".',
                style: TextStyle(color: p.textMuted, fontSize: 13),
              ),
            ),
          );
        }

        return Column(
          key: const ValueKey('loaded'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < filtered.length; i++) ...[
              FadeSlideIn(
                index: i,
                perItemDelay: const Duration(milliseconds: 25),
                child: _RoleRow(role: filtered[i], p: p),
              ),
              const SizedBox(height: 8),
            ],
          ],
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

class _AnalyticsHeader extends StatelessWidget {
  const _AnalyticsHeader({required this.roles, required this.p});

  final AdminRolesProvider roles;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    if (roles.listState != AdminRolesLoadState.loaded || roles.roles.isEmpty) {
      return const SizedBox.shrink();
    }

    final all = roles.roles;
    final total = all.length;
    final withRequirements = all.where((r) => r.requirementsCount > 0).length;
    final withoutRequirements = total - withRequirements;
    final chosenAtLeastOnce = all.where((r) => r.popularity > 0).length;
    final avgRequirements = total == 0
        ? 0.0
        : all.fold<int>(0, (a, r) => a + r.requirementsCount) / total;

    final topChoices = [...all]
      ..sort((a, b) => b.popularity.compareTo(a.popularity));
    final topFive = topChoices.where((r) => r.popularity > 0).take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatCardGrid(
          children: [
            StatCard(
              label: 'TOTAL ROLES',
              value: '$total',
              icon: Icons.badge_outlined,
            ),
            StatCard(
              label: 'FULLY CONFIGURED',
              value: '$withRequirements',
              icon: Icons.check_circle_outline,
              accentColor: p.green,
              caption: '$withoutRequirements with no requirements yet',
            ),
            StatCard(
              label: 'CHOSEN BY USERS',
              value: '$chosenAtLeastOnce',
              icon: Icons.flag_outlined,
              accentColor: p.amber,
            ),
            StatCard(
              label: 'AVG SKILLS / ROLE',
              value: avgRequirements.toStringAsFixed(1),
              icon: Icons.psychology_outlined,
            ),
          ],
        ),
        if (topFive.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'TOP CAREER CHOICES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: p.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          AdminCard(
            child: Column(
              children: [
                for (final role in topFive) ...[
                  _RoleBar(
                    name: role.name,
                    count: role.popularity,
                    maxCount: topFive.first.popularity,
                    p: p,
                  ),
                  if (role != topFive.last) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _RoleBar extends StatelessWidget {
  const _RoleBar({
    required this.name,
    required this.count,
    required this.maxCount,
    required this.p,
  });

  final String name;
  final int count;
  final int maxCount;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount == 0 ? 0.0 : count / maxCount;
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            name,
            style: TextStyle(fontSize: 12.5, color: p.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.02, 1.0),
              minHeight: 8,
              backgroundColor: p.border,
              valueColor: AlwaysStoppedAnimation(p.indigo),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 22,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: p.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({required this.role, required this.p});

  final AdminRoleSummary role;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.all(12),
      onTap: () => context.go('/admin/roles/${role.id}'),
      child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: p.indigoLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.badge_outlined, size: 17, color: p.indigo),
              ),
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
                        style: TextStyle(fontSize: 11.5, color: p.textMuted),
                      ),
                  ],
                ),
              ),
              _CountPill(
                icon: Icons.psychology_outlined,
                value: role.requirementsCount,
                emptyColor: p.red,
                p: p,
              ),
              const SizedBox(width: 6),
              _CountPill(
                icon: Icons.flag_outlined,
                value: role.popularity,
                emptyColor: null,
                p: p,
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: p.textMuted, size: 20),
            ],
      ),
    );
  }
}

/// Small icon+count badge — flags in red when a role has zero required
/// skills configured (an easy thing for an admin to miss and worth
/// surfacing directly in the list, not just on the detail screen).
class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.icon,
    required this.value,
    required this.emptyColor,
    required this.p,
  });

  final IconData icon;
  final int value;
  final Color? emptyColor;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == 0 && emptyColor != null;
    final color = isEmpty ? emptyColor! : p.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isEmpty ? color.withValues(alpha: 0.12) : p.surface1,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
