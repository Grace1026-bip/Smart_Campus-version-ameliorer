import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_app/donnees/services/client_api_reponse.dart';
import 'package:smart_campus_app/donnees/services/service_api.dart';
import 'package:smart_campus_app/donnees/services/service_valve.dart';

void main() {
  tearDown(() {
    ApiDataSource.client = ApiService();
  });

  test('ValveApiService cree un brouillon avec le cours et le type valides',
      () async {
    final fake = _FakeHttp([
      _jsonResponse(201, {
        'publication': {
          'id': 12,
          'statut': 'brouillon',
          'type_publication': 'annonce',
        },
      }),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final publication = await const ValveApiService().creerPublication(
      coursId: 7,
      typePublication: 'annonce',
      titre: 'Information de cours',
      contenu: 'Le prochain cours est maintenu.',
      publierMaintenant: false,
    );

    expect(publication['statut'], 'brouillon');
    expect(fake.requests.single.methode, 'POST');
    expect(
        fake.requests.single.uri.path, '/api/v1/enseignant/valve/publications');
    expect(jsonDecode(fake.requests.single.body!)['publier_maintenant'], false);
  });

  test('ValveApiService utilise les routes de publication et d archivage',
      () async {
    final fake = _FakeHttp([
      _jsonResponse(200, {
        'publication': {'id': 12, 'statut': 'publiee'}
      }),
      _jsonResponse(200, {
        'publication': {'id': 12, 'statut': 'archivee'}
      }),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);
    const service = ValveApiService();

    final publiee = await service.publierPublication(12);
    final archivee = await service.archiverPublication(12);

    expect(publiee['statut'], 'publiee');
    expect(archivee['statut'], 'archivee');
    expect(fake.requests.map((request) => request.uri.path), [
      '/api/v1/enseignant/valve/publications/12/publier',
      '/api/v1/enseignant/valve/publications/12/archiver',
    ]);
  });

  test('ValveApiService filtre la liste par cours et type sans secret',
      () async {
    final fake = _FakeHttp([
      _jsonResponse(200, {
        'elements': [
          {'id': 12, 'cours_id': 7, 'type_publication': 'devoir'},
        ],
        'total': 1,
      }),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final data = await const ValveApiService().valveEnseignant(
      coursId: 7,
      typePublication: 'devoir',
    );

    expect(data['total'], 1);
    expect(fake.requests.single.uri.queryParameters['cours_id'], '7');
    expect(
        fake.requests.single.uri.queryParameters['type_publication'], 'devoir');
    expect(fake.requests.single.body, isNull);
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
