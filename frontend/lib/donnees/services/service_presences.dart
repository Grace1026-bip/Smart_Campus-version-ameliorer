import 'service_api.dart';

class PresencesApiService {
  const PresencesApiService();

  Future<List<dynamic>> seances({String? dateSeance}) async {
    final data = await ApiDataSource.client.get(
      '/surveillant/seances',
      query: dateSeance == null ? const {} : {'date_seance': dateSeance},
    );
    return data['elements'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> creerSeance({
    required int coursId,
    required String dateSeance,
    String? heureDebut,
    String? heureFin,
    String typeCours = 'cours_1',
  }) async {
    return ApiDataSource.client.post(
      '/surveillant/seances',
      body: {
        'cours_id': coursId,
        'date_seance': dateSeance,
        if (heureDebut != null) 'heure_debut': heureDebut,
        if (heureFin != null) 'heure_fin': heureFin,
        'type_cours': typeCours,
      },
    );
  }

  Future<Map<String, dynamic>> ouvrirSeance(int seanceId) async {
    return ApiDataSource.client.post('/surveillant/seances/$seanceId/ouvrir');
  }

  Future<Map<String, dynamic>> fermerSeance(int seanceId) async {
    return ApiDataSource.client.post('/surveillant/seances/$seanceId/fermer');
  }

  Future<List<dynamic>> etudiants(int seanceId) async {
    final data = await ApiDataSource.client
        .get('/surveillant/seances/$seanceId/etudiants');
    return data['elements'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> controlerAcces({
    required int seanceId,
    required String matricule,
    String statut = 'present',
  }) async {
    return ApiDataSource.client.post(
      '/surveillant/seances/$seanceId/controle-acces',
      body: {'matricule': matricule, 'statut': statut},
    );
  }

  Future<List<dynamic>> presences(int seanceId) async {
    final data = await ApiDataSource.client
        .get('/surveillant/seances/$seanceId/presences');
    return data['elements'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> confirmerCours2(int seanceId) async {
    return ApiDataSource.client.post(
      '/chef-promotion/seances/$seanceId/confirmer-cours-2',
    );
  }

  Future<List<dynamic>> seancesPromotion({String? dateSeance}) async {
    final data = await ApiDataSource.client.get(
      '/chef-promotion/seances',
      query: dateSeance == null ? const {} : {'date_seance': dateSeance},
    );
    return data['elements'] as List<dynamic>? ?? const [];
  }

  Future<List<dynamic>> presencesPromotion(int seanceId) async {
    final data = await ApiDataSource.client
        .get('/chef-promotion/seances/$seanceId/presences');
    return data['elements'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> enregistrerPresencesCours({
    required int coursId,
    required String dateSeance,
    required List<Map<String, dynamic>> presences,
  }) async {
    return ApiDataSource.client.post(
      '/enseignant/cours/$coursId/presences',
      body: {
        'date_seance': dateSeance,
        'presences': presences,
      },
    );
  }
}

class PresencesDataSource {
  static const PresencesApiService service = PresencesApiService();
}
