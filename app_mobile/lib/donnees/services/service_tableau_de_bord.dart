import 'service_api.dart';

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
}

class TableauDeBordDataSource {
  static const TableauDeBordApiService service = TableauDeBordApiService();
}
