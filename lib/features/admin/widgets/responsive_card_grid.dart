import 'package:flutter/material.dart';

import 'fade_slide_in.dart';

/// Lays out entity cards (a role, an achievement, …) in a responsive grid
/// instead of one card per row stretched to the full window width — a
/// single 2000px-wide row per item looks broken on a big monitor even
/// though the same list looks fine in a small window.
class ResponsiveCardGrid extends StatelessWidget {
  const ResponsiveCardGrid({
    super.key,
    required this.children,
    this.targetCardWidth = 340,
    this.spacing = 12,
    this.runSpacing = 12,
    this.animate = true,
  });

  final List<Widget> children;
  final double targetCardWidth;
  final double spacing;
  final double runSpacing;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = ((width + spacing) / (targetCardWidth + spacing))
            .floor()
            .clamp(1, 4);
        final totalSpacing = spacing * (columns - 1);
        final itemWidth = (width - totalSpacing) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (var i = 0; i < children.length; i++)
              SizedBox(
                width: itemWidth,
                child: animate
                    ? FadeSlideIn(
                        index: i,
                        perItemDelay: const Duration(milliseconds: 25),
                        child: children[i],
                      )
                    : children[i],
              ),
          ],
        );
      },
    );
  }
}
