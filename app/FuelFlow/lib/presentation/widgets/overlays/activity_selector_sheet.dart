import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/constants.dart';
import '../../../domain/entities/entities.dart';

/// Activity mode selector bottom sheet with glass-morphism effect
class ActivitySelectorSheet extends StatelessWidget {
  final ActivityMode currentMode;
  final ValueChanged<ActivityMode> onModeSelected;

  const ActivitySelectorSheet({
    super.key,
    required this.currentMode,
    required this.onModeSelected,
  });

  /// Show the activity selector as a modal bottom sheet
  static Future<ActivityMode?> show(
    BuildContext context, {
    required ActivityMode currentMode,
  }) {
    return showModalBottomSheet<ActivityMode>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ActivitySelectorSheet(
        currentMode: currentMode,
        onModeSelected: (mode) => Navigator.of(context).pop(mode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.border),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_run,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'SELECT ACTIVITY MODE',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.border, height: 1),

            // Activity options
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: ActivityMode.values.map((mode) {
                      return _ActivityModeItem(
                        mode: mode,
                        isSelected: mode == currentMode,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          onModeSelected(mode);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ActivityModeItem extends StatelessWidget {
  final ActivityMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActivityModeItem({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getActivityModeColor(mode.toApiString());

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border(left: BorderSide(color: color, width: 3))
              : Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconForMode(mode),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode.displayName,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mode.description,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Multiplier badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${mode.multiplier}x',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),

            if (isSelected) ...[
              const SizedBox(width: 12),
              Icon(
                Icons.check_circle,
                color: color,
                size: 24,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconForMode(ActivityMode mode) {
    switch (mode) {
      case ActivityMode.resting:
        return Icons.weekend_rounded;
      case ActivityMode.coding:
        return Icons.code_rounded;
      case ActivityMode.studying:
        return Icons.menu_book_rounded;
      case ActivityMode.gymStrength:
        return Icons.fitness_center_rounded;
      case ActivityMode.gymCardio:
        return Icons.directions_run_rounded;
      case ActivityMode.sleeping:
        return Icons.bedtime_rounded;
    }
  }
}
