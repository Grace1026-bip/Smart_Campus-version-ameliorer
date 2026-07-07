import 'service_api.dart';

class ReclamationsApiService {
  const ReclamationsApiService();

  Future<Map<String, dynamic>> reclamationsEtudiant({
    int page = 1,
    int taille = 20,
  }) async {
    return ApiDataSource.client.get(
      '/etudiant/reclamations',
      query: {'page': page, 'taille': taille},
    );
  }

  Future<Map<String, dynamic>> creerReclamation({
    required String categorie,
    required String objet,
    required String description,
    int? coursId,
    int? noteId,
    String priorite = 'normale',
  }) async {
    final data = await ApiDataSource.client.post(
      '/etudiant/reclamations',
      body: {
        'categorie': categorie,
        'objet': objet,
        'description': description,
        if (coursId != null) 'cours_id': coursId,
        if (noteId != null) 'note_id': noteId,
        'priorite': priorite,
      },
    );
    return data['reclamation'] as Map<String, dynamic>? ?? const {};
  }

  Future<Map<String, dynamic>> detailReclamationEtudiant(int id) async {
    final data = await ApiDataSource.client.get('/etudiant/reclamations/$id');
    return data['reclamation'] as Map<String, dynamic>? ?? const {};
  }

  Future<Map<String, dynamic>> ajouterMessageEtudiant({
    required int reclamationId,
    required String message,
  }) async {
    final data = await ApiDataSource.client.post(
      '/etudiant/reclamations/$reclamationId/messages',
      body: {'message': message},
    );
    return data['message'] as Map<String, dynamic>? ?? const {};
  }

  Future<Map<String, dynamic>> reclamationsTraitement({
    int page = 1,
    int taille = 20,
    String? statut,
    String? priorite,
    String? categorie,
    int? coursId,
  }) async {
    return ApiDataSource.client.get(
      '/reclamations',
      query: {
        'page': page,
        'taille': taille,
        if (statut != null) 'statut': statut,
        if (priorite != null) 'priorite': priorite,
        if (categorie != null) 'categorie': categorie,
        if (coursId != null) 'cours_id': coursId,
      },
    );
  }

  Future<Map<String, dynamic>> detailReclamationTraitement(int id) async {
    final data = await ApiDataSource.client.get('/reclamations/$id');
    return data['reclamation'] as Map<String, dynamic>? ?? const {};
  }

  Future<Map<String, dynamic>> ajouterMessageTraitement({
    required int reclamationId,
    required String message,
    bool estInterne = false,
  }) async {
    final data = await ApiDataSource.client.post(
      '/reclamations/$reclamationId/messages',
      body: {
        'message': message,
        'est_interne': estInterne,
      },
    );
    return data['message'] as Map<String, dynamic>? ?? const {};
  }

  Future<Map<String, dynamic>> traiterReclamation({
    required int reclamationId,
    String? statut,
    String? priorite,
    int? assigneeA,
    String? commentaire,
    String? reponseEtudiant,
  }) async {
    final data = await ApiDataSource.client.put(
      '/reclamations/$reclamationId/traitement',
      body: {
        if (statut != null) 'statut': statut,
        if (priorite != null) 'priorite': priorite,
        if (assigneeA != null) 'assignee_a': assigneeA,
        if (commentaire != null && commentaire.trim().isNotEmpty)
          'commentaire': commentaire.trim(),
        if (reponseEtudiant != null && reponseEtudiant.trim().isNotEmpty)
          'reponse_etudiant': reponseEtudiant.trim(),
      },
    );
    return data['reclamation'] as Map<String, dynamic>? ?? const {};
  }
}

class ReclamationsDataSource {
  static const ReclamationsApiService service = ReclamationsApiService();
}
