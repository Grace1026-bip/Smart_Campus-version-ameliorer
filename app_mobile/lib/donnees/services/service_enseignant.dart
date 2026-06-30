import 'service_api.dart';

class EnseignantApiService {
  const EnseignantApiService();

  Future<Map<String, dynamic>> tableauDeBord() async {
    final data =
        await ApiDataSource.client.get('/api/enseignant/tableau-de-bord');
    return data['tableau_de_bord'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> cours() async {
    final data = await ApiDataSource.client.get('/api/enseignant/cours');
    return data['cours'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> detailCours(int id) async {
    final data = await ApiDataSource.client.get('/api/enseignant/cours/$id');
    return data['cours'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> valve() async {
    final data = await ApiDataSource.client.get('/api/enseignant/valve');
    return data['publications'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> creerPublication({
    required int coursId,
    required String typePublication,
    required String titre,
    required String contenu,
    String? pieceJointeUrl,
    String? pieceJointeNom,
    String? pieceJointeBase64,
    bool estImportant = false,
  }) async {
    return ApiDataSource.client.post(
      '/api/enseignant/valve/publication',
      body: {
        'cours_id': coursId,
        'type_publication': typePublication,
        'titre': titre,
        'contenu': contenu,
        'piece_jointe_url': pieceJointeUrl,
        'piece_jointe_nom': pieceJointeNom,
        'piece_jointe_base64': pieceJointeBase64,
        'est_important': estImportant,
      },
    );
  }

  Future<Map<String, dynamic>> modifierPublication({
    required int publicationId,
    String? typePublication,
    String? titre,
    String? contenu,
    String? pieceJointeUrl,
    bool? estImportant,
  }) async {
    return ApiDataSource.client.put(
      '/api/enseignant/valve/publication/$publicationId',
      body: {
        if (typePublication != null) 'type_publication': typePublication,
        if (titre != null) 'titre': titre,
        if (contenu != null) 'contenu': contenu,
        if (pieceJointeUrl != null) 'piece_jointe_url': pieceJointeUrl,
        if (estImportant != null) 'est_important': estImportant,
      },
    );
  }

  Future<void> supprimerPublication(int publicationId) async {
    await ApiDataSource.client
        .delete('/api/enseignant/valve/publication/$publicationId');
  }

  Future<List<dynamic>> etudiantsCours(int id) async {
    final data =
        await ApiDataSource.client.get('/api/enseignant/cours/$id/etudiants');
    return data['etudiants'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> notesCours(int id) async {
    return ApiDataSource.client.get('/api/enseignant/cours/$id/notes');
  }

  Future<Map<String, dynamic>> enregistrerBrouillon({
    required int coursId,
    required List<Map<String, dynamic>> notes,
  }) async {
    return ApiDataSource.client.post(
      '/api/enseignant/cours/$coursId/notes/brouillon',
      body: {'notes': notes},
    );
  }

  Future<Map<String, dynamic>> publierNotes(int coursId) async {
    return ApiDataSource.client.post(
      '/api/enseignant/cours/$coursId/notes/publier',
    );
  }

  Future<List<dynamic>> etudiantsRisque(int coursId) async {
    final data = await ApiDataSource.client
        .get('/api/enseignant/cours/$coursId/etudiants-a-risque');
    return data['etudiants_a_risque'] as List<dynamic>? ?? const [];
  }

  Future<List<dynamic>> reclamations() async {
    final data = await ApiDataSource.client.get('/api/enseignant/reclamations');
    return data['reclamations'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> detailReclamation(int reclamationId) async {
    final data = await ApiDataSource.client
        .get('/api/enseignant/reclamations/$reclamationId');
    return data['reclamation'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> repondreReclamation({
    required int reclamationId,
    required String message,
    String statut = 'en_cours',
  }) async {
    return ApiDataSource.client.post(
      '/api/enseignant/reclamations/$reclamationId/repondre',
      body: {
        'message': message,
        'statut': statut,
      },
    );
  }
}

class EnseignantDataSource {
  static const EnseignantApiService service = EnseignantApiService();
}
