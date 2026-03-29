import 'package:shared_preferences/shared_preferences.dart';

/// AuthService — persists JWT token and basic user info via SharedPreferences.
/// All repositories use this to attach the Authorization header.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const _keyToken = 'auth_token';
  static const _keyUserId = 'user_id';
  static const _keyUserEmail = 'user_email';
  static const _keyUserName = 'user_name';
  static const _keyOnboardingCompleted = 'onboarding_completed';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ── Token ──────────────────────────────────────────────
  Future<void> saveToken(String token) async {
    await _ensureInit();
    await _prefs!.setString(_keyToken, token);
  }

  String? getToken() => _prefs?.getString(_keyToken);

  bool get isAuthenticated {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }

  bool get isOnboardingCompleted =>
      _prefs?.getBool(_keyOnboardingCompleted) ?? false;

  Future<void> markOnboardingCompleted() async {
    await _ensureInit();
    await _prefs!.setBool(_keyOnboardingCompleted, true);
  }

  // ── User data ──────────────────────────────────────────
  Future<void> saveUserData({
    required String userId,
    required String email,
    String? name,
  }) async {
    await _ensureInit();
    await _prefs!.setString(_keyUserId, userId);
    await _prefs!.setString(_keyUserEmail, email);
    if (name != null) await _prefs!.setString(_keyUserName, name);
  }

  String? getUserId() => _prefs?.getString(_keyUserId);
  String? getUserEmail() => _prefs?.getString(_keyUserEmail);
  String? getUserName() => _prefs?.getString(_keyUserName);

  // ── Logout ─────────────────────────────────────────────
  Future<void> clearAll() async {
    await _ensureInit();
    await _prefs!.remove(_keyToken);
    await _prefs!.remove(_keyUserId);
    await _prefs!.remove(_keyUserEmail);
    await _prefs!.remove(_keyUserName);
  }

  Future<void> _ensureInit() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
}
