import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Runtime, theme-aware counterpart to the static [AppColors] constants.
@immutable
class AppPalette {
  final Color indigo;
  final Color indigoLight;
  final Color indigoTint;
  final Color green;
  final Color greenLight;
  final Color greenText;
  final Color amber;
  final Color amberLight;
  final Color amberText;
  final Color red;
  final Color redLight;
  final Color surface0;
  final Color surface1;
  final Color surface2;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const AppPalette({
    required this.indigo,
    required this.indigoLight,
    required this.indigoTint,
    required this.green,
    required this.greenLight,
    required this.greenText,
    required this.amber,
    required this.amberLight,
    required this.amberText,
    required this.red,
    required this.redLight,
    required this.surface0,
    required this.surface1,
    required this.surface2,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  static AppPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  static const light = AppPalette(
    indigo: AppColors.indigo,
    indigoLight: AppColors.indigoLight,
    indigoTint: AppColors.indigoTint,
    green: AppColors.green,
    greenLight: AppColors.greenLight,
    greenText: AppColors.greenText,
    amber: AppColors.amber,
    amberLight: AppColors.amberLight,
    amberText: AppColors.amberText,
    red: AppColors.red,
    redLight: AppColors.redLight,
    surface0: AppColors.surface0,
    surface1: AppColors.surface1,
    surface2: AppColors.surface2,
    border: AppColors.border,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
  );

  static const dark = AppPalette(
    indigo: Color(0xFF818CF8),
    indigoLight: Color(0xFF2A2F63),
    indigoTint: Color(0xFF9CA5F8),
    green: Color(0xFF4ADE80),
    greenLight: Color(0xFF17301F),
    greenText: Color(0xFF86EFAC),
    amber: Color(0xFFFBBF24),
    amberLight: Color(0xFF3A2E12),
    amberText: Color(0xFFFCD34D),
    red: Color(0xFFF87171),
    redLight: Color(0xFF3A1D1D),
    surface0: Color(0xFF121212),
    surface1: Color(0xFF1C1C1E),
    surface2: Color(0xFF232326),
    border: Color(0xFF34343A),
    textPrimary: Color(0xFFF3F4F6),
    textSecondary: Color(0xFFB4B8C2),
    textMuted: Color(0xFF7D818C),
  );
}
