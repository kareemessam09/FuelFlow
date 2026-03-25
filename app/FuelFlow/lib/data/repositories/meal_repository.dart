import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/constants.dart';
import '../../domain/entities/entities.dart';

/// MealRepository - Handles API calls for meal logging and AI analysis
abstract class MealRepository {
  /// Upload an image for AI analysis
  Future<MealAnalysisResult> analyzeImage(File imageFile);

  /// Log a confirmed meal
  Future<MealLog> logMeal({
    required String foodName,
    required double fullnessVolume,
    required double absorptionRate,
    required AbsorptionProfile absorptionProfile,
    required int estimatedSatietyMinutes,
    String? imageUrl,
  });

  /// Get meal history
  Future<List<MealLog>> getMealHistory({int limit = 20});
}

/// Implementation of MealRepository
class MealRepositoryImpl implements MealRepository {
  final Dio _dio;

  MealRepositoryImpl({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConstants.baseApiUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              headers: {
                'Content-Type': 'application/json',
              },
            ));

  @override
  Future<MealAnalysisResult> analyzeImage(File imageFile) async {
    try {
      // Create multipart form data
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'meal_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final response = await _dio.post(
        AppConstants.mealAnalysisEndpoint,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200) {
        return _parseAnalysisResult(response.data);
      }

      throw Exception('Failed to analyze image: ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<MealLog> logMeal({
    required String foodName,
    required double fullnessVolume,
    required double absorptionRate,
    required AbsorptionProfile absorptionProfile,
    required int estimatedSatietyMinutes,
    String? imageUrl,
  }) async {
    try {
      final response = await _dio.post(
        '/meal/log',
        data: {
          'foodName': foodName,
          'fullnessVolume': fullnessVolume,
          'absorptionRate': absorptionRate,
          'absorptionProfile': absorptionProfile.name,
          'estimatedSatietyMinutes': estimatedSatietyMinutes,
          'imageUrl': imageUrl,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _parseMealLog(response.data);
      }

      throw Exception('Failed to log meal: ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<MealLog>> getMealHistory({int limit = 20}) async {
    try {
      final response = await _dio.get(
        '/meal/history',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['meals'] ?? [];
        return data.map((json) => _parseMealLog(json)).toList();
      }

      throw Exception('Failed to get meal history: ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  MealAnalysisResult _parseAnalysisResult(Map<String, dynamic> json) {
    return MealAnalysisResult(
      foodName: json['foodName'] as String,
      absorptionProfile: AbsorptionProfile.fromString(
        json['absorptionProfile'] as String,
      ),
      glycemicIndex: (json['glycemicIndex'] as num).toDouble(),
      estimatedSatietyMinutes: json['estimatedSatietyMinutes'] as int,
      estimatedFullnessPercentage:
          (json['estimatedFullnessPercentage'] as num).toDouble(),
      nutritionSummary: json['nutritionSummary'] as String?,
      detectedIngredients: (json['detectedIngredients'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  MealLog _parseMealLog(Map<String, dynamic> json) {
    return MealLog(
      id: json['id'] as String,
      userId: json['userId'] as String,
      foodName: json['foodName'] as String,
      fullnessVolume: (json['fullnessVolume'] as num).toDouble(),
      absorptionRate: (json['absorptionRate'] as num).toDouble(),
      absorptionProfile: AbsorptionProfile.fromString(
        json['absorptionProfile'] as String,
      ),
      estimatedSatietyMinutes: json['estimatedSatietyMinutes'] as int,
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet.');
      case DioExceptionType.connectionError:
        return Exception('No internet connection.');
      case DioExceptionType.badResponse:
        final message = e.response?.data?['message'] ?? 'Server error';
        return Exception('$message (${e.response?.statusCode})');
      default:
        return Exception('Network error: ${e.message}');
    }
  }
}
