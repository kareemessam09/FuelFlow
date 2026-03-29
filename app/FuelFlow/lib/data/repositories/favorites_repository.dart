import 'package:dio/dio.dart';
import '../datasources/remote/api_client.dart';
import '../models/models.dart';
import '../../domain/entities/meal.dart';

abstract class FavoritesRepository {
  // Favorite Meals
  Future<List<FavoriteMeal>> getFavorites();
  Future<FavoriteMeal> createFavorite(FavoriteMeal favorite);
  Future<void> deleteFavorite(String id);
  Future<MealLog> logFavoriteMeal(String id);
  
  // Templates
  Future<List<MealTemplate>> getTemplates();
  Future<MealTemplate> createTemplate(MealTemplate template);
  Future<void> deleteTemplate(String id);
  Future<MealLog> logTemplate(String id);
  
  // Custom Foods
  Future<List<CustomFood>> getCustomFoods();
  Future<CustomFood> createCustomFood(CustomFood food);
  Future<void> deleteCustomFood(String id);
  Future<MealLog> logCustomFood(String id, {double servings = 1.0});
  
  // Recent Foods
  Future<List<MealLog>> getRecentFoods({int limit = 10});
}

class FavoritesRepositoryImpl implements FavoritesRepository {
  final Dio _dio = ApiClient.instance;

  // Favorite Meals
  @override
  Future<List<FavoriteMeal>> getFavorites() async {
    try {
      final response = await _dio.get('/favorites/meals');
      final list = response.data as List;
      return list.map((json) => FavoriteMeal.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<FavoriteMeal> createFavorite(FavoriteMeal favorite) async {
    try {
      final response = await _dio.post('/favorites/meals', data: favorite.toJson());
      return FavoriteMeal.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> deleteFavorite(String id) async {
    try {
      await _dio.delete('/favorites/meals/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<MealLog> logFavoriteMeal(String id) async {
    try {
      final response = await _dio.post('/favorites/meals/$id/log');
      return _mealLogFromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Templates
  @override
  Future<List<MealTemplate>> getTemplates() async {
    try {
      final response = await _dio.get('/favorites/templates');
      final list = response.data as List;
      return list.map((json) => MealTemplate.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<MealTemplate> createTemplate(MealTemplate template) async {
    try {
      final response = await _dio.post('/favorites/templates', data: template.toJson());
      return MealTemplate.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> deleteTemplate(String id) async {
    try {
      await _dio.delete('/favorites/templates/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<MealLog> logTemplate(String id) async {
    try {
      final response = await _dio.post('/favorites/templates/$id/log');
      return _mealLogFromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Custom Foods
  @override
  Future<List<CustomFood>> getCustomFoods() async {
    try {
      final response = await _dio.get('/favorites/foods');
      final list = response.data as List;
      return list.map((json) => CustomFood.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<CustomFood> createCustomFood(CustomFood food) async {
    try {
      final response = await _dio.post('/favorites/foods', data: food.toJson());
      return CustomFood.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> deleteCustomFood(String id) async {
    try {
      await _dio.delete('/favorites/foods/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<MealLog> logCustomFood(String id, {double servings = 1.0}) async {
    try {
      final response = await _dio.post(
        '/favorites/foods/$id/log',
        queryParameters: {'servings': servings},
      );
      return _mealLogFromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Recent Foods
  @override
  Future<List<MealLog>> getRecentFoods({int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/favorites/recent',
        queryParameters: {'limit': limit},
      );
      final list = response.data as List;
      return list.map((json) => _mealLogFromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  MealLog _mealLogFromJson(Map<String, dynamic> json) {
    return MealLog(
      id: json['id'].toString(),
      userId: json['userId'] as String,
      foodName: json['foodName'] as String,
      fullnessVolume: (json['fullnessVolume'] as num).toDouble(),
      absorptionRate: (json['absorptionRate'] as num).toDouble(),
      absorptionProfile: AbsorptionProfile.fromString(json['absorptionProfile'] as String),
      estimatedSatietyMinutes: json['estimatedSatiety'] as int,
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      final message = error.response?.data?['message'] as String? ??
          error.message ??
          'Network error occurred';
      return Exception(message);
    }
    return Exception(error.toString());
  }
}
