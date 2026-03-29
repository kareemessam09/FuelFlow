import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/constants.dart';
import '../../../data/repositories/fuel_repository.dart';
import '../../../domain/entities/entities.dart';
import '../../../services/services.dart';
import 'fuel_event.dart';
import 'fuel_state.dart';

/// FuelBloc - The core engine that manages the "Stomach Balloon" state
/// 
/// Key responsibilities:
/// 1. Local decay timer - updates UI every second using the decay formula
/// 2. Activity mode management - adjusts decay multiplier
/// 3. Meal integration - adds fuel and updates glycemic index
/// 4. Server sync - periodically syncs with backend
/// 5. Time-drift protection - calculates decay using DateTime.now().difference()
/// 6. Weighted GI for multiple meals - tracks all active meals
/// 7. User sensitivity - customizable critical threshold
class FuelBloc extends Bloc<FuelEvent, FuelBlocState> {
  Timer? _decayTimer;
  Timer? _syncTimer;
  final FuelRepository _fuelRepository;

  /// Reference timestamp for decay calculation (prevents time drift)
  DateTime _lastDecayReferenceTime = DateTime.now();

  /// Current user profile (loaded from local storage)
  User? _currentUser;

  /// Active meals in the stomach (for weighted GI calculation)
  final Map<String, MealLog> _activeMeals = {};

  FuelBloc({FuelRepository? fuelRepository})
      : _fuelRepository = fuelRepository ?? FuelRepositoryImpl(),
        super(FuelBlocState.initial()) {
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

    // Load saved user profile from local storage
    _currentUser = LocalStorageService().loadUser() ?? User.guest();

    // Try to restore previous fuel state from local storage
    FuelState? savedState = LocalStorageService().loadFuelState();
    
    final initialState = savedState ?? FuelState.initial();

    // Load recent meals to populate active meals
    if (savedState != null && savedState.activeMealIds != null) {
      final recentMeals = LocalStorageService().getRecentMealLogs(days: 1);
      for (final meal in recentMeals) {
        if (savedState.activeMealIds!.contains(meal.id)) {
          _activeMeals[meal.id] = meal;
        }
      }
    }

    emit(state.copyWith(
      fuelState: initialState,
      status: FuelBlocStatus.running,
      isDecayActive: true,
    ));

    _startDecayTimer();
    _startSyncTimer();
    _lastDecayReferenceTime = DateTime.now();
  }

  /// Handle decay tick - called every second
  /// IMPORTANT: This only triggers UI updates. Actual decay is calculated
  /// using DateTime.now().difference() to prevent time-drift attacks
  void _onTickDecay(
    FuelTickDecay event,
    Emitter<FuelBlocState> emit,
  ) {
    if (!state.isDecayActive) return;

    final now = DateTime.now();
    final elapsed = now.difference(_lastDecayReferenceTime);
    _lastDecayReferenceTime = now;

    // Calculate weighted GI if multiple meals are active
    final double effectiveGI = _calculateWeightedGlycemicIndex();
    
    // Clean up expired meals (older than 4 hours)
    _removeExpiredMeals();

    // Apply decay formula: V_remaining = V_start - (R_base * G_index * M_activity * Δt)
    final newFuelState = state.fuelState.applyDecay(
      elapsed: elapsed,
      baseRate: AppConstants.baseMetabolicRate,
      effectiveGI: effectiveGI,
    );

    // Check if we've crossed the custom threshold based on user sensitivity
    final threshold = _currentUser?.sensitivityLevel.notificationThreshold ?? 30.0;
    final wasAboveThreshold = state.fuelState.currentVolume > threshold;
    final isNowAtOrBelowThreshold = newFuelState.currentVolume <= threshold;
    final crossedThreshold = wasAboveThreshold && isNowAtOrBelowThreshold;

    // Suppress notifications during sleep mode
    final shouldSuppressNotification = state.fuelState.currentMode == ActivityMode.sleeping;

    emit(state.copyWith(
      fuelState: newFuelState.copyWith(
        currentGlycemicIndex: effectiveGI,
        activeMealIds: _activeMeals.keys.toList(),
      ),
      // Reset notification flag when we cross threshold (so it can trigger)
      // But suppress if in sleep mode
      criticalNotificationShown: 
          (crossedThreshold && !shouldSuppressNotification) ? false : state.criticalNotificationShown,
    ));

    // Auto-save state periodically (every 10 seconds)
    if (elapsed.inSeconds % 10 == 0) {
      LocalStorageService().saveFuelState(state.fuelState);
    }
  }

