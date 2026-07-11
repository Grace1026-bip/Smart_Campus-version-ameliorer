import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_app/donnees/modeles/modeles_faculte.dart';
import 'package:smart_campus_app/donnees/services/client_api_reponse.dart';
import 'package:smart_campus_app/donnees/services/service_api.dart';
import 'package:smart_campus_app/donnees/services/service_authentification.dart';
import 'package:smart_campus_app/donnees/services/service_session.dart';

void main() {
  tearDown(() {
    SessionService.clear();
    ApiDataSource.client = ApiService();
    AuthDataSource.service = const ApiAuthService();
  });

  test('ApiService ajoute le Bearer token et actualise la session', () async {
    final fake = _FakeHttp([
      _jsonResponse(401, {'detail': 'Token expire'}),
      _jsonResponse(200, {
        'succes': true,
        'message': 'Session actualisee',
        'donnees': {
          'access_token': 'access-new',
          'refresh_token': 'refresh-new',
          'role_actif': 'etudiant',
        },
      }),
      _jsonResponse(200, {
        'succes': true,
        'message': 'OK',
        'donnees': {'valeur': 42},
      }),
    ]);
    final client = ApiService(envoyer: fake.send)
      ..configurerSession(
        accessToken: 'access-old',
        refreshToken: 'refresh-old',
        roleActif: 'etudiant',
      );

    final data = await client.get('/notifications');

    expect(data['valeur'], 42);
    expect(fake.requests, hasLength(3));
    expect(
      fake.requests.first.headers['Authorization'],
      'Bearer access-old',
    );
    expect(fake.requests[1].uri.path, '/api/v1/auth/actualiser');
    expect(
      fake.requests.last.headers['Authorization'],
      'Bearer access-new',
    );
    expect(client.accessToken, 'access-new');
    expect(client.refreshToken, 'refresh-new');
  });

  test('ApiAuthService envoie email, mot de passe et role a FastAPI', () async {
    final fake = _FakeHttp([
      _jsonResponse(200, {
        'succes': true,
        'message': 'Connexion reussie',
        'donnees': {
          'access_token': 'access-token',
          'refresh_token': 'refresh-token',
          'role_actif': 'enseignant',
          'utilisateur': {
            'id': 7,
            'nom': 'Mukendi',
            'postnom': null,
            'prenom': 'Jean',
            'email': 'enseignant@smartfaculty.test',
            'telephone': null,
            'statut': 'actif',
            'roles': ['enseignant'],
            'role_actif': 'enseignant',
            'permissions': [],
          },
        },
      }),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final user = await const ApiAuthService().login(
      identifier: 'enseignant@smartfaculty.test',
      password: 'Smart@123456',
      role: UserRole.teacher,
    );

    final body =
        jsonDecode(fake.requests.single.body ?? '{}') as Map<String, dynamic>;
    expect(fake.requests.single.uri.path, '/api/v1/auth/connexion');
    expect(body['email'], 'enseignant@smartfaculty.test');
    expect(body['mot_de_passe'], 'Smart@123456');
    expect(body['role'], 'enseignant');
    expect(user.email, 'enseignant@smartfaculty.test');
    expect(user.role, UserRole.teacher);
    expect(SessionService.currentRole, UserRole.teacher);
    expect(ApiDataSource.client.accessToken, 'access-token');
  });

  test('les roles Flutter ont une correspondance FastAPI unique', () {
    expect(
      UserRole.values.map((role) => role.apiValue).toList(),
      [
        'administrateur',
        'appariteur',
        'etudiant',
        'enseignant',
        'chef_promotion',
        'doyen',
      ],
    );
    expect(userRoleFromApi('icp'), isNull);
    expect(userRoleFromApi('paritaire'), isNull);
    expect(userRoleFromApi('surveillant'), isNull);
    expect(userRoleFromApi('vice_doyen'), isNull);
  });

  test('ApiAuthService utilise uniquement le role actif retourne', () async {
    final fake = _FakeHttp([
      _jsonResponse(200, {
        'succes': true,
        'donnees': {
          'access_token': 'access-token',
          'refresh_token': 'refresh-token',
          'role_actif': 'etudiant',
          'utilisateur': {
            'nom': 'Etudiant',
            'email': 'etudiant@smartfaculty.test',
            'roles': ['etudiant'],
          },
        },
      }),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final user = await const ApiAuthService().login(
      identifier: 'etudiant@smartfaculty.test',
      password: 'Smart@123456',
      role: UserRole.administrator,
    );

    expect(user.role, UserRole.student);
    expect(SessionService.currentRole, UserRole.student);
    expect(ApiDataSource.client.roleActif, 'etudiant');
  });

  for (final cas in <Map<String, Object>>[
    {
      'type': TypeErreurTransport.serveurInaccessible,
      'message':
          'Serveur indisponible. Verifiez que le backend FastAPI est lance.',
    },
    {
      'type': TypeErreurTransport.delaiDepasse,
      'message': 'Le serveur FastAPI ne repond pas dans le delai attendu.',
    },
    {
      'type': TypeErreurTransport.cors,
      'message': 'Connexion bloquee par la politique CORS du backend FastAPI.',
    },
  ]) {
    final type = cas['type'] as TypeErreurTransport;
    final message = cas['message'] as String;
    test('ApiService distingue le transport ${type.name}', () async {
      final client = ApiService(
        envoyer: ({
          required methode,
          required uri,
          required headers,
          body,
        }) async {
          throw ErreurTransportHttp(type);
        },
      );

      expect(
        () => client.get('/statut'),
        throwsA(
          isA<ApiException>().having(
            (erreur) => erreur.message,
            'message',
            message,
          ),
        ),
      );
    });
  }

  for (final cas in <Map<String, Object>>[
    {'code': 401, 'message': 'Email, mot de passe ou role incorrect'},
    {'code': 403, 'message': 'Compte non actif'},
    {'code': 500, 'message': 'Erreur interne du serveur'},
  ]) {
    final code = cas['code'] as int;
    final message = cas['message'] as String;
    test('ApiService conserve le message HTTP $code', () async {
      final fake = _FakeHttp([
        _jsonResponse(code, {'message': message}),
      ]);
      final client = ApiService(envoyer: fake.send);

      expect(
        () => client.post('/auth/connexion'),
        throwsA(
          isA<ApiException>()
              .having((erreur) => erreur.statusCode, 'statusCode', code)
              .having((erreur) => erreur.message, 'message', message),
        ),
      );
    });
  }

  test('ApiService identifie une validation HTTP 422', () async {
    final fake = _FakeHttp([
      _jsonResponse(422, {
        'detail': [
          {
            'loc': ['body', 'email'],
            'msg': 'Field required'
          },
        ],
      }),
    ]);
    final client = ApiService(envoyer: fake.send);

    expect(
      () => client.post('/auth/connexion'),
      throwsA(
        isA<ApiException>()
            .having((erreur) => erreur.statusCode, 'statusCode', 422)
            .having(
              (erreur) => erreur.message,
              'message',
              'Validation des donnees refusee.',
            ),
      ),
    );
  });

  test('ApiService identifie une reponse JSON invalide', () async {
    final fake = _FakeHttp([
      const ReponseHttp(statusCode: 200, body: '<html>', headers: {}),
    ]);
    final client = ApiService(envoyer: fake.send);

    expect(
      () => client.get('/statut'),
      throwsA(
        isA<ApiException>().having(
          (erreur) => erreur.message,
          'message',
          contains('Reponse API invalide'),
        ),
      ),
    );
  });
}

class _CapturedRequest {
  const _CapturedRequest({
    required this.methode,
    required this.uri,
    required this.headers,
    required this.body,
  });

  final String methode;
  final Uri uri;
  final Map<String, String> headers;
  final String? body;
}

class _FakeHttp {
  _FakeHttp(this.responses);

  final List<ReponseHttp> responses;
  final List<_CapturedRequest> requests = [];

  Future<ReponseHttp> send({
    required String methode,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) async {
    requests.add(
      _CapturedRequest(
        methode: methode,
        uri: uri,
        headers: Map<String, String>.from(headers),
        body: body,
      ),
    );
    if (responses.isEmpty) {
      return _jsonResponse(500, {'message': 'Aucune reponse fake'});
    }
    return responses.removeAt(0);
  }
}

ReponseHttp _jsonResponse(int statusCode, Object body) {
  return ReponseHttp(
    statusCode: statusCode,
    body: jsonEncode(body),
    headers: const {'content-type': 'application/json'},
  );
}
