import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/constants.dart';
import '../../domain/entities/entities.dart';
import '../datasources/remote/api_client.dart';

/// MealRepository — wraps backend /meals/* endpoints
abstract class MealRepository {
  /// Upload a food image for Gemini AI analysis (POST /meals/snap)
  Future<MealAnalysisResult> analyzeImage(File imageFile);

  /// Log a meal manually (POST /meals/manual)
  Future<MealLog> logMeal({
    required String foodName,
    required double fullnessVolume,
    required double absorptionRate,
    required AbsorptionProfile absorptionProfile,
    required int estimatedSatietyMinutes,
    String? imageUrl,
  });

  /// Get meal history (GET /meals/my)
  Future<List<MealLog>> getMealHistory({int limit = 20});

  /// Get today's meals (GET /meals/my/today)
  Future<List<MealLog>> getTodaysMeals();
}

class MealRepositoryImpl implements MealRepository {
  final Dio _dio;

  MealRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  @override
  Future<MealAnalysisResult> analyzeImage(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        // Backend expects the file field to be named 'image'
        // No userId — JWT is in the Authorization header
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'meal_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final response = await _dio.post(
        AppConstants.mealSnapEndpoint,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      // Backend returns a full MealLog + energyState on snap
      return _parseSnapToAnalysisResult(
          response.data as Map<String, dynamic>);
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
      final payload = <String, dynamic>{
        'foodName': foodName,
        'fullnessVolume': fullnessVolume,
        'absorptionRate': absorptionRate,
        'absorptionProfile': absorptionProfile.toApiString(),
        // Backend field is estimatedSatiety (int minutes)
        'estimatedSatiety': estimatedSatietyMinutes,
      };
      if (imageUrl != null) {
        payload['imageUrl'] = imageUrl;
      }

      final response = await _dio.post(
        AppConstants.mealManualEndpoint,
        data: payload,
      );

      return _parseMealLog(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<MealLog>> getMealHistory({int limit = 20}) async {
    try {
      final response = await _dio.get(AppConstants.mealHistoryEndpoint);
      final List<dynamic> data = response.data as List<dynamic>? ?? [];
      return data
          .map((json) => _parseMealLog(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<MealLog>> getTodaysMeals() async {
    try {
      final response = await _dio.get(AppConstants.mealTodayEndpoint);
      final List<dynamic> data = response.data as List<dynamic>? ?? [];
      return data
          .map((json) => _parseMealLog(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ── Parsers ────────────────────────────────────────────────────────────────

  /// The /meals/snap endpoint returns a MealLog-shaped object + aiAnalysis + energyState
  MealAnalysisResult _parseSnapToAnalysisResult(Map<String, dynamic> json) {
    final aiAnalysis = json['aiAnalysis'] as Map<String, dynamic>?;
    return MealAnalysisResult(
      foodName: json['foodName'] as String,
      absorptionProfile: AbsorptionProfile.fromString(
        json['absorptionProfile'] as String? ?? 'Balanced',
      ),
      // Backend stores absorptionRate (1-100 GI scale); keep as-is for display
      glycemicIndex: (json['absorptionRate'] as num?)?.toDouble() ?? 50.0,
      estimatedSatietyMinutes: json['estimatedSatiety'] as int? ?? 120,
      estimatedFullnessPercentage:
          (json['fullnessVolume'] as num?)?.toDouble() ?? 30.0,
      nutritionSummary: aiAnalysis?['notes'] as String?,
      detectedIngredients: null, // Backend doesn't return ingredient list
    );
  }

  MealLog _parseMealLog(Map<String, dynamic> json) {
    return MealLog(
      // Backend MealLog id is an int; convert to String for the app entity
      id: json['id']?.toString() ?? '',
      userId: json['userId'] as String? ?? '',
      foodName: json['foodName'] as String,
      fullnessVolume: (json['fullnessVolume'] as num).toDouble(),
      // Backend field: absorptionRate (NOT glycemicIndex)
      absorptionRate: (json['absorptionRate'] as num).toDouble(),
      absorptionProfile: AbsorptionProfile.fromString(
        json['absorptionProfile'] as String? ?? 'Balanced',
      ),
      // Backend field: estimatedSatiety (NOT estimatedSatietyMinutes)
      estimatedSatietyMinutes: json['estimatedSatiety'] as int? ?? 120,
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Check your internet.');
      case DioExceptionType.connectionError:
        return Exception('No internet connection.');
      case DioExceptionType.badResponse:
        final msg = e.response?.data?['message'];
        if (msg is String) return Exception(msg);
        return Exception('Server error: ${e.response?.statusCode}');
      default:
        return Exception('Network error: ${e.message}');
    }
  }
}
