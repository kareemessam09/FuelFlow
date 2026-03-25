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
  /// This represents the baseline energy consumption per minute
  static const double baseMetabolicRate = 0.5;
  
  /// Maximum fuel volume percentage
  static const double maxFuelVolume = 100.0;
  
  /// Minimum fuel volume percentage
  static const double minFuelVolume = 0.0;
  
  /// Warning threshold percentage (Yellow zone starts)
  static const double warningThreshold = 60.0;
  
  /// Critical threshold percentage (Red zone starts)
  static const double criticalThreshold = 30.0;
  
  /// Notification trigger threshold
  static const double notificationThreshold = 30.0;

  // ============================================
  // ACTIVITY MULTIPLIERS (M_activity)
  // ============================================
  
  /// Multiplier map for different activity modes
  static const Map<String, double> activityMultipliers = {
    'resting': 1.0,
    'coding': 1.3,
    'studying': 1.6,
    'gym_strength': 3.5,
    'gym_cardio': 5.0,
  };

  // ============================================
  // TIMING CONSTANTS
  // ============================================
  
  /// Local decay update interval in milliseconds
  static const int decayUpdateIntervalMs = 1000;
  
  /// Server sync interval in milliseconds (every 30 seconds)
  static const int serverSyncIntervalMs = 30000;
  
  /// Animation duration for balloon fill changes
  static const int balloonAnimationDurationMs = 800;
  
  /// Wave animation cycle duration in milliseconds
  static const int waveAnimationCycleMs = 2000;

  // ============================================
  // UI CONSTANTS
  // ============================================
  
  /// Default border radius
  static const double defaultBorderRadius = 16.0;
  
  /// Card border radius
  static const double cardBorderRadius = 20.0;
  
  /// Button border radius
  static const double buttonBorderRadius = 12.0;
  
  /// Default padding
  static const double defaultPadding = 16.0;
  
  /// Large padding
  static const double largePadding = 24.0;
  
  /// Small padding
  static const double smallPadding = 8.0;

  // ============================================
  // BALLOON WIDGET CONSTANTS
  // ============================================
  
  /// Balloon widget default size
  static const double balloonDefaultSize = 280.0;
  
  /// Number of wave layers for liquid effect
  static const int waveLayerCount = 3;
  
  /// Wave amplitude multiplier
  static const double waveAmplitude = 8.0;
  
  /// Glow blur radius
  static const double glowBlurRadius = 20.0;
  
  /// Glow spread radius
  static const double glowSpreadRadius = 5.0;

  // ============================================
  // API ENDPOINTS (Placeholder - configure in env)
  // ============================================
  
  static const String baseApiUrl = 'http://localhost:3000/api';
  static const String mealAnalysisEndpoint = '/meal/analyze';
  static const String fuelStateEndpoint = '/fuel/state';
  static const String activityEndpoint = '/activity';
  static const String userEndpoint = '/user';
}
