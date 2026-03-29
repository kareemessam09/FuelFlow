// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_adapter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapterAdapter extends TypeAdapter<UserAdapter> {
  @override
  final int typeId = 7;

  @override
  UserAdapter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserAdapter(
      id: fields[0] as String,
      email: fields[1] as String?,
      displayName: fields[2] as String?,
      sensitivityLevelIndex: fields[3] as int,
      targetGoalIndex: fields[4] as int,
      createdAt: fields[5] as DateTime,
      units: (fields[6] as String?) ?? 'metric',
    );
  }

  @override
  void write(BinaryWriter writer, UserAdapter obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.displayName)
      ..writeByte(3)
      ..write(obj.sensitivityLevelIndex)
      ..writeByte(4)
      ..write(obj.targetGoalIndex)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.units);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
