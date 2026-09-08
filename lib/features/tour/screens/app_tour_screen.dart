import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/tour_progress_dots.dart';
import '../widgets/tour_slide.dart';

/// Shown once, right after a brand-new user finishes Onboarding — gated by
/// `AuthProvider.justCompletedOnboarding`, an in-memory-only flag rather
/// than a persisted preference, since "onboarding just completed" is
/// itself already a one-time event for any given account. Returning users
/// never see this again, and there's no extra flag to keep in sync with
/// anything.
///
/// Unlike OnboardingScreen, nothing here is mandatory: swiping works, and
/// Skip is always visible, since this is purely informational.
class AppTourScreen extends StatefulWidget {
  const AppTourScreen({super.key});

  @override
  State<AppTourScreen> createState() => _AppTourScreenState();
}

class _AppTourScreenState extends State<AppTourScreen> {
  final _pageController = PageController();
  int _step = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _next() {
    if (_step < tourSlides.length - 1) {
      _goTo(_step + 1);
    } else {
      _finish();
    }
  }

  void _finish() {
    context.read<AuthProvider>().finishTour();
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isLast = _step == tourSlides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 20, 0),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: TextStyle(color: p.textMuted, fontSize: 13),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _step = i),
                children: [
                  for (final slide in tourSlides) TourSlide(data: slide),
                ],
              ),
            ),
            TourProgressDots(step: _step, totalSteps: tourSlides.length),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: ElevatedButton(
                onPressed: _next,
                child: Text(isLast ? 'Get Started' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
