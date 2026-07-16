import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_app/donnees/services/client_api_reponse.dart';
import 'package:smart_campus_app/donnees/services/service_api.dart';
import 'package:smart_campus_app/donnees/services/service_reinitialisations.dart';

void main() {
  tearDown(() => ApiDataSource.client = ApiService());

  test('la demande de reinitialisation reste publique et sans secret',
      () async {
    final fake = _FakeHttp([
      _jsonResponse(201, {'reference': 'RST-TEST-001', 'statut': 'en_attente'}),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final resultat = await const ReinitialisationsApiService()
        .demander('ETUDIANT@EXAMPLE.TEST');

    expect(resultat['statut'], 'en_attente');
    expect(fake.requests.single.uri.path,
        '/api/v1/auth/mot-de-passe-oublie/demandes');
    expect(fake.requests.single.body, contains('etudiant@example.test'));
    expect(fake.requests.single.body, isNot(contains('mot_de_passe')));
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
    requests.add(_RequestCapture(uri: uri, body: body ?? ''));
    return responses.removeAt(0);
  }
}

class _RequestCapture {
  const _RequestCapture({required this.uri, required this.body});

  final Uri uri;
  final String body;
}

ReponseHttp _jsonResponse(int statusCode, Map<String, dynamic> data) {
  return ReponseHttp(
    statusCode: statusCode,
    body: jsonEncode({'succes': true, 'donnees': data}),
    headers: const {},
  );
}
