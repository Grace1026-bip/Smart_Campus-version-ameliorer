import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_app/donnees/services/client_api_reponse.dart';
import 'package:smart_campus_app/donnees/services/service_api.dart';
import 'package:smart_campus_app/donnees/services/service_presences.dart';

void main() {
  tearDown(() => ApiDataSource.client = ApiService());

  test('liste les seances du surveillant avec un filtre date', () async {
    final fake = _FakeHttp([
      _success({'elements': []})
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final result =
        await const PresencesApiService().seances(dateSeance: '2026-07-10');

    expect(result, isEmpty);
    expect(fake.requests.single.uri.path, '/api/v1/surveillant/seances');
    expect(
        fake.requests.single.uri.queryParameters['date_seance'], '2026-07-10');
  });

  test('cree une seance sans envoyer une autorite utilisateur', () async {
    final fake = _FakeHttp([
      _success({'id': 8, 'statut': 'planifiee'})
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    await const PresencesApiService().creerSeance(
      coursId: 4,
      dateSeance: '2026-07-10',
      heureDebut: '08:00:00',
      heureFin: '12:00:00',
    );

    expect(fake.requests.single.methode, 'POST');
    expect(fake.requests.single.uri.path, '/api/v1/surveillant/seances');
    expect(fake.requests.single.body, contains('"cours_id":4'));
    expect(fake.requests.single.body, isNot(contains('utilisateur_id')));
    expect(fake.requests.single.body, isNot(contains('pourcentage')));
  });

  test('ouvre et ferme une seance par les routes dediees', () async {
    final fake = _FakeHttp([
      _success({'statut': 'ouverte'}),
      _success({'statut': 'fermee'}),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    await const PresencesApiService().ouvrirSeance(8);
    await const PresencesApiService().fermerSeance(8);

    expect(fake.requests.map((request) => request.uri.path), [
      '/api/v1/surveillant/seances/8/ouvrir',
      '/api/v1/surveillant/seances/8/fermer',
    ]);
  });

  test('controle un acces par matricule et preserve le statut refuse',
      () async {
    final fake = _FakeHttp([
      _success({
        'acces_autorise': false,
        'motif': 'paiement_insuffisant',
        'presence': {'statut': 'refuse'},
      }),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final result = await const PresencesApiService().controlerAcces(
      seanceId: 8,
      matricule: 'SF-L2-0001',
    );

    expect(result['motif'], 'paiement_insuffisant');
    expect(fake.requests.single.uri.path,
        '/api/v1/surveillant/seances/8/controle-acces');
    expect(fake.requests.single.body, contains('SF-L2-0001'));
  });

  test('recupere les etudiants et les presences de la seance', () async {
    final fake = _FakeHttp([
      _success({
        'elements': [
          {'matricule': 'SF-L2-0001'}
        ]
      }),
      _success({
        'elements': [
          {'statut': 'present'}
        ]
      }),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final etudiants = await const PresencesApiService().etudiants(8);
    final presences = await const PresencesApiService().presences(8);

    expect(etudiants.single['matricule'], 'SF-L2-0001');
    expect(presences.single['statut'], 'present');
    expect(fake.requests.map((request) => request.uri.path), [
      '/api/v1/surveillant/seances/8/etudiants',
      '/api/v1/surveillant/seances/8/presences',
    ]);
  });

  test('confirme le cours 2 avec le service du chef de promotion', () async {
    final fake = _FakeHttp([
      _success({'confirme_cours_2': true})
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final result = await const PresencesApiService().confirmerCours2(8);

    expect(result['confirme_cours_2'], isTrue);
    expect(fake.requests.single.uri.path,
        '/api/v1/chef-promotion/seances/8/confirmer-cours-2');
  });

  test('recupere les seances limitees a la promotion du chef', () async {
    final fake = _FakeHttp([
      _success({'elements': []})
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final result = await const PresencesApiService().seancesPromotion();

    expect(result, isEmpty);
    expect(fake.requests.single.uri.path, '/api/v1/chef-promotion/seances');
  });

  test('recupere les presences et le resume de l etudiant', () async {
    final fake = _FakeHttp([
      _success({
        'elements': [
          {'statut': 'absent'}
        ],
        'resume': {'taux_presence': 0.0}
      })
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final result = await const PresencesApiService().presencesEtudiant(
      statut: 'absent',
    );

    expect(result['resume']['taux_presence'], 0.0);
    expect(fake.requests.single.uri.path, '/api/v1/etudiants/moi/presences');
    expect(fake.requests.single.uri.queryParameters['statut'], 'absent');
  });

  test('recupere les seances de l enseignant et leur detail', () async {
    final fake = _FakeHttp([
      _success({'elements': []}),
      _success({'elements': []}),
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    await const PresencesApiService().seancesEnseignant(statut: 'fermee');
    await const PresencesApiService().presencesSeanceEnseignant(12);

    expect(fake.requests.map((request) => request.uri.path), [
      '/api/v1/enseignants/moi/seances',
      '/api/v1/enseignants/moi/seances/12/presences',
    ]);
  });

  test('recupere le resume de fermeture', () async {
    final fake = _FakeHttp([
      _success({'presents': 1, 'absences_creees': 2})
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final result = await const PresencesApiService().resumeSeance(12);

    expect(result['absences_creees'], 2);
    expect(
        fake.requests.single.uri.path, '/api/v1/surveillant/seances/12/resume');
  });

  test('enregistre une correction avec motif obligatoire', () async {
    final fake = _FakeHttp([
      _success({'statut': 'retard'})
    ]);
    ApiDataSource.client = ApiService(envoyer: fake.send);

    final result = await const PresencesApiService().corrigerPresence(
      seanceId: 12,
      presenceId: 21,
      nouveauStatut: 'retard',
      motif: 'Justification verifiee',
    );

    expect(result['statut'], 'retard');
    expect(fake.requests.single.methode, 'PATCH');
    expect(fake.requests.single.uri.path,
        '/api/v1/surveillant/seances/12/presences/21');
    expect(fake.requests.single.body, contains('Justification verifiee'));
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
  _RequestCapture(
      {required this.methode, required this.uri, required this.body});

  final String methode;
  final Uri uri;
  final String? body;
}

ReponseHttp _success(Map<String, dynamic> donnees) {
  return ReponseHttp(
    statusCode: 200,
    body: jsonEncode({'succes': true, 'donnees': donnees}),
    headers: const {},
  );
}
