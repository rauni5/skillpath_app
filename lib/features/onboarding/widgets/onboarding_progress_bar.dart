import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// Step indicator for the onboarding wizard: a numbered circle per step,
/// filled and checked once passed, connected by lines — clearer than a
/// plain segmented bar because it tells the user *which* step they're on
/// and how many remain, not just a fraction of progress.
class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({
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
      children: List.generate(totalSteps * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line between step i~/2 and the next.
          final leftStepDone = (i - 1) ~/ 2 < step;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 2,
              color: leftStepDone ? p.indigo : p.border,
            ),
          );
        }
        final index = i ~/ 2;
        final isDone = index < step;
        final isCurrent = index == step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone || isCurrent ? p.indigo : p.surface1,
            border: Border.all(
              color: isDone || isCurrent ? p.indigo : p.border,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isDone
                ? const Icon(
                    Icons.check,
                    key: ValueKey('check'),
                    size: 13,
                    color: Colors.white,
                  )
                : Text(
                    '${index + 1}',
                    key: ValueKey('num$index'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isCurrent ? Colors.white : p.textMuted,
                    ),
                  ),
          ),
        );
      }),
    );
  }
}
