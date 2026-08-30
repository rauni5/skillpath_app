import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/admin_user_summary.dart';
import '../../../core/models/admin_user_analytics.dart';
import '../../../core/models/admin_users_query.dart';
import '../../../core/models/user.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_users_provider.dart';
import '../widgets/admin_card.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/mini_bar_chart.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/stat_card.dart';
import '../widgets/stat_card_grid.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminUsersProvider>();
      admin.loadUsers();
      admin.loadAnalytics();
    });
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
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _AnalyticsHeader(admin: admin, p: p),
            const SizedBox(height: 24),
            TextField(
              controller: _searchCtrl,
              onChanged: (v) =>
                  context.read<AdminUsersProvider>().setSearchQuery(v),
              decoration: const InputDecoration(
                hintText: 'Search by name or email…',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            _StatusFilterRow(admin: admin, p: p),
            const SizedBox(height: 14),
            _buildBody(context, p, admin),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppPalette p,
    AdminUsersProvider admin,
  ) {
    switch (admin.state) {
      case AdminUsersLoadState.initial:
      case AdminUsersLoadState.loading:
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            children: List.generate(
              6,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: ShimmerListRow(),
              ),
            ),
          ),
        );
      case AdminUsersLoadState.error:
        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: ErrorView(
            key: const ValueKey('error'),
            message: admin.error ?? 'Something went wrong.',
            onRetry: _load,
          ),
        );
      case AdminUsersLoadState.loaded:
        if (admin.users.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              key: const ValueKey('empty'),
              child: Text(
                admin.searchQuery.isEmpty
                    ? 'No users match this filter.'
                    : 'No users match "${admin.searchQuery}".',
                style: TextStyle(color: p.textMuted, fontSize: 13),
              ),
            ),
          );
        }

        return Column(
          key: const ValueKey('loaded'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _UsersTable(admin: admin, p: p),
            const SizedBox(height: 12),
            _Pager(admin: admin),
          ],
        );
    }
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
                fontWeight: FontWeight.w600,
                color: admin.statusFilter == filter
                    ? p.indigo
                    : p.textSecondary,
              ),
              selectedColor: p.indigoLight,
              backgroundColor: p.surface2,
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

class _Pager extends StatelessWidget {
  const _Pager({required this.admin});

  final AdminUsersProvider admin;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    if (admin.totalPages <= 1) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${admin.totalElements} user${admin.totalElements == 1 ? '' : 's'} total',
          style: TextStyle(fontSize: 12, color: p.textMuted),
        ),
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

/// Analytics: a 3-column stat grid plus a couple of charts for variety
/// (donut for the categorical experience-level split, bars for the
/// signup trend over time).
class _AnalyticsHeader extends StatelessWidget {
  const _AnalyticsHeader({required this.admin, required this.p});

  final AdminUsersProvider admin;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    final analytics = admin.analytics;

