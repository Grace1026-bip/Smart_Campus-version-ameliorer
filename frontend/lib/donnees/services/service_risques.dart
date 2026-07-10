import 'service_api.dart';

class RisquesApiService {
  const RisquesApiService();

  Future<Map<String, dynamic>> risquesEtudiant() async {
    return ApiDataSource.client.get('/etudiant/risques');
  }

  Future<Map<String, dynamic>> risquesCoursEtudiant(int coursId) async {
    return ApiDataSource.client.get('/etudiant/cours/$coursId/risques');
  }

  Future<Map<String, dynamic>> risquesCoursEnseignant({
    required int coursId,
    int page = 1,
    int taille = 20,
    String? niveau,
  }) async {
    return ApiDataSource.client.get(
      '/enseignant/cours/$coursId/risques',
      query: {
        'page': page,
        'taille': taille,
        if (niveau != null) 'niveau': niveau,
      },
    );
  }

  Future<Map<String, dynamic>> recalculerRisquesCours(int coursId) async {
    return ApiDataSource.client
        .post('/enseignant/cours/$coursId/risques/recalculer');
  }

  Future<Map<String, dynamic>> risquesGlobal({
    int page = 1,
    int taille = 20,
    String? niveau,
    int? promotionId,
    int? coursId,
  }) async {
    return ApiDataSource.client.get(
      '/risques',
      query: {
        'page': page,
        'taille': taille,
        if (niveau != null) 'niveau': niveau,
        if (promotionId != null) 'promotion_id': promotionId,
        if (coursId != null) 'cours_id': coursId,
      },
    );
  }

  Future<Map<String, dynamic>> recalculerRisquesGlobal({
    int? promotionId,
    int? coursId,
  }) async {
    return ApiDataSource.client.post(
      '/risques/recalculer',
      body: {
        if (promotionId != null) 'promotion_id': promotionId,
        if (coursId != null) 'cours_id': coursId,
      },
    );
  }
}

class RisquesDataSource {
  static const RisquesApiService service = RisquesApiService();
}
