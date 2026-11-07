import 'package:flutter/material.dart';

/// Renders [child] the way Chrome's page zoom would at [scale] — everything
/// (text, icons, spacing) gets uniformly bigger — with a guaranteed minimum
/// logical canvas size underneath the zoom. If the actual browser window is
/// too small to fit that minimum at [scale], the canvas doesn't shrink or
/// squash: it stays pinned at its minimum size and becomes scrollable
/// instead, so dragging the window smaller never breaks a screen's layout.
///
/// How it works: Chrome's zoom effectively shrinks the number of CSS
/// pixels the page can lay out in, then blows the render back up to fill
/// the real window — content re-flows to use *more* space per element.
/// We do the same thing explicitly: give [child] a smaller "logical"
/// [BoxConstraints]/[MediaQueryData] than the real viewport (real size ÷
/// scale), then [Transform.scale] the whole rendered result back up by
/// [scale] so it fills the real viewport again.
class AdminZoomView extends StatelessWidget {
  const AdminZoomView({
    super.key,
    required this.child,
    this.scale = 1.2,
    this.minLogicalWidth = 1180,
    this.minLogicalHeight = 720,
  });

  final Widget child;

  /// 1.2 == "120%", matching Chrome's zoom levels/notation.
  final double scale;

  /// The smallest logical canvas the admin UI is ever laid out at, even if
  /// the real window (physical size ÷ scale) is smaller than this. Chosen
  /// to comfortably fit the 236px side nav plus a data table without its
  /// columns getting cramped.
  final double minLogicalWidth;
  final double minLogicalHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final physicalWidth = constraints.maxWidth;
        final physicalHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : minLogicalHeight * scale;

        var logicalWidth = physicalWidth / scale;
        var logicalHeight = physicalHeight / scale;
        if (logicalWidth < minLogicalWidth) logicalWidth = minLogicalWidth;
        if (logicalHeight < minLogicalHeight) {
          logicalHeight = minLogicalHeight;
        }

        final renderedWidth = logicalWidth * scale;
        final renderedHeight = logicalHeight * scale;

        final mq = MediaQuery.of(context);
        Widget canvas = MediaQuery(
          data: mq.copyWith(size: Size(logicalWidth, logicalHeight)),
          child: SizedBox(
            width: logicalWidth,
            height: logicalHeight,
            child: child,
          ),
        );

        canvas = Transform.scale(
          scale: scale,
          alignment: Alignment.topLeft,
          filterQuality: FilterQuality.medium,
          child: canvas,
        );

        canvas = SizedBox(
          width: renderedWidth,
          height: renderedHeight,
          child: canvas,
        );

        final overflowsH = renderedWidth > physicalWidth + 0.5;
        final overflowsV = renderedHeight > physicalHeight + 0.5;
        if (!overflowsH && !overflowsV) return canvas;

        // The zoomed canvas is bigger than the real window — let the
        // person scroll to reach the rest of it instead of clipping or
        // squashing anything.
        return Scrollbar(
          thumbVisibility: overflowsH,
          notificationPredicate: (notification) => notification.depth == 0,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: overflowsH
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            child: Scrollbar(
              thumbVisibility: overflowsV,
              notificationPredicate: (notification) => notification.depth == 1,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                physics: overflowsV
                    ? const ClampingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                child: canvas,
              ),
            ),
          ),
        );
      },
    );
  }
}
