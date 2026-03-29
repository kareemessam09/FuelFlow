import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../services/services.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// AuthBloc — manages login, registration, and session persistence
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final AuthService _authService;
  final FirebaseMessaging _firebaseMessaging;

  AuthBloc({
    required AuthRepository authRepository,
    AuthService? authService,
    FirebaseMessaging? firebaseMessaging,
  })  : _authRepository = authRepository,
        _authService = authService ?? AuthService(),
        _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance,
        super(AuthState.initial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthLogin>(_onLogin);
    on<AuthRegister>(_onRegister);
    on<AuthLogout>(_onLogout);
  }

  /// On app start — check if a token is persisted
  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    await _authService.init();
    if (_authService.isAuthenticated) {
      try {
        // Validate the token is still good
        final user = await _authRepository.getMe();
        emit(AuthState.authenticated(user));
      } catch (_) {
        // Token invalid / expired
        await _authService.clearAll();
        emit(AuthState.unauthenticated());
      }
    } else {
      emit(AuthState.unauthenticated());
    }
  }

  Future<void> _onLogin(
    AuthLogin event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());
    try {
      final result = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      await _authService.saveToken(result.accessToken);
      await _authService.saveUserData(
        userId: result.user.id,
        email: result.user.email ?? event.email,
        name: result.user.displayName,
      );
      await _syncFcmToken();
      emit(AuthState.authenticated(result.user));
    } catch (e) {
      emit(AuthState.error(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onRegister(
    AuthRegister event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());
    try {
      final result = await _authRepository.register(
        email: event.email,
        password: event.password,
        name: event.name,
      );
      await _authService.saveToken(result.accessToken);
      await _authService.saveUserData(
        userId: result.user.id,
        email: result.user.email ?? event.email,
        name: result.user.displayName,
      );
      await _syncFcmToken();
      emit(AuthState.authenticated(result.user));
    } catch (e) {
      emit(AuthState.error(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLogout(
    AuthLogout event,
    Emitter<AuthState> emit,
  ) async {
    await _authService.clearAll();
    emit(AuthState.unauthenticated());
  }

  Future<void> _syncFcmToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token == null || token.isEmpty) return;
      await _authRepository.updateFcmToken(fcmToken: token);
    } on Exception catch (e) {
      debugPrint('FCM token sync failed: $e');
    }
  }
}
