import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/skill.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/skills_provider.dart';
import '../widgets/owned_skill_tile.dart';

const _categoryOrder = [
  SkillCategory.frontend,
  SkillCategory.backend,
  SkillCategory.mobile,
  SkillCategory.devops,
  SkillCategory.cloud,
  SkillCategory.database,
  SkillCategory.dataEngineering,
  SkillCategory.uiUx,
  SkillCategory.unknown,
];

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  int? get _userId => context.read<AuthProvider>().currentUser?.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final userId = _userId;
    if (userId != null) context.read<SkillsProvider>().loadAll(userId);
  }

  Future<void> _openAddSkills() async {
    HapticFeedback.selectionClick();
    await context.push('/profile/skills/add');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final skills = context.watch<SkillsProvider>();
    final loading =
        skills.catalogState == SkillsLoadState.loading ||
        skills.userSkillsState == SkillsLoadState.loading;
    final hasError =
        skills.catalogState == SkillsLoadState.error ||
        skills.userSkillsState == SkillsLoadState.error;

    return Scaffold(
      appBar: AppBar(title: const Text('Your skills')),
      floatingActionButton: SafeArea(
        child: FloatingActionButton.extended(
          onPressed: _openAddSkills,
          icon: const Icon(Icons.add),
          label: const Text('Add skill'),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: loading && skills.userSkills.isEmpty
              ? const LoadingView(key: ValueKey('loading'))
              : hasError && skills.userSkills.isEmpty
              ? ErrorView(
                  key: const ValueKey('error'),
                  message: skills.errorMessage ?? 'Something went wrong.',
                  onRetry: _load,
                )
              : RefreshIndicator(
                  key: const ValueKey('loaded'),
                  onRefresh: () async => _load(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                    children: [
                      _YourSkillsSection(
                        skills: skills,
                        onRemove: (id) {
                          HapticFeedback.lightImpact();
                          final userId = _userId;
                          if (userId != null) skills.removeSkill(userId, id);
                        },
                        onBrowse: _openAddSkills,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _YourSkillsSection extends StatelessWidget {
  const _YourSkillsSection({
    required this.skills,
    required this.onRemove,
    required this.onBrowse,
  });

  final SkillsProvider skills;
  final void Function(int skillId) onRemove;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final owned = skills.userSkills;

    final grouped = <SkillCategory, List<Skill>>{};
    for (final s in owned) {
      grouped.putIfAbsent(s.category, () => []).add(s);
    }
    final orderedCategories = _categoryOrder.where(grouped.containsKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          label: 'YOUR SKILLS',
          icon: Icons.psychology_outlined,
          trailing: owned.isEmpty
              ? null
              : Text(
                  '${owned.length}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: p.indigo,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(height: 10),
        if (owned.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.surface1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.border),
            ),
            child: Column(
              children: [
                Icon(Icons.lightbulb_outline, size: 26, color: p.textMuted),
                const SizedBox(height: 10),
                Text(
                  "You haven't added any skills yet.",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add what you already know — it powers your roadmap and career gap analysis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: p.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: onBrowse,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add a skill'),
                ),
              ],
            ),
          )
        else ...[
          _StatsRow(count: owned.length, categoryCount: grouped.length),
          const SizedBox(height: 16),
          for (final category in orderedCategories) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(category.icon, size: 13, color: p.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    category.label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: p.textMuted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Divider(color: p.border, height: 1)),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: grouped[category]!
                  .map(
                    (s) => SizedBox(
                      width:
                          (MediaQuery.of(context).size.width - 16 * 2 - 8) / 2,
                      child: OwnedSkillTile(
                        skill: s,
                        isPending: skills.pendingSkillIds.contains(s.id),
                        onRemove: () => onRemove(s.id),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.count, required this.categoryCount});

  final int count;
  final int categoryCount;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: p.indigoLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 15, color: p.indigo),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count ${count == 1 ? 'skill' : 'skills'} across '
              '$categoryCount ${categoryCount == 1 ? 'category' : 'categories'}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: p.indigo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
