import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_app/donnees/services/client_api_reponse.dart';
import 'package:smart_campus_app/donnees/services/service_api.dart';
import 'package:smart_campus_app/donnees/services/service_enseignant.dart';

void main() {
  tearDown(() {
    ApiDataSource.client = ApiService();
  });

  test('EnseignantApiService utilise la route de profil courant', () async {
    final fake = _FakeHttp([
      _jsonResponse(200, {
        'nom_complet': 'Test Enseignant',
        'role_actif': 'enseignant',
      }),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final profil = await const EnseignantApiService().profil();

    expect(profil['role_actif'], 'enseignant');
    expect(fake.requests.single.uri.path, '/api/v1/enseignants/moi');
  });

  test('EnseignantApiService preserve une liste de cours vide', () async {
    final fake = _FakeHttp([
      _jsonResponse(200, {
        'elements': [],
        'total': 0,
      }),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final cours = await const EnseignantApiService().cours();

    expect(cours, isEmpty);
    expect(fake.requests.single.uri.path, '/api/v1/enseignants/moi/cours');
  });

  test(
      'EnseignantApiService utilise le detail securise et les donnees academiques',
      () async {
    final fake = _FakeHttp([
      _jsonResponse(200, {
        'id': 7,
        'code': 'WEB202',
        'intitule': 'Developpement Web',
        'promotion': {'nom': 'L2 Informatique'},
        'semestre': {'nom': 'Semestre 2'},
        'annee_academique': {'libelle': '2025-2026'},
        'nombre_credits': 5,
        'nombre_heures': 60,
      }),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final cours = await const EnseignantApiService().detailCours(7);

    expect(cours['code'], 'WEB202');
    expect(cours['promotion'], 'L2 Informatique');
    expect(cours['semestre'], 'Semestre 2');
    expect(cours['annee_academique'], '2025-2026');
    expect(cours['credits'], 5);
    expect(fake.requests.single.uri.path, '/api/v1/enseignants/moi/cours/7');
  });

  test('EnseignantApiService liste et normalise les encadrements', () async {
    final fake = _FakeHttp([
      _jsonResponse(200, {
        'elements': [
          {
            'id': 12,
            'role_encadrement': 'principal',
            'projet': {
              'id': 4,
              'titre': 'Plateforme campus',
              'type_projet': 'genie_logiciel',
              'type_projet_libelle': 'Genie logiciel',
              'statut': 'en_cours',
            },
            'etudiant': {
              'id': 8,
              'nom_complet': 'Etudiant Test',
              'matricule': 'MAT-008',
            },
          },
        ],
        'total': 1,
      }),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final encadrements = await const EnseignantApiService().encadrements(
          typeProjet: 'genie_logiciel',
          statut: 'en_cours',
          anneeAcademiqueId: 3,
          recherche: 'campus',
        );

    expect(encadrements, hasLength(1));
    expect(encadrements.single['titre'], 'Plateforme campus');
    expect(encadrements.single['type_projet'], 'genie_logiciel');
    expect(encadrements.single['etudiant']['matricule'], 'MAT-008');
    expect(fake.requests.single.uri.path, '/api/v1/enseignants/moi/encadrements');
    expect(fake.requests.single.uri.queryParameters['type_projet'], 'genie_logiciel');
    expect(fake.requests.single.uri.queryParameters['statut'], 'en_cours');
    expect(fake.requests.single.uri.queryParameters['annee_academique_id'], '3');
    expect(fake.requests.single.uri.queryParameters['recherche'], 'campus');
  });

  test('EnseignantApiService utilise le detail securise dun encadrement', () async {
    final fake = _FakeHttp([
      _jsonResponse(200, {
        'id': 12,
        'role_encadrement': 'principal',
        'projet': {
          'titre': 'Plateforme campus',
          'type_projet': 'genie_logiciel',
          'statut': 'en_cours',
        },
        'etudiant': {'nom_complet': 'Etudiant Test'},
        'autres_encadreurs': [],
      }),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final detail = await const EnseignantApiService().detailEncadrement(12);

    expect(detail['titre'], 'Plateforme campus');
    expect(detail['etudiant']['nom_complet'], 'Etudiant Test');
    expect(fake.requests.single.uri.path, '/api/v1/enseignants/moi/encadrements/12');
  });
}

class _FakeHttp {
  _FakeHttp(this.responses);

  final List<ReponseHttp> responses;
  final requests = <_RequestCapture>[];

  Future<ReponseHttp> send({
    required String methode,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) async {
    requests.add(_RequestCapture(methode: methode, uri: uri));
    return responses.removeAt(0);
  }
}

class _RequestCapture {
  _RequestCapture({required this.methode, required this.uri});

  final String methode;
  final Uri uri;
}

ReponseHttp _jsonResponse(int statusCode, Map<String, dynamic> donnees) {
  return ReponseHttp(
    statusCode: statusCode,
    body: jsonEncode({'succes': true, 'donnees': donnees}),
    headers: const {},
  );
}
