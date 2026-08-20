import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

class DonutSegment {
  final String label;
  final int value;
  final Color color;

  DonutSegment({required this.label, required this.value, required this.color});
}

/// Small, dependency-free donut chart (custom-painted) for showing a
/// categorical breakdown — e.g. users by experience level, or admins vs
/// regular users. Falls back to a neutral message when there's no data.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.segments,
    this.size = 120,
    this.strokeWidth = 18,
  });

  final List<DonutSegment> segments;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final total = segments.fold<int>(0, (a, s) => a + s.value);

    if (total == 0) {
      return SizedBox(
        height: size,
        child: Center(
          child: Text(
            'No data yet.',
            style: TextStyle(color: p.textMuted, fontSize: 12.5),
          ),
        ),
      );
    }

    return Row(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) {
              return CustomPaint(
                painter: _DonutPainter(
                  segments: segments,
                  total: total,
                  strokeWidth: strokeWidth,
                  progress: t,
                  trackColor: p.border,
                ),
                child: Center(
                  child: Text(
                    '$total',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final s in segments)
                if (s.value > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: s.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: p.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${s.value}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.total,
    required this.strokeWidth,
    required this.progress,
    required this.trackColor,
  });

  final List<DonutSegment> segments;
  final int total;
  final double strokeWidth;
  final double progress;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, track);

    double startAngle = -math.pi / 2;
    for (final s in segments) {
      if (s.value <= 0) continue;
      final sweep = (s.value / total) * 2 * math.pi * progress;
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += (s.value / total) * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.segments != segments;
  }
}
