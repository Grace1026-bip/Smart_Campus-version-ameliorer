import 'service_api.dart';
import 'service_reclamations.dart';
import 'service_risques.dart';

class TableauDeBordApiService {
  const TableauDeBordApiService();

  Future<Map<String, dynamic>> resumeDecisionnel() async {
    return ApiDataSource.client.get('/dashboard/resume');
  }

  Future<Map<String, dynamic>> coursDifficiles({
    int page = 1,
    int taille = 20,
    int? promotionId,
  }) async {
    return ApiDataSource.client.get(
      '/dashboard/cours-difficiles',
      query: {
        'page': page,
        'taille': taille,
        if (promotionId != null) 'promotion_id': promotionId,
      },
    );
  }

  Future<Map<String, dynamic>> performancesPromotions({
    int page = 1,
    int taille = 20,
  }) async {
    return ApiDataSource.client.get(
      '/dashboard/performances-promotions',
      query: {'page': page, 'taille': taille},
    );
  }

  Future<Map<String, dynamic>> reclamations() async {
    return ApiDataSource.client.get('/dashboard/reclamations');
  }

  Future<Map<String, dynamic>> risques({String? niveau}) async {
    return ApiDataSource.client.get(
      '/dashboard/risques',
      query: {
        if (niveau != null) 'niveau': niveau,
      },
    );
  }

  Future<Map<String, dynamic>> donneesDecisionnelles() async {
    final resultats = await Future.wait<Map<String, dynamic>>([
      resumeDecisionnel(),
      coursDifficiles(),
      performancesPromotions(),
      reclamations(),
      risques(),
      RisquesDataSource.service.risquesGlobal(taille: 10),
      ReclamationsDataSource.service.reclamationsTraitement(taille: 10),
    ]);

    return {
      'resume': resultats[0],
      'cours_difficiles': resultats[1],
      'performances_promotions': resultats[2],
      'reclamations_dashboard': resultats[3],
      'risques_dashboard': resultats[4],
      'risques_global': resultats[5],
      'reclamations_traitement': resultats[6],
    };
  }
}

class TableauDeBordDataSource {
  static const TableauDeBordApiService service = TableauDeBordApiService();
}
