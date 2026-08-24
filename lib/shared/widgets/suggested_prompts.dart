import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Tappable example-question chips for an empty chat — sends the prompt
/// immediately rather than just filling the input, since these are meant
/// as a fast way in, not a drafting aid.
class SuggestedPrompts extends StatelessWidget {
  const SuggestedPrompts({
    super.key,
    required this.prompts,
    required this.onSelect,
  });

  final List<String> prompts;
  final void Function(String prompt) onSelect;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: prompts
          .map(
            (prompt) => InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onSelect(prompt),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: p.surface2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.border),
                ),
                child: Text(
                  prompt,
                  style: TextStyle(fontSize: 12.5, color: p.textPrimary),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
