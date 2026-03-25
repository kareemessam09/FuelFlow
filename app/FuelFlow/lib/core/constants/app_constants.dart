import '../config/app_config.dart';

/// App-wide constants for FuelFlow
class AppConstants {
  AppConstants._();

  // ============================================
  // APP INFO
  // ============================================
  static const String appName = 'FuelFlow';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Proactive Energy Manager';

  // ============================================
  // FUEL/DECAY ALGORITHM CONSTANTS
  // ============================================

  /// Base metabolic rate constant (R_base in the formula)
  /// V_remaining = V_start - (R_base * G_index * M_activity * Δt)
  static const double baseMetabolicRate = 0.5;

  /// Maximum fuel volume percentage
  static const double maxFuelVolume = 100.0;

  /// Minimum fuel volume percentage
  static const double minFuelVolume = 0.0;

  /// Warning threshold percentage (Yellow zone starts, > 60% is Optimal)
  static const double warningThreshold = 60.0;

  /// Critical threshold percentage (Red zone starts, 30-60% is Warning)
  static const double criticalThreshold = 30.0;

  /// Notification trigger threshold
  static const double notificationThreshold = 30.0;

  // ============================================
  // ACTIVITY MULTIPLIERS (M_activity)
  // PascalCase values match the backend ActivityMode enum
  // ============================================

  /// Multiplier map for different activity modes (keyed by backend API string)
  static const Map<String, double> activityMultipliers = {
    'Resting': 1.0,
    'Coding': 1.3,
    'Studying': 1.6,
    'GymStrength': 3.5,
    'GymCardio': 5.0,
  };

  // ============================================
  // TIMING CONSTANTS
  // ============================================

  /// Local decay update interval in milliseconds
  static const int decayUpdateIntervalMs = 1000;

  /// Server sync interval in milliseconds (environment-aware)
  static int get serverSyncIntervalMs => AppConfig.serverSyncIntervalMs;

  /// Animation duration for balloon fill changes
  static const int balloonAnimationDurationMs = 800;

  /// Wave animation cycle duration in milliseconds
  static const int waveAnimationCycleMs = 2000;

  // ============================================
  // UI CONSTANTS
  // ============================================

  static const double defaultBorderRadius = 16.0;
  static const double cardBorderRadius = 20.0;
  static const double buttonBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double largePadding = 24.0;
  static const double smallPadding = 8.0;

  // ============================================
  // BALLOON WIDGET CONSTANTS
  // ============================================

  static const double balloonDefaultSize = 280.0;
  static const int waveLayerCount = 3;
  static const double waveAmplitude = 8.0;
  static const double glowBlurRadius = 20.0;
  static const double glowSpreadRadius = 5.0;

  // ============================================
  // API ENDPOINTS — must match NestJS backend routes
  // ============================================

  /// Base API URL (environment-aware via AppConfig)
  static String get baseApiUrl => AppConfig.baseApiUrl;

  // Auth
  static const String authRegisterEndpoint = '/auth/register';
  static const String authLoginEndpoint = '/auth/login';
  static const String authMeEndpoint = '/auth/me';
  static const String authFcmTokenEndpoint = '/auth/fcm-token';

  // Meals
  static const String mealSnapEndpoint = '/meals/snap';
  static const String mealManualEndpoint = '/meals/manual';
  static const String mealHistoryEndpoint = '/meals/my';
  static const String mealTodayEndpoint = '/meals/my/today';

  // Activity
  static const String activityToggleEndpoint = '/activity/toggle';
  static const String activityStatusEndpoint = '/activity/status';
  static const String activityEndEndpoint = '/activity/end';

  // Energy
  static const String energyStatusEndpoint = '/energy/status';
  static const String energyConstantsEndpoint = '/energy/constants';

  // Users
  static const String usersEndpoint = '/users';
}
