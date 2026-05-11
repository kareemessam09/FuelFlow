import 'package:equatable/equatable.dart';

/// User entity with profile and preferences
class User extends Equatable {
  final String id;
  final String? email;
  final String? displayName;
  final SensitivityLevel sensitivityLevel;
  final TargetGoal targetGoal;
  final String units;
  final DateTime createdAt;
  final bool notifyOnLowEnergy;
  final bool notifyMealReminders;

  const User({
    required this.id,
    this.email,
    this.displayName,
    this.sensitivityLevel = SensitivityLevel.sensitive,
    this.targetGoal = TargetGoal.maintenance,
    this.units = 'metric',
    required this.createdAt,
    this.notifyOnLowEnergy = true,
    this.notifyMealReminders = true,
  });

  /// Factory for creating a guest/anonymous user
  factory User.guest() {
    return User(
      id: 'guest',
      sensitivityLevel: SensitivityLevel.sensitive,
      targetGoal: TargetGoal.maintenance,
      units: 'metric',
      createdAt: DateTime.now(),
      notifyOnLowEnergy: true,
      notifyMealReminders: true,
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    SensitivityLevel? sensitivityLevel,
    TargetGoal? targetGoal,
    String? units,
    DateTime? createdAt,
    bool? notifyOnLowEnergy,
    bool? notifyMealReminders,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      sensitivityLevel: sensitivityLevel ?? this.sensitivityLevel,
      targetGoal: targetGoal ?? this.targetGoal,
      units: units ?? this.units,
      createdAt: createdAt ?? this.createdAt,
      notifyOnLowEnergy: notifyOnLowEnergy ?? this.notifyOnLowEnergy,
      notifyMealReminders: notifyMealReminders ?? this.notifyMealReminders,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    sensitivityLevel,
    targetGoal,
    units,
    createdAt,
    notifyOnLowEnergy,
    notifyMealReminders,
  ];
}

/// User's sensitivity to energy crashes
/// Affects notification thresholds and alert frequency
enum SensitivityLevel {
  low('Low', 'Fewer alerts, higher tolerance'),
  normal('Normal', 'Standard alert thresholds'),
  sensitive('Sensitive', 'High-priority alerts, lower thresholds');

  final String displayName;
  final String description;

  const SensitivityLevel(this.displayName, this.description);

  /// Get the notification threshold based on sensitivity
  double get notificationThreshold {
    switch (this) {
      case SensitivityLevel.low:
        return 20.0;
      case SensitivityLevel.normal:
        return 30.0;
      case SensitivityLevel.sensitive:
        return 40.0;
    }
  }

  static SensitivityLevel fromString(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return SensitivityLevel.low;
      case 'normal':
        return SensitivityLevel.normal;
      case 'sensitive':
        return SensitivityLevel.sensitive;
      default:
        return SensitivityLevel.sensitive;
    }
  }
}

/// User's metabolic/fitness goal
/// Affects suggestions and recommendations
enum TargetGoal {
  cutting('Cutting', 'Fat loss focus'),
  maintenance('Maintenance', 'Maintain current weight'),
  bulking('Bulking', 'Muscle gain focus');

  final String displayName;
  final String description;

  const TargetGoal(this.displayName, this.description);

  static TargetGoal fromString(String goal) {
    switch (goal.toLowerCase()) {
      case 'cutting':
        return TargetGoal.cutting;
      case 'maintenance':
        return TargetGoal.maintenance;
      case 'bulking':
        return TargetGoal.bulking;
      default:
        return TargetGoal.maintenance;
    }
  }
}
