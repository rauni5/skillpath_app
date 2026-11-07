import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../providers/admin_roles_provider.dart';
import '../widgets/admin_bits.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/shimmer_skeleton.dart';

enum _RoleSortBy { name, branches, skills, popularity }

class AdminRolesScreen extends StatefulWidget {
  const AdminRolesScreen({super.key});

  @override
  State<AdminRolesScreen> createState() => _AdminRolesScreenState();
}

class _AdminRolesScreenState extends State<AdminRolesScreen> {
  final _searchCtrl = TextEditingController();
  _RoleSortBy _sortBy = _RoleSortBy.name;
  bool _sortAsc = true;

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
            ? [...roles.roles]
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

        filtered.sort((a, b) {
          final cmp = switch (_sortBy) {
            _RoleSortBy.name => a.name.toLowerCase().compareTo(
              b.name.toLowerCase(),
            ),
            _RoleSortBy.branches => a.branchCount.compareTo(b.branchCount),
            _RoleSortBy.skills => a.requirementsCount.compareTo(
              b.requirementsCount,
            ),
            _RoleSortBy.popularity => a.popularity.compareTo(b.popularity),
          };
          return _sortAsc ? cmp : -cmp;
        });

        return RefreshIndicator(
          key: const ValueKey('loaded'),
          onRefresh: () async => _load(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            children: [
              AdminDataTable(
                sortColumnIndex: _RoleSortBy.values.indexOf(_sortBy),
                sortAscending: _sortAsc,
                columns: [
                  DataColumn(
                    label: const Text('Name'),
                    onSort: (_, asc) => setState(() {
                      _sortBy = _RoleSortBy.name;
                      _sortAsc = asc;
                    }),
                  ),
                  const DataColumn(label: Text('Description')),
                  DataColumn(
                    label: const Text('Branches'),
                    numeric: true,
                    onSort: (_, asc) => setState(() {
                      _sortBy = _RoleSortBy.branches;
                      _sortAsc = asc;
                    }),
                  ),
                  DataColumn(
                    label: const Text('Skills'),
                    numeric: true,
                    onSort: (_, asc) => setState(() {
                      _sortBy = _RoleSortBy.skills;
                      _sortAsc = asc;
                    }),
                  ),
                  DataColumn(
                    label: const Text('Popularity'),
                    numeric: true,
                    onSort: (_, asc) => setState(() {
                      _sortBy = _RoleSortBy.popularity;
                      _sortAsc = asc;
                    }),
                  ),
                  const DataColumn(label: Text('')),
                ],
                rows: [
                  for (final role in filtered)
                    DataRow(
                      onSelectChanged: (_) =>
                          context.push('/admin/roles/${role.id}'),
                      cells: [
                        DataCell(
                          Text(
                            role.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 260,
                            child: Text(
                              (role.description ?? '').trim().isNotEmpty
                                  ? role.description!
                                  : '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: p.textMuted),
                            ),
                          ),
                        ),
                        DataCell(
                          Pill(
                            icon: Icons.alt_route,
                            label: '${role.branchCount}',
                            color: role.branchCount == 0 ? p.red : p.textMuted,
                            filled: role.branchCount == 0,
                          ),
                        ),
                        DataCell(
                          Pill(
                            icon: Icons.psychology_outlined,
                            label: '${role.requirementsCount}',
                          ),
                        ),
                        DataCell(
                          Pill(
                            icon: Icons.flag_outlined,
                            label: '${role.popularity}',
                          ),
                        ),
                        DataCell(
                          Icon(Icons.chevron_right, size: 18, color: p.textMuted),
                        ),
                      ],
                    ),
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
          return AdminFormDialog(
            icon: Icons.badge_outlined,
            title: 'New career role',
            subtitle: 'Add a role students can pick as a career goal.',
            accentColor: AppPalette.of(ctx).amber,
            isSubmitting: roles.isCreating,
            errorText: roles.createError,
            onCancel: () => Navigator.of(ctx).pop(),
            onSubmit: () async {
              if (!formKey.currentState!.validate()) return;
              final created = await roles.createRole(
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
              );
              if (created != null && ctx.mounted) {
                Navigator.of(ctx).pop();
              }
            },
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      prefixIcon: Icon(Icons.notes_outlined, size: 20),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

