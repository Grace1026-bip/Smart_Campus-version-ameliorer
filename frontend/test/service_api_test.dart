import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_app/donnees/modeles/modeles_faculte.dart';
import 'package:smart_campus_app/donnees/services/client_api_reponse.dart';
import 'package:smart_campus_app/donnees/services/client_multipart_reponse.dart';
import 'package:smart_campus_app/donnees/services/service_api.dart';
import 'package:smart_campus_app/donnees/services/service_authentification.dart';
import 'package:smart_campus_app/donnees/services/service_inscriptions.dart';
import 'package:smart_campus_app/donnees/services/service_persistence.dart';
import 'package:smart_campus_app/donnees/services/service_session.dart';
import 'package:smart_campus_app/coeur/routes/routes_application.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  tearDown(() async {
    await SessionService.clear();
    SessionPersistenceService.resetStorage();
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
    final client = ApiService(envoyer: fake.send);
    await client.configurerSession(
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
    expect(fake.requests.first.headers.containsValue('******'), isFalse);
    expect(fake.requests[1].uri.path, '/api/v1/auth/actualiser');
    expect(
      fake.requests.last.headers['Authorization'],
      'Bearer access-new',
    );
    expect(client.accessToken, 'access-new');
    expect(client.refreshToken, 'refresh-new');
  });

  test('ApiService n ajoute pas de header Authorization sans token', () async {
    final fake = _FakeHttp([
      _jsonResponse(200, {
        'succes': true,
        'donnees': {'valeur': 1},
      }),
    ]);
    final client = ApiService(envoyer: fake.send);

    await client.get('/statut');

    expect(fake.requests.single.headers.containsKey('Authorization'), isFalse);
    expect(fake.requests.single.headers.containsValue('******'), isFalse);
  });

  test('ApiService envoie des captures multipart avec Bearer', () async {
    final captures = <String, Object?>{};
    final client = ApiService(
      envoyerMultipart: ({
        required methode,
        required uri,
        required headers,
        required fields,
        required parts,
      }) async {
        captures['methode'] = methode;
        captures['uri'] = uri.path;
        captures['headers'] = headers;
        captures['fields'] = fields;
        captures['parts'] = parts;
        return _jsonResponse(201, {
          'succes': true,
          'donnees': {'statut': 'actif'},
        });
      },
    );
    await client.configurerSession(
      accessToken: 'access-test',
      refreshToken: 'refresh-test',
      roleActif: 'appariteur',
    );

    await client.postMultipart(
      '/appariteur/biometrie/etudiants/8/enroler',
      fields: {'consentement': 'true'},
      parts: [
        const MultipartPart(
          name: 'images',
          bytes: [1, 2, 3],
          filename: 'capture.png',
          contentType: 'image/png',
        ),
      ],
    );

    expect(captures['methode'], 'POST');
    expect(captures['uri'], '/api/v1/appariteur/biometrie/etudiants/8/enroler');
    expect((captures['headers'] as Map)['Authorization'], 'Bearer access-test');
    expect((captures['fields'] as Map)['consentement'], 'true');
    expect((captures['parts'] as List).single, isA<MultipartPart>());
  });

  test('ApiAuthService envoie email, mot de passe et role a FastAPI', () async {
    final storage = _FakeSessionStorage();
    SessionPersistenceService.configureStorage(storage);
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
    await Future<void>.delayed(Duration.zero);
    expect(storage.session?['access_token'], 'access-token');
    expect(storage.session?['refresh_token'], 'refresh-token');
    expect(storage.session?.containsKey('mot_de_passe'), isFalse);
  });

  test('ApiAuthService restaure et confirme le role actif via /auth/moi',
      () async {
    final storage = _FakeSessionStorage()
      ..session = {
        'access_token': 'access-restored',
        'refresh_token': 'refresh-restored',
        'role_actif': 'etudiant',
      };
    SessionPersistenceService.configureStorage(storage);
    final fake = _FakeHttp([
      _jsonResponse(200, {
        'succes': true,
        'donnees': {
          'nom': 'Enseignant',
          'prenom': 'Restaure',
          'email': 'restaure@smartfaculty.test',
          'roles': ['enseignant'],
          'role_actif': 'enseignant',
        },
      }),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final user = await const ApiAuthService().restoreSession();

    expect(user?.role, UserRole.teacher);
    expect(SessionService.currentRole, UserRole.teacher);
    expect(AppRoutes.dashboardForRole(user!.role), AppRoutes.teacherDashboard);
    expect(fake.requests.single.uri.path, '/api/v1/auth/moi');
    expect(
      fake.requests.single.headers['Authorization'],
      'Bearer access-restored',
    );
  });

  test('ApiAuthService supprime une session locale invalide', () async {
    final storage = _FakeSessionStorage()
      ..session = {
        'access_token': 'access-invalid',
        'refresh_token': 'refresh-invalid',
        'role_actif': 'etudiant',
      };
    SessionPersistenceService.configureStorage(storage);
    final fake = _FakeHttp([
      _jsonResponse(403, {'message': 'Compte non actif'}),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final user = await const ApiAuthService().restoreSession();

    expect(user, isNull);
    expect(SessionService.isAuthenticated, isFalse);
    expect(ApiDataSource.client.estConnecte, isFalse);
    expect(storage.session, isNull);
  });

  test('ApiAuthService reste deconnecte sans session sauvegardee', () async {
    final storage = _FakeSessionStorage();
    SessionPersistenceService.configureStorage(storage);
    final fake = _FakeHttp([]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final user = await const ApiAuthService().restoreSession();

    expect(user, isNull);
    expect(SessionService.isAuthenticated, isFalse);
    expect(fake.requests, isEmpty);
  });

  test(
      'SessionPersistenceService restaure et supprime une session via injection',
      () async {
    final storage = _FakeSessionStorage();
    SessionPersistenceService.configureStorage(storage);

    await SessionPersistenceService.saveSession(
      accessToken: 'access-test',
      refreshToken: 'refresh-test',
      roleActif: 'etudiant',
    );

    expect(await SessionPersistenceService.restoreSession(), {
      'access_token': 'access-test',
      'refresh_token': 'refresh-test',
      'role_actif': 'etudiant',
    });
    expect(storage.session?.containsKey('mot_de_passe'), isFalse);

    await SessionPersistenceService.clearSession();
    expect(await SessionPersistenceService.restoreSession(), isNull);
  });

  test('SessionPersistenceService absorbe les erreurs de stockage', () async {
    final storage = _FakeSessionStorage()
      ..failRead = true
      ..failWrite = true
      ..failClear = true;
    SessionPersistenceService.configureStorage(storage);

    await expectLater(
      SessionPersistenceService.saveSession(
        accessToken: 'access-test',
        refreshToken: 'refresh-test',
        roleActif: 'etudiant',
      ),
      completes,
    );
    await expectLater(SessionPersistenceService.restoreSession(), completes);
    await expectLater(SessionPersistenceService.clearSession(), completes);
    expect(await SessionPersistenceService.restoreSession(), isNull);
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
        'surveillant',
        'doyen',
        'vice_doyen',
      ],
    );
    expect(userRoleFromApi('icp'), isNull);
    expect(userRoleFromApi('paritaire'), isNull);
    expect(userRoleFromApi('surveillant'), UserRole.surveillant);
    expect(userRoleFromApi('vice_doyen'), UserRole.viceDean);
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

  test('DemandeInscriptionPayload limite les roles publics', () {
    expect(
      TypeDemandeInscription.values.map((type) => type.apiValue).toList(),
      ['etudiant', 'enseignant'],
    );
  });

  test('ApiInscriptionService cree une demande sans session locale', () async {
    final fake = _FakeHttp([
      _jsonResponse(201, {
        'succes': true,
        'message': 'Demande creee',
        'donnees': {
          'reference': 'SF-ABC123',
          'type_demande': 'etudiant',
          'email': 'test@smartfaculty.test',
          'statut': 'en_attente',
        },
      }),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final demande = await const ApiInscriptionService().creerDemande(
      const DemandeInscriptionPayload(
        type: TypeDemandeInscription.etudiant,
        email: ' TEST@SMARTFACULTY.TEST ',
        motDePasse: 'Smart@123456',
        nom: 'Test',
        matricule: 'SF-TEST',
        promotionId: 1,
      ),
    );

    final body =
        jsonDecode(fake.requests.single.body ?? '{}') as Map<String, dynamic>;
    expect(fake.requests.single.uri.path, '/api/v1/inscriptions/demandes');
    expect(body['type_demande'], 'etudiant');
    expect(body['email'], 'test@smartfaculty.test');
    expect(body.containsKey('access_token'), isFalse);
    expect(demande.statut, 'en_attente');
    expect(SessionService.isAuthenticated, isFalse);
    expect(ApiDataSource.client.accessToken, isNull);
  });

  test('ApiInscriptionService consulte un statut de demande', () async {
    final fake = _FakeHttp([
      _jsonResponse(200, {
        'succes': true,
        'donnees': {
          'reference': 'SF-ABC123',
          'type_demande': 'enseignant',
          'email': 'prof@smartfaculty.test',
          'statut': 'rejetee',
          'motif_rejet': 'Dossier incomplet',
        },
      }),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final demande = await const ApiInscriptionService().consulterStatut(
      reference: 'SF-ABC123',
      email: ' PROF@SMARTFACULTY.TEST ',
    );

    expect(
        fake.requests.single.uri.path, '/api/v1/inscriptions/demandes/statut');
    expect(fake.requests.single.uri.queryParameters['email'],
        'prof@smartfaculty.test');
    expect(demande.statut, 'rejetee');
    expect(demande.motifRejet, 'Dossier incomplet');
  });

  for (final cas in <Map<String, Object>>[
    {
      'type': TypeErreurTransport.serveurInaccessible,
      'message': 'Le serveur FastAPI est inaccessible.',
    },
    {
      'type': TypeErreurTransport.delaiDepasse,
      'message': 'La connexion a expire.',
    },
    {
      'type': TypeErreurTransport.cors,
      'message': 'Requete refusee par le navigateur.',
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
    {'code': 401, 'message': 'Identifiants incorrects.'},
    {'code': 403, 'message': 'Compte non autorise ou acces refuse.'},
    {'code': 500, 'message': 'Le serveur FastAPI a rencontre une erreur.'},
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
              (erreur) => erreur.messagePourUtilisateur,
              'messagePourUtilisateur',
              'Requete invalide. Verifiez les donnees saisies.',
            ),
      ),
    );
  });

  test('ApiService ne classe pas une erreur inattendue comme CORS', () async {
    final client = ApiService(
      envoyer: ({
        required methode,
        required uri,
        required headers,
        body,
      }) async {
        throw StateError('erreur reseau inattendue');
      },
    );

    expect(
      () => client.get('/statut'),
      throwsA(
        isA<ApiException>().having(
          (erreur) => erreur.message,
          'message',
          'Le serveur FastAPI est inaccessible.',
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

class _FakeSessionStorage implements SessionStorage {
  Map<String, String>? session;
  bool failRead = false;
  bool failWrite = false;
  bool failClear = false;

  @override
  Future<Map<String, String>?> readSession() async {
    if (failRead) throw StateError('lecture impossible');
    return session == null ? null : Map<String, String>.from(session!);
  }

  @override
  Future<void> writeSession({
    required String accessToken,
    required String refreshToken,
    required String roleActif,
  }) async {
    if (failWrite) throw StateError('ecriture impossible');
    session = {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'role_actif': roleActif,
    };
  }

  @override
  Future<void> clearSession() async {
    if (failClear) throw StateError('suppression impossible');
    session = null;
  }
}

ReponseHttp _jsonResponse(int statusCode, Object body) {
  return ReponseHttp(
    statusCode: statusCode,
    body: jsonEncode(body),
    headers: const {'content-type': 'application/json'},
  );
}
