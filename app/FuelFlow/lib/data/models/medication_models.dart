class Medication {
  final String id;
  final String userId;
  final String name;
  final String timing; // before | after
  final String mealType; // breakfast | lunch | dinner | any
  final String? dosage;
  final String? notes;
  final bool reminderEnabled;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Medication({
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

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'].toString(),
      userId: json['userId'] as String,
      name: json['name'] as String,
      timing: (json['timing'] as String).toLowerCase(),
      mealType: (json['mealType'] as String? ?? 'any').toLowerCase(),
      dosage: json['dosage'] as String?,
      notes: json['notes'] as String?,
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'timing': timing,
      'mealType': mealType,
      'dosage': dosage,
      'notes': notes,
      'reminderEnabled': reminderEnabled,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'name': name,
      'timing': timing,
      'mealType': mealType,
      'dosage': dosage,
      'notes': notes,
      'reminderEnabled': reminderEnabled,
    };
  }
}

class MedicationLog {
  final String id;
  final String userId;
  final String medicationId;
  final String? mealId;
  final DateTime takenAt;
  final String? notes;
  final Medication? medication;

  const MedicationLog({
    required this.id,
    required this.userId,
    required this.medicationId,
    this.mealId,
    required this.takenAt,
    this.notes,
    this.medication,
  });

  factory MedicationLog.fromJson(Map<String, dynamic> json) {
    return MedicationLog(
      id: json['id'].toString(),
      userId: json['userId'] as String,
      medicationId: json['medicationId'].toString(),
      mealId: json['mealId']?.toString(),
      takenAt: DateTime.parse(json['takenAt'] as String),
      notes: json['notes'] as String?,
      medication: json['medication'] != null
          ? Medication.fromJson(json['medication'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toCreateJson() {
    final data = <String, dynamic>{
      'medicationId': int.tryParse(medicationId) ?? medicationId,
      'takenAt': takenAt.toIso8601String(),
    };
    if (mealId != null) {
      data['mealId'] = int.tryParse(mealId!) ?? mealId;
    }
    if (notes != null) {
      data['notes'] = notes;
    }
    return data;
  }
}

class MedicationSchedule {
  final String id;
  final String userId;
  final String medicationId;
  final List<int> daysOfWeek;
  final String time; // HH:mm
  final bool enabled;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Medication? medication;

  const MedicationSchedule({
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

  factory MedicationSchedule.fromJson(Map<String, dynamic> json) {
    final rawDays = json['daysOfWeek'];
    final days = <int>[];
    if (rawDays is String) {
      days.addAll(
        rawDays
            .split(',')
            .map((e) => int.tryParse(e.trim()))
            .whereType<int>(),
      );
    } else if (rawDays is List) {
      days.addAll(
        rawDays.map((e) => int.tryParse(e.toString())).whereType<int>(),
      );
    }

    return MedicationSchedule(
      id: json['id'].toString(),
      userId: json['userId'] as String,
      medicationId: json['medicationId'].toString(),
      daysOfWeek: days,
      time: json['time'] as String,
      enabled: json['enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      medication: json['medication'] != null
          ? Medication.fromJson(json['medication'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'medicationId': int.tryParse(medicationId) ?? medicationId,
      'daysOfWeek': daysOfWeek,
      'time': time,
      'enabled': enabled,
    };
  }
}

class BeforeMealCheckResult {
  final bool hasRequiredMedications;
  final String message;
  final List<Medication> medications;

  const BeforeMealCheckResult({
    required this.hasRequiredMedications,
    required this.message,
    required this.medications,
  });

  factory BeforeMealCheckResult.fromJson(Map<String, dynamic> json) {
    final meds = (json['medications'] as List<dynamic>? ?? const [])
        .map((e) => Medication.fromJson(e as Map<String, dynamic>))
        .toList();

    return BeforeMealCheckResult(
      hasRequiredMedications: json['hasRequiredMedications'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      medications: meds,
    );
  }
}
