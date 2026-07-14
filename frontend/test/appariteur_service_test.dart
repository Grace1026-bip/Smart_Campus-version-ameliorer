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

  test('AppariteurApiService charge et filtre les projets', () async {
    final fake = _FakeHttp([
      _jsonResponse(200, {
        'elements': [
          {
            'id': 12,
            'titre': 'Plateforme universitaire',
            'type_projet': 'genie_logiciel',
            'statut': 'propose',
          },
        ],
        'total': 1,
      }),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final resultat = await const AppariteurApiService().projets(
      typeProjet: 'genie_logiciel',
      statut: 'propose',
      recherche: 'Plateforme',
      sansEncadreur: true,
    );

    expect(resultat['total'], 1);
    expect(fake.requests.single.uri.path, '/api/v1/appariteur/projets');
    expect(fake.requests.single.uri.queryParameters['type_projet'],
        'genie_logiciel');
    expect(fake.requests.single.uri.queryParameters['sans_encadreur'], 'true');
  });

  test('AppariteurApiService couvre specialites et attribution', () async {
    final fake = _FakeHttp([
      _jsonResponse(201, {'id': 12}),
      _jsonResponse(200, {'id': 12}),
      _jsonResponse(200, {'id': 12}),
      _jsonResponse(200, {'id': 12, 'specialites': []}),
      _jsonResponse(200, {'id': 4, 'specialites': []}),
      _jsonResponse(201, {'id': 21}),
      _jsonResponse(200, {'id': 21}),
      _jsonResponse(200, {'id': 21}),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);
    const service = AppariteurApiService();

    await service.creerProjet(
      etudiantId: 1,
      titre: 'Plateforme',
      typeProjet: 'genie_logiciel',
    );
    await service.detailProjet(12);
    await service.modifierProjet(12, statut: 'en_cours');
    await service.configurerSpecialites(
      enseignantId: 4,
      typesProjet: ['genie_logiciel'],
    );
    await service.specialitesEnseignant(4);
    await service.attribuerEncadrement(
      projetId: 12,
      enseignantId: 4,
      roleEncadrement: 'principal',
      remplacerPrincipal: true,
    );
    await service.modifierEncadrement(
      projetId: 12,
      encadrementId: 21,
      roleEncadrement: 'co_encadreur',
    );
    await service.desactiverEncadrement(projetId: 12, encadrementId: 21);

    expect(fake.requests.map((request) => request.methode), [
      'POST',
      'GET',
      'PATCH',
      'PUT',
      'GET',
      'POST',
      'PATCH',
      'POST',
    ]);
    expect(fake.requests[5].uri.path,
        '/api/v1/appariteur/projets/12/encadrements');
    expect(fake.requests[7].uri.path,
        '/api/v1/appariteur/projets/12/encadrements/21/desactiver');
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
