import 'package:flutter/material.dart';

import '../../../core/models/career_role.dart';
import '../../../core/theme/app_colors.dart';

class RoleCard extends StatelessWidget {
  const RoleCard({super.key, required this.role, required this.isSelected, required this.onTap});

  final CareerRole role;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.indigoLight : AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.indigo : AppColors.border, width: isSelected ? 1.5 : 0.75),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.name,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.indigo : AppColors.textPrimary,
                    ),
                  ),
                  if (role.description != null && role.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      role.description!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                key: ValueKey(isSelected),
                color: isSelected ? AppColors.indigo : AppColors.border,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
