import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Center(
      child: CircularProgressIndicator(color: p.indigo, strokeWidth: 2.5),
    );
  }
}
