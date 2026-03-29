// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_adapter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityLogAdapterAdapter extends TypeAdapter<ActivityLogAdapter> {
  @override
  final int typeId = 1;

  @override
  ActivityLogAdapter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActivityLogAdapter(
      adapterId: fields[0] as String,
      adapterUserId: fields[1] as String,
      adapterModeIndex: fields[2] as int,
      adapterStartTime: fields[3] as DateTime,
      adapterEndTime: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ActivityLogAdapter obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.adapterId)
      ..writeByte(1)
      ..write(obj.adapterUserId)
      ..writeByte(2)
      ..write(obj.adapterModeIndex)
      ..writeByte(3)
      ..write(obj.adapterStartTime)
      ..writeByte(4)
      ..write(obj.adapterEndTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityLogAdapterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
