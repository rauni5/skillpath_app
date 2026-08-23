import 'package:flutter/material.dart';

/// exported app icon.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, required this.color, this.size = 96});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.27),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.25)!],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.14),
          ),
        ],
      ),
      child: CustomPaint(painter: _PathMarkPainter()),
    );
  }
}

class _PathMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.24, size.height * 0.72)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.40,
        size.width * 0.40,
        size.height * 0.28,
        size.width * 0.50,
        size.height * 0.42,
      )
      ..cubicTo(
        size.width * 0.60,
        size.height * 0.56,
        size.width * 0.76,
        size.height * 0.44,
        size.width * 0.76,
        size.height * 0.28,
      );

    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.052
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);

    final dotFill = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(size.width * 0.24, size.height * 0.72),
      size.width * 0.057,
      dotFill,
    );
    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.42),
      size.width * 0.047,
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );
    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.28),
      size.width * 0.073,
      dotFill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
