import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../domain/entities/entities.dart';

/// Timer display widget showing time until crash
class CrashTimerWidget extends StatelessWidget {
  final int minutesRemaining;
  final FuelLevel level;

  const CrashTimerWidget({
    super.key,
    required this.minutesRemaining,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final hours = minutesRemaining ~/ 60;
    final minutes = minutesRemaining % 60;

    final timeString = hours > 0
        ? '${hours}h ${minutes}m'
        : '${minutes}m';

    final color = _getColorForLevel(level);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'TIME TO CRASH',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              timeString,
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: color,
                shadows: [
                  Shadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _buildStatusIndicator(level),
      ],
    );
  }

  Widget _buildStatusIndicator(FuelLevel level) {
    final color = _getColorForLevel(level);
    final text = _getStatusText(level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Color _getColorForLevel(FuelLevel level) {
    switch (level) {
      case FuelLevel.optimal:
        return AppColors.fuelOptimal;
      case FuelLevel.warning:
        return AppColors.fuelWarning;
      case FuelLevel.critical:
        return AppColors.fuelCritical;
      case FuelLevel.depleted:
        return AppColors.fuelDepleted;
    }
  }

  String _getStatusText(FuelLevel level) {
    switch (level) {
      case FuelLevel.optimal:
        return 'OPTIMAL';
      case FuelLevel.warning:
        return 'WARNING';
      case FuelLevel.critical:
        return 'CRITICAL';
      case FuelLevel.depleted:
        return 'DEPLETED';
    }
  }
}
