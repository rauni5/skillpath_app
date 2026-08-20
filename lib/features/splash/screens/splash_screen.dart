import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// Placeholder splash screen while the auth status is unknown
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SkillPath',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: p.indigo,
              ),
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(color: p.indigo),
          ],
        ),
      ),
    );
  }
}
