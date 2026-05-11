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
        // Preferred: pass full URL via --dart-define=API_URL=http://<host>:3000/api
        const apiUrl = String.fromEnvironment('API_URL');
        if (apiUrl.isNotEmpty) {
          return _normalizeApiUrl(apiUrl);
        }

        // Fallback pieces for local development:
        // --dart-define=API_HOST=192.168.x.x (physical phone on same Wi-Fi)
        // --dart-define=API_PORT=3000
        // --dart-define=API_SCHEME=http
        const apiScheme = String.fromEnvironment('API_SCHEME', defaultValue: 'http');
        const apiHost = String.fromEnvironment('API_HOST', defaultValue: '10.0.2.2');
        const apiPort = int.fromEnvironment('API_PORT', defaultValue: 3000);
        final normalizedHost = _normalizeApiHost(apiHost);
        return Uri(
          scheme: apiScheme,
          host: normalizedHost,
          port: apiPort,
          path: '/api',
        ).toString();
      case Environment.staging:
        return 'https://staging-api.fuelflow.app/api';
      case Environment.production:
        return 'https://api.fuelflow.app/api';
    }
  }

  static String _normalizeApiUrl(String rawValue) {
    var value = rawValue.trim();
    if (value.isEmpty) return 'http://10.0.2.2:3000/api';

    // Handle common typo: missing scheme (e.g. 192.168.1.5:3000/api).
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'http://$value';
    }

    final parsed = Uri.tryParse(value);
    if (parsed == null || parsed.host.isEmpty) return value;

    var path = parsed.path;
    if (path.isEmpty || path == '/') {
      path = '/api';
    } else if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    return parsed
        .replace(
          path: path,
          query: null,
          fragment: null,
        )
        .toString();
  }

  static String _normalizeApiHost(String rawHost) {
    var host = rawHost.trim();
    if (host.isEmpty) return '10.0.2.2';

    final withScheme = host.startsWith('http://') || host.startsWith('https://')
        ? host
        : 'http://$host';
    final parsed = Uri.tryParse(withScheme);
    if (parsed != null && parsed.host.isNotEmpty) {
      return parsed.host;
    }

    // Fallback sanitization for malformed host values.
    host = host.replaceAll(RegExp(r'^https?://'), '');
    if (host.contains('/')) {
      host = host.split('/').first;
    }
    if (host.contains(':')) {
      host = host.split(':').first;
    }
    return host.isEmpty ? '10.0.2.2' : host;
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
