import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_app/donnees/services/client_api_reponse.dart';
import 'package:smart_campus_app/donnees/services/service_api.dart';
import 'package:smart_campus_app/donnees/services/service_notes.dart';

void main() {
  tearDown(() {
    ApiDataSource.client = ApiService();
  });

  test('NotesApiService charge les types et les evaluations du cours',
      () async {
    final fake = _FakeHttp([
      _jsonResponse(200, {
        'types': [
          {'id': 1, 'nom': 'examen'},
        ],
      }),
      _jsonResponse(200, {
        'evaluations': [
          {'id': 9, 'titre': 'Examen', 'ponderation': 100},
        ],
      }),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);
    const service = NotesApiService();

    final types = await service.typesEvaluations();
    final evaluations = await service.evaluationsCours(7);

    expect(types.single['nom'], 'examen');
    expect(evaluations.single['id'], 9);
    expect(fake.requests.map((request) => request.uri.path), [
      '/api/v1/enseignant/types-evaluations',
      '/api/v1/enseignant/cours/7/evaluations',
    ]);
  });

  test(
      'NotesApiService enregistre une note zero sans la confondre avec une absence',
      () async {
    final fake = _FakeHttp([
      _jsonResponse(200, {
        'evaluation': {'id': 9, 'statut': 'brouillon'},
        'notes': [
          {'etudiant_id': 3, 'note_obtenue': 0},
        ],
      }),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final data = await const NotesApiService().enregistrerNotes(
      evaluationId: 9,
      notes: [
        {'etudiant_id': 3, 'note_obtenue': 0},
      ],
    );

    expect(data['notes'][0]['note_obtenue'], 0);
    expect(
        jsonDecode(fake.requests.single.body!)['notes'][0]['note_obtenue'], 0);
  });

  test('NotesApiService publie avec le nom de confirmation backend', () async {
    final fake = _FakeHttp([
      _jsonResponse(200, {
        'evaluation': {'id': 9, 'statut': 'publiee'},
      }),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final evaluation = await const NotesApiService().publierEvaluation(
      evaluationId: 9,
    );

    expect(evaluation['statut'], 'publiee');
    final payload =
        jsonDecode(fake.requests.single.body!) as Map<String, dynamic>;
    expect(payload['confirmer_notes_manquantes'], false);
    expect(payload.containsKey('autoriser_notes_manquantes'), false);
  });

  test('NotesApiService charge un apercu et publie les resultats du cours',
      () async {
    final fake = _FakeHttp([
      _jsonResponse(200, {
        'cours_id': 7,
        'etat': 'incomplet',
        'total_ponderation': 100,
        'notes_manquantes': 1,
      }),
      _jsonResponse(200, {
        'cours_id': 7,
        'etat': 'verrouille',
        'evaluations_verrouillees': true,
      }),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);
    const service = NotesApiService();

    final apercu = await service.apercuResultatsCours(7);
    final publication = await service.publierResultatsCours(7);

    expect(apercu['etat'], 'incomplet');
    expect(publication['evaluations_verrouillees'], true);
    expect(fake.requests.map((request) => request.uri.path), [
      '/api/v1/enseignant/cours/7/resultats/apercu',
      '/api/v1/enseignant/cours/7/resultats/publier',
    ]);
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
    requests.add(_RequestCapture(methode: methode, uri: uri, body: body));
    return responses.removeAt(0);
  }
}

class _RequestCapture {
  _RequestCapture({required this.methode, required this.uri, this.body});

  final String methode;
  final Uri uri;
  final String? body;
}

ReponseHttp _jsonResponse(int statusCode, Map<String, dynamic> donnees) {
  return ReponseHttp(
    statusCode: statusCode,
    body: jsonEncode({'succes': true, 'donnees': donnees}),
    headers: const {},
  );
}
