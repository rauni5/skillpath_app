import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/achievement.dart';
import '../../../core/models/admin_achievement.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../providers/admin_achievements_provider.dart';
import '../widgets/admin_card.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/stat_card.dart';
import '../widgets/stat_card_grid.dart';

class AdminAchievementsScreen extends StatefulWidget {
  const AdminAchievementsScreen({super.key});

  @override
  State<AdminAchievementsScreen> createState() =>
      _AdminAchievementsScreenState();
}

class _AdminAchievementsScreenState extends State<AdminAchievementsScreen> {
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

  void _load() => context.read<AdminAchievementsProvider>().loadCatalog();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final achievements = context.watch<AdminAchievementsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          IconButton(
            tooltip: 'New achievement',
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/admin/achievements/new'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _AnalyticsHeader(achievements: achievements, p: p),
            const SizedBox(height: 20),
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search achievements…',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            _buildBody(context, p, achievements),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppPalette p,
    AdminAchievementsProvider achievements,
  ) {
    switch (achievements.listState) {
      case AdminAchievementsLoadState.initial:
      case AdminAchievementsLoadState.loading:
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
      case AdminAchievementsLoadState.error:
        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: ErrorView(
            key: const ValueKey('error'),
            message: achievements.listError ?? 'Something went wrong.',
            onRetry: _load,
          ),
        );
      case AdminAchievementsLoadState.loaded:
        final query = _searchCtrl.text.trim().toLowerCase();
        final filtered = query.isEmpty
            ? achievements.catalog
            : achievements.catalog
                  .where((a) => a.title.toLowerCase().contains(query))
                  .toList();

        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              key: const ValueKey('empty'),
              child: Text(
                query.isEmpty
                    ? 'No achievements yet.'
                    : 'No achievements match "$query".',
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
                child: _AchievementRow(achievement: filtered[i], p: p),
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
    }
  }
}

class _AnalyticsHeader extends StatelessWidget {
  const _AnalyticsHeader({required this.achievements, required this.p});

  final AdminAchievementsProvider achievements;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    if (achievements.listState != AdminAchievementsLoadState.loaded ||
        achievements.catalog.isEmpty) {
      return const SizedBox.shrink();
    }

    final catalog = achievements.catalog;
    final total = catalog.length;
    final enabled = catalog.where((a) => a.enabled).length;
    final disabled = total - enabled;
    final totalUnlocks = catalog.fold<int>(0, (a, b) => a + b.unlockedByCount);
    final neverUnlocked = catalog.where((a) => a.unlockedByCount == 0).length;
    final avgUnlocks = total == 0 ? 0.0 : totalUnlocks / total;

    final mostEarned = [...catalog]
      ..sort((a, b) => b.unlockedByCount.compareTo(a.unlockedByCount));
    final topFive = mostEarned
        .where((a) => a.unlockedByCount > 0)
        .take(5)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatCardGrid(
          children: [
            StatCard(
              label: 'TOTAL ACHIEVEMENTS',
              value: '$total',
              icon: Icons.emoji_events_outlined,
              caption: disabled > 0 ? '$disabled disabled' : null,
            ),
            StatCard(
              label: 'ENABLED',
              value: '$enabled',
              icon: Icons.check_circle_outline,
              accentColor: p.green,
            ),
            StatCard(
              label: 'TOTAL UNLOCKS',
              value: '$totalUnlocks',
              icon: Icons.lock_open_outlined,
              accentColor: p.amber,
              caption: 'avg ${avgUnlocks.toStringAsFixed(1)} per achievement',
            ),
            StatCard(
              label: 'NEVER UNLOCKED',
              value: '$neverUnlocked',
              icon: Icons.hourglass_empty,
              accentColor: neverUnlocked > 0 ? p.red : null,
            ),
          ],
        ),
        if (topFive.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'MOST EARNED',
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
                for (final a in topFive) ...[
                  _AchievementBar(
                    name: a.title,
                    count: a.unlockedByCount,
                    maxCount: topFive.first.unlockedByCount,
                    p: p,
                  ),
                  if (a != topFive.last) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _AchievementBar extends StatelessWidget {
  const _AchievementBar({
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
              valueColor: AlwaysStoppedAnimation(p.amber),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 26,
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

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.achievement, required this.p});

  final AdminAchievement achievement;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    return AdminCard(
      padding: const EdgeInsets.all(12),
      onTap: () => context.go('/admin/achievements/${a.id}'),
      child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: a.enabled ? p.indigoLight : p.surface1,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Achievement.iconForName(a.icon),
                  size: 18,
                  color: a.enabled ? p.indigo : p.textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a.criteriaType.unlockHint(a.criteriaValue),
                      style: TextStyle(fontSize: 11.5, color: p.textMuted),
                    ),
                  ],
                ),
              ),
              if (!a.enabled)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: p.surface1,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Disabled',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: p.textMuted,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: a.unlockedByCount == 0
                      ? p.redLight
                      : p.surface1,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 12,
                      color: a.unlockedByCount == 0 ? p.red : p.textMuted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${a.unlockedByCount}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: a.unlockedByCount == 0 ? p.red : p.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: p.textMuted, size: 20),
            ],
      ),
    );
  }
}
