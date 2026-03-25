import 'package:equatable/equatable.dart';
import 'activity.dart';

/// Represents the current energy/fuel state of the user's "stomach balloon"
/// This is the core entity that drives the app's visualization
class FuelState extends Equatable {
  /// Current volume percentage (0-100)
  final double currentVolume;

  /// Current activity mode
  final ActivityMode currentMode;

  /// Current glycemic index coefficient (from last meal)
  final double currentGlycemicIndex;

  /// Timestamp of the last state update
  final DateTime lastUpdated;

  /// Timestamp of the last meal
  final DateTime? lastMealTime;

  /// Name of the last meal consumed
  final String? lastMealName;

  const FuelState({
    required this.currentVolume,
    required this.currentMode,
    required this.currentGlycemicIndex,
    required this.lastUpdated,
    this.lastMealTime,
    this.lastMealName,
  });

  /// Factory constructor for initial/default state
  factory FuelState.initial() {
    return FuelState(
      currentVolume: 50.0,
      currentMode: ActivityMode.resting,
      currentGlycemicIndex: 1.0,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get the fuel status level
  FuelLevel get level {
    if (currentVolume > 60) return FuelLevel.optimal;
    if (currentVolume > 30) return FuelLevel.warning;
    if (currentVolume > 0) return FuelLevel.critical;
    return FuelLevel.depleted;
  }

  /// Check if at critical threshold (notification trigger)
  bool get isAtCriticalThreshold => currentVolume <= 30 && currentVolume > 0;

  /// Check if depleted
  bool get isDepleted => currentVolume <= 0;

  /// Calculate estimated minutes until crash (0%)
  /// Based on current decay rate
  int calculateMinutesToCrash({double baseRate = 0.5}) {
    if (currentVolume <= 0) return 0;

    // V_remaining = V_start - (R_base * G_index * M_activity * Δt)
    // Solving for Δt when V_remaining = 0:
    // Δt = V_start / (R_base * G_index * M_activity)
    final decayRatePerMinute = baseRate * currentGlycemicIndex * currentMode.multiplier;
    if (decayRatePerMinute <= 0) return 999; // Safeguard

    return (currentVolume / decayRatePerMinute).ceil();
  }

  /// Calculate estimated minutes until warning threshold (30%)
  int calculateMinutesToWarning({double baseRate = 0.5}) {
    if (currentVolume <= 30) return 0;

    final volumeToWarning = currentVolume - 30;
    final decayRatePerMinute = baseRate * currentGlycemicIndex * currentMode.multiplier;
    if (decayRatePerMinute <= 0) return 999;

    return (volumeToWarning / decayRatePerMinute).ceil();
  }

  /// Apply decay for a given time delta
  FuelState applyDecay({
    required Duration elapsed,
    double baseRate = 0.5,
  }) {
    final minutes = elapsed.inSeconds / 60.0;
    final decay = baseRate * currentGlycemicIndex * currentMode.multiplier * minutes;
    final newVolume = (currentVolume - decay).clamp(0.0, 100.0);

    return copyWith(
      currentVolume: newVolume,
      lastUpdated: DateTime.now(),
    );
  }

  /// Add fuel from a meal (additive, capped at 100%)
  FuelState addFuel({
    required double amount,
    required double newGlycemicIndex,
    required String mealName,
  }) {
    final newVolume = (currentVolume + amount).clamp(0.0, 100.0);

    return copyWith(
      currentVolume: newVolume,
      currentGlycemicIndex: newGlycemicIndex,
      lastUpdated: DateTime.now(),
      lastMealTime: DateTime.now(),
      lastMealName: mealName,
    );
  }

  FuelState copyWith({
    double? currentVolume,
    ActivityMode? currentMode,
    double? currentGlycemicIndex,
    DateTime? lastUpdated,
    DateTime? lastMealTime,
    String? lastMealName,
  }) {
    return FuelState(
      currentVolume: currentVolume ?? this.currentVolume,
      currentMode: currentMode ?? this.currentMode,
      currentGlycemicIndex: currentGlycemicIndex ?? this.currentGlycemicIndex,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastMealTime: lastMealTime ?? this.lastMealTime,
      lastMealName: lastMealName ?? this.lastMealName,
    );
  }

  @override
  List<Object?> get props => [
        currentVolume,
        currentMode,
        currentGlycemicIndex,
        lastUpdated,
        lastMealTime,
        lastMealName,
      ];
}

/// Enum representing the current fuel level status
enum FuelLevel {
  optimal('Optimal', 'Energy levels are great'),
  warning('Warning', 'Consider refueling soon'),
  critical('Critical', 'High risk of energy crash'),
  depleted('Depleted', 'Energy fully depleted');

  final String displayName;
  final String description;

  const FuelLevel(this.displayName, this.description);
}
