import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../widgets/onboarding_about_step.dart';
import '../widgets/onboarding_goal_step.dart';
import '../widgets/onboarding_progress_bar.dart';
import '../widgets/onboarding_skills_step.dart';
import '../widgets/onboarding_summary_step.dart';

/// Shown right after account creation — for both email registration and
/// Google sign-in — until the user has set a career goal. Gated by
/// `AuthProvider.needsOnboarding` via the router redirect, so there's no
/// way to reach the main app without passing through here at least once.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _totalSteps = 4;
  static const _stepTitles = [
    'About you',
    'Your skills',
    'Career goal',
    'Summary',
  ];

  final _pageController = PageController();
  int _step = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    // Unfocus active keyboard inputs before changing step/screen
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _next() => _goTo((_step + 1).clamp(0, _totalSteps - 1));
  void _back() => _goTo((_step - 1).clamp(0, _totalSteps - 1));

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  if (_step > 0)
                    IconButton(
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_back),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    )
                  else
                    const SizedBox(width: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OnboardingProgressBar(
                      step: _step,
                      totalSteps: _totalSteps,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    'Step ${_step + 1} of $_totalSteps · ${_stepTitles[_step]}',
                    key: ValueKey(_step),
                    style: TextStyle(
                      fontSize: 11,
                      color: p.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                // Steps advance via buttons only, so users can't swipe
                // past the required goal-selection step.
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  OnboardingAboutStep(onContinue: _next),
                  OnboardingSkillsStep(onContinue: _next),
                  OnboardingGoalStep(onContinue: _next),
                  const OnboardingSummaryStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
