import 'service_api.dart';

class AppariteurApiService {
  const AppariteurApiService();

  Future<Map<String, dynamic>> tableauDeBord() async {
    final data =
        await ApiDataSource.client.get('/api/appariteur/tableau-de-bord');
    return data['tableau_de_bord'] as Map<String, dynamic>? ?? const {};
  }

  Future<List<dynamic>> etudiants() async {
    final data = await ApiDataSource.client.get('/api/appariteur/etudiants');
    return data['etudiants'] as List<dynamic>? ?? const [];
  }

  Future<List<dynamic>> enseignants() async {
    final data = await ApiDataSource.client.get('/api/appariteur/enseignants');
    return data['enseignants'] as List<dynamic>? ?? const [];
  }

  Future<List<dynamic>> promotions() async {
    final data = await ApiDataSource.client.get('/api/appariteur/promotions');
    return data['promotions'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> detailPromotion(int id) async {
    final data = await ApiDataSource.client.get('/api/appariteur/promotions/$id');
    return data['promotion'] as Map<String, dynamic>? ?? const {};
  }

  Future<List<dynamic>> cours() async {
    final data = await ApiDataSource.client.get('/api/appariteur/cours');
    return data['cours'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> detailCours(int id) async {
    final data = await ApiDataSource.client.get('/api/appariteur/cours/$id');
    return data['cours'] as Map<String, dynamic>? ?? const {};
  }

  Future<List<dynamic>> reclamations() async {
    final data = await ApiDataSource.client.get('/api/appariteur/reclamations');
    return data['reclamations'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> detailReclamation(int id) async {
    final data =
        await ApiDataSource.client.get('/api/appariteur/reclamations/$id');
    return data['reclamation'] as Map<String, dynamic>? ?? const {};
  }

  Future<Map<String, dynamic>> changerStatutReclamation({
    required int id,
    required String statut,
    String message = '',
  }) async {
    final data = await ApiDataSource.client.put(
      '/api/appariteur/reclamations/$id/statut',
      body: {
        'statut': statut,
        if (message.trim().isNotEmpty) 'message': message.trim(),
      },
    );
    return data['reclamation'] as Map<String, dynamic>? ?? const {};
  }

  Future<List<dynamic>> risques() async {
    final data = await ApiDataSource.client.get('/api/appariteur/risques');
    return data['risques'] as List<dynamic>? ?? const [];
  }

  Future<List<dynamic>> projets() async {
    final data = await ApiDataSource.client.get('/api/appariteur/projets');
    return data['projets'] as List<dynamic>? ?? const [];
  }

  Future<List<dynamic>> stages() async {
    final data = await ApiDataSource.client.get('/api/appariteur/stages');
    return data['stages'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> assistant() async {
    final data = await ApiDataSource.client.get('/api/appariteur/assistant');
    return data['assistant'] as Map<String, dynamic>? ?? const {};
  }

  Future<Map<String, dynamic>> rapports() async {
    return ApiDataSource.client.get('/api/appariteur/rapports');
  }
}

class AppariteurDataSource {
  static const AppariteurApiService service = AppariteurApiService();
}
