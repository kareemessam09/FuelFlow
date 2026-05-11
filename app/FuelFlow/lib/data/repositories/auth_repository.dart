import 'package:dio/dio.dart';
import '../../core/constants/constants.dart';
import '../../domain/entities/entities.dart';
import '../datasources/remote/api_client.dart';

/// Auth response from the backend
class AuthResult {
  final User user;
  final String accessToken;

  const AuthResult({required this.user, required this.accessToken});
}

/// AuthRepository — wraps /auth/* endpoints
abstract class AuthRepository {
  Future<AuthResult> register({
    required String email,
    required String password,
    String? name,
  });

  Future<AuthResult> login({required String email, required String password});

  Future<AuthResult> googleSignIn({required String idToken});

  Future<User> getMe();
  Future<void> forgotPassword({required String email});
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  });
  Future<void> updateFcmToken({required String fcmToken});
}

/// Implementation backed by the NestJS backend's /auth/* endpoints
class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;

  AuthRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  @override
  Future<AuthResult> register({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.authRegisterEndpoint,
        data: {
          'email': email,
          'password': password,
          if (name != null && name.isNotEmpty) 'name': name,
        },
      );
      return _parseAuthResult(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.authLoginEndpoint,
        data: {'email': email, 'password': password},
      );
      return _parseAuthResult(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AuthResult> googleSignIn({required String idToken}) async {
    try {
      final response = await _dio.post(
        '/auth/google',
        data: {'idToken': idToken},
      );
      return _parseAuthResult(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<User> getMe() async {
    try {
      final response = await _dio.post(AppConstants.authMeEndpoint);
      final userData = response.data['user'] as Map<String, dynamic>;
      return _parseUser(userData);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/auth/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/auth/reset-password',
        data: {'email': email, 'token': token, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> updateFcmToken({required String fcmToken}) async {
    try {
      await _dio.post(
        AppConstants.authFcmTokenEndpoint,
        data: {'fcmToken': fcmToken},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  AuthResult _parseAuthResult(Map<String, dynamic> json) {
    final userData = json['user'] as Map<String, dynamic>;
    final token = json['accessToken'] as String;
    return AuthResult(user: _parseUser(userData), accessToken: token);
  }

  User _parseUser(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'];
    final createdAt = createdAtRaw is String
        ? (DateTime.tryParse(createdAtRaw) ?? DateTime.now())
        : (createdAtRaw is DateTime ? createdAtRaw : DateTime.now());

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
      createdAt: createdAt,
      notifyOnLowEnergy: (json['notifyOnLowEnergy'] as bool?) ?? true,
      notifyMealReminders: (json['notifyMealReminders'] as bool?) ?? true,
    );
  }

  Exception _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError) {
      return Exception(
        'No internet connection. Make sure the backend is running.',
      );
    }
    if (e.response?.statusCode == 409) {
      return Exception('An account with this email already exists.');
    }
    if (e.response?.statusCode == 401) {
      return Exception('Invalid email or password.');
    }
    final message = e.response?.data?['message'];
    if (message is String) return Exception(message);
    if (message is List) return Exception(message.join('. '));
    return Exception(
      'Authentication failed (${e.response?.statusCode ?? 'no response'})',
    );
  }
}
