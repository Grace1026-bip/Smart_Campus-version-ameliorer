import 'dart:convert';

import '../../core/config/api_config.dart';
import 'client_api_reponse.dart';
import 'client_api_stub.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors = const {}});

  final String message;
  final int? statusCode;
  final Map<String, dynamic> errors;

  @override
  String toString() => message;
}

class ApiService {
  final Map<String, String> _cookies = {};

  Uri _uri(String path) => ApiConfig.endpoint(path);

  Future<Map<String, dynamic>> get(String path) async {
    final response = await _request(
      methode: 'GET',
      uri: _uri(path),
      headers: _headers(),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic> body = const {},
  }) async {
    final response = await _request(
      methode: 'POST',
      uri: _uri(path),
      headers: _headers(json: true),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic> body = const {},
  }) async {
    final response = await _request(
      methode: 'PUT',
      uri: _uri(path),
      headers: _headers(json: true),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final response = await _request(
      methode: 'DELETE',
      uri: _uri(path),
      headers: _headers(),
    );
    return _decode(response);
  }

  Map<String, String> _headers({bool json = false}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
    };

    if (_cookies.isNotEmpty) {
      headers['Cookie'] = _cookies.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('; ');
    }

    return headers;
  }

  Future<ReponseHttp> _request({
    required String methode,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) async {
    try {
      return await envoyerRequeteHttp(
        methode: methode,
        uri: uri,
        headers: headers,
        body: body,
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        ApiConfig.serverUnavailableMessage,
      );
    }
  }

  Map<String, dynamic> _decode(ReponseHttp response) {
    _storeCookies(response);

    final body = response.body.trim();
    if (response.statusCode == 0 || body.isEmpty) {
      throw ApiException(
        ApiConfig.serverUnavailableMessage,
        statusCode: response.statusCode,
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw ApiException(
        'Réponse API invalide. Vérifiez que l URL du backend PHP est correcte.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw ApiException(
        'Format de reponse API inattendu.',
        statusCode: response.statusCode,
      );
    }

    final payload = decoded;
    final success = payload['succes'] == true;

    if (!success) {
      throw ApiException(
        payload['message']?.toString() ?? 'Erreur API',
        statusCode: response.statusCode,
        errors: payload['erreurs'] is Map<String, dynamic>
            ? payload['erreurs'] as Map<String, dynamic>
            : const {},
      );
    }

    return payload['donnees'] is Map<String, dynamic>
        ? payload['donnees'] as Map<String, dynamic>
        : <String, dynamic>{};
  }

  void _storeCookies(ReponseHttp response) {
    final rawCookie = response.headers['set-cookie'];
    if (rawCookie == null) return;

    for (final cookie in rawCookie.split(',')) {
      final firstPart = cookie.split(';').first;
      final separator = firstPart.indexOf('=');
      if (separator <= 0) continue;
      _cookies[firstPart.substring(0, separator).trim()] =
          firstPart.substring(separator + 1).trim();
    }
  }
}

class ApiDataSource {
  static final ApiService client = ApiService();
}
