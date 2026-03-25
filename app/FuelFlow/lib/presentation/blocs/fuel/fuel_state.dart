import 'package:equatable/equatable.dart';
import '../../../domain/entities/entities.dart';

/// Represents the state of the FuelBloc
class FuelBlocState extends Equatable {
  /// The current fuel state
  final FuelState fuelState;

  /// Whether the decay timer is running
  final bool isDecayActive;

  /// Whether we're currently syncing with server
  final bool isSyncing;

  /// Last sync timestamp
  final DateTime? lastSyncTime;

  /// Whether critical notification has been shown for current dip below threshold
  final bool criticalNotificationShown;

  /// Error message if any
  final String? errorMessage;

  /// Status of the bloc
  final FuelBlocStatus status;

  const FuelBlocState({
    required this.fuelState,
    this.isDecayActive = false,
    this.isSyncing = false,
    this.lastSyncTime,
    this.criticalNotificationShown = false,
    this.errorMessage,
    this.status = FuelBlocStatus.initial,
  });

  /// Factory for initial state
  factory FuelBlocState.initial() {
    return FuelBlocState(
      fuelState: FuelState.initial(),
      status: FuelBlocStatus.initial,
    );
  }

  /// Check if we should trigger critical notification
  /// Only triggers once per crossing the threshold
  bool get shouldTriggerCriticalNotification {
    return fuelState.isAtCriticalThreshold && !criticalNotificationShown;
  }

  /// Minutes until crash for UI display
  int get minutesToCrash => fuelState.calculateMinutesToCrash();

  /// Minutes until warning for UI display
  int get minutesToWarning => fuelState.calculateMinutesToWarning();

  /// Current fuel level for UI
  FuelLevel get currentLevel => fuelState.level;

  /// Current volume percentage for UI
  double get currentVolume => fuelState.currentVolume;

  /// Current activity mode for UI
  ActivityMode get currentMode => fuelState.currentMode;

  FuelBlocState copyWith({
    FuelState? fuelState,
    bool? isDecayActive,
    bool? isSyncing,
    DateTime? lastSyncTime,
    bool? criticalNotificationShown,
    String? errorMessage,
    FuelBlocStatus? status,
  }) {
    return FuelBlocState(
      fuelState: fuelState ?? this.fuelState,
      isDecayActive: isDecayActive ?? this.isDecayActive,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      criticalNotificationShown: criticalNotificationShown ?? this.criticalNotificationShown,
      errorMessage: errorMessage,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        fuelState,
        isDecayActive,
        isSyncing,
        lastSyncTime,
        criticalNotificationShown,
        errorMessage,
        status,
      ];
}

/// Status enum for FuelBloc
enum FuelBlocStatus {
  initial,
  loading,
  running,
  paused,
  error,
}
