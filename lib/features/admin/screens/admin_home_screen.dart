import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../providers/admin_dashboard_provider.dart';
import '../widgets/admin_bits.dart';
import '../widgets/admin_card.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/labeled_bar_list.dart';
import '../widgets/mini_bar_chart.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/stat_card.dart';
import '../widgets/stat_card_grid.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminDashboardProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dashboard = context.watch<AdminDashboardProvider>();

    return Scaffold(
      backgroundColor: p.surface2,
      body: Column(
        children: [
          AdminPageHeader(
            icon: Icons.dashboard_outlined,
            title: 'Overview',
            subtitle: dashboard.lastUpdated == null
                ? 'A snapshot of your platform\'s activity.'
                : 'Last updated ${_relativeTime(dashboard.lastUpdated!)}.',
            trailing: IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  context.read<AdminDashboardProvider>().loadStats(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
                  context.read<AdminDashboardProvider>().loadStats(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                children: [
                  StatCardGrid(
                    minCardWidth: 220,
                    maxColumns: 4,
                    children: [
                      _QuickLink(
                        icon: Icons.people_outline,
                        title: 'Users',
                        color: p.indigo,
                        onTap: () => context.go('/admin/users'),
                      ),
                      _QuickLink(
                        icon: Icons.psychology_outlined,
                        title: 'Skills',
                        color: p.green,
                        onTap: () => context.go('/admin/skills'),
                      ),
                      _QuickLink(
                        icon: Icons.badge_outlined,
                        title: 'Roles',
                        color: p.amber,
                        onTap: () => context.go('/admin/roles'),
                      ),
                      _QuickLink(
                        icon: Icons.emoji_events_outlined,
                        title: 'Achievements',
                        color: p.red,
                        onTap: () => context.go('/admin/achievements'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _Body(dashboard: dashboard, p: p),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 10) return 'just now';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return AdminCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.arrow_forward, size: 14, color: p.textMuted),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.dashboard, required this.p});

  final AdminDashboardProvider dashboard;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    switch (dashboard.state) {
      case AdminDashboardLoadState.initial:
      case AdminDashboardLoadState.loading:
        return StatCardGrid(
          animate: false,
          children: List.generate(6, (_) => const ShimmerStatCard()),
        );
      case AdminDashboardLoadState.error:
        return InlineErrorState(
          message: dashboard.error ?? 'Could not load platform stats.',
          onRetry: () => dashboard.loadStats(),
        );
      case AdminDashboardLoadState.loaded:
        final stats = dashboard.stats!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Platform stats'),
            const SizedBox(height: 12),
            StatCardGrid(
              children: [
                StatCard(
                  label: 'Total users',
                  value: '${stats.totalUsers}',
                  icon: Icons.people_outline,
                  caption: '+${stats.newUsersLast7Days} this week',
                  onTap: () => context.go('/admin/users'),
                ),
                StatCard(
                  label: 'Projects',
                  value: '${stats.totalProjects}',
                  icon: Icons.folder_open_outlined,
                  caption:
                      '${stats.openProjects} open · ${stats.completedProjects} done',
                ),
                StatCard(
                  label: 'Skills catalogue',
                  value: '${stats.totalSkills}',
                  icon: Icons.psychology_outlined,
                  accentColor: p.green,
                  onTap: () => context.go('/admin/skills'),
                ),
                StatCard(
                  label: 'Career roles',
                  value: '${stats.totalCareerRoles}',
                  icon: Icons.badge_outlined,
                  accentColor: p.amber,
                  onTap: () => context.go('/admin/roles'),
                ),
                StatCard(
                  label: 'Achievements',
                  value: '${stats.totalAchievements}',
                  icon: Icons.emoji_events_outlined,
                  accentColor: p.red,
                  caption: '${stats.achievementsUnlockedCount} unlocked',
                  onTap: () => context.go('/admin/achievements'),
                ),
                StatCard(
                  label: 'Avg skills / user',
                  value: stats.avgSkillsPerUser.toStringAsFixed(1),
                  icon: Icons.trending_up,
                  accentColor: p.indigo,
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const SectionLabel('Signups'),
                              if (dashboard.trendLoading) ...[
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 11,
                                  height: 11,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.6,
                                    color: p.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          _TrendDaySelector(dashboard: dashboard, p: p),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AdminCard(
                        child: AnimatedOpacity(
                          opacity: dashboard.trendLoading ? 0.5 : 1,
                          duration: const Duration(milliseconds: 150),
                          child: MiniBarChart(
                            data: stats.userSignupTrend,
                            height: 140,
                            expectedDays: dashboard.trendDays,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                if (stats.topSkills.isNotEmpty)
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionLabel('Top skills'),
                        const SizedBox(height: 12),
                        AdminCard(
                          child: LabeledBarList(
                            items: [
                              for (final s in stats.topSkills)
                                BarListItem(label: s.name, value: s.userCount),
                            ],
                            barColor: p.green,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        );
    }
  }
}

class _TrendDaySelector extends StatelessWidget {
  const _TrendDaySelector({required this.dashboard, required this.p});

  final AdminDashboardProvider dashboard;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final days in AdminDashboardProvider.trendDayOptions)
            _DayChip(
              days: days,
              selected: dashboard.trendDays == days,
              onTap: () => dashboard.setTrendDays(days),
              p: p,
            ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.days,
    required this.selected,
    required this.onTap,
    required this.p,
  });

  final int days;
  final bool selected;
  final VoidCallback onTap;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? p.indigo : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${days}d',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : p.textMuted,
          ),
        ),
      ),
    );
  }
}
