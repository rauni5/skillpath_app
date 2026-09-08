import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/achievement.dart';
import '../../../core/theme/app_palette.dart';
import '../providers/admin_achievements_provider.dart';
import '../widgets/admin_bits.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/shimmer_skeleton.dart';

enum _AchSortBy { title, category, unlocked }

class AdminAchievementsScreen extends StatefulWidget {
  const AdminAchievementsScreen({super.key});

  @override
  State<AdminAchievementsScreen> createState() =>
      _AdminAchievementsScreenState();
}

class _AdminAchievementsScreenState extends State<AdminAchievementsScreen> {
  final _searchCtrl = TextEditingController();
  _AchSortBy _sortBy = _AchSortBy.title;
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
            ? [...achievements.catalog]
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

        filtered.sort((a, b) {
          final cmp = switch (_sortBy) {
            _AchSortBy.title => a.title.toLowerCase().compareTo(
              b.title.toLowerCase(),
            ),
            _AchSortBy.category => a.category.toLowerCase().compareTo(
              b.category.toLowerCase(),
            ),
            _AchSortBy.unlocked => a.unlockedByCount.compareTo(
              b.unlockedByCount,
            ),
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
                sortColumnIndex: _AchSortBy.values.indexOf(_sortBy),
                sortAscending: _sortAsc,
                columns: [
                  const DataColumn(label: Text('')),
                  DataColumn(
                    label: const Text('Title'),
                    onSort: (_, asc) => setState(() {
                      _sortBy = _AchSortBy.title;
                      _sortAsc = asc;
                    }),
                  ),
                  const DataColumn(label: Text('Unlock condition')),
                  DataColumn(
                    label: const Text('Category'),
                    onSort: (_, asc) => setState(() {
                      _sortBy = _AchSortBy.category;
                      _sortAsc = asc;
                    }),
                  ),
                  DataColumn(
                    label: const Text('Unlocked by'),
                    numeric: true,
                    onSort: (_, asc) => setState(() {
                      _sortBy = _AchSortBy.unlocked;
                      _sortAsc = asc;
                    }),
                  ),
                  const DataColumn(label: Text('Status')),
                  const DataColumn(label: Text('')),
                ],
                rows: [
                  for (final a in filtered)
                    DataRow(
                      onSelectChanged: (_) =>
                          context.push('/admin/achievements/${a.id}'),
                      cells: [
                        DataCell(
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: a.enabled ? p.indigoLight : p.surface2,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Achievement.iconForName(a.icon),
                              size: 15,
                              color: a.enabled ? p.indigo : p.textMuted,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            a.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 220,
                            child: Text(
                              a.criteriaType.unlockHint(a.criteriaValue),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: p.textMuted),
                            ),
                          ),
                        ),
                        DataCell(Text(a.category)),
                        DataCell(
                          Pill(
                            icon: Icons.emoji_events_outlined,
                            label: '${a.unlockedByCount}',
                            color: a.unlockedByCount == 0
                                ? p.red
                                : p.textMuted,
                            filled: a.unlockedByCount == 0,
                          ),
                        ),
                        DataCell(
                          a.enabled
                              ? Pill(label: 'Enabled', color: p.green, filled: true)
                              : const Pill(label: 'Disabled'),
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
}

