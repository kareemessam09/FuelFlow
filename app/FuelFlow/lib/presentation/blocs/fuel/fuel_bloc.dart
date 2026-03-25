import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/constants.dart';
import '../../../domain/entities/entities.dart';
import 'fuel_event.dart';
import 'fuel_state.dart';

/// FuelBloc - The core engine that manages the "Stomach Balloon" state
/// 
/// Key responsibilities:
/// 1. Local decay timer - updates UI every second using the decay formula
/// 2. Activity mode management - adjusts decay multiplier
/// 3. Meal integration - adds fuel and updates glycemic index
/// 4. Server sync - periodically syncs with backend
class FuelBloc extends Bloc<FuelEvent, FuelBlocState> {
  Timer? _decayTimer;
  Timer? _syncTimer;
  DateTime _lastTickTime = DateTime.now();

  FuelBloc() : super(FuelBlocState.initial()) {
    on<FuelInitialize>(_onInitialize);
    on<FuelTickDecay>(_onTickDecay);
    on<FuelChangeActivity>(_onChangeActivity);
    on<FuelAddMeal>(_onAddMeal);
    on<FuelSyncWithServer>(_onSyncWithServer);
    on<FuelUpdateFromServer>(_onUpdateFromServer);
    on<FuelPauseDecay>(_onPauseDecay);
    on<FuelResumeDecay>(_onResumeDecay);
    on<FuelReset>(_onReset);
    on<FuelCriticalNotificationShown>(_onCriticalNotificationShown);
  }

  /// Initialize the fuel state and start timers
  Future<void> _onInitialize(
    FuelInitialize event,
    Emitter<FuelBlocState> emit,
  ) async {
    emit(state.copyWith(status: FuelBlocStatus.loading));

    // TODO: Load saved state from local storage or fetch from server
    // For now, start with a default state
    final initialState = FuelState.initial();

    emit(state.copyWith(
      fuelState: initialState,
      status: FuelBlocStatus.running,
      isDecayActive: true,
    ));

    _startDecayTimer();
    _startSyncTimer();
    _lastTickTime = DateTime.now();
  }

  /// Handle decay tick - called every second
  void _onTickDecay(
    FuelTickDecay event,
    Emitter<FuelBlocState> emit,
  ) {
    if (!state.isDecayActive) return;

    final now = DateTime.now();
    final elapsed = now.difference(_lastTickTime);
    _lastTickTime = now;

    // Apply decay formula: V_remaining = V_start - (R_base * G_index * M_activity * Δt)
    final newFuelState = state.fuelState.applyDecay(
      elapsed: elapsed,
      baseRate: AppConstants.baseMetabolicRate,
    );

    // Check if we've crossed the critical threshold
    final wasAboveCritical = state.fuelState.currentVolume > AppConstants.criticalThreshold;
    final isNowAtOrBelowCritical = newFuelState.currentVolume <= AppConstants.criticalThreshold;
    final crossedThreshold = wasAboveCritical && isNowAtOrBelowCritical;

    emit(state.copyWith(
      fuelState: newFuelState,
      // Reset notification flag when we cross threshold (so it can trigger)
      criticalNotificationShown: crossedThreshold ? false : state.criticalNotificationShown,
    ));
  }

  /// Change activity mode
  void _onChangeActivity(
    FuelChangeActivity event,
    Emitter<FuelBlocState> emit,
  ) {
    final newFuelState = state.fuelState.copyWith(
      currentMode: event.newMode,
      lastUpdated: DateTime.now(),
    );

    emit(state.copyWith(fuelState: newFuelState));

    // Trigger server sync when activity changes
    add(const FuelSyncWithServer());
  }

  /// Add fuel from a meal
  void _onAddMeal(
    FuelAddMeal event,
    Emitter<FuelBlocState> emit,
  ) {
    final newFuelState = state.fuelState.addFuel(
      amount: event.fullnessAmount,
      newGlycemicIndex: event.glycemicIndex,
      mealName: event.mealName,
    );

    // Reset critical notification flag since we've refueled
    emit(state.copyWith(
      fuelState: newFuelState,
      criticalNotificationShown: false,
    ));

    // Sync with server after adding meal
    add(const FuelSyncWithServer());
  }

  /// Sync with backend server
  Future<void> _onSyncWithServer(
    FuelSyncWithServer event,
    Emitter<FuelBlocState> emit,
  ) async {
    if (state.isSyncing) return;

    emit(state.copyWith(isSyncing: true));

    try {
      // TODO: Implement actual API call
      // final serverState = await _fuelRepository.syncState(state.fuelState);
      // add(FuelUpdateFromServer(serverState));
      
      // For now, just update sync time
      await Future.delayed(const Duration(milliseconds: 100));
      
      emit(state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
      ));
    } catch (e) {
      emit(state.copyWith(
        isSyncing: false,
        errorMessage: 'Failed to sync with server: $e',
        status: FuelBlocStatus.error,
      ));
    }
  }

  /// Update state from server response
  void _onUpdateFromServer(
    FuelUpdateFromServer event,
    Emitter<FuelBlocState> emit,
  ) {
    // Interpolate between local and server state if needed
    // For now, trust server state
    emit(state.copyWith(
      fuelState: event.serverState,
      lastSyncTime: DateTime.now(),
      isSyncing: false,
    ));
  }

  /// Pause decay timer (app backgrounded)
  void _onPauseDecay(
    FuelPauseDecay event,
    Emitter<FuelBlocState> emit,
  ) {
    _stopDecayTimer();
    emit(state.copyWith(
      isDecayActive: false,
      status: FuelBlocStatus.paused,
    ));
  }

  /// Resume decay timer
  void _onResumeDecay(
    FuelResumeDecay event,
    Emitter<FuelBlocState> emit,
  ) {
    _lastTickTime = DateTime.now();
    _startDecayTimer();
    emit(state.copyWith(
      isDecayActive: true,
      status: FuelBlocStatus.running,
    ));
  }

  /// Reset to initial state
  void _onReset(
    FuelReset event,
    Emitter<FuelBlocState> emit,
  ) {
    emit(FuelBlocState.initial().copyWith(
      isDecayActive: true,
      status: FuelBlocStatus.running,
    ));
    _lastTickTime = DateTime.now();
  }

  /// Mark that critical notification was shown
  void _onCriticalNotificationShown(
    FuelCriticalNotificationShown event,
    Emitter<FuelBlocState> emit,
  ) {
    emit(state.copyWith(criticalNotificationShown: true));
  }

  /// Start the local decay timer
  void _startDecayTimer() {
    _decayTimer?.cancel();
    _decayTimer = Timer.periodic(
      const Duration(milliseconds: AppConstants.decayUpdateIntervalMs),
      (_) => add(const FuelTickDecay()),
    );
  }

  /// Stop the decay timer
  void _stopDecayTimer() {
    _decayTimer?.cancel();
    _decayTimer = null;
  }

  /// Start the server sync timer
  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      const Duration(milliseconds: AppConstants.serverSyncIntervalMs),
      (_) => add(const FuelSyncWithServer()),
    );
  }

  /// Stop the sync timer
  void _stopSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  @override
  Future<void> close() {
    _stopDecayTimer();
    _stopSyncTimer();
    return super.close();
  }
}
