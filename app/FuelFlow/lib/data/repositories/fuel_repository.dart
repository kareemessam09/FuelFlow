import 'package:dio/dio.dart';
import '../../core/constants/constants.dart';
import '../../domain/entities/entities.dart';
import '../datasources/remote/api_client.dart';

/// FuelRepository — wraps backend energy and activity endpoints
abstract class FuelRepository {
  /// Get the current energy state from the backend (GET /energy/status)
  Future<FuelState> getCurrentState();

  /// Toggle the user's activity mode on the backend (POST /activity/toggle)
  /// Returns the server-calculated alert time (when energy will hit critical threshold)
  Future<DateTime?> updateActivityMode(ActivityMode mode);
}

class FuelRepositoryImpl implements FuelRepository {
  final Dio _dio;

  FuelRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  @override
  Future<FuelState> getCurrentState() async {
    try {
      final response = await _dio.get(AppConstants.energyStatusEndpoint);
      return _parseEnergyResponse(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<DateTime?> updateActivityMode(ActivityMode mode) async {
    try {
      final response = await _dio.post(
        AppConstants.activityToggleEndpoint,
        data: {
          // Backend ToggleActivityDto only takes modeType (userId comes from JWT)
          'modeType': mode.toApiString(),
        },
      );
      
      // Parse alertTime from response if present
      final data = response.data as Map<String, dynamic>?;
      if (data != null && data['alertTime'] != null) {
        return DateTime.tryParse(data['alertTime'] as String);
      }
      return null;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Parses the GET /energy/status response into a [FuelState]
  FuelState _parseEnergyResponse(Map<String, dynamic> json) {
    final energyState = json['energyState'] as Map<String, dynamic>;
    final currentActivityJson = json['currentActivity'] as Map<String, dynamic>?;

    final volumeRemaining =
        (energyState['volumeRemaining'] as num?)?.toDouble() ?? 0.0;
    final modeTypeStr =
        currentActivityJson?['modeType'] as String? ?? 'Resting';
    final effectiveGI =
        (json['effectiveGlycemicIndex'] as num?)?.toDouble() ?? 50.0;

    return FuelState(
      currentVolume: volumeRemaining,
      currentMode: ActivityMode.fromApiString(modeTypeStr),
      // Normalize GI from 1-100 backend scale to 0.01-1.0 local coefficient
      currentGlycemicIndex: (effectiveGI / 100).clamp(0.01, 1.0),
      lastUpdated: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
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
        return Exception('Server error: ${e.response?.statusCode}');
      default:
        return Exception('Network error: ${e.message}');
    }
  }
}
