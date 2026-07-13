import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_app/coeur/routes/routes_application.dart';
import 'package:smart_campus_app/donnees/services/client_api_reponse.dart';
import 'package:smart_campus_app/donnees/services/service_api.dart';
import 'package:smart_campus_app/donnees/services/service_appariteur.dart';

void main() {
  tearDown(() {
    ApiDataSource.client = ApiService();
  });

  test('AppariteurApiService charge les enrolements avec ses filtres',
      () async {
    final fake = _FakeHttp([
      _jsonResponse(200, {
        'elements': [
          {
            'id': 8,
            'reference_fiche': 'ENR-0001-TEST',
            'statut': 'en_attente',
            'etudiant': {'matricule': 'SF-L2-0001', 'nom': 'Etudiant Test'},
          },
        ],
        'total': 1,
      }),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final resultat = await const AppariteurApiService().enrolements(
      recherche: 'SF-L2',
      anneeAcademiqueId: 1,
      promotionId: 2,
      statut: 'en_attente',
    );

    expect(resultat['total'], 1);
    expect(resultat['elements'], hasLength(1));
    expect(fake.requests.single.uri.path, '/api/v1/appariteur/enrolements');
    expect(fake.requests.single.uri.queryParameters['recherche'], 'SF-L2');
    expect(
        fake.requests.single.uri.queryParameters['annee_academique_id'], '1');
    expect(fake.requests.single.uri.queryParameters['promotion_id'], '2');
    expect(fake.requests.single.uri.queryParameters['statut'], 'en_attente');
  });

  test('AppariteurApiService couvre creation validation annulation et fiche',
      () async {
    final fake = _FakeHttp([
      _jsonResponse(201, {'id': 8, 'statut': 'en_attente'}),
      _jsonResponse(200, {'id': 8, 'statut': 'en_attente'}),
      _jsonResponse(200, {'id': 8, 'statut': 'en_attente'}),
      _jsonResponse(200, {'id': 8, 'statut': 'valide'}),
      _jsonResponse(200, {'id': 8, 'statut': 'annule'}),
      _jsonResponse(200, {'id': 8, 'statut': 'valide', 'programme': []}),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);
    const service = AppariteurApiService();

    await service.creerEnrolement(
      etudiantId: 1,
      promotionId: 2,
      anneeAcademiqueId: 1,
      dateEnrolement: '2026-07-13',
    );
    await service.detailEnrolement(8);
    await service.modifierEnrolement(8, dateEnrolement: '2026-07-14');
    await service.validerEnrolement(8);
    await service.annulerEnrolement(8, motif: 'Correction');
    final fiche = await service.donneesFicheEnrolement(8);

    expect(fiche['statut'], 'valide');
    expect(fake.requests.map((request) => request.methode), [
      'POST',
      'GET',
      'PATCH',
      'POST',
      'POST',
      'GET',
    ]);
    expect(
        fake.requests[3].uri.path, '/api/v1/appariteur/enrolements/8/valider');
    expect(
        fake.requests[4].uri.path, '/api/v1/appariteur/enrolements/8/annuler');
    expect(fake.requests[5].uri.path,
        '/api/v1/appariteur/enrolements/8/fiche/donnees');
  });

  test('la navigation Appariteur expose Enrolements', () {
    expect(AppRoutes.apparitorEnrollments, '/apparitorat/enrolements');
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
