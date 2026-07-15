import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/config/api_config.dart';
import 'client_api_reponse.dart';
import 'client_api_stub.dart';
import 'client_multipart_reponse.dart';
import 'client_multipart_stub.dart';
import 'service_persistence.dart';

typedef EnvoyeurRequeteHttp = Future<ReponseHttp> Function({
  required String methode,
  required Uri uri,
  required Map<String, String> headers,
  String? body,
});

typedef EnvoyeurRequeteOctetsHttp = Future<ReponseOctetsHttp> Function({
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

  String get messagePourUtilisateur {
    switch (statusCode) {
      case 401:
        return 'Identifiants incorrects.';
      case 403:
        return 'Compte non autorise ou acces refuse.';
      case 422:
        return 'Requete invalide. Verifiez les donnees saisies.';
      case 500:
        return 'Le serveur FastAPI a rencontre une erreur.';
      default:
        return message;
    }
  }

  @override
  String toString() => message;
}

class ApiService {
  ApiService({
    EnvoyeurRequeteHttp envoyer = envoyerRequeteHttp,
    EnvoyeurRequeteOctetsHttp? envoyerOctets,
    EnvoyeurMultipartHttp? envoyerMultipart,
  })  : _envoyer = envoyer,
        _envoyerOctets = envoyerOctets ?? envoyerRequeteOctetsHttp,
        _envoyerMultipart = envoyerMultipart ?? envoyerRequeteMultipart;

  final EnvoyeurRequeteHttp _envoyer;
  final EnvoyeurRequeteOctetsHttp _envoyerOctets;
  final EnvoyeurMultipartHttp _envoyerMultipart;
  String? _accessToken;
  String? _refreshToken;
  String? _roleActif;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get roleActif => _roleActif;
  bool get estConnecte => _accessToken != null && _refreshToken != null;

  Future<void> configurerSession({
    required String accessToken,
    required String refreshToken,
    required String roleActif,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _roleActif = roleActif;
    await SessionPersistenceService.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      roleActif: roleActif,
    );
  }

  Future<void> viderSession() async {
    _accessToken = null;
    _refreshToken = null;
    _roleActif = null;
    await SessionPersistenceService.clearSession();
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

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic> body = const {},
  }) async {
    final response = await _requestWithRefresh(
      methode: 'PATCH',
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

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    Map<String, String> fields = const {},
    required List<MultipartPart> parts,
  }) async {
    var response = await _requestMultipart(
      methode: 'POST',
      uri: _uri(path),
      headers: _headers(),
      fields: fields,
      parts: parts,
    );
    if (response.statusCode == 401 && _refreshToken != null) {
      final refreshed = await _actualiserSession();
      if (refreshed) {
        response = await _requestMultipart(
          methode: 'POST',
          uri: _uri(path),
          headers: _headers(),
          fields: fields,
          parts: parts,
        );
      }
    }
    return _decode(response);
  }

  Future<List<int>> getBytes(String path) async {
    var response = await _requestBytes(
      methode: 'GET',
      uri: _uri(path),
      headers: _headers(),
    );

    if (response.statusCode == 401 && _refreshToken != null) {
      final refreshed = await _actualiserSession();
      if (refreshed) {
        response = await _requestBytes(
          methode: 'GET',
          uri: _uri(path),
          headers: _headers(),
        );
      }
    }

    if (response.statusCode >= 400) {
      throw ApiException(
        _messagePourStatut(response.statusCode),
        statusCode: response.statusCode,
      );
    }
    return response.bytes;
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
    } on ErreurTransportHttp catch (erreur) {
      switch (erreur.type) {
        case TypeErreurTransport.serveurInaccessible:
          throw ApiException(ApiConfig.serverUnavailableMessage);
        case TypeErreurTransport.delaiDepasse:
          throw ApiException('La connexion a expire.');
        case TypeErreurTransport.cors:
          throw ApiException('Requete refusee par le navigateur.');
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(ApiConfig.serverUnavailableMessage);
    }
  }

  Future<ReponseHttp> _requestMultipart({
    required String methode,
    required Uri uri,
    required Map<String, String> headers,
    required Map<String, String> fields,
    required List<MultipartPart> parts,
  }) async {
    try {
      return await _envoyerMultipart(
        methode: methode,
        uri: uri,
        headers: headers,
        fields: fields,
        parts: parts,
      );
    } on ErreurTransportHttp catch (erreur) {
      switch (erreur.type) {
        case TypeErreurTransport.serveurInaccessible:
          throw ApiException(ApiConfig.serverUnavailableMessage);
        case TypeErreurTransport.delaiDepasse:
          throw ApiException('La connexion a expire.');
        case TypeErreurTransport.cors:
          throw ApiException('Requete refusee par le navigateur.');
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(ApiConfig.serverUnavailableMessage);
    }
  }

  Future<ReponseOctetsHttp> _requestBytes({
    required String methode,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) async {
    try {
      return await _envoyerOctets(
        methode: methode,
        uri: uri,
        headers: headers,
        body: body,
      );
    } on ErreurTransportHttp catch (erreur) {
      switch (erreur.type) {
        case TypeErreurTransport.serveurInaccessible:
          throw ApiException(ApiConfig.serverUnavailableMessage);
        case TypeErreurTransport.delaiDepasse:
          throw ApiException('La connexion a expire.');
        case TypeErreurTransport.cors:
          throw ApiException('Requete refusee par le navigateur.');
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(ApiConfig.serverUnavailableMessage);
    }
  }

  String _messagePourStatut(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Session expiree.';
      case 403:
        return 'Acces refuse.';
      case 404:
        return 'Fiche introuvable.';
      case 409:
        return 'Fiche indisponible.';
      case 500:
        return 'Le serveur FastAPI a rencontre une erreur.';
      default:
        return 'Le telechargement a echoue.';
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
        await viderSession();
        return false;
      }

      final data = _decode(response);
      final accessToken = data['access_token']?.toString();
      final refreshToken = data['refresh_token']?.toString();
      final roleActif = data['role_actif']?.toString() ?? _roleActif;

      if (accessToken == null || refreshToken == null || roleActif == null) {
        await viderSession();
        return false;
      }

      await configurerSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        roleActif: roleActif,
      );
      return true;
    } catch (_) {
      await viderSession();
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
