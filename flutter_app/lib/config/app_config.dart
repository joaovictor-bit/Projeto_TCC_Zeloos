import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    return kIsWeb || defaultTargetPlatform != TargetPlatform.android
        ? 'http://localhost:3005'
        : 'http://10.0.2.2:3005';
  }

  static const String appVersion = '1.0.0';
  static const Duration requestTimeout = Duration(seconds: 15);
  static const String authTokenKey = 'auth_token';
}
