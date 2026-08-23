import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/router/skill_check_route_args.dart';
import '../../auth/providers/auth_provider.dart';
import '../../roadmap/providers/roadmap_provider.dart';
import '../providers/skills_provider.dart';
import '../widgets/catalog_skill_row.dart';
import '../widgets/category_filter_row.dart';

/// Full-screen overlay for adding a skill. Rather than self-reporting a
/// proficiency level, picking a skill here launches the same AI skill-check
/// used on the roadmap — passing it adds the skill at the level actually
/// earned.
class AddSkillsScreen extends StatefulWidget {
  const AddSkillsScreen({super.key});

  @override
  State<AddSkillsScreen> createState() => _AddSkillsScreenState();
}

class _AddSkillsScreenState extends State<AddSkillsScreen> {
  final _searchCtrl = TextEditingController();

  int? get _userId => context.read<AuthProvider>().currentUser?.id;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _startSkillCheck(int skillId, String skillName) async {
    final passed = await context.push<bool>(
      '/roadmap/skill/$skillId/skill-check',
      extra: SkillCheckRouteArgs(skillName, returnLabel: 'Done'),
    );
    if (passed == true && mounted) {
      final userId = _userId;
      if (userId != null) {
        await Future.wait([
          context.read<SkillsProvider>().loadUserSkills(userId),
          context.read<RoadmapProvider>().load(userId),
        ]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final skills = context.watch<SkillsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Add a skill')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: p.indigoLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.quiz_outlined, size: 16, color: p.indigo),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pick a skill to take a quick skill check — passing adds it at the level you earn.',
                            style: TextStyle(
                              fontSize: 12,
                              color: p.indigo,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    onChanged: skills.setSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Search skills…',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                skills.setSearchQuery('');
                              },
                            ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  CategoryFilterRow(
                    selected: skills.categoryFilter,
                    onSelect: skills.setCategoryFilter,
                  ),
                ],
              ),
            ),
            Expanded(
              child: skills.filteredCatalog.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 30,
                              color: p.textMuted,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No matching skills.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: p.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: skills.filteredCatalog.length,
                      itemBuilder: (context, index) {
                        final s = skills.filteredCatalog[index];
                        return CatalogSkillRow(
                          skill: s,
                          isPending: false,
                          onAddDirect: () => _startSkillCheck(s.id, s.name),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