    if (admin.analyticsState == AdminAnalyticsLoadState.loading &&
        analytics == null) {
      return const SizedBox(
        height: 90,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (analytics == null) {
      // Analytics failed to load — don't block the user list over it.
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatCardGrid(
          children: [
            StatCard(
              label: 'TOTAL USERS',
              value: '${analytics.totalUsers}',
              icon: Icons.people_outline,
              onTap: () => admin.setStatusFilter(UserStatusFilter.all),
            ),
            StatCard(
              label: 'ADMINS',
              value: '${analytics.adminCount}',
              icon: Icons.shield_outlined,
              accentColor: p.amber,
              onTap: () => admin.setStatusFilter(UserStatusFilter.admin),
            ),
            StatCard(
              label: 'AVAILABLE',
              value: '${analytics.availableCount}',
              icon: Icons.check_circle_outline,
              accentColor: p.green,
              caption: '${analytics.unavailableCount} unavailable',
            ),
            StatCard(
              label: 'NEW THIS WEEK',
              value: '${analytics.newUsersLast7Days}',
              icon: Icons.trending_up,
              caption: '${analytics.newUsersLast30Days} in last 30 days',
            ),
            StatCard(
              label: 'AVG SKILLS / USER',
              value: analytics.avgSkillsPerUser.toStringAsFixed(1),
              icon: Icons.psychology_outlined,
            ),
            StatCard(
              label: 'CAREER GOAL SET',
              value: '${analytics.usersWithCareerGoalSet}',
              icon: Icons.flag_outlined,
            ),
          ],
        ),
        if (analytics.byExperienceLevel.values.any((v) => v > 0)) ...[
          const SizedBox(height: 18),
          _SectionLabel(text: 'BY EXPERIENCE LEVEL', p: p),
          const SizedBox(height: 10),
          AdminCard(
            child: Column(
              children: [
                for (final entry in _levelEntries(analytics)) ...[
                  _LevelBar(
                    label: _titleCase(entry.key),
                    count: entry.value,
                    maxCount: _levelMax(analytics),
                    color: _levelColor(entry.key, p),
                    p: p,
                  ),
                  if (entry != _levelEntries(analytics).last)
                    const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
        if (analytics.signupTrend.isNotEmpty) ...[
          const SizedBox(height: 18),
          _SectionLabel(text: 'SIGNUPS — LAST 30 DAYS', p: p),
          const SizedBox(height: 10),
          AdminCard(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
            child: MiniBarChart(data: analytics.signupTrend, height: 90),
          ),
        ],
      ],
    );
  }

  List<MapEntry<String, int>> _levelEntries(AdminUserAnalytics analytics) {
    // Only show levels that are actually in use, in a stable order.
    return analytics.byExperienceLevel.entries
        .where((e) => e.value > 0)
        .toList();
  }

  int _levelMax(AdminUserAnalytics analytics) {
    return analytics.byExperienceLevel.values.fold(0, (a, b) => a > b ? a : b);
  }

  Color _levelColor(String level, AppPalette p) {
    switch (level.toUpperCase()) {
      case 'BEGINNER':
        return p.amber;
      case 'ADVANCED':
        return p.green;
      case 'INTERMEDIATE':
      default:
        return p.indigo;
    }
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}

class _LevelBar extends StatelessWidget {
  const _LevelBar({
    required this.label,
    required this.count,
    required this.maxCount,
    required this.color,
    required this.p,
  });

  final String label;
  final int count;
  final int maxCount;
  final Color color;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount == 0 ? 0.0 : count / maxCount;
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
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
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 24,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.p});

  final String text;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: p.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }
}

/// The actual user table — a proper Material [DataTable], horizontally
/// scrollable, with sortable Name and Joined columns (mapped to the
/// server-side sort), per-user stats, and Admin/Active toggles inline.
/// Full-width table built from plain Rows/Expanded — not Material's
/// [DataTable], which sizes columns to content and leaves a gap (or forces
/// horizontal scrolling that hides trailing columns like the toggles).
/// Flex-based columns always fill the available width and every column,
/// including Access, stays on-screen without scrolling.
class _UsersTable extends StatelessWidget {
  const _UsersTable({required this.admin, required this.p});

  final AdminUsersProvider admin;
  final AppPalette p;

  // Shared flex ratios between the header and every data row.
  static const _flexUser = 3;
  static const _flexLevel = 2;
  static const _flexStats = 3;
  static const _flexGoal = 1;
  static const _flexJoined = 2;
  static const _flexAccess = 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          for (var i = 0; i < admin.users.length; i++)
            _buildRow(context, admin.users[i], i),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: p.surface1,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: _flexUser,
            child: _SortableHeaderLabel(
              label: 'User',
              active: admin.sortBy == UserSortBy.name,
              ascending: admin.sortDir == SortDir.asc,
              onTap: () => admin.setSort(UserSortBy.name),
              p: p,
            ),
          ),
          Expanded(flex: _flexLevel, child: _HeaderLabel('Level', p)),
          Expanded(flex: _flexStats, child: _HeaderLabel('Stats', p)),
          Expanded(flex: _flexGoal, child: _HeaderLabel('Goal', p)),
          Expanded(
            flex: _flexJoined,
            child: _SortableHeaderLabel(
              label: 'Joined',
              active: admin.sortBy == UserSortBy.createdAt,
              ascending: admin.sortDir == SortDir.asc,
              onTap: () => admin.setSort(UserSortBy.createdAt),
              p: p,
            ),
          ),
          Expanded(flex: _flexAccess, child: _HeaderLabel('Access', p)),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, AdminUserSummary summary, int index) {
    final user = summary.user;
    final isSelf = context.watch<AuthProvider>().currentUser?.id == user.id;
    final isPending = admin.pendingUserIds.contains(user.id);

    return FadeSlideIn(
      index: index,
      perItemDelay: const Duration(milliseconds: 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: index.isOdd ? p.surface1.withValues(alpha: 0.35) : null,
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
                  radius: 13,
                  backgroundColor: p.indigoLight,
                  child: Text(
                    user.initials,
                    style: TextStyle(
                      color: p.indigo,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
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
                                fontWeight: FontWeight.w600,
                                color: p.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelf) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(you)',
                              style: TextStyle(fontSize: 10, color: p.textMuted),
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
            child: _LevelBadge(level: user.experienceLevel.name, p: p),
          ),
          Expanded(
            flex: _flexStats,
            child: _StatsCell(summary: summary, p: p),
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
                ? const _MiniSpinner()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ToggleBadge(
                        active: user.isAdmin,
                        activeLabel: 'Admin',
                        inactiveLabel: 'User',
                        activeColor: p.amber,
                        p: p,
                        onTap: isSelf
                            ? null
                            : () => _confirmAdminToggle(
                                  context,
                                  user,
                                  !user.isAdmin,
                                ),
                      ),
                      const SizedBox(height: 5),
                      _ToggleBadge(
                        active: user.isActive,
                        activeLabel: 'Active',
                        inactiveLabel: 'Inactive',
                        activeColor: p.green,
                        p: p,
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

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
        title: Text(
          makeAdmin ? 'Grant admin access?' : 'Revoke admin access?',
        ),
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
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.text, this.p);

  final String text;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: p.textMuted,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _SortableHeaderLabel extends StatelessWidget {
  const _SortableHeaderLabel({
    required this.label,
    required this.active,
    required this.ascending,
    required this.onTap,
    required this.p,
  });

  final String label;
  final bool active;
  final bool ascending;
  final VoidCallback onTap;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
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
}

/// The three per-user counts (skills/projects/achievements) as small icon
/// chips that wrap, rather than three separate table columns — keeps the
/// table to six columns total so it fits full-width without scrolling.
class _StatsCell extends StatelessWidget {
  const _StatsCell({required this.summary, required this.p});

  final AdminUserSummary summary;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 3,
      children: [
        _StatChip(
          icon: Icons.psychology_outlined,
          value: summary.skillsCount,
          p: p,
        ),
        _StatChip(
          icon: Icons.folder_open_outlined,
          value: summary.ownedProjectsCount,
          p: p,
        ),
        _StatChip(
          icon: Icons.emoji_events_outlined,
          value: summary.achievementsCount,
          p: p,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.value, required this.p});

  final IconData icon;
  final int value;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: p.textMuted),
        const SizedBox(width: 2),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: p.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MiniSpinner extends StatelessWidget {
  const _MiniSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 18,
      width: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

/// Compact pill toggle used for Admin/Active columns — replaces the
/// full-size Material [Switch], which was clipping inside the table's
/// tight row height. Tap to flip; the confirm dialog decides the outcome.
class _ToggleBadge extends StatelessWidget {
  const _ToggleBadge({
    required this.active,
    required this.activeLabel,
    required this.inactiveLabel,
    required this.activeColor,
    required this.p,
    this.onTap,
  });

  final bool active;
  final String activeLabel;
  final String inactiveLabel;
  final Color activeColor;
  final AppPalette p;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: active ? activeColor.withValues(alpha: 0.14) : p.surface1,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active
                    ? activeColor.withValues(alpha: 0.4)
                    : p.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active ? Icons.check_circle : Icons.remove_circle_outline,
                  size: 12,
                  color: active ? activeColor : p.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  active ? activeLabel : inactiveLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active ? activeColor : p.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level, required this.p});

  final String level;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    final label = level.isEmpty
        ? '—'
        : level[0].toUpperCase() + level.substring(1).toLowerCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: p.indigoTint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: p.indigo,
        ),
      ),
    );
  }
}
