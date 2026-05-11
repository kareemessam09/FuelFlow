import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'neon_button.dart';

class StateFeedback extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const StateFeedback({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              BrutalButton(label: actionLabel!, onPressed: onAction!, isPrimary: false),
            ],
          ],
        ),
      ),
    );
  }
}
