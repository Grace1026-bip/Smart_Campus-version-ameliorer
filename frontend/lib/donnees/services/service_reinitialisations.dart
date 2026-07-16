import 'service_api.dart';

class ReinitialisationsApiService {
  const ReinitialisationsApiService();

  Future<List<dynamic>> demandesDoyen() async {
    final data = await ApiDataSource.client.get('/auth/mot-de-passe-oublie/demandes');
    return data['elements'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> approuverDoyen(int id) {
    return ApiDataSource.client.post('/auth/mot-de-passe-oublie/demandes/$id/approuver');
  }

  Future<Map<String, dynamic>> rejeterDoyen(int id, {String? motif}) {
    return ApiDataSource.client.post(
      '/auth/mot-de-passe-oublie/demandes/$id/rejeter',
      body: {if (motif != null && motif.trim().isNotEmpty) 'motif': motif.trim()},
    );
  }

  Future<Map<String, dynamic>> demander(String email) {
    return ApiDataSource.client.post(
      '/auth/mot-de-passe-oublie/demandes',
      body: {'email': email.trim().toLowerCase()},
    );
  }

  Future<Map<String, dynamic>> reinitialiser({
    required String reference,
    required String jeton,
    required String nouveauMotDePasse,
  }) {
    return ApiDataSource.client.post(
      '/auth/mot-de-passe-oublie/reinitialiser',
      body: {
        'reference': reference.trim(),
        'jeton': jeton.trim(),
        'nouveau_mot_de_passe': nouveauMotDePasse,
      },
    );
  }
}

class ReinitialisationsDataSource {
  static ReinitialisationsApiService service =
      const ReinitialisationsApiService();
}
