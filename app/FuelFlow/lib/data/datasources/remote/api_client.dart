import 'package:dio/dio.dart';
import '../../../core/constants/constants.dart';
import '../../../services/auth_service.dart';

/// Shared Dio singleton with automatic JWT injection.
/// All repositories use [ApiClient.instance] instead of creating their own Dio.
class ApiClient {
  ApiClient._();

  static Dio? _dio;

  static Dio get instance {
    _dio ??= _createDio();
    return _dio!;
  }

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseApiUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    // Auth interceptor — injects Bearer token on every request
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = AuthService().getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // Token expired — clear auth and let the app handle redirect
            AuthService().clearAll();
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  /// Rebuild the client (e.g. after logout or token change)
  static void reset() => _dio = null;
}
