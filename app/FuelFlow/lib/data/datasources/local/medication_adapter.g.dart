// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication_adapter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicationAdapterAdapter extends TypeAdapter<MedicationAdapter> {
  @override
  final int typeId = 8;

  @override
  MedicationAdapter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicationAdapter(
      id: fields[0] as String,
      userId: fields[1] as String,
      name: fields[2] as String,
      timing: fields[3] as String,
      mealType: fields[4] as String,
      dosage: fields[5] as String?,
      notes: fields[6] as String?,
      reminderEnabled: fields[7] as bool,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, MedicationAdapter obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.timing)
      ..writeByte(4)
      ..write(obj.mealType)
      ..writeByte(5)
      ..write(obj.dosage)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.reminderEnabled)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationAdapterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MedicationLogAdapterAdapter extends TypeAdapter<MedicationLogAdapter> {
  @override
  final int typeId = 9;

  @override
  MedicationLogAdapter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicationLogAdapter(
      id: fields[0] as String,
      userId: fields[1] as String,
      medicationId: fields[2] as String,
      mealId: fields[3] as String?,
      takenAt: fields[4] as DateTime,
      notes: fields[5] as String?,
      medication: fields[6] as MedicationAdapter?,
    );
  }

  @override
  void write(BinaryWriter writer, MedicationLogAdapter obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.medicationId)
      ..writeByte(3)
      ..write(obj.mealId)
      ..writeByte(4)
      ..write(obj.takenAt)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.medication);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationLogAdapterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MedicationScheduleAdapterAdapter
    extends TypeAdapter<MedicationScheduleAdapter> {
  @override
  final int typeId = 10;

  @override
  MedicationScheduleAdapter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicationScheduleAdapter(
      id: fields[0] as String,
      userId: fields[1] as String,
      medicationId: fields[2] as String,
      daysOfWeek: (fields[3] as List).cast<int>(),
      time: fields[4] as String,
      enabled: fields[5] as bool,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime?,
      medication: fields[8] as MedicationAdapter?,
    );
  }

  @override
  void write(BinaryWriter writer, MedicationScheduleAdapter obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.medicationId)
      ..writeByte(3)
      ..write(obj.daysOfWeek)
      ..writeByte(4)
      ..write(obj.time)
      ..writeByte(5)
      ..write(obj.enabled)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.medication);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationScheduleAdapterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
