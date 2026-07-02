import 'service_api.dart';

class EtudiantApiService {
  const EtudiantApiService();

  Future<Map<String, dynamic>> tableauDeBord() async {
    final data =
        await ApiDataSource.client.get('/api/etudiant/tableau-de-bord');
    return data['tableau_de_bord'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> cours() async {
    final data = await ApiDataSource.client.get('/api/etudiant/cours');
    return data['cours'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> detailCours(int id) async {
    final data = await ApiDataSource.client.get('/api/etudiant/cours/$id');
    return data['cours'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> valve() async {
    final data = await ApiDataSource.client.get('/api/etudiant/valve');
    return data['valve'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> valveCours(int id) async {
    return ApiDataSource.client.get('/api/etudiant/valve/cours/$id');
  }

  Future<Map<String, dynamic>> notes() async {
    return ApiDataSource.client.get('/api/etudiant/notes');
  }

  Future<List<dynamic>> alertes() async {
    final data = await ApiDataSource.client.get('/api/etudiant/alertes');
    return data['alertes'] as List<dynamic>? ?? const [];
  }

  Future<List<dynamic>> reclamations() async {
    final data = await ApiDataSource.client.get('/api/etudiant/reclamations');
    return data['reclamations'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> profil() async {
    final data = await ApiDataSource.client.get('/api/etudiant/profil');
    return data['profil'] as Map<String, dynamic>? ?? const {};
  }

  Future<Map<String, dynamic>> modifierProfil(
    Map<String, dynamic> donnees,
  ) async {
    final data = await ApiDataSource.client.put(
      '/api/etudiant/profil',
      body: donnees,
    );
    return data['profil'] as Map<String, dynamic>? ?? const {};
  }

  Future<Map<String, dynamic>> creerReclamation({
    required int coursId,
    int? noteId,
    required String titre,
    required String description,
    String type = 'note',
    String priorite = 'normale',
  }) async {
    return ApiDataSource.client.post(
      '/api/etudiant/reclamations',
      body: {
        'cours_id': coursId,
        if (noteId != null) 'note_id': noteId,
        'titre': titre,
        'description': description,
        'type_reclamation': type,
        'priorite': priorite,
      },
    );
  }
}

class EtudiantDataSource {
  static const EtudiantApiService service = EtudiantApiService();
}
