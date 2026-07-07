import 'service_api.dart';

class PresencesApiService {
  const PresencesApiService();

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
