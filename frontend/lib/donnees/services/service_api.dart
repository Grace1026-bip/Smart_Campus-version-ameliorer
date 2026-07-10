import 'dart:convert';

import '../../core/config/api_config.dart';
import 'client_api_reponse.dart';
import 'client_api_stub.dart';

typedef EnvoyeurRequeteHttp = Future<ReponseHttp> Function({
  required String methode,
  required Uri uri,
  required Map<String, String> headers,
  String? body,
});

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors = const {}});

  final String message;
  final int? statusCode;
  final Map<String, dynamic> errors;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({EnvoyeurRequeteHttp envoyer = envoyerRequeteHttp})
      : _envoyer = envoyer;

  final EnvoyeurRequeteHttp _envoyer;
  String? _accessToken;
  String? _refreshToken;
  String? _roleActif;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get roleActif => _roleActif;
  bool get estConnecte => _accessToken != null && _refreshToken != null;

  void configurerSession({
    required String accessToken,
    required String refreshToken,
    required String roleActif,
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _roleActif = roleActif;
  }

  void viderSession() {
    _accessToken = null;
    _refreshToken = null;
    _roleActif = null;
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic> query = const {},
  }) async {
    final response = await _requestWithRefresh(
      methode: 'GET',
      uri: _uri(path, query),
      headers: _headers(),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic> body = const {},
  }) async {
    final response = await _requestWithRefresh(
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
    final response = await _requestWithRefresh(
      methode: 'PUT',
      uri: _uri(path),
      headers: _headers(json: true),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final response = await _requestWithRefresh(
      methode: 'DELETE',
      uri: _uri(path),
      headers: _headers(),
    );
    return _decode(response);
  }

  Uri _uri(String path, [Map<String, dynamic> query = const {}]) {
    final uri = ApiConfig.endpoint(path);
    final cleanedQuery = <String, String>{};
    for (final entry in query.entries) {
      final value = entry.value;
      if (value == null) continue;
      cleanedQuery[entry.key] = value.toString();
    }

    if (cleanedQuery.isEmpty) return uri;
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        ...cleanedQuery,
      },
    );
  }

  Map<String, String> _headers({
    bool json = false,
    bool authenticated = true,
  }) {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
    };

    if (authenticated && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
  }

  Future<ReponseHttp> _requestWithRefresh({
    required String methode,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) async {
    final response = await _request(
      methode: methode,
      uri: uri,
      headers: headers,
      body: body,
    );

    if (response.statusCode != 401 || _refreshToken == null) {
      return response;
    }

    final refreshed = await _actualiserSession();
    if (!refreshed) return response;

    return _request(
      methode: methode,
      uri: uri,
      headers: _headers(json: headers.containsKey('Content-Type')),
      body: body,
    );
  }

  Future<ReponseHttp> _request({
    required String methode,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) async {
    try {
      return await _envoyer(
        methode: methode,
        uri: uri,
        headers: headers,
        body: body,
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(ApiConfig.serverUnavailableMessage);
    }
  }

  Future<bool> _actualiserSession() async {
    final token = _refreshToken;
    if (token == null) return false;

    try {
      final response = await _request(
        methode: 'POST',
        uri: _uri('/auth/actualiser'),
        headers: _headers(json: true, authenticated: false),
        body: jsonEncode({
          'refresh_token': token,
          if (_roleActif != null) 'role': _roleActif,
        }),
      );

      if (response.statusCode >= 400) {
        viderSession();
        return false;
      }

      final data = _decode(response);
      final accessToken = data['access_token']?.toString();
      final refreshToken = data['refresh_token']?.toString();
      final roleActif = data['role_actif']?.toString() ?? _roleActif;

      if (accessToken == null || refreshToken == null || roleActif == null) {
        viderSession();
        return false;
      }

      configurerSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        roleActif: roleActif,
      );
      return true;
    } catch (_) {
      viderSession();
      return false;
    }
  }

  Map<String, dynamic> _decode(ReponseHttp response) {
    final body = response.body.trim();
    if (response.statusCode == 0) {
      throw ApiException(
        ApiConfig.serverUnavailableMessage,
        statusCode: response.statusCode,
      );
    }

    if (body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return <String, dynamic>{};
      }
      throw ApiException(
        'Reponse API vide.',
        statusCode: response.statusCode,
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw ApiException(
        'Reponse API invalide. Verifiez que l URL du backend FastAPI est correcte.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw ApiException(
        'Format de reponse API inattendu.',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 400) {
      throw ApiException(
        _messageErreur(decoded),
        statusCode: response.statusCode,
        errors: _erreurs(decoded),
      );
    }

    if (decoded['succes'] == false) {
      throw ApiException(
        decoded['message']?.toString() ?? 'Erreur API',
        statusCode: response.statusCode,
        errors: _erreurs(decoded),
      );
    }

    if (decoded['succes'] == true) {
      final donnees = decoded['donnees'];
      if (donnees is Map<String, dynamic>) return donnees;
      if (donnees is List) return {'elements': donnees};
      return <String, dynamic>{};
    }

    return decoded;
  }

  String _messageErreur(Map<String, dynamic> payload) {
    final message = payload['message'];
    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString();
    }

    final detail = payload['detail'];
    if (detail is String && detail.trim().isNotEmpty) return detail;
    if (detail is List && detail.isNotEmpty) {
      return 'Validation des donnees refusee.';
    }

    return 'Erreur API';
  }

  Map<String, dynamic> _erreurs(Map<String, dynamic> payload) {
    final erreurs = payload['erreurs'];
    if (erreurs is Map<String, dynamic>) return erreurs;
    if (erreurs is List) return {'erreurs': erreurs};

    final detail = payload['detail'];
    if (detail is Map<String, dynamic>) return detail;
    if (detail is List) return {'detail': detail};

    return const {};
  }
}

class ApiDataSource {
  static ApiService client = ApiService();
}
