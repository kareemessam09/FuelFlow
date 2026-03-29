import 'package:dio/dio.dart';
import '../datasources/remote/api_client.dart';

class ActivityGoal {
  final int id;
  final String activityType;
  final int targetMinutes;
  final String period;

  const ActivityGoal({
    required this.id,
    required this.activityType,
    required this.targetMinutes,
    required this.period,
  });

  factory ActivityGoal.fromJson(Map<String, dynamic> json) {
    return ActivityGoal(
      id: (json['id'] as num).toInt(),
      activityType: json['activityType'] as String,
      targetMinutes: (json['targetMinutes'] as num).toInt(),
      period: json['period'] as String,
    );
  }
}

abstract class GoalsRepository {
  Future<List<ActivityGoal>> getGoals();
  Future<ActivityGoal> createGoal({
    required String activityType,
    required int targetMinutes,
    required String period,
  });
  Future<ActivityGoal> updateGoal({
    required int id,
    String? activityType,
    int? targetMinutes,
    String? period,
  });
  Future<void> deleteGoal({required int id});
}

class GoalsRepositoryImpl implements GoalsRepository {
  final Dio _dio;

  GoalsRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  @override
  Future<List<ActivityGoal>> getGoals() async {
    try {
      final response = await _dio.get('/custom-activities/goals');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => ActivityGoal.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      if (msg is String) throw Exception(msg);
      throw Exception('Failed to load goals: ${e.message}');
    }
  }

  @override
  Future<ActivityGoal> createGoal({
    required String activityType,
    required int targetMinutes,
    required String period,
  }) async {
    try {
      final response = await _dio.post(
        '/custom-activities/goals',
        data: {
          'activityType': activityType,
          'targetMinutes': targetMinutes,
          'period': period,
        },
      );
      return ActivityGoal.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      if (msg is String) throw Exception(msg);
      throw Exception('Failed to create goal: ${e.message}');
    }
  }

  @override
  Future<ActivityGoal> updateGoal({
    required int id,
    String? activityType,
    int? targetMinutes,
    String? period,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (activityType != null) {
        payload['activityType'] = activityType;
      }
      if (targetMinutes != null) {
        payload['targetMinutes'] = targetMinutes;
      }
      if (period != null) {
        payload['period'] = period;
      }

      final response = await _dio.patch(
        '/custom-activities/goals/$id',
        data: payload,
      );
      return ActivityGoal.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      if (msg is String) throw Exception(msg);
      throw Exception('Failed to update goal: ${e.message}');
    }
  }

  @override
  Future<void> deleteGoal({required int id}) async {
    try {
      await _dio.delete('/custom-activities/goals/$id');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      if (msg is String) throw Exception(msg);
      throw Exception('Failed to delete goal: ${e.message}');
    }
  }
}
