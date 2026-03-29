// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_adapter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MealLogAdapterAdapter extends TypeAdapter<MealLogAdapter> {
  @override
  final int typeId = 3;

  @override
  MealLogAdapter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealLogAdapter(
      id: fields[0] as String,
      userId: fields[1] as String,
      foodName: fields[2] as String,
      fullnessVolume: fields[3] as double,
      absorptionRate: fields[4] as double,
      absorptionProfileIndex: fields[5] as int,
      estimatedSatietyMinutes: fields[6] as int,
      imageUrl: fields[7] as String?,
      createdAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MealLogAdapter obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.foodName)
      ..writeByte(3)
      ..write(obj.fullnessVolume)
      ..writeByte(4)
      ..write(obj.absorptionRate)
      ..writeByte(5)
      ..write(obj.absorptionProfileIndex)
      ..writeByte(6)
      ..write(obj.estimatedSatietyMinutes)
      ..writeByte(7)
      ..write(obj.imageUrl)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealLogAdapterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
