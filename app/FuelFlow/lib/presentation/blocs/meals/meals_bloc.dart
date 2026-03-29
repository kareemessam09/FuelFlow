import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/repositories.dart';
import '../../../domain/entities/entities.dart';

// Events
abstract class MealsEvent extends Equatable {
  const MealsEvent();
  @override
  List<Object?> get props => [];
}

class MealsLoadHistory extends MealsEvent {}

class MealsLoadToday extends MealsEvent {}

class MealsRefresh extends MealsEvent {}

// States
abstract class MealsState extends Equatable {
  const MealsState();
  @override
  List<Object?> get props => [];
}

class MealsInitial extends MealsState {}

class MealsLoading extends MealsState {}

class MealsLoaded extends MealsState {
  final List<MealLog> meals;
  final bool isTodayOnly;

  const MealsLoaded({
    required this.meals,
    this.isTodayOnly = false,
  });

  @override
  List<Object?> get props => [meals, isTodayOnly];
}

class MealsError extends MealsState {
  final String message;
  const MealsError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class MealsBloc extends Bloc<MealsEvent, MealsState> {
  final MealRepository repository;

  MealsBloc({MealRepository? repository})
      : repository = repository ?? MealRepositoryImpl(),
        super(MealsInitial()) {
    on<MealsLoadHistory>(_onLoadHistory);
    on<MealsLoadToday>(_onLoadToday);
    on<MealsRefresh>(_onRefresh);
  }

  Future<void> _onLoadHistory(MealsLoadHistory event, Emitter<MealsState> emit) async {
    emit(MealsLoading());
    try {
      final meals = await repository.getMealHistory(limit: 50);
      emit(MealsLoaded(meals: meals, isTodayOnly: false));
    } catch (e) {
      emit(MealsError(e.toString()));
    }
  }

  Future<void> _onLoadToday(MealsLoadToday event, Emitter<MealsState> emit) async {
    emit(MealsLoading());
    try {
      final meals = await repository.getTodaysMeals();
      emit(MealsLoaded(meals: meals, isTodayOnly: true));
    } catch (e) {
      emit(MealsError(e.toString()));
    }
  }

  Future<void> _onRefresh(MealsRefresh event, Emitter<MealsState> emit) async {
    final currentState = state;
    if (currentState is MealsLoaded) {
      if (currentState.isTodayOnly) {
        add(MealsLoadToday());
      } else {
        add(MealsLoadHistory());
      }
    } else {
      add(MealsLoadToday());
    }
  }
}
