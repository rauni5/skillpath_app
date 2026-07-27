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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'What can you already do?',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Add the skills you already have — tap a level to add it. You can always change these later.",
                style: TextStyle(fontSize: 13, color: p.textMuted, height: 1.4),
              ),
              const SizedBox(height: 18),
              if (skills.userSkills.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: skills.userSkills
                      .map(
                        (s) => Chip(
                          label: Text(
                            s.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: p.indigoLight,
                          deleteIcon: const Icon(Icons.close, size: 15),
                          onDeleted: userId == null
                              ? null
                              : () => skills.removeSkill(userId, s.id),
                          side: BorderSide.none,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
              ],
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
            children: skills.filteredCatalog
                .map(
                  (s) => CatalogSkillRow(
                    skill: s,
                    isPending: skills.pendingSkillIds.contains(s.id),
                    onAdd: (proficiency) {
                      if (userId != null)
                        skills.addSkill(userId, s, proficiency);
                    },
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
