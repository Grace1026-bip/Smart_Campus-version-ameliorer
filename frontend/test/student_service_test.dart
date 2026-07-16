import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_app/coeur/routes/routes_application.dart';
import 'package:smart_campus_app/donnees/services/client_api_reponse.dart';
import 'package:smart_campus_app/donnees/services/service_api.dart';
import 'package:smart_campus_app/donnees/services/service_etudiant.dart';

void main() {
  tearDown(() => ApiDataSource.client = ApiService());

  test('EtudiantApiService charge ses enrolements et projets', () async {
    final fake = _FakeHttp([
      _jsonResponse(200, {
        'elements': [
          {
            'id': 8,
            'reference_fiche': 'ENR-0001-TEST',
            'statut': 'valide',
            'fiche_disponible': true,
          },
        ],
      }),
      _jsonResponse(200, {'id': 8, 'programme': []}),
      _jsonResponse(200, {
        'elements': [
          {
            'id': 12,
            'titre': 'Plateforme universitaire',
            'encadreurs': [
              {'nom': 'Professeur Test', 'role_encadrement': 'principal'},
            ],
          },
        ],
      }),
      _jsonResponse(200, {'id': 12, 'encadreurs': []}),
    ]);
    ApiDataSource.client = ApiService(
      envoyer: fake.send,
      envoyerOctets: fake.sendOctets,
    );
    const service = EtudiantApiService();

    final enrolements = await service.enrolements();
    final detailEnrolement = await service.detailEnrolement(8);
    final projets = await service.projetsAcademiques();
    final detailProjet = await service.detailProjetAcademique(12);

    expect(enrolements.single['fiche_disponible'], true);
    expect(detailEnrolement['id'], 8);
    expect(projets.single['id'], 12);
    expect(detailProjet['id'], 12);
    expect(fake.requests.map((item) => item.uri.path), [
      '/api/v1/etudiants/moi/enrolements',
      '/api/v1/etudiants/moi/enrolements/8',
      '/api/v1/etudiants/moi/projets',
      '/api/v1/etudiants/moi/projets/12',
    ]);
  });

  test('EtudiantApiService recupere les octets de la fiche PDF', () async {
    final fake = _FakeHttp([])
      ..octets = const ReponseOctetsHttp(
        statusCode: 200,
        bytes: [37, 80, 68, 70, 45],
        headers: {'content-type': 'application/pdf'},
      );
    ApiDataSource.client = ApiService(
      envoyer: fake.send,
      envoyerOctets: fake.sendOctets,
    );

    final bytes =
        await const EtudiantApiService().telechargerFicheEnrolement(8);

    expect(bytes, [37, 80, 68, 70, 45]);
    expect(fake.octetsRequests.single.uri.path,
        '/api/v1/etudiants/moi/enrolements/8/fiche');
  });

  test('la navigation Etudiant expose Mon enrolement et Mon projet', () {
    expect(AppRoutes.studentEnrollments, '/student/enrollments');
    expect(AppRoutes.studentProjects, '/student/projects');
  });

  test('l espace academique utilise le dashboard et l historique reels', () async {
    final fake = _FakeHttp([
      _jsonResponse(200, {
        'profil': {
          'nom_complet': 'Etudiant Test',
          'matricule': 'SF-001',
          'promotion': 'L2 Informatique',
        },
        'nombre_cours': 1,
        'nombre_resultats_officiels': 0,
        'cours': [],
        'projets': [],
      }),
      _jsonResponse(200, {
        'cours': [
          {
            'cours': {
              'id': 4,
              'code': 'BD201',
              'intitule': 'Bases de donnees',
              'nombre_credits': 5,
            },
          },
        ],
        'promotion': {'nom': 'L2 Informatique'},
        'annee_academique': {'libelle': '2025-2026'},
      }),
      _jsonResponse(200, {
        'groupes': [
          {
            'annee_academique': {'libelle': '2025-2026'},
            'promotion': {'nom': 'L2 Informatique'},
            'semestre': {'nom': 'Semestre 1'},
            'cours': [],
          },
        ],
      }),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    const service = EtudiantApiService();
    final dashboard = await service.tableauDeBord();
    final courses = await service.cours();
    final history = await service.historiqueAcademique();

    expect(dashboard['profil']['matricule'], 'SF-001');
    expect(courses.single['code'], 'BD201');
    expect(history['groupes'], isNotEmpty);
    expect(fake.requests.map((item) => item.uri.path), [
      '/api/v1/etudiants/moi/tableau-de-bord',
      '/api/v1/etudiants/moi/cours',
      '/api/v1/etudiants/moi/historique-academique',
    ]);
  });

  test('la navigation Etudiant expose Historique', () {
    expect(AppRoutes.studentHistory, '/student/history');
  });

  test('EtudiantApiService soumet un projet avec une categorie controlee',
      () async {
    final fake = _FakeHttp([
      _jsonResponse(201, {'id': 19, 'statut': 'en_attente_validation'}),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final resultat = await const EtudiantApiService().soumettreProjet(
      titre: 'Laboratoire numerique',
      typeProjet: 'reseaux',
      description: 'Description de demonstration.',
    );

    expect(resultat['statut'], 'en_attente_validation');
    expect(fake.requests.single.methode, 'POST');
    expect(fake.requests.single.uri.path, '/api/v1/etudiants/moi/projets');
  });
}

class _FakeHttp {
  _FakeHttp(this.responses);

  final List<ReponseHttp> responses;
  final requests = <_RequestCapture>[];
  final octetsRequests = <_RequestCapture>[];
  ReponseOctetsHttp octets = const ReponseOctetsHttp(
    statusCode: 200,
    bytes: [],
    headers: {},
  );

  Future<ReponseHttp> send({
    required String methode,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) async {
    requests.add(_RequestCapture(methode: methode, uri: uri));
    return responses.removeAt(0);
  }

  Future<ReponseOctetsHttp> sendOctets({
    required String methode,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) async {
    octetsRequests.add(_RequestCapture(methode: methode, uri: uri));
    return octets;
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
