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
