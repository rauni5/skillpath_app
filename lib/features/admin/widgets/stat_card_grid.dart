import 'package:flutter/material.dart';

import 'fade_slide_in.dart';

/// Lays out stat cards (or anything) in a fixed number of equal-width
/// columns per row, wrapping to new rows as needed. Unlike [Wrap] alone,
/// card width is derived from the available width divided by [columns]
/// rather than each card's intrinsic content size, so cards line up into
/// a clean grid instead of packing as many as fit.
///
/// Children stagger in with a fade+slide by default — set [animate] to
/// false to skip that (e.g. when re-rendering after a filter change,
/// where re-animating every card would feel noisy).
class StatCardGrid extends StatelessWidget {
  const StatCardGrid({
    super.key,
    required this.children,
    this.columns = 3,
    this.spacing = 10,
    this.runSpacing = 10,
    this.animate = true,
  });

  final List<Widget> children;
  final int columns;
  final double spacing;
  final double runSpacing;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSpacing = spacing * (columns - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (var i = 0; i < children.length; i++)
              SizedBox(
                width: itemWidth,
                child: animate
                    ? FadeSlideIn(index: i, child: children[i])
                    : children[i],
              ),
          ],
        );
      },
    );
  }
}
