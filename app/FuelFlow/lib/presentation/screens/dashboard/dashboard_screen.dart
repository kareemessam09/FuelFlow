import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants.dart';
import '../../../domain/entities/entities.dart';
import '../../blocs/fuel/fuel.dart';
import '../../widgets/balloon/balloon.dart';
import '../../widgets/common/common.dart';
import '../../widgets/overlays/overlays.dart';

/// DashboardScreen - The main screen of FuelFlow
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
                Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.backgroundGradient,
                  ),
                ),

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
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  void _handleFuelStateChanges(BuildContext context, FuelBlocState state) {
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
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ENERGY CRITICAL',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Mode: ${state.currentMode.displayName}. Refuel now!',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'ADD FUEL',
          textColor: Colors.white,
          onPressed: () => context.push('/meal-capture'),
        ),
      ),
    );
  }

  Widget _buildTopSection(BuildContext context, FuelBlocState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          // App title with logo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_gas_station_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              ShaderMask(
                shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                child: const Text(
                  'FuelFlow',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

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
      child: FittedBox(
        fit: BoxFit.contain,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
                      child: LiquidBalloonWidget(
                        fillPercentage: state.currentVolume,
                        size: 280,
                        onTap: () => _showEnergyDetails(context, state),
                      ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, FuelBlocState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          // Current activity indicator
          _buildActivityIndicator(context, state),
          const SizedBox(height: 16),

          // Action button
          BrutalButton(
            height: 60,
            label: 'ADD FUEL',
            icon: Icons.add_a_photo_rounded,
            onPressed: () => context.push('/meal-capture'),
          ),
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
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForMode(mode),
              color: color,
              size: 24,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                mode.displayName.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${mode.multiplier}x',
                style: const TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: true,
                onTap: () => context.go('/'),
              ),
              _buildNavItem(
                context,
                icon: Icons.restaurant_rounded,
                label: 'Meals',
                onTap: () => context.push('/meals'),
              ),
              _buildNavItem(
                context,
                icon: Icons.favorite_rounded,
                label: 'Favorites',
                onTap: () => context.push('/favorites'),
              ),
              _buildNavItem(
                context,
                icon: Icons.analytics_rounded,
                label: 'Analytics',
                onTap: () => context.push('/analytics'),
              ),
              _buildNavItem(
                context,
                icon: Icons.settings_rounded,
                label: 'Settings',
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEnergyDetails(BuildContext context, FuelBlocState state) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Energy Insights',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text('Current mode: ${state.currentMode.displayName}'),
            Text('Fuel level: ${state.currentVolume.toStringAsFixed(0)}%'),
            Text('Time to critical: ${state.minutesToCrash} min'),
            const SizedBox(height: 14),
            const Text(
              'Tip: Keep fuel above 60% during focused sessions for better consistency.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final color = isActive ? AppColors.primary : AppColors.textTertiary;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
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
