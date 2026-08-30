import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/portfolio.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/models/cv_checklist.dart';

class ProfileIncompleteDialog extends StatelessWidget {
  const ProfileIncompleteDialog({super.key, required this.data});
  final PortfolioData data;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final checklist = cvChecklist(data);

    return AlertDialog(
      title: const Text('Finish your profile first'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your CV is built from your portfolio, so a few things need '
            'filling in before there\'s enough to export:',
            style: TextStyle(fontSize: 13, color: p.textSecondary),
          ),
          const SizedBox(height: 14),
          for (final check in checklist)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    check.done ? Icons.check_circle : Icons.circle_outlined,
                    size: 18,
                    color: check.done ? p.greenText : p.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      check.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: check.done ? p.textMuted : p.textPrimary,
                        decoration: check.done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.push('/profile/settings/edit');
          },
          child: const Text('Edit Profile'),
        ),
      ],
    );
  }
}
