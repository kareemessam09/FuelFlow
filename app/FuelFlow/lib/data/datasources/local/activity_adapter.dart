import 'package:hive/hive.dart';
import '../../../domain/entities/entities.dart';

part 'activity_adapter.g.dart';

/// Hive TypeAdapter for ActivityMode enum
class ActivityModeAdapter extends TypeAdapter<ActivityMode> {
  @override
  final int typeId = 0;

  @override
  ActivityMode read(BinaryReader reader) {
    final index = reader.readByte();
    return ActivityMode.values[index];
  }

  @override
  void write(BinaryWriter writer, ActivityMode obj) {
    writer.writeByte(obj.index);
  }
}

/// Hive TypeAdapter for ActivityLog
@HiveType(typeId: 1)
class ActivityLogAdapter extends ActivityLog {
  @HiveField(0)
  final String adapterId;
  
  @HiveField(1)
  final String adapterUserId;
  
  @HiveField(2)
  final int adapterModeIndex;
  
  @HiveField(3)
  final DateTime adapterStartTime;
  
  @HiveField(4)
  final DateTime? adapterEndTime;

  const ActivityLogAdapter({
    required this.adapterId,
    required this.adapterUserId,
    required this.adapterModeIndex,
    required this.adapterStartTime,
    this.adapterEndTime,
  }) : super(
          id: adapterId,
          userId: adapterUserId,
          mode: ActivityMode.resting, // Will be overridden
          startTime: adapterStartTime,
          endTime: adapterEndTime,
        );

  factory ActivityLogAdapter.fromEntity(ActivityLog log) {
    return ActivityLogAdapter(
      adapterId: log.id,
      adapterUserId: log.userId,
      adapterModeIndex: log.mode.index,
      adapterStartTime: log.startTime,
      adapterEndTime: log.endTime,
    );
  }

  ActivityLog toEntity() {
    return ActivityLog(
      id: adapterId,
      userId: adapterUserId,
      mode: ActivityMode.values[adapterModeIndex],
      startTime: adapterStartTime,
      endTime: adapterEndTime,
    );
  }
}
