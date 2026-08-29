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

/// General-purpose "here's what happened" status dialog.
Future<void> showOutcomeDialog(
  BuildContext context, {
  required String title,
  required String message,
  bool isPositive = true,
  String buttonText = 'Got it',
}) {
  final p = AppPalette.of(context);
  return _showBaseCustomDialog(
    context,
    icon: isPositive ? Icons.check_circle_rounded : Icons.info_rounded,
    badgeColor: isPositive ? p.green : p.textMuted,
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
}) {
  final p = AppPalette.of(context);
  return _showBaseCustomDialog(
    context,
    icon: Icons.check_circle_rounded,
    badgeColor: p.green,
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
}) {
  final p = AppPalette.of(context);
  return _showBaseCustomDialog(
    context,
    icon: Icons.error_rounded,
    badgeColor: p.red,
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
  String? overheadLabel,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black.withValues(alpha: 0.54),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) =>
        const SizedBox.shrink(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final bounceCurve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );

      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: bounceCurve,
          child: _FeedbackDialogCard(
            icon: icon,
            badgeColor: badgeColor,
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
    this.overheadLabel,
  });

  final IconData icon;
  final Color badgeColor;
  final String title;
  final String message;
  final String buttonText;
  final String? overheadLabel;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          color: p.surface2,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: p.textPrimary.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Layered Icon Badge with Glow
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badgeColor.withValues(alpha: 0.12),
                border: Border.all(
                  color: badgeColor.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: badgeColor.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon, color: badgeColor, size: 32),
            ),
            const SizedBox(height: 20),

            // Optional Overhead Label (e.g. "ACHIEVEMENT UNLOCKED")
            if (overheadLabel != null) ...[
              Text(
                overheadLabel!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: badgeColor,
                ),
              ),
              const SizedBox(height: 6),
            ],

            // Main Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),

            // Description Body
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: p.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),

            // Full-width Dismiss Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: badgeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
