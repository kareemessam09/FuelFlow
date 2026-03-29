import 'package:dio/dio.dart';
import '../datasources/remote/api_client.dart';
import '../models/models.dart';

abstract class AnalyticsRepository {
  Future<WeeklyReport> getWeeklyReport({int weeksAgo = 0});
  Future<WeeklyReport> getMonthlyReport({int monthsAgo = 0});
  Future<MealStats> getMealStats({int days = 7});
  Future<ActivityStats> getActivityStats({int days = 7});
  Future<List<GoalProgress>> getGoalProgress({int days = 7});
  Future<Map<String, dynamic>> exportData();
}

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final Dio _dio = ApiClient.instance;

  @override
  Future<WeeklyReport> getWeeklyReport({int weeksAgo = 0}) async {
    try {
      final response = await _dio.get(
        '/analytics/weekly',
        queryParameters: {'weeksAgo': weeksAgo},
      );
      return WeeklyReport.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<WeeklyReport> getMonthlyReport({int monthsAgo = 0}) async {
    try {
      final response = await _dio.get(
        '/analytics/monthly',
        queryParameters: {'monthsAgo': monthsAgo},
      );
      return WeeklyReport.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<MealStats> getMealStats({int days = 7}) async {
    try {
      final response = await _dio.get(
        '/analytics/meals',
        queryParameters: {'days': days},
      );
      return MealStats.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ActivityStats> getActivityStats({int days = 7}) async {
    try {
      final response = await _dio.get(
        '/analytics/activities',
        queryParameters: {'days': days},
      );
      return ActivityStats.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<GoalProgress>> getGoalProgress({int days = 7}) async {
    try {
      final response = await _dio.get(
        '/analytics/goal-progress',
        queryParameters: {'days': days},
      );
      final list = response.data as List;
      return list.map((json) => GoalProgress.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> exportData() async {
    try {
      final response = await _dio.get('/analytics/export/json');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
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