  /// Calculate weighted glycemic index from all active meals
  /// When multiple meals overlap, we need a weighted average based on
  /// remaining volume contribution of each meal
  /// 
  /// RETURNS: Normalized GI in range 0.01-1.0 (matching backend)
  double _calculateWeightedGlycemicIndex() {
    if (_activeMeals.isEmpty) {
      return 0.5; // Default baseline GI (50 / 100 = 0.5)
    }

    if (_activeMeals.length == 1) {
      // glycemicIndexCoefficient is stored as raw (1-100), normalize it
      final rawGI = _activeMeals.values.first.glycemicIndexCoefficient;
      return (rawGI / 100).clamp(0.01, 1.0);
    }

    // Calculate weighted GI based on meal contribution and age
    double totalWeight = 0.0;
    double weightedSum = 0.0;

    for (final meal in _activeMeals.values) {
      final ageInMinutes = DateTime.now().difference(meal.createdAt).inMinutes;
      
      // Weight decreases as meal ages (absorption complete after ~4 hours)
      // Weight = 1.0 at t=0, decreases exponentially
      final weight = _calculateMealWeight(ageInMinutes, meal.estimatedSatietyMinutes);
      
      // Normalize the raw GI (1-100) to coefficient (0.01-1.0)
      final normalizedGI = (meal.glycemicIndexCoefficient / 100).clamp(0.01, 1.0);
      
      totalWeight += weight;
      weightedSum += normalizedGI * weight;
    }

    return totalWeight > 0 ? weightedSum / totalWeight : 0.5;
  }

  /// Calculate the weight of a meal based on age and satiety duration
  /// Returns a value between 0.0 and 1.0
  double _calculateMealWeight(int ageInMinutes, int satietyMinutes) {
    if (ageInMinutes <= 0) return 1.0;
    if (ageInMinutes >= satietyMinutes * 2) return 0.0; // Fully absorbed after 2x satiety
    
    // Exponential decay: weight = e^(-k * age / satiety)
    // Where k = ln(100) / 2 to reach ~0.01 at 2x satiety
    const k = 2.3; // ln(10)
    final normalizedAge = ageInMinutes / satietyMinutes;
    return (1.0 / (1.0 + k * normalizedAge)).clamp(0.0, 1.0);
  }

  /// Remove meals that are fully absorbed (older than 4 hours)
  void _removeExpiredMeals() {
    final now = DateTime.now();
    final fourHoursAgo = now.subtract(const Duration(hours: 4));
    
    _activeMeals.removeWhere((id, meal) {
      final expired = meal.createdAt.isBefore(fourHoursAgo);
      return expired;
    });
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

    // Save state when activity changes
    LocalStorageService().saveFuelState(newFuelState);

    // Log activity change locally
    LocalStorageService().addActivityLog(
      ActivityLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _currentUser?.id ?? 'guest',
        mode: event.newMode,
        startTime: DateTime.now(),
      ),
    );

