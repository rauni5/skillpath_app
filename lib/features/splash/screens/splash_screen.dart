import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/brand_mark.dart';

/// Branded splash screen shown while the auth status is unknown.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  late final AnimationController _dots = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  late final Animation<double> _markScale = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
  );

  late final Animation<double> _markFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
  );

  late final Animation<double> _textFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
  );

  late final Animation<Offset> _textSlide =
      Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entrance,
          curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
        ),
      );

  late final Animation<double> _taglineFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.55, 0.9, curve: Curves.easeOut),
  );

  late final Animation<double> _dotsFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _entrance.dispose();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.surface0, p.indigoLight.withValues(alpha: 0.55)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _markFade,
                child: ScaleTransition(
                  scale: _markScale,
                  child: BrandMark(color: p.indigo, size: 96),
                ),
              ),
              const SizedBox(height: 28),
              SlideTransition(
                position: _textSlide,
                child: FadeTransition(
                  opacity: _textFade,
                  child: Text(
                    'SkillPath',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: p.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _taglineFade,
                child: Text(
                  'From skill to portfolio',
                  style: TextStyle(
                    fontSize: 13,
                    color: p.textMuted,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 44),
              FadeTransition(
                opacity: _dotsFade,
                child: AnimatedBuilder(
                  animation: _dots,
                  builder: (context, _) =>
                      _PulsingDots(progress: _dots.value, color: p.indigo),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingDots extends StatelessWidget {
  const _PulsingDots({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final t = (progress - i * 0.2) % 1.0;
        final scale = 0.5 + 0.5 * (1 - (2 * t - 1).abs()).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Transform.scale(
            scale: 0.6 + 0.4 * scale,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.4 + 0.6 * scale),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}
