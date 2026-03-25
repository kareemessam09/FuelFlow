import 'package:equatable/equatable.dart';
import 'activity.dart';

/// Represents the current energy/fuel state of the user's "stomach balloon"
/// This is the core entity that drives the app's visualization
/// 
/// IMPORTANT: currentGlycemicIndex is stored in normalized form (0.01-1.0)
/// This matches the backend which divides GI by 100. Raw GI values (1-100)
/// should be normalized before storing.
class FuelState extends Equatable {
  /// Current volume percentage (0-100)
  final double currentVolume;

  /// Current activity mode
  final ActivityMode currentMode;

  /// Current glycemic index coefficient (NORMALIZED: 0.01-1.0)
  /// Raw GI (1-100) is divided by 100 before storing
  final double currentGlycemicIndex;

  /// Timestamp of the last state update
  final DateTime lastUpdated;

  /// Timestamp of the last meal
  final DateTime? lastMealTime;

  /// Name of the last meal consumed
  final String? lastMealName;

  /// List of active meal IDs currently in the stomach (NEW: for weighted GI)
  final List<String>? activeMealIds;

  const FuelState({
    required this.currentVolume,
    required this.currentMode,
    required this.currentGlycemicIndex,
    required this.lastUpdated,
    this.lastMealTime,
    this.lastMealName,
    this.activeMealIds,
  });

  /// Factory constructor for initial/default state
  /// NOTE: currentGlycemicIndex is normalized to 0.01-1.0 range (matching backend)
  /// Default 0.5 = GI of 50 / 100
  factory FuelState.initial() {
    return FuelState(
      currentVolume: 50.0,
      currentMode: ActivityMode.resting,
      currentGlycemicIndex: 0.5, // Normalized: GI 50 / 100 = 0.5
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
  /// Note: This will be customized per user's sensitivity setting
  bool get isAtCriticalThreshold => currentVolume <= 30 && currentVolume > 0;
  
  /// Check if at custom threshold (for user sensitivity)
  bool isAtCustomThreshold(double threshold) =>
      currentVolume <= threshold && currentVolume > 0;

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
  /// effectiveGI parameter supports weighted GI from multiple meals
  FuelState applyDecay({
    required Duration elapsed,
    double baseRate = 0.5,
    double? effectiveGI,
  }) {
    final minutes = elapsed.inSeconds / 60.0;
    final giToUse = effectiveGI ?? currentGlycemicIndex;
    final decay = baseRate * giToUse * currentMode.multiplier * minutes;
    final newVolume = (currentVolume - decay).clamp(0.0, 100.0);

    return copyWith(
      currentVolume: newVolume,
      lastUpdated: DateTime.now(),
    );
  }

  /// Add fuel from a meal (additive, capped at 100%)
  /// mealId is optional for tracking active meals
  /// 
  /// IMPORTANT: newGlycemicIndex should be passed as RAW value (1-100).
  /// It will be normalized to 0.01-1.0 range internally.
  FuelState addFuel({
    required double amount,
    required double newGlycemicIndex,
    required String mealName,
    String? mealId,
  }) {
    final newVolume = (currentVolume + amount).clamp(0.0, 100.0);
    
    // Normalize GI from raw (1-100) to coefficient (0.01-1.0)
    // This matches the backend's normalization: glycemicIndex / 100
    final normalizedGI = (newGlycemicIndex / 100).clamp(0.01, 1.0);
    
    // Add meal ID to active meals list
    final updatedActiveMealIds = List<String>.from(activeMealIds ?? []);
    if (mealId != null && !updatedActiveMealIds.contains(mealId)) {
      updatedActiveMealIds.add(mealId);
    }

    return copyWith(
      currentVolume: newVolume,
      currentGlycemicIndex: normalizedGI,
      lastUpdated: DateTime.now(),
      lastMealTime: DateTime.now(),
      lastMealName: mealName,
      activeMealIds: updatedActiveMealIds,
    );
  }

  FuelState copyWith({
    double? currentVolume,
    ActivityMode? currentMode,
    double? currentGlycemicIndex,
    DateTime? lastUpdated,
    DateTime? lastMealTime,
    String? lastMealName,
    List<String>? activeMealIds,
  }) {
    return FuelState(
      currentVolume: currentVolume ?? this.currentVolume,
      currentMode: currentMode ?? this.currentMode,
      currentGlycemicIndex: currentGlycemicIndex ?? this.currentGlycemicIndex,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastMealTime: lastMealTime ?? this.lastMealTime,
      lastMealName: lastMealName ?? this.lastMealName,
      activeMealIds: activeMealIds ?? this.activeMealIds,
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
        activeMealIds,
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
