import 'package:flutter/material.dart';
import '../../core/models/achievement.dart';
import '../../core/theme/app_palette.dart';

/// Celebratory popup for an achievement unlock.
Future<void> showAchievementUnlockedDialog(
  BuildContext context,
  Achievement achievement,
) {
  final p = AppPalette.of(context);
  return _showBaseCustomDialog(
    context,
    icon: achievement.iconData,
    badgeColor: p.indigo,
    overheadLabel: 'ACHIEVEMENT UNLOCKED',
    title: achievement.title,
    message: achievement.description,
    buttonText: 'Nice!',
  );
}

/// Basic informational dialog (e.g., project acceptances, general notices).
Future<void> showInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
  String buttonText = 'Got it',
  IconData icon = Icons.info_outline_rounded,
  Color? buttonColor,
}) {
  final p = AppPalette.of(context);
  return _showBaseCustomDialog(
    context,
    icon: icon,
    badgeColor: p.textMuted,
    buttonColor:
        buttonColor ?? p.indigo, // Standard primary action button color
    title: title,
    message: message,
    buttonText: buttonText,
  );
}

/// General-purpose "here's what happened" status dialog.
Future<void> showOutcomeDialog(
  BuildContext context, {
  required String title,
  required String message,
  bool isPositive = true,
  String buttonText = 'Got it',
  Color? buttonColor,
}) {
  final p = AppPalette.of(context);
  return _showBaseCustomDialog(
    context,
    icon: isPositive ? Icons.check_circle_rounded : Icons.info_rounded,
    badgeColor: isPositive ? p.green : p.textMuted,
    buttonColor: buttonColor,
    title: title,
    message: message,
    buttonText: buttonText,
  );
}

/// Clean modal for an operational success action.
Future<void> showSuccessDialog(
  BuildContext context,
  String message, {
  String title = 'Success!',
  String buttonText = 'Done',
  Color? buttonColor,
}) {
  final p = AppPalette.of(context);
  return _showBaseCustomDialog(
    context,
    icon: Icons.check_circle_rounded,
    badgeColor: p.green,
    buttonColor: buttonColor,
    title: title,
    message: message,
    buttonText: buttonText,
  );
}

/// Clean modal for an operational error or failure state.
Future<void> showErrorDialog(
  BuildContext context,
  String message, {
  String title = 'Something went wrong',
  String buttonText = 'Dismiss',
  Color? buttonColor,
}) {
  final p = AppPalette.of(context);
  return _showBaseCustomDialog(
    context,
    icon: Icons.error_rounded,
    badgeColor: p.red,
    buttonColor: buttonColor,
    title: title,
    message: message,
    buttonText: buttonText,
  );
}

/// Primary animated dialog wrapper to keep all modals completely consistent.
Future<void> _showBaseCustomDialog(
  BuildContext context, {
  required IconData icon,
  required Color badgeColor,
  required String title,
  required String message,
  required String buttonText,
  Color? buttonColor,
  String? overheadLabel,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) =>
        const SizedBox.shrink(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curve),
          child: _FeedbackDialogCard(
            icon: icon,
            badgeColor: badgeColor,
            buttonColor: buttonColor,
            overheadLabel: overheadLabel,
            title: title,
            message: message,
            buttonText: buttonText,
          ),
        ),
      );
    },
  );
}

class _FeedbackDialogCard extends StatelessWidget {
  const _FeedbackDialogCard({
    required this.icon,
    required this.badgeColor,
    required this.title,
    required this.message,
    required this.buttonText,
    this.buttonColor,
    this.overheadLabel,
  });

  final IconData icon;
  final Color badgeColor;
  final Color? buttonColor;
  final String title;
  final String message;
  final String buttonText;
  final String? overheadLabel;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final effectiveButtonColor = buttonColor ?? badgeColor;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        decoration: BoxDecoration(
          color: p.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: p.textPrimary.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badgeColor.withValues(alpha: 0.08),
                border: Border.all(
                  color: badgeColor.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: badgeColor, size: 26),
            ),
            const SizedBox(height: 16),

            // Optional Overhead Label
            if (overheadLabel != null) ...[
              Text(
                overheadLabel!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: badgeColor,
                ),
              ),
              const SizedBox(height: 4),
            ],

            // Main Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),

            // Description Body
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: p.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: effectiveButtonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
