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

class _OnboardingSkillsStepState extends State<OnboardingSkillsStep>
    with WidgetsBindingObserver {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  bool _keyboardWasOpen = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _searchFocus.addListener(_onSearchFocusChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final userId = context.read<AuthProvider>().currentUser?.id;

      if (userId != null) {
        context.read<SkillsProvider>().loadAll(userId);
      }
    });
  }

  void _onSearchFocusChanged() {
    if (!mounted) return;

    setState(() {});
  }

  @override
  void didChangeMetrics() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;

    final keyboardHeight = view.viewInsets.bottom;
    final keyboardIsOpen = keyboardHeight > 0;

    // Keyboard was open and has now been closed.
    if (_keyboardWasOpen && !keyboardIsOpen) {
      // Wait until Flutter finishes processing the keyboard
      // dismissal before removing focus.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (_searchFocus.hasFocus) {
          _searchFocus.unfocus();
        }
      });
    }

    _keyboardWasOpen = keyboardIsOpen;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _searchCtrl.dispose();
    _searchFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skills = context.watch<SkillsProvider>();
    final userId = context.watch<AuthProvider>().currentUser?.id;
    final p = AppPalette.of(context);

    final selectedCount = skills.userSkills.length;
    final isSearching = _searchFocus.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: isSearching
                    ? const SizedBox.shrink()
                    : Column(
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
                            "Tap a skill to add it — added skills stay in "
                            "the list and turn indigo, so it's easy to see "
                            "everything you've picked. You can always "
                            "change these later.",
                            style: TextStyle(
                              fontSize: 13,
                              color: p.textMuted,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
              ),

              TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                autofocus: false,
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

              if (isSearching && selectedCount > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
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
                  ),
                ),
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

        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: isSearching
              ? const SizedBox.shrink()
              : Padding(
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
        ),
      ],
    );
  }
}
