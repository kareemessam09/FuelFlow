// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fuel_state_adapter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FuelStateAdapterAdapter extends TypeAdapter<FuelStateAdapter> {
  @override
  final int typeId = 4;

  @override
  FuelStateAdapter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FuelStateAdapter(
      currentVolume: fields[0] as double,
      currentModeIndex: fields[1] as int,
      currentGlycemicIndex: fields[2] as double,
      lastUpdated: fields[3] as DateTime,
      lastMealTime: fields[4] as DateTime?,
      lastMealName: fields[5] as String?,
      activeMealIds: (fields[6] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, FuelStateAdapter obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.currentVolume)
      ..writeByte(1)
      ..write(obj.currentModeIndex)
      ..writeByte(2)
      ..write(obj.currentGlycemicIndex)
      ..writeByte(3)
      ..write(obj.lastUpdated)
      ..writeByte(4)
      ..write(obj.lastMealTime)
      ..writeByte(5)
      ..write(obj.lastMealName)
      ..writeByte(6)
      ..write(obj.activeMealIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FuelStateAdapterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
