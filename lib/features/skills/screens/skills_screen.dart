import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/skills_provider.dart';
import '../widgets/catalog_skill_row.dart';
import '../widgets/category_filter_row.dart';
import '../widgets/owned_skill_tile.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  final _searchCtrl = TextEditingController();

  int? get _userId => context.read<AuthProvider>().currentUser?.id;

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
    final userId = _userId;
    if (userId != null) context.read<SkillsProvider>().loadAll(userId);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final skills = context.watch<SkillsProvider>();
    final loading =
        skills.catalogState == SkillsLoadState.loading ||
        skills.userSkillsState == SkillsLoadState.loading;
    final hasError =
        skills.catalogState == SkillsLoadState.error ||
        skills.userSkillsState == SkillsLoadState.error;

    return Scaffold(
      appBar: AppBar(title: const Text('Your skills')),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: loading && skills.catalog.isEmpty
            ? const LoadingView(key: ValueKey('loading'))
            : hasError && skills.catalog.isEmpty
            ? ErrorView(
                key: const ValueKey('error'),
                message: skills.errorMessage ?? 'Something went wrong.',
                onRetry: _load,
              )
            : RefreshIndicator(
                key: const ValueKey('loaded'),
                onRefresh: () async => _load(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: [
                    SectionHeader(
                      label: 'YOUR SKILLS',
                      icon: Icons.psychology_outlined,
                      trailing: skills.userSkills.isEmpty
                          ? null
                          : Text(
                              '${skills.userSkills.length}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: p.indigo,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                    const SizedBox(height: 10),
                    if (skills.userSkills.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: p.surface1,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 18,
                              color: p.textMuted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No skills added yet — tap any skill below to add it.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: p.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: skills.userSkills
                            .map(
                              (s) => SizedBox(
                                width:
                                    (MediaQuery.of(context).size.width -
                                        16 * 2 -
                                        8) /
                                    2,
                                child: OwnedSkillTile(
                                  skill: s,
                                  isPending: skills.pendingSkillIds.contains(
                                    s.id,
                                  ),
                                  onRemove: () {
                                    HapticFeedback.lightImpact();
                                    final userId = _userId;
                                    if (userId != null)
                                      skills.removeSkill(userId, s.id);
                                  },
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 24),
                    const SectionHeader(
                      label: 'ADD SKILLS',
                      icon: Icons.add_circle_outline,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchCtrl,
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
                                  setState(() {});
                                },
                              ),
                        isDense: true,
                      ),
                      onTap: () => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    CategoryFilterRow(
                      selected: skills.categoryFilter,
                      onSelect: skills.setCategoryFilter,
                    ),
                    const SizedBox(height: 12),
                    if (skills.filteredCatalog.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
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
                      )
                    else
                      ...skills.filteredCatalog.map(
                        (s) => CatalogSkillRow(
                          skill: s,
                          isPending: skills.pendingSkillIds.contains(s.id),
                          onAdd: (proficiency) {
                            HapticFeedback.selectionClick();
                            final userId = _userId;
                            if (userId != null)
                              skills.addSkill(userId, s, proficiency);
                          },
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
