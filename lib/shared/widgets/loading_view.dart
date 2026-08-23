import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.scale(scale: 0.9 + 0.1 * value, child: child),
        ),
        child: CircularProgressIndicator(color: p.indigo, strokeWidth: 2.5),
      ),
    );
  }
}
