import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String webBaseUrl = String.fromEnvironment(
    'API_BASE_URL_WEB',
    defaultValue: 'http://localhost:8080/smart-faculty/backend/public',
  );

  static const String desktopBaseUrl = String.fromEnvironment(
    'API_BASE_URL_DESKTOP',
    defaultValue: 'http://localhost:8080/smart-faculty/backend/public',
  );

  static const String androidEmulatorBaseUrl = String.fromEnvironment(
    'API_BASE_URL_ANDROID',
    defaultValue: 'http://10.0.2.2:8080/smart-faculty/backend/public',
  );

  static const String realDeviceBaseUrl = String.fromEnvironment(
    'API_BASE_URL_DEVICE',
    defaultValue: 'http://ADRESSE_IP_DU_PC:8080/smart-faculty/backend/public',
  );

  static const String serverUnavailableMessage =
      'Serveur indisponible. Vérifiez que le backend PHP est lancé.';

  static String get baseUrl {
    if (configuredBaseUrl.trim().isNotEmpty) {
      return _withoutTrailingSlash(configuredBaseUrl);
    }

    if (kIsWeb) {
      return _withoutTrailingSlash(webBaseUrl);
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return _withoutTrailingSlash(androidEmulatorBaseUrl);
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _withoutTrailingSlash(realDeviceBaseUrl);
    }

    return _withoutTrailingSlash(desktopBaseUrl);
  }

  static Uri endpoint(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath');
  }

  static String _withoutTrailingSlash(String value) {
    return value.trim().replaceFirst(RegExp(r'/+$'), '');
  }
}
