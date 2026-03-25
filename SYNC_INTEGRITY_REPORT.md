# FuelFlow — Sync Integrity Report

**Auditor:** QA & Integration Engineer  
**Date:** 2026-03-25  
**Scope:** Energy Sync Engine - Flutter (BLoC) <-> NestJS Backend

---

## Executive Summary

| Category | Status | Issues Found |
|----------|--------|--------------|
| Data Normalization | PASS | Previously fixed (GI 0.01-1.0 now consistent) |
| Polling & Sync Logic | FAIL | Missing timer reset after server sync |
| Activity Mode Transitions | PARTIAL | Optimistic UI works, alertTime not persisted |
| App Resumption | FAIL | Missing server sync on resume |
| Multiple Meals | PASS | Backend is source of truth via effectiveGlycemicIndex |

---

## 1. Data Normalization Audit

### 1.1 GI Normalization - PASS

| Component | Value | Status |
|-----------|-------|--------|
| Backend `R_BASE` | 0.5 | OK |
| Flutter `baseMetabolicRate` | 0.5 | OK |
| Backend GI normalization | `glycemicIndex / 100` | OK |
| Flutter GI normalization | `(effectiveGI / 100).clamp(0.01, 1.0)` | OK |
| Flutter `FuelState.initial()` | `currentGlycemicIndex: 0.5` | OK |

**Verdict:** Both systems now use identical normalization (0.01-1.0 range).

### 1.2 Activity Multipliers - PASS

| Mode | Backend | Flutter | Match |
|------|---------|---------|-------|
| Resting | 1.0 | 1.0 | OK |
| Coding | 1.3 | 1.3 | OK |
| Studying | 1.6 | 1.6 | OK |
| GymStrength | 3.5 | 3.5 | OK |
| GymCardio | 5.0 | 5.0 | OK |

### 1.3 Thresholds - PASS

| Threshold | Backend | Flutter | Match |
|-----------|---------|---------|-------|
| Warning | 60% | 60% | OK |
| Critical | 30% | 30% | OK |
| Alert | 30% | 30% | OK |

---

## 2. Polling & Sync Logic

### 2.1 FuelRepository.syncStatus() - ISSUE FOUND

**Problem:** The `_onSyncWithServer` handler updates state from server but does NOT reset `_lastDecayReferenceTime`.

```dart
// Current (fuel_bloc.dart:291-315)
Future<void> _onSyncWithServer(...) async {
  final serverState = await _fuelRepository.getCurrentState();
  emit(state.copyWith(
    fuelState: serverState,
    isSyncing: false,
    lastSyncTime: DateTime.now(),
  ));
  // BUG: _lastDecayReferenceTime is NOT reset!
  // This causes drift: next tick calculates decay from OLD reference time
}
```

**Impact:** After sync, the next `_onTickDecay` call will calculate decay using the old `_lastDecayReferenceTime`, causing a "jump" in volume.

**Fix Required:** Reset the reference time after server sync.

### 2.2 Server Response Mapping - PASS

The `FuelRepository._parseEnergyResponse()` correctly maps:
- `energyState.volumeRemaining` -> `currentVolume`
- `effectiveGlycemicIndex` -> normalized `currentGlycemicIndex`
- `currentActivity.modeType` -> `ActivityMode`

---

## 3. Activity Mode Transitions

### 3.1 Optimistic UI - PASS

The `_onChangeActivity` handler correctly:
1. Updates local state immediately (optimistic)
2. Saves to local storage
3. Fires API call in background (fire-and-forget)

### 3.2 AlertTime Handling - ISSUE FOUND

**Problem:** The backend's `alertTime` is returned but NOT used by the Flutter app.

```dart
// Backend activity.service.ts returns:
return {
  ...activity,
  energyState,
  alertTime,  // <-- This is calculated and returned
};

// But FuelRepository only calls:
await _dio.post(AppConstants.activityToggleEndpoint, ...);
// The response is IGNORED - alertTime is never parsed or used
```

**Impact:** Background notifications can't be scheduled based on server's predicted crash time.

---

## 4. Critical Edge Cases

### 4.1 App Resumption - ISSUE FOUND

**Problem:** On `AppLifecycleState.resumed`, the app:
1. Calls `FuelResumeDecay` which applies offline decay
2. Restarts the decay timer
3. Does NOT sync with server

