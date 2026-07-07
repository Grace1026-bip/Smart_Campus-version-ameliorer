import 'service_api.dart';

class ValveApiService {
  const ValveApiService();

  Future<Map<String, dynamic>> valveEnseignant({
    int page = 1,
    int taille = 20,
    String? recherche,
    int? coursId,
    String? typePublication,
    String? statut,
  }) async {
    return ApiDataSource.client.get(
      '/enseignant/valve',
      query: {
        'page': page,
        'taille': taille,
        if (recherche != null && recherche.trim().isNotEmpty)
          'recherche': recherche.trim(),
        if (coursId != null) 'cours_id': coursId,
        if (typePublication != null) 'type_publication': typePublication,
        if (statut != null) 'statut': statut,
      },
    );
  }

  Future<Map<String, dynamic>> creerPublication({
    required int coursId,
    required String typePublication,
    required String titre,
    required String contenu,
    bool estImportante = false,
    bool publierMaintenant = false,
  }) async {
    final data = await ApiDataSource.client.post(
      '/enseignant/valve/publications',
      body: {
        'cours_id': coursId,
        'type_publication': typePublication,
        'titre': titre,
        'contenu': contenu,
        'est_importante': estImportante,
        'publier_maintenant': publierMaintenant,
      },
    );
    return data['publication'] as Map<String, dynamic>? ?? const {};
  }

  Future<Map<String, dynamic>> obtenirPublicationEnseignant(
    int publicationId,
  ) async {
    final data = await ApiDataSource.client
        .get('/enseignant/valve/publications/$publicationId');
    return data['publication'] as Map<String, dynamic>? ?? const {};
  }

  Future<Map<String, dynamic>> modifierPublication({
    required int publicationId,
    required Map<String, dynamic> donnees,
  }) async {
    final data = await ApiDataSource.client.put(
      '/enseignant/valve/publications/$publicationId',
      body: donnees,
    );
    return data['publication'] as Map<String, dynamic>? ?? const {};
  }

  Future<Map<String, dynamic>> publierPublication(int publicationId) async {
    final data = await ApiDataSource.client
        .post('/enseignant/valve/publications/$publicationId/publier');
    return data['publication'] as Map<String, dynamic>? ?? const {};
  }

  Future<Map<String, dynamic>> archiverPublication(int publicationId) async {
    final data = await ApiDataSource.client
        .post('/enseignant/valve/publications/$publicationId/archiver');
    return data['publication'] as Map<String, dynamic>? ?? const {};
  }

  Future<void> supprimerPublication(int publicationId) async {
    await archiverPublication(publicationId);
  }

  Future<Map<String, dynamic>> valveEtudiant() async {
    return ApiDataSource.client.get('/etudiant/valve');
  }

  Future<Map<String, dynamic>> valveCoursEtudiant(int coursId) async {
    return ApiDataSource.client.get('/etudiant/valve/cours/$coursId');
  }

  Future<Map<String, dynamic>> obtenirPublicationEtudiant(
    int publicationId,
  ) async {
    final data = await ApiDataSource.client
        .get('/etudiant/valve/publications/$publicationId');
    return data['publication'] as Map<String, dynamic>? ?? const {};
  }
}

class ValveDataSource {
  static const ValveApiService service = ValveApiService();
}
