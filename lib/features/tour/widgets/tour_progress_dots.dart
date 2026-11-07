import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// Simple dot indicator for the app tour's 9 slides. Deliberately not
/// OnboardingProgressBar (numbered circles + checkmarks) — that's built
/// for a short, mandatory 4-step wizard; a plain dot row reads better for
/// a longer, swipeable, skippable carousel.
class TourProgressDots extends StatelessWidget {
  const TourProgressDots({
    super.key,
    required this.step,
    required this.totalSteps,
  });

  final int step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (i) {
        final isCurrent = i == step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isCurrent ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isCurrent ? p.indigo : p.border,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