```dart
// Current (fuel_bloc.dart:351-378)
void _onResumeDecay(...) {
  // Apply offline decay - CORRECT
  final newFuelState = state.fuelState.applyDecay(...);
  
  // Reset reference time - CORRECT
  _lastDecayReferenceTime = now;
  _startDecayTimer();
  
  // BUG: No server sync! App state may have drifted while backgrounded
}
```

**Impact:** If meals were added from another device or the backend processed events while app was backgrounded, local state diverges.

### 4.2 Multiple Meals (Weighted GI) - PASS

The backend's `calculateEffectiveGlycemicIndex` is now the source of truth:
1. `energy.controller.ts:calculateWeightedGI()` computes weighted GI from active meals
2. Response includes `effectiveGlycemicIndex`
3. `FuelRepository._parseEnergyResponse()` applies this value to local state

The Flutter app's local `_calculateWeightedGlycemicIndex()` is only used between syncs for smooth UI updates.

---

## 5. Required Fixes

### Fix 1: Reset Reference Time After Server Sync

**File:** `app/FuelFlow/lib/presentation/blocs/fuel/fuel_bloc.dart`

```dart
Future<void> _onSyncWithServer(
  FuelSyncWithServer event,
  Emitter<FuelBlocState> emit,
) async {
  if (state.isSyncing) return;

  emit(state.copyWith(isSyncing: true));

  try {
    final serverState = await _fuelRepository.getCurrentState();
    
    // FIX: Reset the decay reference time to prevent drift
    _lastDecayReferenceTime = DateTime.now();
    
    emit(state.copyWith(
      fuelState: serverState,
      isSyncing: false,
      lastSyncTime: DateTime.now(),
    ));
    LocalStorageService().saveFuelState(serverState);
  } catch (e) {
    emit(state.copyWith(isSyncing: false));
  }
}
```

### Fix 2: Sync with Server on App Resume

**File:** `app/FuelFlow/lib/presentation/blocs/fuel/fuel_bloc.dart`

```dart
void _onResumeDecay(
  FuelResumeDecay event,
  Emitter<FuelBlocState> emit,
) {
  // Apply offline decay first (for instant UI update)
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
  
  // FIX: Trigger server sync to reconcile any drift
  add(const FuelSyncWithServer());
}
```

### Fix 3: Handle AlertTime from Activity Toggle Response

**File:** `app/FuelFlow/lib/data/repositories/fuel_repository.dart`

```dart
/// Toggle activity and return the server's alertTime for notification scheduling
Future<DateTime?> updateActivityModeWithAlert(ActivityMode mode) async {
  try {
    final response = await _dio.post(
      AppConstants.activityToggleEndpoint,
      data: {'modeType': mode.toApiString()},
    );
    
    final alertTimeStr = response.data['alertTime'] as String?;
    if (alertTimeStr != null) {
      return DateTime.parse(alertTimeStr);
    }
    return null;
  } on DioException catch (e) {
    throw _handleDioError(e);
  }
}
```

**File:** `app/FuelFlow/lib/presentation/blocs/fuel/fuel_bloc.dart`

```dart
void _onChangeActivity(
  FuelChangeActivity event,
  Emitter<FuelBlocState> emit,
) async {
  // Optimistic UI update
  final newFuelState = state.fuelState.copyWith(
    currentMode: event.newMode,
    lastUpdated: DateTime.now(),
  );
  emit(state.copyWith(fuelState: newFuelState));
  LocalStorageService().saveFuelState(newFuelState);

  // Sync with backend and schedule notification
  try {
    final alertTime = await _fuelRepository.updateActivityModeWithAlert(event.newMode);
    if (alertTime != null) {
      // Schedule background notification at alertTime
      NotificationService().scheduleCriticalAlert(alertTime);
    }
  } catch (e) {
    print('[FuelBloc] Failed to sync activity mode: $e');
  }
}
```

---

## 6. Verification Checklist

After applying fixes, verify:

- [ ] Server sync resets `_lastDecayReferenceTime` (no volume jump after sync)
- [ ] App resume triggers server sync (state reconciliation)
- [ ] Activity toggle response's `alertTime` schedules notification
- [ ] Local decay rate matches server rate (test with same inputs)
- [ ] Weighted GI from server overrides local calculation after sync

---

## Conclusion

The Energy Sync Engine has **3 integration issues** that need to be fixed:

1. **Time Drift on Sync** - Reference time not reset after server sync
2. **No Reconciliation on Resume** - App doesn't sync after being backgrounded
3. **AlertTime Unused** - Server's notification time is ignored

After applying the fixes above, the system will have **Zero Logic Drift** between local and server calculations.
