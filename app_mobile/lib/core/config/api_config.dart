import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String webBaseUrl = String.fromEnvironment(
    'API_BASE_URL_WEB',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const String desktopBaseUrl = String.fromEnvironment(
    'API_BASE_URL_DESKTOP',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const String androidEmulatorBaseUrl = String.fromEnvironment(
    'API_BASE_URL_ANDROID',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const String realDeviceBaseUrl = String.fromEnvironment(
    'API_BASE_URL_DEVICE',
    defaultValue: 'http://ADRESSE_IP_DU_PC:8000',
  );

  static const String serverUnavailableMessage =
      'Serveur indisponible. Verifiez que le backend FastAPI est lance.';

  static const String apiPrefix = '/api/v1';

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
    final apiPath = normalizedPath.startsWith(apiPrefix)
        ? normalizedPath
        : '$apiPrefix$normalizedPath';
    return Uri.parse('$baseUrl$apiPath');
  }

  static String _withoutTrailingSlash(String value) {
    return value.trim().replaceFirst(RegExp(r'/+$'), '');
  }
}
