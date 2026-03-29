import 'package:equatable/equatable.dart';

/// Represents the different activity modes a user can be in
/// Each mode has a different energy consumption multiplier
enum ActivityMode {
  sleeping('Sleeping', 0.1, 'Minimal energy consumption during sleep'),
  resting('Resting', 1.0, 'Sedentary or light movement'),
  coding('Coding', 1.3, 'Sustained cognitive load'),
  studying('Studying', 1.6, 'High-intensity focus/memory tasks'),
  gymStrength('Gym (Strength)', 3.5, 'Anaerobic/weightlifting depletion'),
  gymCardio('Gym (Cardio)', 5.0, 'Maximum energy burn rate');

  final String displayName;
  final double multiplier;
  final String description;

  const ActivityMode(this.displayName, this.multiplier, this.description);

  /// Get ActivityMode from string — accepts both legacy snake_case and
  /// the backend's PascalCase enum values
  static ActivityMode fromString(String mode) {
    switch (mode.toLowerCase()) {
      case 'sleeping':
      case 'sleep':
        return ActivityMode.sleeping;
      case 'resting':
        return ActivityMode.resting;
      case 'coding':
        return ActivityMode.coding;
      case 'studying':
        return ActivityMode.studying;
      case 'gymstrength':
      case 'gym_strength':
      case 'gym (strength)':
        return ActivityMode.gymStrength;
      case 'gymcardio':
      case 'gym_cardio':
      case 'gym (cardio)':
        return ActivityMode.gymCardio;
      default:
        return ActivityMode.resting;
    }
  }

  /// Alias for [fromString] — accepts PascalCase strings from the backend
  static ActivityMode fromApiString(String mode) => fromString(mode);

  /// Convert to API string — must match the backend ActivityMode enum (PascalCase)
  String toApiString() {
    switch (this) {
      case ActivityMode.sleeping:
        // Backend doesn't support Sleeping; send Resting as the closest mode
        return 'Resting';
      case ActivityMode.resting:
        return 'Resting';
      case ActivityMode.coding:
        return 'Coding';
      case ActivityMode.studying:
        return 'Studying';
      case ActivityMode.gymStrength:
        return 'GymStrength';
      case ActivityMode.gymCardio:
        return 'GymCardio';
    }
  }
}

/// Activity log entity representing a period of activity
class ActivityLog extends Equatable {
  final String id;
  final String userId;
  final ActivityMode mode;
  final DateTime startTime;
  final DateTime? endTime;

  const ActivityLog({
    required this.id,
    required this.userId,
    required this.mode,
    required this.startTime,
    this.endTime,
  });

  /// Check if this activity is currently active
  bool get isActive => endTime == null;

  /// Get duration of this activity
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  ActivityLog copyWith({
    String? id,
    String? userId,
    ActivityMode? mode,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return ActivityLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mode: mode ?? this.mode,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  List<Object?> get props => [id, userId, mode, startTime, endTime];
}
