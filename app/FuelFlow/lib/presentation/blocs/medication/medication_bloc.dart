import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../data/models/medication_models.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../services/local_storage_service.dart';

abstract class MedicationEvent extends Equatable {
  const MedicationEvent();

  @override
  List<Object?> get props => [];
}

class MedicationLoadAll extends MedicationEvent {
  const MedicationLoadAll();
}

class MedicationRefresh extends MedicationEvent {
  const MedicationRefresh();
}

class MedicationCreateRequested extends MedicationEvent {
  final Medication medication;

  const MedicationCreateRequested(this.medication);

  @override
  List<Object?> get props => [medication];
}

class MedicationUpdateRequested extends MedicationEvent {
  final String id;
  final Medication medication;

  const MedicationUpdateRequested({
    required this.id,
    required this.medication,
  });

  @override
  List<Object?> get props => [id, medication];
}

class MedicationDeleteRequested extends MedicationEvent {
  final String id;

  const MedicationDeleteRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class MedicationLogTakenRequested extends MedicationEvent {
  final Medication medication;
  final String? mealId;
  final String? notes;

  const MedicationLogTakenRequested({
    required this.medication,
    this.mealId,
    this.notes,
  });

  @override
  List<Object?> get props => [medication, mealId, notes];
}

class MedicationCheckBeforeMealRequested extends MedicationEvent {
  final String mealType;

  const MedicationCheckBeforeMealRequested(this.mealType);

  @override
  List<Object?> get props => [mealType];
}

abstract class MedicationState extends Equatable {
  const MedicationState();

  @override
  List<Object?> get props => [];
}

class MedicationInitial extends MedicationState {}

class MedicationLoading extends MedicationState {}

class MedicationLoaded extends MedicationState {
  final List<Medication> medications;
  final List<MedicationLog> todayLogs;
  final List<MedicationSchedule> schedules;
  final BeforeMealCheckResult? beforeMealCheck;
  final String? statusMessage;

  const MedicationLoaded({
    required this.medications,
    required this.todayLogs,
    required this.schedules,
    this.beforeMealCheck,
    this.statusMessage,
  });

  MedicationLoaded copyWith({
    List<Medication>? medications,
    List<MedicationLog>? todayLogs,
    List<MedicationSchedule>? schedules,
    BeforeMealCheckResult? beforeMealCheck,
    String? statusMessage,
    bool clearStatusMessage = false,
  }) {
    return MedicationLoaded(
      medications: medications ?? this.medications,
      todayLogs: todayLogs ?? this.todayLogs,
      schedules: schedules ?? this.schedules,
      beforeMealCheck: beforeMealCheck ?? this.beforeMealCheck,
      statusMessage: clearStatusMessage ? null : (statusMessage ?? this.statusMessage),
    );
  }

  @override
  List<Object?> get props => [
        medications,
        todayLogs,
        schedules,
        beforeMealCheck,
        statusMessage,
      ];
}

class MedicationError extends MedicationState {
  final String message;

  const MedicationError(this.message);

  @override
  List<Object?> get props => [message];
}

class MedicationBloc extends Bloc<MedicationEvent, MedicationState> {
  final MedicationRepository _repository;
  final LocalStorageService _localStorage;

  MedicationBloc({
    MedicationRepository? repository,
    LocalStorageService? localStorage,
  })  : _repository = repository ?? MedicationRepositoryImpl(),
        _localStorage = localStorage ?? LocalStorageService(),
        super(MedicationInitial()) {
    on<MedicationLoadAll>(_onLoadAll);
    on<MedicationRefresh>(_onRefresh);
    on<MedicationCreateRequested>(_onCreateMedication);
    on<MedicationUpdateRequested>(_onUpdateMedication);
    on<MedicationDeleteRequested>(_onDeleteMedication);
    on<MedicationLogTakenRequested>(_onLogTakenMedication);
    on<MedicationCheckBeforeMealRequested>(_onCheckBeforeMeal);
  }

