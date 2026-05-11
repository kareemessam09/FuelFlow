import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/models/models.dart';

// Events
abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();
  @override
  List<Object?> get props => [];
}

class FavoritesLoadMeals extends FavoritesEvent {}

class FavoritesLoadTemplates extends FavoritesEvent {}

class FavoritesLoadFoods extends FavoritesEvent {}

class FavoritesDeleteMeal extends FavoritesEvent {
  final int id;
  const FavoritesDeleteMeal(this.id);
  @override
  List<Object?> get props => [id];
}

// States
abstract class FavoritesState extends Equatable {
  const FavoritesState();
  @override
  List<Object?> get props => [];
}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {}

class FavoritesLoaded extends FavoritesState {
  final List<FavoriteMeal> meals;
  final List<MealTemplate> templates;
  final List<CustomFood> foods;

  const FavoritesLoaded({
    this.meals = const [],
    this.templates = const [],
    this.foods = const [],
  });

  @override
  List<Object?> get props => [meals, templates, foods];
}

class FavoritesError extends FavoritesState {
  final String message;
  const FavoritesError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final FavoritesRepository repository;

  FavoritesBloc({FavoritesRepository? repository})
      : repository = repository ?? FavoritesRepositoryImpl(),
        super(FavoritesInitial()) {
    on<FavoritesLoadMeals>(_onLoadMeals);
    on<FavoritesLoadTemplates>(_onLoadTemplates);
    on<FavoritesLoadFoods>(_onLoadFoods);
    on<FavoritesDeleteMeal>(_onDeleteMeal);
  }

  Future<void> _onLoadMeals(FavoritesLoadMeals event, Emitter<FavoritesState> emit) async {
    emit(FavoritesLoading());
    try {
      final meals = await repository.getFavorites();
      emit(FavoritesLoaded(meals: meals));
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      debugPrint('[FavoritesBloc] Failed to load favorite meals: $error');
      emit(FavoritesError(error.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLoadTemplates(FavoritesLoadTemplates event, Emitter<FavoritesState> emit) async {
    emit(FavoritesLoading());
    try {
      final templates = await repository.getTemplates();
      emit(FavoritesLoaded(templates: templates));
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      debugPrint('[FavoritesBloc] Failed to load templates: $error');
      emit(FavoritesError(error.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLoadFoods(FavoritesLoadFoods event, Emitter<FavoritesState> emit) async {
    emit(FavoritesLoading());
    try {
      final foods = await repository.getCustomFoods();
      emit(FavoritesLoaded(foods: foods));
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      debugPrint('[FavoritesBloc] Failed to load custom foods: $error');
      emit(FavoritesError(error.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onDeleteMeal(FavoritesDeleteMeal event, Emitter<FavoritesState> emit) async {
    try {
      await repository.deleteFavorite(event.id.toString());
      add(FavoritesLoadMeals()); // Reload
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      debugPrint('[FavoritesBloc] Failed to delete favorite meal: $error');
      emit(FavoritesError(error.toString().replaceFirst('Exception: ', '')));
    }
  }
}
