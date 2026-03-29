import 'package:hive/hive.dart';
import '../../../domain/entities/entities.dart';

part 'meal_adapter.g.dart';

/// Hive TypeAdapter for AbsorptionProfile enum
class AbsorptionProfileAdapter extends TypeAdapter<AbsorptionProfile> {
  @override
  final int typeId = 2;

  @override
  AbsorptionProfile read(BinaryReader reader) {
    final index = reader.readByte();
    return AbsorptionProfile.values[index];
  }

  @override
  void write(BinaryWriter writer, AbsorptionProfile obj) {
    writer.writeByte(obj.index);
  }
}

/// Hive TypeAdapter for MealLog
@HiveType(typeId: 3)
class MealLogAdapter extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String foodName;

  @HiveField(3)
  final double fullnessVolume;

  @HiveField(4)
  final double absorptionRate;

  @HiveField(5)
  final int absorptionProfileIndex;

  @HiveField(6)
  final int estimatedSatietyMinutes;

  @HiveField(7)
  final String? imageUrl;

  @HiveField(8)
  final DateTime createdAt;

  MealLogAdapter({
    required this.id,
    required this.userId,
    required this.foodName,
    required this.fullnessVolume,
    required this.absorptionRate,
    required this.absorptionProfileIndex,
    required this.estimatedSatietyMinutes,
    this.imageUrl,
    required this.createdAt,
  });

  factory MealLogAdapter.fromEntity(MealLog meal) {
    return MealLogAdapter(
      id: meal.id,
      userId: meal.userId,
      foodName: meal.foodName,
      fullnessVolume: meal.fullnessVolume,
      absorptionRate: meal.absorptionRate,
      absorptionProfileIndex: meal.absorptionProfile.index,
      estimatedSatietyMinutes: meal.estimatedSatietyMinutes,
      imageUrl: meal.imageUrl,
      createdAt: meal.createdAt,
    );
  }

  MealLog toEntity() {
    return MealLog(
      id: id,
      userId: userId,
      foodName: foodName,
      fullnessVolume: fullnessVolume,
      absorptionRate: absorptionRate,
      absorptionProfile: AbsorptionProfile.values[absorptionProfileIndex],
      estimatedSatietyMinutes: estimatedSatietyMinutes,
      imageUrl: imageUrl,
      createdAt: createdAt,
    );
  }
}
