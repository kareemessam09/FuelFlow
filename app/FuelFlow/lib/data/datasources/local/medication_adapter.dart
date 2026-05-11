import 'package:hive/hive.dart';
import '../../models/medication_models.dart';

part 'medication_adapter.g.dart';

@HiveType(typeId: 8)
class MedicationAdapter extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String timing;

  @HiveField(4)
  final String mealType;

  @HiveField(5)
  final String? dosage;

  @HiveField(6)
  final String? notes;

  @HiveField(7)
  final bool reminderEnabled;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime? updatedAt;

  MedicationAdapter({
    required this.id,
    required this.userId,
    required this.name,
    required this.timing,
    required this.mealType,
    this.dosage,
    this.notes,
    required this.reminderEnabled,
    required this.createdAt,
    this.updatedAt,
  });

  factory MedicationAdapter.fromModel(Medication model) {
    return MedicationAdapter(
      id: model.id,
      userId: model.userId,
      name: model.name,
      timing: model.timing,
      mealType: model.mealType,
      dosage: model.dosage,
      notes: model.notes,
      reminderEnabled: model.reminderEnabled,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  Medication toModel() {
    return Medication(
      id: id,
      userId: userId,
      name: name,
      timing: timing,
      mealType: mealType,
      dosage: dosage,
      notes: notes,
      reminderEnabled: reminderEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

@HiveType(typeId: 9)
class MedicationLogAdapter extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String medicationId;

  @HiveField(3)
  final String? mealId;

  @HiveField(4)
  final DateTime takenAt;

  @HiveField(5)
  final String? notes;

  @HiveField(6)
  final MedicationAdapter? medication;

  MedicationLogAdapter({
    required this.id,
    required this.userId,
    required this.medicationId,
    this.mealId,
    required this.takenAt,
    this.notes,
    this.medication,
  });

  factory MedicationLogAdapter.fromModel(MedicationLog model) {
    return MedicationLogAdapter(
      id: model.id,
      userId: model.userId,
      medicationId: model.medicationId,
      mealId: model.mealId,
      takenAt: model.takenAt,
      notes: model.notes,
      medication: model.medication != null
          ? MedicationAdapter.fromModel(model.medication!)
          : null,
    );
  }

  MedicationLog toModel() {
    return MedicationLog(
      id: id,
      userId: userId,
      medicationId: medicationId,
      mealId: mealId,
      takenAt: takenAt,
      notes: notes,
      medication: medication?.toModel(),
    );
  }
}

@HiveType(typeId: 10)
class MedicationScheduleAdapter extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String medicationId;

  @HiveField(3)
  final List<int> daysOfWeek;

  @HiveField(4)
  final String time;

  @HiveField(5)
  final bool enabled;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime? updatedAt;

  @HiveField(8)
  final MedicationAdapter? medication;

  MedicationScheduleAdapter({
    required this.id,
    required this.userId,
    required this.medicationId,
    required this.daysOfWeek,
    required this.time,
    required this.enabled,
    required this.createdAt,
    this.updatedAt,
    this.medication,
  });

  factory MedicationScheduleAdapter.fromModel(MedicationSchedule model) {
    return MedicationScheduleAdapter(
      id: model.id,
      userId: model.userId,
      medicationId: model.medicationId,
      daysOfWeek: model.daysOfWeek,
      time: model.time,
      enabled: model.enabled,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      medication: model.medication != null
          ? MedicationAdapter.fromModel(model.medication!)
          : null,
    );
  }

  MedicationSchedule toModel() {
    return MedicationSchedule(
      id: id,
      userId: userId,
      medicationId: medicationId,
      daysOfWeek: daysOfWeek,
      time: time,
      enabled: enabled,
      createdAt: createdAt,
      updatedAt: updatedAt,
      medication: medication?.toModel(),
    );
  }
}
