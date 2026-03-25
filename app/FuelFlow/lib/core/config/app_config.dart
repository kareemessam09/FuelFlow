/// App Environment Configuration
/// 
/// Provides environment-aware configuration for API endpoints and other settings.
/// Defaults to development mode for debugging.
enum Environment {
  development,
  staging,
  production,
}

class AppConfig {
  AppConfig._();
  
  /// Current environment - defaults to development
  static Environment _environment = Environment.development;
  
  /// Get current environment
  static Environment get environment => _environment;
  
  /// Set environment (call this in main.dart before runApp)
  static void setEnvironment(Environment env) {
    _environment = env;
  }
  
  /// API Base URL based on environment
  static String get baseApiUrl {
    switch (_environment) {
      case Environment.development:
        // Use 10.0.2.2 for Android emulator (maps to host localhost)
        // Use localhost for iOS simulator
        // Use your machine's IP for physical devices
        return const String.fromEnvironment(
          'API_URL',
          defaultValue: 'http://10.0.2.2:3000/api',
        );
      case Environment.staging:
        return 'https://staging-api.fuelflow.app/api';
      case Environment.production:
        return 'https://api.fuelflow.app/api';
    }
  }
  
  /// Whether to enable debug features
  static bool get isDebug => _environment == Environment.development;
  
  /// Whether to enable analytics
  static bool get analyticsEnabled => _environment == Environment.production;
  
  /// Connection timeout in milliseconds
  static int get connectionTimeout {
    switch (_environment) {
      case Environment.development:
        return 30000; // 30 seconds for dev (slower)
      case Environment.staging:
      case Environment.production:
        return 15000; // 15 seconds for prod
    }
  }
  
  /// Server sync interval in milliseconds
  static int get serverSyncIntervalMs {
    switch (_environment) {
      case Environment.development:
        return 60000; // 1 minute for dev
      case Environment.staging:
      case Environment.production:
        return 30000; // 30 seconds for prod
    }
  }
}
