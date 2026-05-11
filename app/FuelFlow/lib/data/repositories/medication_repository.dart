import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../datasources/remote/api_client.dart';
import '../models/medication_models.dart';

abstract class MedicationRepository {
  Future<List<Medication>> getMedications();
  Future<Medication> getMedication(String id);
  Future<Medication> createMedication(Medication medication);
  Future<Medication> updateMedication(String id, Medication medication);
  Future<void> deleteMedication(String id);

  Future<MedicationLog> logMedication(MedicationLog log);
  Future<List<MedicationLog>> getTodayLogs();
  Future<List<MedicationLog>> getHistoryLogs({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<BeforeMealCheckResult> checkBeforeMeal({required String mealType});
  Future<List<Medication>> getAfterMeal({required String mealType});

  Future<List<MedicationSchedule>> getSchedules();
  Future<MedicationSchedule> createSchedule(MedicationSchedule schedule);
  Future<MedicationSchedule> updateSchedule(
    String id,
    MedicationSchedule schedule,
  );
  Future<void> deleteSchedule(String id);
}

class MedicationRepositoryImpl implements MedicationRepository {
  final Dio _dio;

  MedicationRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  @override
  Future<List<Medication>> getMedications() async {
    try {
      final response = await _dio.get(AppConstants.medicationsEndpoint);
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((e) => Medication.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Medication> getMedication(String id) async {
    try {
      final response = await _dio.get('${AppConstants.medicationsEndpoint}/$id');
      return Medication.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Medication> createMedication(Medication medication) async {
    try {
      final response = await _dio.post(
        AppConstants.medicationsEndpoint,
        data: medication.toCreateJson(),
      );
      return Medication.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Medication> updateMedication(String id, Medication medication) async {
    try {
      final response = await _dio.patch(
        '${AppConstants.medicationsEndpoint}/$id',
        data: medication.toUpdateJson(),
      );
      return Medication.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> deleteMedication(String id) async {
    try {
      await _dio.delete('${AppConstants.medicationsEndpoint}/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<MedicationLog> logMedication(MedicationLog log) async {
    try {
      final response = await _dio.post(
        AppConstants.medicationLogsEndpoint,
        data: log.toCreateJson(),
      );
      return MedicationLog.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<MedicationLog>> getTodayLogs() async {
    try {
      final response = await _dio.get(AppConstants.medicationTodayLogsEndpoint);
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((e) => MedicationLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<MedicationLog>> getHistoryLogs({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (startDate != null) query['startDate'] = startDate.toIso8601String();
      if (endDate != null) query['endDate'] = endDate.toIso8601String();

      final response = await _dio.get(
        AppConstants.medicationHistoryLogsEndpoint,
        queryParameters: query.isEmpty ? null : query,
      );
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((e) => MedicationLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<BeforeMealCheckResult> checkBeforeMeal({required String mealType}) async {
    try {
      final response = await _dio.get(
        AppConstants.medicationCheckBeforeMealEndpoint,
        queryParameters: {'mealType': mealType},
      );
      return BeforeMealCheckResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<Medication>> getAfterMeal({required String mealType}) async {
    try {
      final response = await _dio.get(
        AppConstants.medicationAfterMealEndpoint,
        queryParameters: {'mealType': mealType},
      );
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((e) => Medication.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<MedicationSchedule>> getSchedules() async {
    try {
      final response = await _dio.get(AppConstants.medicationSchedulesEndpoint);
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((e) => MedicationSchedule.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<MedicationSchedule> createSchedule(MedicationSchedule schedule) async {
    try {
      final response = await _dio.post(
        AppConstants.medicationSchedulesEndpoint,
        data: schedule.toCreateJson(),
      );
      return MedicationSchedule.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<MedicationSchedule> updateSchedule(
    String id,
    MedicationSchedule schedule,
  ) async {
    try {
      final response = await _dio.patch(
        '${AppConstants.medicationSchedulesEndpoint}/$id',
        data: schedule.toCreateJson(),
      );
      return MedicationSchedule.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> deleteSchedule(String id) async {
    try {
      await _dio.delete('${AppConstants.medicationSchedulesEndpoint}/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(Object error) {
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final message = responseData['message'];
        if (message is String) return Exception(message);
        if (message is List && message.isNotEmpty) {
          return Exception(message.first.toString());
        }
      }
      return Exception(error.message ?? 'Network error occurred');
    }
    return Exception(error.toString());
  }
}

