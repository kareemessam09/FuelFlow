import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/user.dart';
import '../datasources/remote/api_client.dart';

abstract class UsersRepository {
  Future<User> updateUserPreferences({
    required String userId,
    required SensitivityLevel sensitivityLevel,
    required TargetGoal targetGoal,
    String? units,
    String? displayName,
    bool? notifyOnLowEnergy,
    bool? notifyMealReminders,
  });

  Future<User> updateProfile({
    required String userId,
    required String displayName,
  });

  Future<void> deleteUser({
    required String userId,
  });
}

class UsersRepositoryImpl implements UsersRepository {
  final Dio _dio;

  UsersRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  @override
  Future<User> updateUserPreferences({
    required String userId,
    required SensitivityLevel sensitivityLevel,
    required TargetGoal targetGoal,
    String? units,
    String? displayName,
    bool? notifyOnLowEnergy,
    bool? notifyMealReminders,
  }) async {
    try {
      final payload = <String, dynamic>{
        'sensitivityLevel': sensitivityLevel.displayName,
        'targetGoal': targetGoal.displayName,
      };
      if (units != null) {
        payload['units'] = units;
      }
      if (displayName != null && displayName.trim().isNotEmpty) {
        payload['name'] = displayName.trim();
      }
      if (notifyOnLowEnergy != null) {
        payload['notifyOnLowEnergy'] = notifyOnLowEnergy;
      }
      if (notifyMealReminders != null) {
        payload['notifyMealReminders'] = notifyMealReminders;
      }

      final response = await _dio.patch(
        '${AppConstants.usersEndpoint}/$userId',
        data: payload,
      );
      return _parseUser(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      if (msg is String) throw Exception(msg);
      throw Exception('Failed to update user preferences: ${e.message}');
    }
  }

  @override
  Future<User> updateProfile({
    required String userId,
    required String displayName,
  }) async {
    try {
      final response = await _dio.patch(
        '${AppConstants.usersEndpoint}/$userId',
        data: {'name': displayName.trim()},
      );
      return _parseUser(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      if (msg is String) throw Exception(msg);
      throw Exception('Failed to update profile: ${e.message}');
    }
  }

  @override
  Future<void> deleteUser({
    required String userId,
  }) async {
    try {
      await _dio.delete('${AppConstants.usersEndpoint}/$userId');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      if (msg is String) throw Exception(msg);
      throw Exception('Failed to delete account: ${e.message}');
    }
  }

  User _parseUser(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['name'] as String?,
      sensitivityLevel: json['sensitivityLevel'] != null
          ? SensitivityLevel.fromString(json['sensitivityLevel'] as String)
          : SensitivityLevel.sensitive,
      targetGoal: json['targetGoal'] != null
          ? TargetGoal.fromString(json['targetGoal'] as String)
          : TargetGoal.maintenance,
      units: (json['units'] as String?) ?? 'metric',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
