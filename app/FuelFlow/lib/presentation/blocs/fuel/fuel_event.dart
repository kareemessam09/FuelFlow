import 'package:equatable/equatable.dart';
import '../../../domain/entities/entities.dart';

/// Base class for all FuelBloc events
abstract class FuelEvent extends Equatable {
  const FuelEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize the fuel state (on app start)
class FuelInitialize extends FuelEvent {
  const FuelInitialize();
}

/// Tick event for local decay calculation (called every second)
class FuelTickDecay extends FuelEvent {
  const FuelTickDecay();
}

/// Change the current activity mode
class FuelChangeActivity extends FuelEvent {
  final ActivityMode newMode;

  const FuelChangeActivity(this.newMode);

  @override
  List<Object?> get props => [newMode];
}

/// Add fuel from a meal
class FuelAddMeal extends FuelEvent {
  final double fullnessAmount;
  final double glycemicIndex;
  final String mealName;

  const FuelAddMeal({
    required this.fullnessAmount,
    required this.glycemicIndex,
    required this.mealName,
  });

  @override
  List<Object?> get props => [fullnessAmount, glycemicIndex, mealName];
}

/// Sync state with backend server
class FuelSyncWithServer extends FuelEvent {
  const FuelSyncWithServer();
}

/// Update state from server response
class FuelUpdateFromServer extends FuelEvent {
  final FuelState serverState;

  const FuelUpdateFromServer(this.serverState);

  @override
  List<Object?> get props => [serverState];
}

/// Pause the decay timer (e.g., app backgrounded)
class FuelPauseDecay extends FuelEvent {
  const FuelPauseDecay();
}

/// Resume the decay timer
class FuelResumeDecay extends FuelEvent {
  const FuelResumeDecay();
}

/// Reset fuel state to default
class FuelReset extends FuelEvent {
  const FuelReset();
}

/// Mark that critical threshold notification was shown
class FuelCriticalNotificationShown extends FuelEvent {
  const FuelCriticalNotificationShown();
}
