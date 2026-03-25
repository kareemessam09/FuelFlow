import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/constants.dart';
import '../../../domain/entities/entities.dart';
import '../../blocs/fuel/fuel.dart';
import '../../blocs/meal/meal.dart';
import '../../widgets/balloon/balloon.dart';
import '../../widgets/common/common.dart';
import '../../widgets/overlays/overlays.dart';

/// DashboardScreen - The main screen of FuelFlow
/// 
/// Features:
/// - Central animated Stomach Balloon
/// - Time to Crash display
/// - Current activity mode indicator
/// - Quick action buttons (Activity, Snap & Fuel)
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<FuelBloc, FuelBlocState>(
          listener: _handleFuelStateChanges,
          builder: (context, state) {
            return Stack(
              children: [
                // Background gradient
                _buildBackground(),

                // Main content
                Column(
                  children: [
                    // Top section - Timer and status
                    _buildTopSection(context, state),

                    // Center section - Balloon
                    Expanded(
                      child: _buildBalloonSection(context, state),
                    ),

                    // Bottom section - Actions and info
                    _buildBottomSection(context, state),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _handleFuelStateChanges(BuildContext context, FuelBlocState state) {
    // Handle critical threshold notification
    if (state.shouldTriggerCriticalNotification) {
      _showCriticalAlert(context, state);
      context.read<FuelBloc>().add(const FuelCriticalNotificationShown());
    }
  }

  void _showCriticalAlert(BuildContext context, FuelBlocState state) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.fuelCritical),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Energy levels dropping!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Mode: ${state.currentMode.displayName}. Refuel soon.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.fuelCritical.withOpacity(0.5)),
        ),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'ADD FUEL',
          textColor: AppColors.fuelCritical,
          onPressed: () => _openMealCapture(context),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
    );
  }

  Widget _buildTopSection(BuildContext context, FuelBlocState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          // App title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_gas_station,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'FuelFlow',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Crash timer
          CrashTimerWidget(
            minutesRemaining: state.minutesToCrash,
            level: state.currentLevel,
          ),
        ],
      ),
    );
  }

  Widget _buildBalloonSection(BuildContext context, FuelBlocState state) {
    return Center(
      child: LiquidBalloonWidget(
        fillPercentage: state.currentVolume,
        size: 280,
        onTap: () {
          // Could show detailed stats overlay
        },
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, FuelBlocState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          // Current activity indicator
          _buildActivityIndicator(context, state),
          const SizedBox(height: 20),

          // Action buttons
          _buildActionButtons(context, state),
        ],
      ),
    );
  }

  Widget _buildActivityIndicator(BuildContext context, FuelBlocState state) {
    final mode = state.currentMode;
    final color = AppColors.getActivityModeColor(mode.toApiString());

    return GestureDetector(
      onTap: () => _openActivitySelector(context, state),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForMode(mode),
              color: color,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              mode.displayName.toUpperCase(),
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${mode.multiplier}x',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, FuelBlocState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Activity selector button
        NeonIconButton(
          icon: Icons.directions_run,
          color: AppColors.getActivityModeColor(state.currentMode.toApiString()),
          onPressed: () => _openActivitySelector(context, state),
          tooltip: 'Change Activity',
        ),
        const SizedBox(width: 24),

        // Main action - Add Fuel
        SizedBox(
          width: 160,
          child: NeonButton(
            label: 'ADD FUEL',
            icon: Icons.add_a_photo,
            color: AppColors.fuelOptimal,
            onPressed: () => _openMealCapture(context),
          ),
        ),
        const SizedBox(width: 24),

        // Stats/History button
        NeonIconButton(
          icon: Icons.analytics,
          color: AppColors.secondary,
          onPressed: () {
            // TODO: Open stats/history screen
          },
          tooltip: 'View Stats',
        ),
      ],
    );
  }

  void _openActivitySelector(BuildContext context, FuelBlocState state) async {
    final selectedMode = await ActivitySelectorSheet.show(
      context,
      currentMode: state.currentMode,
    );

    if (selectedMode != null && context.mounted) {
      context.read<FuelBloc>().add(FuelChangeActivity(selectedMode));
    }
  }

  void _openMealCapture(BuildContext context) {
    // For now, add mock meal data
    // TODO: Implement camera capture flow
    context.read<FuelBloc>().add(
      const FuelAddMeal(
        fullnessAmount: 35,
        glycemicIndex: 1.0,
        mealName: 'Quick Snack',
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.fuelOptimal),
            const SizedBox(width: 12),
            Text(
              'Fuel added! +35%',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  IconData _getIconForMode(ActivityMode mode) {
    switch (mode) {
      case ActivityMode.resting:
        return Icons.weekend;
      case ActivityMode.coding:
        return Icons.code;
      case ActivityMode.studying:
        return Icons.menu_book;
      case ActivityMode.gymStrength:
        return Icons.fitness_center;
      case ActivityMode.gymCardio:
        return Icons.directions_run;
    }
  }
}
