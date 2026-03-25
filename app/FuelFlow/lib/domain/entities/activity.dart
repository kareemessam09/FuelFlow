import 'package:equatable/equatable.dart';

/// Represents the different activity modes a user can be in
/// Each mode has a different energy consumption multiplier
enum ActivityMode {
  resting('Resting', 1.0, 'Sedentary or light movement'),
  coding('Coding', 1.3, 'Sustained cognitive load'),
  studying('Studying', 1.6, 'High-intensity focus/memory tasks'),
  gymStrength('Gym (Strength)', 3.5, 'Anaerobic/weightlifting depletion'),
  gymCardio('Gym (Cardio)', 5.0, 'Maximum energy burn rate');

  final String displayName;
  final double multiplier;
  final String description;

  const ActivityMode(this.displayName, this.multiplier, this.description);

  /// Get ActivityMode from string
  static ActivityMode fromString(String mode) {
    switch (mode.toLowerCase()) {
      case 'resting':
        return ActivityMode.resting;
      case 'coding':
        return ActivityMode.coding;
      case 'studying':
        return ActivityMode.studying;
      case 'gym_strength':
      case 'gym (strength)':
        return ActivityMode.gymStrength;
      case 'gym_cardio':
      case 'gym (cardio)':
        return ActivityMode.gymCardio;
      default:
        return ActivityMode.resting;
    }
  }

  /// Convert to API-friendly string
  String toApiString() {
    switch (this) {
      case ActivityMode.resting:
        return 'resting';
      case ActivityMode.coding:
        return 'coding';
      case ActivityMode.studying:
        return 'studying';
      case ActivityMode.gymStrength:
        return 'gym_strength';
      case ActivityMode.gymCardio:
        return 'gym_cardio';
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
