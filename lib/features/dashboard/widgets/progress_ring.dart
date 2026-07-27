import 'package:flutter/material.dart';

/// Circular career-progress indicator drawn with CustomPaint, matching the
/// mockup's `.pring` SVG ring (rotated so it starts at 12 o'clock).
///
/// Animates smoothly whenever [percent] changes — both the arc sweep and
/// the number count up together — so a fresh gap-analysis result feels
/// like real progress rather than a static number swap.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.percent,
    this.size = 56,
    this.strokeWidth = 5,
    this.trackColor = const Color(0x33FFFFFF),
    this.progressColor = Colors.white,
    this.labelColor = Colors.white,
  });

  final int percent;
  final double size;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percent.clamp(0, 100).toDouble()),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animatedPercent, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  percent: animatedPercent / 100,
                  strokeWidth: strokeWidth,
                  trackColor: trackColor,
                  progressColor: progressColor,
                ),
              ),
              Text(
                '${animatedPercent.round()}%',
                style: TextStyle(
                  color: labelColor,
                  fontSize: size * 0.24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.percent,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  final double percent;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final progress = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -1.5708; // -90deg, start at 12 o'clock
    final sweepAngle = 6.28319 * percent; // 2*pi * percent
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.percent != percent || oldDelegate.progressColor != progressColor;
}
