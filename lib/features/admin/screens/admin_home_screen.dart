import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../providers/admin_dashboard_provider.dart';
import '../widgets/admin_card.dart';
import '../widgets/donut_chart.dart';
import '../widgets/fade_slide_in.dart';
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
      appBar: AppBar(
        title: const Text('Admin Overview'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AdminDashboardProvider>().loadStats(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            context.read<AdminDashboardProvider>().loadStats(),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (dashboard.lastUpdated != null) ...[
              Text(
                'Last updated ${_relativeTime(dashboard.lastUpdated!)}',
                style: TextStyle(fontSize: 11.5, color: p.textMuted),
              ),
              const SizedBox(height: 14),
            ],
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                FadeSlideIn(
                  index: 0,
                  child: _AdminCard(
                    icon: Icons.people_outline,
                    title: 'Users',
                    subtitle: 'View users and manage admin access.',
                    onTap: () => context.go('/admin/users'),
                  ),
                ),
                FadeSlideIn(
                  index: 1,
                  child: _AdminCard(
                    icon: Icons.psychology_outlined,
                    title: 'Skills',
                    subtitle: 'Manage the skill catalogue and dependencies.',
                    onTap: () => context.go('/admin/skills'),
                  ),
                ),
                FadeSlideIn(
                  index: 2,
                  child: _AdminCard(
                    icon: Icons.badge_outlined,
                    title: 'Career Roles',
                    subtitle: 'Manage roles and their required skills.',
                    onTap: () => context.go('/admin/roles'),
                  ),
                ),
                FadeSlideIn(
                  index: 3,
                  child: _AdminCard(
                    icon: Icons.emoji_events_outlined,
                    title: 'Achievements',
                    subtitle: 'Create and manage unlockable achievements.',
                    onTap: () => context.go('/admin/achievements'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _DashboardAnalytics(dashboard: dashboard, p: p),
          ],
        ),
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

class _DashboardAnalytics extends StatelessWidget {
  const _DashboardAnalytics({required this.dashboard, required this.p});

  final AdminDashboardProvider dashboard;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    switch (dashboard.state) {
      case AdminDashboardLoadState.initial:
      case AdminDashboardLoadState.loading:
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: StatCardGrid(
            animate: false,
            children: List.generate(6, (_) => const ShimmerStatCard()),
          ),
        );
      case AdminDashboardLoadState.error:
        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dashboard.error ?? 'Could not load platform stats.',
                style: TextStyle(color: p.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => dashboard.loadStats(),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      case AdminDashboardLoadState.loaded:
        final stats = dashboard.stats!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(text: 'PLATFORM STATS', p: p),
            const SizedBox(height: 10),
            StatCardGrid(
              children: [
                StatCard(
                  label: 'TOTAL USERS',
                  value: '${stats.totalUsers}',
                  icon: Icons.people_outline,
                  caption: '+${stats.newUsersLast7Days} this week',
                  onTap: () => context.go('/admin/users'),
                ),
                StatCard(
                  label: 'PROJECTS',
                  value: '${stats.totalProjects}',
                  icon: Icons.folder_open_outlined,
                  caption:
                      '${stats.openProjects} open · ${stats.completedProjects} done',
                ),
                StatCard(
                  label: 'SKILLS CATALOGUE',
                  value: '${stats.totalSkills}',
                  icon: Icons.psychology_outlined,
                  onTap: () => context.go('/admin/skills'),
                ),
                StatCard(
                  label: 'CAREER ROLES',
                  value: '${stats.totalCareerRoles}',
                  icon: Icons.badge_outlined,
                  onTap: () => context.go('/admin/roles'),
                ),
                StatCard(
                  label: 'ACHIEVEMENTS',
                  value: '${stats.totalAchievements}',
                  icon: Icons.emoji_events_outlined,
                  accentColor: p.amber,
                  caption: '${stats.achievementsUnlockedCount} unlocked',
                ),
                StatCard(
                  label: 'AVG SKILLS / USER',
                  value: stats.avgSkillsPerUser.toStringAsFixed(1),
                  icon: Icons.trending_up,
                  accentColor: p.green,
                ),
              ],
            ),
            if (stats.totalProjects > 0) ...[
              const SizedBox(height: 22),
              _SectionLabel(text: 'PROJECTS BY STATUS', p: p),
              const SizedBox(height: 10),
              AdminCard(
                child: DonutChart(
                  segments: [
                    DonutSegment(
                      label: 'Open',
                      value: stats.openProjects,
                      color: p.indigo,
                    ),
                    DonutSegment(
                      label: 'Completed',
                      value: stats.completedProjects,
                      color: p.green,
                    ),
                    DonutSegment(
                      label: 'Other',
                      value:
                          stats.totalProjects -
                          stats.openProjects -
                          stats.completedProjects,
                      color: p.amber,
                    ),
                  ],
                ),
              ),
            ],
            if (stats.userSignupTrend.isNotEmpty) ...[
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _SectionLabel(text: 'SIGNUPS', p: p),
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
              const SizedBox(height: 10),
              AdminCard(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
                child: AnimatedOpacity(
                  opacity: dashboard.trendLoading ? 0.5 : 1,
                  duration: const Duration(milliseconds: 150),
                  child: MiniBarChart(
                    data: stats.userSignupTrend,
                    height: 100,
                    expectedDays: dashboard.trendDays,
                  ),
                ),
              ),
            ],
            if (stats.topSkills.isNotEmpty) ...[
              const SizedBox(height: 26),
              _SectionLabel(text: 'TOP SKILLS', p: p),
              const SizedBox(height: 10),
              AdminCard(
                child: Column(
                  children: [
                    for (final skill in stats.topSkills) ...[
                      _SkillBar(
                        name: skill.name,
                        count: skill.userCount,
                        maxCount: stats.topSkills.first.userCount,
                        p: p,
                      ),
                      if (skill != stats.topSkills.last)
                        const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
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
        color: p.surface1,
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
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : p.textMuted,
          ),
        ),
      ),
    );
  }
}

class _SkillBar extends StatelessWidget {
  const _SkillBar({
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
          width: 110,
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
        Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: p.textPrimary,
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

class _AdminCard extends StatelessWidget {
  const _AdminCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SizedBox(
      width: 260,
      child: AdminCard(
        onTap: onTap,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: p.indigoLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: p.indigo, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: p.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
