import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/admin_user_summary.dart';
import '../../../core/models/admin_users_query.dart';
import '../../../core/models/user.dart';
import '../../../core/theme/app_palette.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_users_provider.dart';
import '../widgets/admin_bits.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/shimmer_skeleton.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
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

  void _load() {
    final admin = context.read<AdminUsersProvider>();
    admin.loadUsers();
    admin.loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final admin = context.watch<AdminUsersProvider>();

    return Scaffold(
      backgroundColor: p.surface2,
      body: Column(
        children: [
          AdminPageHeader(
            icon: Icons.people_outline,
            title: 'Users',
            subtitle:
                '${admin.totalElements} user${admin.totalElements == 1 ? '' : 's'} on the platform.',
            trailing: IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: _load,
            ),
            bottom: TextField(
              controller: _searchCtrl,
              onChanged: (v) =>
                  context.read<AdminUsersProvider>().setSearchQuery(v),
              decoration: const InputDecoration(
                hintText: 'Search by name or email…',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _load(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                children: [
                  _StatusFilterRow(admin: admin, p: p),
                  const SizedBox(height: 16),
                  _ListBody(admin: admin, p: p),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterRow extends StatelessWidget {
  const _StatusFilterRow({required this.admin, required this.p});

  final AdminUsersProvider admin;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in UserStatusFilter.values) ...[
            ChoiceChip(
              label: Text(filter.label),
              selected: admin.statusFilter == filter,
              onSelected: (_) => admin.setStatusFilter(filter),
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: admin.statusFilter == filter
                    ? p.indigo
                    : p.textSecondary,
              ),
              selectedColor: p.indigoLight,
              backgroundColor: p.surface1,
              side: BorderSide(color: p.border),
              showCheckmark: false,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody({required this.admin, required this.p});

  final AdminUsersProvider admin;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    switch (admin.state) {
      case AdminUsersLoadState.initial:
      case AdminUsersLoadState.loading:
        return Column(
          children: List.generate(
            6,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: ShimmerListRow(),
            ),
          ),
        );
      case AdminUsersLoadState.error:
        return InlineErrorState(
          message: admin.error ?? 'Something went wrong.',
          onRetry: () {
            admin.loadUsers();
            admin.loadAnalytics();
          },
        );
      case AdminUsersLoadState.loaded:
        if (admin.users.isEmpty) {
          return EmptyState(
            icon: Icons.people_outline,
            message: admin.searchQuery.isEmpty
                ? 'No users match this filter.'
                : 'No users match "${admin.searchQuery}".',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _UsersTable(admin: admin, p: p),
            const SizedBox(height: 12),
            _Pager(admin: admin, p: p),
          ],
        );
    }
  }
}

class _Pager extends StatelessWidget {
  const _Pager({required this.admin, required this.p});

  final AdminUsersProvider admin;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    if (admin.totalPages <= 1) {
      return Text(
        '${admin.totalElements} user${admin.totalElements == 1 ? '' : 's'} total',
        style: TextStyle(fontSize: 12, color: p.textMuted),
      );
    }
    final currentPage = admin.page;
    final canGoBack = currentPage > 0;
    final canGoForward = currentPage < admin.totalPages - 1;
    return Row(
      children: [
        Text(
          '${admin.totalElements} users • page ${currentPage + 1} of ${admin.totalPages}',
          style: TextStyle(fontSize: 12, color: p.textMuted),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Previous page',
          icon: const Icon(Icons.chevron_left),
          onPressed: canGoBack ? () => admin.goToPage(currentPage - 1) : null,
        ),
        IconButton(
          tooltip: 'Next page',
          icon: const Icon(Icons.chevron_right),
          onPressed: canGoForward
              ? () => admin.goToPage(currentPage + 1)
              : null,
        ),
      ],
    );
  }
}

/// Renders through the same [AdminDataTable] used by the Skills, Roles,
/// and Achievements screens — same fill-then-scroll responsive behavior,
/// same header/row chrome — instead of the bespoke Row/Expanded table
/// this replaced, which had none of that and crushed illegibly on
/// narrow/mobile-web widths.
class _UsersTable extends StatelessWidget {
  const _UsersTable({required this.admin, required this.p});

  final AdminUsersProvider admin;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().currentUser?.id;

    return AdminDataTable(
      sortColumnIndex: switch (admin.sortBy) {
        UserSortBy.name => 0,
        UserSortBy.createdAt => 4,
        UserSortBy.email => null,
      },
      sortAscending: admin.sortDir == SortDir.asc,
      columns: [
        DataColumn(
          label: const Text('User'),
          onSort: (_, _) => admin.setSort(UserSortBy.name),
        ),
        const DataColumn(label: Text('Level')),
        const DataColumn(label: Text('Stats')),
        const DataColumn(label: Text('Goal')),
        DataColumn(
          label: const Text('Joined'),
          onSort: (_, _) => admin.setSort(UserSortBy.createdAt),
        ),
        const DataColumn(label: Text('Access')),
      ],
      rows: [
        for (final summary in admin.users)
          _buildRow(context, summary, currentUserId),
      ],
    );
  }

  DataRow _buildRow(
    BuildContext context,
    AdminUserSummary summary,
    int? currentUserId,
  ) {
    final user = summary.user;
    final isSelf = currentUserId == user.id;
    final isPending = admin.pendingUserIds.contains(user.id);

    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 190,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: p.indigoLight,
                  child: Text(
                    user.initials,
                    style: TextStyle(
                      color: p.indigo,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: p.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelf) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(you)',
                              style: TextStyle(
                                fontSize: 10,
                                color: p.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        user.email,
                        style: TextStyle(fontSize: 11, color: p.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(Pill(label: _titleCase(user.experienceLevel.name))),
        DataCell(
          SizedBox(
            width: 150,
            child: Wrap(
              spacing: 8,
              runSpacing: 3,
              children: [
                _statChip(Icons.psychology_outlined, summary.skillsCount),
                _statChip(
                  Icons.folder_open_outlined,
                  summary.ownedProjectsCount,
                ),
                _statChip(
                  Icons.emoji_events_outlined,
                  summary.achievementsCount,
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Icon(
            summary.careerGoalSet ? Icons.flag : Icons.flag_outlined,
            size: 15,
            color: summary.careerGoalSet ? p.indigo : p.textMuted,
          ),
        ),
        DataCell(
          Text(
            user.createdAt == null ? '—' : _formatDate(user.createdAt!),
            style: TextStyle(fontSize: 11.5, color: p.textSecondary),
          ),
        ),
        DataCell(
          // Two badges stacked vertically (the original layout) could run
          // taller than the DataTable's fixed row height, spilling down
          // into the row below and overlapping its cells — a fixed-height
          // table row can't grow to fit taller content the way the old
          // Row/Expanded table's rows could. Side by side instead, this
          // comfortably fits within a single row's height no matter how
          // tall the table's rows are configured.
          isPending
              ? const MiniSpinner()
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ToggleBadge(
                      active: user.isAdmin,
                      activeLabel: 'Admin',
                      inactiveLabel: 'User',
                      activeColor: p.amber,
                      onTap: isSelf
                          ? null
                          : () => _confirmAdminToggle(
                              context,
                              user,
                              !user.isAdmin,
                            ),
                    ),
                    const SizedBox(width: 8),
                    ToggleBadge(
                      active: user.isActive,
                      activeLabel: 'Active',
                      inactiveLabel: 'Inactive',
                      activeColor: p.green,
                      onTap: isSelf
                          ? null
                          : () => _confirmActiveToggle(
                              context,
                              user,
                              !user.isActive,
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _statChip(IconData icon, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: p.textMuted),
        const SizedBox(width: 2),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: p.textSecondary,
          ),
        ),
      ],
    );
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  Future<void> _confirmAdminToggle(
    BuildContext context,
    AppUser user,
    bool makeAdmin,
  ) async {
    final confirmed = await showAdminConfirmDialog(
      context,
      title: makeAdmin ? 'Grant admin access?' : 'Revoke admin access?',
      message: makeAdmin
          ? '${user.name} will be able to sign in to the admin panel and manage skills, roles, and users.'
          : '${user.name} will lose access to the admin panel.',
      confirmLabel: makeAdmin ? 'Grant access' : 'Revoke access',
      icon: Icons.shield_outlined,
      destructive: !makeAdmin,
    );
    if (confirmed == true && context.mounted) {
      final ok = await context.read<AdminUsersProvider>().setAdmin(
        user.id,
        makeAdmin,
      );
      if (!context.mounted) return;
      _showErrorIfAny(context, ok);
    }
  }

  Future<void> _confirmActiveToggle(
    BuildContext context,
    AppUser user,
    bool makeActive,
  ) async {
    final confirmed = await showAdminConfirmDialog(
      context,
      title: makeActive ? 'Reactivate user?' : 'Deactivate user?',
      message: makeActive
          ? '${user.name} will be able to sign in again.'
          : '${user.name} will be signed out and blocked from signing '
                'in until reactivated. Their data is kept as-is.',
      confirmLabel: makeActive ? 'Reactivate' : 'Deactivate',
      icon: Icons.check_circle_outline,
      destructive: !makeActive,
    );
    if (confirmed == true && context.mounted) {
      final ok = await context.read<AdminUsersProvider>().setActive(
        user.id,
        makeActive,
      );
      if (!context.mounted) return;
      _showErrorIfAny(context, ok);
    }
  }

  void _showErrorIfAny(BuildContext context, bool ok) {
    if (!ok && context.mounted) {
      final error = context.read<AdminUsersProvider>().error;
      if (error != null) {}
    }
  }
}
