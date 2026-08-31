import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/achievement.dart';
import '../../../core/models/admin_achievement.dart';
import '../../../core/theme/app_palette.dart';
import '../providers/admin_achievements_provider.dart';
import '../widgets/admin_bits.dart';
import '../widgets/admin_card.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/responsive_card_grid.dart';
import '../widgets/shimmer_skeleton.dart';

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
      backgroundColor: p.surface2,
      body: Column(
        children: [
          AdminPageHeader(
            icon: Icons.emoji_events_outlined,
            title: 'Achievements',
            subtitle:
                '${achievements.catalog.length} achievement${achievements.catalog.length == 1 ? '' : 's'} defined.',
            trailing: FilledButton.icon(
              onPressed: () => context.push('/admin/achievements/new'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New'),
            ),
            bottom: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search achievements…',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _buildBody(context, p, achievements),
            ),
          ),
        ],
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
      case AdminAchievementsLoadState.error:
        return InlineErrorState(
          key: const ValueKey('error'),
          message: achievements.listError ?? 'Something went wrong.',
          onRetry: _load,
        );
      case AdminAchievementsLoadState.loaded:
        final query = _searchCtrl.text.trim().toLowerCase();
        final filtered = query.isEmpty
            ? achievements.catalog
            : achievements.catalog
                  .where((a) => a.title.toLowerCase().contains(query))
                  .toList();

        if (filtered.isEmpty) {
          return EmptyState(
            key: const ValueKey('empty'),
            icon: Icons.emoji_events_outlined,
            message: query.isEmpty
                ? 'No achievements yet.'
                : 'No achievements match "$query".',
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
                  for (final a in filtered)
                    _AchievementCard(achievement: a, p: p),
                ],
              ),
            ],
          ),
        );
    }
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement, required this.p});

  final AdminAchievement achievement;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    return AdminCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.push('/admin/achievements/${a.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: a.enabled ? p.indigoLight : p.surface2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Achievement.iconForName(a.icon),
                  size: 18,
                  color: a.enabled ? p.indigo : p.textMuted,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: p.textMuted, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            a.title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            a.criteriaType.unlockHint(a.criteriaValue),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: p.textMuted, height: 1.35),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (!a.enabled) const Pill(label: 'Disabled'),
              Pill(
                icon: Icons.emoji_events_outlined,
                label: '${a.unlockedByCount} unlocked',
                color: a.unlockedByCount == 0 ? p.red : p.textMuted,
                filled: a.unlockedByCount == 0,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