    // Notify backend and handle alertTime response
    _fuelRepository.updateActivityMode(event.newMode).then((alertTime) {
      // Schedule notification for when energy will hit critical threshold
      if (alertTime != null) {
        NotificationService().scheduleEnergyAlert(
          alertTime: alertTime,
          currentMode: event.newMode.displayName,
        );
      }
    }).catchError((e) {
      // Non-fatal: local state is already updated
      // ignore: avoid_print
      print('[FuelBloc] Failed to sync activity mode: $e');
    });
  }

  /// Add fuel from a meal
  void _onAddMeal(
    FuelAddMeal event,
    Emitter<FuelBlocState> emit,
  ) {
    // Create MealLog for this new meal
    final newMeal = MealLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _currentUser?.id ?? 'guest',
      foodName: event.mealName,
      fullnessVolume: event.fullnessAmount,
      absorptionRate: event.glycemicIndex,
      absorptionProfile: _getAbsorptionProfileFromGI(event.glycemicIndex),
      estimatedSatietyMinutes: _estimateSatietyMinutes(event.fullnessAmount, event.glycemicIndex),
      createdAt: DateTime.now(),
    );

    // Add to active meals
    _activeMeals[newMeal.id] = newMeal;

    // Save to local storage
    LocalStorageService().addMealLog(newMeal);

    final newFuelState = state.fuelState.addFuel(
      amount: event.fullnessAmount,
      newGlycemicIndex: event.glycemicIndex,
      mealName: event.mealName,
      mealId: newMeal.id,
    );

    // Reset critical notification flag since we've refueled
    emit(state.copyWith(
      fuelState: newFuelState,
      criticalNotificationShown: false,
    ));

    // Save state
    LocalStorageService().saveFuelState(newFuelState);

    // Sync with server after adding meal
    add(const FuelSyncWithServer());
  }

  /// Helper: Estimate absorption profile from GI value
  AbsorptionProfile _getAbsorptionProfileFromGI(double gi) {
    if (gi > 70) return AbsorptionProfile.fast;
    if (gi > 40) return AbsorptionProfile.balanced;
    return AbsorptionProfile.slowRelease;
  }

  /// Helper: Estimate satiety duration based on fullness and GI
  int _estimateSatietyMinutes(double fullness, double gi) {
    // Base satiety: 180 minutes (3 hours) at 100% fullness and GI 50
    // Adjust for fullness and inverse GI (higher GI = shorter satiety)
    final baseSatiety = 180;
    final fullnessFactor = fullness / 100.0;
    final giFactor = (100 - gi) / 50.0; // Inverse relationship
    return (baseSatiety * fullnessFactor * giFactor).round().clamp(60, 300);
  }

  /// Sync with backend server — fetches authoritative energy state
  Future<void> _onSyncWithServer(
    FuelSyncWithServer event,
    Emitter<FuelBlocState> emit,
  ) async {
    if (state.isSyncing) return;

    emit(state.copyWith(isSyncing: true));

    try {
      final serverState = await _fuelRepository.getCurrentState();
      
      // CRITICAL: Reset the decay reference time to prevent time drift
      // Without this, the next tick would calculate decay from the old reference,
      // causing a "jump" in volume after sync
      _lastDecayReferenceTime = DateTime.now();
      
      emit(state.copyWith(
        fuelState: serverState,
        isSyncing: false,
        lastSyncTime: DateTime.now(),
      ));
      LocalStorageService().saveFuelState(serverState);
    } catch (e) {
      // Non-fatal: continue running on local state
      emit(state.copyWith(
        isSyncing: false,
        // Don't mark as error — just silently fail sync
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
    
    // Save server state locally
    LocalStorageService().saveFuelState(event.serverState);
  }

  /// Pause decay timer (app backgrounded)
  void _onPauseDecay(
    FuelPauseDecay event,
    Emitter<FuelBlocState> emit,
  ) {
    _stopDecayTimer();
    
    // Save state before pausing
    LocalStorageService().saveFuelState(state.fuelState);
    
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
    // Recalculate decay based on time elapsed while paused
    // This prevents time drift from app backgrounding
    final now = DateTime.now();
    final elapsed = now.difference(_lastDecayReferenceTime);
    
    if (elapsed.inSeconds > 0) {
      final effectiveGI = _calculateWeightedGlycemicIndex();
      final newFuelState = state.fuelState.applyDecay(
        elapsed: elapsed,
        baseRate: AppConstants.baseMetabolicRate,
        effectiveGI: effectiveGI,
      );
      
      emit(state.copyWith(fuelState: newFuelState));
      LocalStorageService().saveFuelState(newFuelState);
    }
    
    _lastDecayReferenceTime = now;
    _startDecayTimer();
    emit(state.copyWith(
      isDecayActive: true,
      status: FuelBlocStatus.running,
    ));

    // CRITICAL: Sync with server after resume to reconcile any drift
    // that occurred while the app was backgrounded
    add(const FuelSyncWithServer());
  }

  /// Reset to initial state
  void _onReset(
    FuelReset event,
    Emitter<FuelBlocState> emit,
  ) {
    _activeMeals.clear();
    
    final initialState = FuelState.initial();
    
    emit(FuelBlocState.initial().copyWith(
      isDecayActive: true,
      status: FuelBlocStatus.running,
    ));
    
    _lastDecayReferenceTime = DateTime.now();
    
    // Save reset state
    LocalStorageService().saveFuelState(initialState);
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
    final syncIntervalMs = AppConstants.serverSyncIntervalMs;
    _syncTimer = Timer.periodic(
      Duration(milliseconds: syncIntervalMs),
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
    
    // Save final state before closing
    LocalStorageService().saveFuelState(state.fuelState);
    
    return super.close();
  }
}
