import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../auth/providers/auth_provider.dart';
import '../../skills/providers/skills_provider.dart';
import '../../skills/widgets/catalog_skill_row.dart';
import '../../skills/widgets/category_filter_row.dart';

class OnboardingSkillsStep extends StatefulWidget {
  const OnboardingSkillsStep({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  State<OnboardingSkillsStep> createState() => _OnboardingSkillsStepState();
}

class _OnboardingSkillsStepState extends State<OnboardingSkillsStep> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) context.read<SkillsProvider>().loadAll(userId);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skills = context.watch<SkillsProvider>();
    final userId = context.watch<AuthProvider>().currentUser?.id;
    final p = AppPalette.of(context);
    final selectedCount = skills.userSkills.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'What can you already do?',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                  if (selectedCount > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: p.indigoLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$selectedCount added',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: p.indigo,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Tap a skill to add it — added skills stay in the list and turn "
                "indigo, so it's easy to see everything you've picked. You can "
                "always change these later.",
                style: TextStyle(fontSize: 13, color: p.textMuted, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchCtrl,
                onChanged: skills.setSearchQuery,
                decoration: const InputDecoration(
                  hintText: 'Search skills…',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              CategoryFilterRow(
                selected: skills.categoryFilter,
                onSelect: skills.setCategoryFilter,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            children: skills.filteredCatalogAll
                .map(
                  (s) => CatalogSkillRow(
                    skill: s,
                    isPending: skills.pendingSkillIds.contains(s.id),
                    isSelected: skills.userSkillIds.contains(s.id),
                    onAdd: (proficiency) {
                      if (userId != null) {
                        skills.addSkill(userId, s, proficiency);
                      }
                    },
                    onRemove: userId == null
                        ? null
                        : () => skills.removeSkill(userId, s.id),
                  ),
                )
                .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: widget.onContinue,
                child: const Text('Continue'),
              ),
              TextButton(
                onPressed: widget.onContinue,
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
