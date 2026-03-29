import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/models/models.dart';

// Events
abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();
  @override
  List<Object?> get props => [];
}

class AnalyticsLoadData extends AnalyticsEvent {
  final String period; // 'day', 'week', 'month'
  const AnalyticsLoadData(this.period);
  @override
  List<Object?> get props => [period];
}

class AnalyticsRefresh extends AnalyticsEvent {}

// States
abstract class AnalyticsState extends Equatable {
  const AnalyticsState();
  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class AnalyticsLoaded extends AnalyticsState {
  final WeeklyReport? weeklyReport;
  final MealStats? mealStats;
  final ActivityStats? activityStats;
  final List<GoalProgress> goals;
  final String period;

  const AnalyticsLoaded({
    this.weeklyReport,
    this.mealStats,
    this.activityStats,
    this.goals = const [],
    required this.period,
  });

  @override
  List<Object?> get props => [weeklyReport, mealStats, activityStats, goals, period];
}

class AnalyticsError extends AnalyticsState {
  final String message;
  const AnalyticsError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsRepository repository;

  AnalyticsBloc({AnalyticsRepository? repository})
      : repository = repository ?? AnalyticsRepositoryImpl(),
        super(AnalyticsInitial()) {
    on<AnalyticsLoadData>(_onLoadData);
    on<AnalyticsRefresh>(_onRefresh);
  }

  Future<void> _onLoadData(AnalyticsLoadData event, Emitter<AnalyticsState> emit) async {
    emit(AnalyticsLoading());
    try {
      final days = event.period == 'day' ? 1 : event.period == 'week' ? 7 : 30;
      
      final results = await Future.wait([
        repository.getWeeklyReport(weeksAgo: 0),
        repository.getMealStats(days: days),
        repository.getActivityStats(days: days),
        repository.getGoalProgress(days: days),
      ]);

      emit(AnalyticsLoaded(
        weeklyReport: results[0] as WeeklyReport,
        mealStats: results[1] as MealStats,
        activityStats: results[2] as ActivityStats,
        goals: results[3] as List<GoalProgress>,
        period: event.period,
      ));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }

  Future<void> _onRefresh(AnalyticsRefresh event, Emitter<AnalyticsState> emit) async {
    final currentState = state;
    if (currentState is AnalyticsLoaded) {
      add(AnalyticsLoadData(currentState.period));
    } else {
      add(const AnalyticsLoadData('week'));
    }
  }
}
