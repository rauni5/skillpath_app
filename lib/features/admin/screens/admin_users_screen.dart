import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/admin_user_summary.dart';
import '../../../core/models/admin_users_query.dart';
import '../../../core/models/user.dart';
import '../../../core/theme/app_palette.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_users_provider.dart';
import '../widgets/admin_bits.dart';
import '../widgets/admin_card.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/fade_slide_in.dart';
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
                  _StatStrip(admin: admin, p: p),
                  const SizedBox(height: 18),
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

/// A slim inline strip of key numbers instead of a full stat-card grid —
/// useful context without the page opening on a wall of analytics.
class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.admin, required this.p});

  final AdminUsersProvider admin;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    final a = admin.analytics;
    if (admin.analyticsState == AdminAnalyticsLoadState.loading && a == null) {
      return const ShimmerBox(width: double.infinity, height: 62, radius: 14);
    }
    if (a == null) return const SizedBox.shrink();

    final items = [
      ('Total', '${a.totalUsers}', Icons.people_outline, p.indigo),
      ('Admins', '${a.adminCount}', Icons.shield_outlined, p.amber),
      ('Active', '${a.availableCount}', Icons.check_circle_outline, p.green),
      ('New this week', '${a.newUsersLast7Days}', Icons.trending_up, p.red),
      (
        'Avg skills/user',
        a.avgSkillsPerUser.toStringAsFixed(1),
        Icons.psychology_outlined,
        p.indigo,
      ),
    ];

    return AdminCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 560;
          final row = Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i != 0) _divider(),
                Expanded(child: _statItem(items[i])),
              ],
            ],
          );
          if (!isNarrow) return row;
          return Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [for (final item in items) _statItem(item)],
          );
        },
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 32,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    color: p.border,
  );

  Widget _statItem((String, String, IconData, Color) item) {
    final (label, value, icon, color) = item;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: p.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: p.textPrimary,
          ),
        ),
      ],
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

/// Full-width table built from plain Rows/Expanded — not Material's
/// [DataTable], which sizes columns to content and leaves a gap or forces
/// horizontal scrolling that hides trailing columns.
class _UsersTable extends StatelessWidget {
  const _UsersTable({required this.admin, required this.p});

  final AdminUsersProvider admin;
  final AppPalette p;

  static const _flexUser = 3;
  static const _flexLevel = 2;
  static const _flexStats = 3;
  static const _flexGoal = 1;
  static const _flexJoined = 2;
  static const _flexAccess = 2;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          for (var i = 0; i < admin.users.length; i++)
            _row(context, admin.users[i], i),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      color: p.surface2,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: _flexUser, child: _sortable('User', UserSortBy.name)),
          Expanded(flex: _flexLevel, child: _label('Level')),
          Expanded(flex: _flexStats, child: _label('Stats')),
          Expanded(flex: _flexGoal, child: _label('Goal')),
          Expanded(
            flex: _flexJoined,
            child: _sortable('Joined', UserSortBy.createdAt),
          ),
          Expanded(flex: _flexAccess, child: _label('Access')),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: p.textMuted,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _sortable(String label, UserSortBy column) {
    final active = admin.sortBy == column;
    final ascending = admin.sortDir == SortDir.asc;
    return InkWell(
      onTap: () => admin.setSort(column),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: active ? p.indigo : p.textMuted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            active
                ? (ascending ? Icons.arrow_upward : Icons.arrow_downward)
                : Icons.unfold_more,
            size: 12,
            color: active ? p.indigo : p.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, AdminUserSummary summary, int index) {
    final user = summary.user;
    final isSelf = context.watch<AuthProvider>().currentUser?.id == user.id;
    final isPending = admin.pendingUserIds.contains(user.id);

    return FadeSlideIn(
      index: index,
      perItemDelay: const Duration(milliseconds: 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: index.isOdd ? p.surface2.withValues(alpha: 0.4) : null,
          border: Border(top: BorderSide(color: p.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: _flexUser,
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
            Expanded(
              flex: _flexLevel,
              child: Pill(label: _titleCase(user.experienceLevel.name)),
            ),
            Expanded(
              flex: _flexStats,
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
            Expanded(
              flex: _flexGoal,
              child: Icon(
                summary.careerGoalSet ? Icons.flag : Icons.flag_outlined,
                size: 15,
                color: summary.careerGoalSet ? p.indigo : p.textMuted,
              ),
            ),
            Expanded(
              flex: _flexJoined,
              child: Text(
                user.createdAt == null ? '—' : _formatDate(user.createdAt!),
                style: TextStyle(fontSize: 11.5, color: p.textSecondary),
              ),
            ),
            Expanded(
              flex: _flexAccess,
              child: isPending
                  ? const MiniSpinner()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(height: 5),
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
        ),
      ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(makeAdmin ? 'Grant admin access?' : 'Revoke admin access?'),
        content: Text(
          makeAdmin
              ? '${user.name} will be able to sign in to the admin panel and manage skills, roles, and users.'
              : '${user.name} will lose access to the admin panel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(makeAdmin ? 'Grant access' : 'Revoke access'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final ok = await context.read<AdminUsersProvider>().setAdmin(
        user.id,
        makeAdmin,
      );
      _showErrorIfAny(context, ok);
    }
  }

  Future<void> _confirmActiveToggle(
    BuildContext context,
    AppUser user,
    bool makeActive,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(makeActive ? 'Reactivate user?' : 'Deactivate user?'),
        content: Text(
          makeActive
              ? '${user.name} will be able to sign in again.'
              : '${user.name} will be signed out and blocked from signing '
                    'in until reactivated. Their data is kept as-is.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: makeActive ? null : AppPalette.of(ctx).red,
            ),
            child: Text(makeActive ? 'Reactivate' : 'Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final ok = await context.read<AdminUsersProvider>().setActive(
        user.id,
        makeActive,
      );
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
