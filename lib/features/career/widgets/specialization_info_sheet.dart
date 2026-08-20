import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

Future<void> showSpecializationInfoSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    builder: (context) {
      final p = AppPalette.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.alt_route, color: p.indigo, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    "What's a specialization?",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'A specialization is a specific technology track within a career role — '
                'for example, MERN, Django, or Spring are all specializations within '
                'Full Stack Developer.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: p.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your roadmap and skill checks are built from whichever specialization '
                "you pick, since each one needs a different set of skills. You can "
                'switch specializations later without losing your progress on shared skills.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: p.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: p.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
