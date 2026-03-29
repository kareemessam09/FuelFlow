import 'package:hive/hive.dart';
import '../../../domain/entities/entities.dart';

part 'fuel_state_adapter.g.dart';

/// Hive TypeAdapter for FuelState
@HiveType(typeId: 4)
class FuelStateAdapter extends HiveObject {
  @HiveField(0)
  final double currentVolume;

  @HiveField(1)
  final int currentModeIndex;

  @HiveField(2)
  final double currentGlycemicIndex;

  @HiveField(3)
  final DateTime lastUpdated;

  @HiveField(4)
  final DateTime? lastMealTime;

  @HiveField(5)
  final String? lastMealName;

  @HiveField(6)
  final List<String> activeMealIds; // NEW: Track multiple meals

  FuelStateAdapter({
    required this.currentVolume,
    required this.currentModeIndex,
    required this.currentGlycemicIndex,
    required this.lastUpdated,
    this.lastMealTime,
    this.lastMealName,
    this.activeMealIds = const [],
  });

  factory FuelStateAdapter.fromEntity(FuelState state) {
    return FuelStateAdapter(
      currentVolume: state.currentVolume,
      currentModeIndex: state.currentMode.index,
      currentGlycemicIndex: state.currentGlycemicIndex,
      lastUpdated: state.lastUpdated,
      lastMealTime: state.lastMealTime,
      lastMealName: state.lastMealName,
      activeMealIds: state.activeMealIds ?? [],
    );
  }

  FuelState toEntity() {
    return FuelState(
      currentVolume: currentVolume,
      currentMode: ActivityMode.values[currentModeIndex],
      currentGlycemicIndex: currentGlycemicIndex,
      lastUpdated: lastUpdated,
      lastMealTime: lastMealTime,
      lastMealName: lastMealName,
      activeMealIds: activeMealIds,
    );
  }
}
