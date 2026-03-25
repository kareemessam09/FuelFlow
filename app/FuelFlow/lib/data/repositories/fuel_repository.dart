import 'package:dio/dio.dart';
import '../../core/constants/constants.dart';
import '../../domain/entities/entities.dart';

/// FuelRepository - Handles API calls for fuel state management
abstract class FuelRepository {
  /// Get the current fuel state from server
  Future<FuelState> getCurrentState();

  /// Sync local state with server
  Future<FuelState> syncState(FuelState localState);

  /// Update activity mode on server
  Future<void> updateActivityMode(ActivityMode mode);
}

/// Implementation of FuelRepository
class FuelRepositoryImpl implements FuelRepository {
  final Dio _dio;

  FuelRepositoryImpl({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConstants.baseApiUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {
                'Content-Type': 'application/json',
              },
            ));

  @override
  Future<FuelState> getCurrentState() async {
    try {
      final response = await _dio.get(AppConstants.fuelStateEndpoint);

      if (response.statusCode == 200) {
        return _parseFuelState(response.data);
      }

      throw Exception('Failed to get fuel state: ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<FuelState> syncState(FuelState localState) async {
    try {
      final response = await _dio.post(
        AppConstants.fuelStateEndpoint,
        data: {
          'currentVolume': localState.currentVolume,
          'currentMode': localState.currentMode.toApiString(),
          'currentGlycemicIndex': localState.currentGlycemicIndex,
          'lastUpdated': localState.lastUpdated.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        return _parseFuelState(response.data);
      }

      throw Exception('Failed to sync state: ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> updateActivityMode(ActivityMode mode) async {
    try {
      final response = await _dio.post(
        AppConstants.activityEndpoint,
        data: {
          'mode': mode.toApiString(),
          'multiplier': mode.multiplier,
          'startTime': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to update activity: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  FuelState _parseFuelState(Map<String, dynamic> json) {
    return FuelState(
      currentVolume: (json['currentVolume'] as num).toDouble(),
      currentMode: ActivityMode.fromString(json['currentMode'] as String),
      currentGlycemicIndex: (json['currentGlycemicIndex'] as num?)?.toDouble() ?? 1.0,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      lastMealTime: json['lastMealTime'] != null
          ? DateTime.parse(json['lastMealTime'] as String)
          : null,
      lastMealName: json['lastMealName'] as String?,
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
        return Exception('Server error: ${e.response?.statusCode}');
      default:
        return Exception('Network error: ${e.message}');
    }
  }
}
