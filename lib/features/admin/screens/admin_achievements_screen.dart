import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/achievement.dart';
import '../../../core/models/admin_achievement.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../providers/admin_achievements_provider.dart';

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
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
        return const LoadingView(key: ValueKey('loading'));
      case AdminAchievementsLoadState.error:
        return ErrorView(
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
          return Center(
            key: const ValueKey('empty'),
            child: Text(
              query.isEmpty
                  ? 'No achievements yet.'
                  : 'No achievements match "$query".',
              style: TextStyle(color: p.textMuted, fontSize: 13),
            ),
          );
        }

        return RefreshIndicator(
          key: const ValueKey('loaded'),
          onRefresh: () async => _load(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final a = filtered[i];
              return Material(
                color: p.surface2,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => context.go('/admin/achievements/${a.id}'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: p.border),
                    ),
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
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: p.textMuted,
                                ),
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
                        Text(
                          '${a.unlockedByCount}',
                          style: TextStyle(fontSize: 11.5, color: p.textMuted),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 14,
                          color: p.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.chevron_right, color: p.textMuted, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
    }
  }
}
