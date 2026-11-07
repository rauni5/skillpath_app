import 'package:flutter/material.dart';

import 'fade_slide_in.dart';

/// Lays out stat cards in equal-width columns, auto-computing how many
/// fit based on available width and [minCardWidth] — so the grid adapts
/// from a single column on a narrow screen to 5-6 columns on a wide
/// monitor, rather than a fixed column count that leaves the page looking
/// sparse (too few, stretched cards) or cramped depending on window size.
class StatCardGrid extends StatelessWidget {
  const StatCardGrid({
    super.key,
    required this.children,
    this.minCardWidth = 190,
    this.maxColumns = 6,
    this.spacing = 12,
    this.runSpacing = 12,
    this.animate = true,
  });

  final List<Widget> children;
  final double minCardWidth;
  final int maxColumns;
  final double spacing;
  final double runSpacing;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        int columns = ((available + spacing) / (minCardWidth + spacing))
            .floor()
            .clamp(1, maxColumns);
        // Never use more columns than we have cards for — avoids a wide
        // near-empty row when e.g. only 2 stats are shown on a huge screen.
        columns = columns.clamp(1, children.isEmpty ? 1 : children.length);

        final totalSpacing = spacing * (columns - 1);
        final itemWidth = (available - totalSpacing) / columns;

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
