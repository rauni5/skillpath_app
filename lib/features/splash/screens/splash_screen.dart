import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/brand_mark.dart';

/// Branded Instagram-style splash screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
  );

  late final Animation<double> _footerFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Scaffold(
      backgroundColor: p.surface0,
      body: SafeArea(
        child: Column(
          children: [
            // Center Logo Section
            Expanded(
              child: Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: BrandMark(color: p.indigo, size: 84),
                  ),
                ),
              ),
            ),

            // Bottom "from SkillPath" Branding Footer
            FadeTransition(
              opacity: _footerFade,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'from',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 0.5,
                        color: p.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SkillPath',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: p.indigo,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