  Future<void> _onLoadAll(
    MedicationLoadAll event,
    Emitter<MedicationState> emit,
  ) async {
    emit(MedicationLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefresh(
    MedicationRefresh event,
    Emitter<MedicationState> emit,
  ) async {
    final current = state;
    if (current is! MedicationLoaded) {
      emit(MedicationLoading());
    } else {
      emit(current.copyWith(clearStatusMessage: true));
    }
    await _fetchAndEmit(emit);
  }

  Future<void> _onCreateMedication(
    MedicationCreateRequested event,
    Emitter<MedicationState> emit,
  ) async {
    final current = state;
    if (current is! MedicationLoaded) return;

    try {
      final created = await _repository.createMedication(event.medication);
      await _localStorage.upsertMedication(created);
      await _fetchAndEmit(emit, statusMessage: 'Medication created');
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      debugPrint('[MedicationBloc] Failed to create medication: $error');
      emit(MedicationError('Failed to create medication: $error'));
      emit(current);
    }
  }

  Future<void> _onUpdateMedication(
    MedicationUpdateRequested event,
    Emitter<MedicationState> emit,
  ) async {
    final current = state;
    if (current is! MedicationLoaded) return;

    try {
      final updated = await _repository.updateMedication(event.id, event.medication);
      await _localStorage.upsertMedication(updated);
      await _fetchAndEmit(emit, statusMessage: 'Medication updated');
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      debugPrint('[MedicationBloc] Failed to update medication: $error');
      emit(MedicationError('Failed to update medication: $error'));
      emit(current);
    }
  }

  Future<void> _onDeleteMedication(
    MedicationDeleteRequested event,
    Emitter<MedicationState> emit,
  ) async {
    final current = state;
    if (current is! MedicationLoaded) return;

    try {
      await _repository.deleteMedication(event.id);
      await _localStorage.removeMedication(event.id);
      await _fetchAndEmit(emit, statusMessage: 'Medication deleted');
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      debugPrint('[MedicationBloc] Failed to delete medication: $error');
      emit(MedicationError('Failed to delete medication: $error'));
      emit(current);
    }
  }

  Future<void> _onLogTakenMedication(
    MedicationLogTakenRequested event,
    Emitter<MedicationState> emit,
  ) async {
    final current = state;
    if (current is! MedicationLoaded) return;

    try {
      final log = MedicationLog(
        id: '0',
        userId: event.medication.userId,
        medicationId: event.medication.id,
        mealId: event.mealId,
        takenAt: DateTime.now(),
        notes: event.notes,
      );
      final createdLog = await _repository.logMedication(log);
      await _localStorage.addMedicationLog(createdLog);
      await _fetchAndEmit(emit, statusMessage: 'Medication logged');
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      debugPrint('[MedicationBloc] Failed to log medication: $error');
      emit(MedicationError('Failed to log medication: $error'));
      emit(current);
    }
  }

  Future<void> _onCheckBeforeMeal(
    MedicationCheckBeforeMealRequested event,
    Emitter<MedicationState> emit,
  ) async {
    final current = state;
    if (current is! MedicationLoaded) return;

    try {
      final result = await _repository.checkBeforeMeal(mealType: event.mealType);
      emit(current.copyWith(beforeMealCheck: result, clearStatusMessage: true));
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      debugPrint('[MedicationBloc] Failed before-meal medication check: $error');
      emit(MedicationError('Failed to check before-meal medications: $error'));
      emit(current);
    }
  }

  Future<void> _fetchAndEmit(
    Emitter<MedicationState> emit, {
    String? statusMessage,
  }) async {
    try {
      final medications = await _repository.getMedications();
      final todayLogs = await _repository.getTodayLogs();
      final schedules = await _repository.getSchedules();

      await _localStorage.upsertMedications(medications);
      await _localStorage.clearMedicationLogs();
      for (final log in todayLogs) {
        await _localStorage.addMedicationLog(log);
      }
      await _localStorage.clearMedicationSchedules();
      await _localStorage.upsertMedicationSchedules(schedules);

      emit(MedicationLoaded(
        medications: medications,
        todayLogs: todayLogs,
        schedules: schedules,
        statusMessage: statusMessage,
      ));
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      debugPrint('[MedicationBloc] Failed to fetch medication data: $error');
      final cachedMedications = _localStorage.getMedications();
      final cachedLogs = _localStorage.getTodayMedicationLogs();
      final cachedSchedules = _localStorage.getMedicationSchedules();

      if (cachedMedications.isNotEmpty ||
          cachedLogs.isNotEmpty ||
          cachedSchedules.isNotEmpty) {
        emit(MedicationLoaded(
          medications: cachedMedications,
          todayLogs: cachedLogs,
          schedules: cachedSchedules,
          statusMessage: 'Showing cached medication data',
        ));
        return;
      }

      emit(MedicationError('Failed to load medications: $error'));
    }
  }
}
