import 'package:hive/hive.dart';
import '../../../domain/entities/entities.dart';

part 'user_adapter.g.dart';

/// Hive TypeAdapter for SensitivityLevel enum
class SensitivityLevelAdapter extends TypeAdapter<SensitivityLevel> {
  @override
  final int typeId = 5;

  @override
  SensitivityLevel read(BinaryReader reader) {
    final index = reader.readByte();
    return SensitivityLevel.values[index];
  }

  @override
  void write(BinaryWriter writer, SensitivityLevel obj) {
    writer.writeByte(obj.index);
  }
}

/// Hive TypeAdapter for TargetGoal enum
class TargetGoalAdapter extends TypeAdapter<TargetGoal> {
  @override
  final int typeId = 6;

  @override
  TargetGoal read(BinaryReader reader) {
    final index = reader.readByte();
    return TargetGoal.values[index];
  }

  @override
  void write(BinaryWriter writer, TargetGoal obj) {
    writer.writeByte(obj.index);
  }
}

/// Hive TypeAdapter for User
@HiveType(typeId: 7)
class UserAdapter extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? email;

  @HiveField(2)
  final String? displayName;

  @HiveField(3)
  final int sensitivityLevelIndex;

  @HiveField(4)
  final int targetGoalIndex;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final String units;

  @HiveField(7)
  final bool notifyOnLowEnergy;

  @HiveField(8)
  final bool notifyMealReminders;

  UserAdapter({
    required this.id,
    this.email,
    this.displayName,
    required this.sensitivityLevelIndex,
    required this.targetGoalIndex,
    required this.createdAt,
    required this.units,
    this.notifyOnLowEnergy = true,
    this.notifyMealReminders = true,
  });

  factory UserAdapter.fromEntity(User user) {
    return UserAdapter(
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      sensitivityLevelIndex: user.sensitivityLevel.index,
      targetGoalIndex: user.targetGoal.index,
      createdAt: user.createdAt,
      units: user.units,
      notifyOnLowEnergy: user.notifyOnLowEnergy,
      notifyMealReminders: user.notifyMealReminders,
    );
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      sensitivityLevel: SensitivityLevel.values[sensitivityLevelIndex],
      targetGoal: TargetGoal.values[targetGoalIndex],
      units: units,
      createdAt: createdAt,
      notifyOnLowEnergy: notifyOnLowEnergy,
      notifyMealReminders: notifyMealReminders,
    );
  }
}
