import 'service_api.dart';

class NotesApiService {
  const NotesApiService();

  Future<List<dynamic>> typesEvaluations() async {
    final data =
        await ApiDataSource.client.get('/enseignant/types-evaluations');
    return data['types'] as List<dynamic>? ?? const [];
  }

  Future<List<dynamic>> evaluationsCours(int coursId) async {
    final data = await ApiDataSource.client
        .get('/enseignant/cours/$coursId/evaluations');
    return data['evaluations'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> apercuResultatsCours(int coursId) async {
    return ApiDataSource.client
        .get('/enseignant/cours/$coursId/resultats/apercu');
  }

  Future<Map<String, dynamic>> publierResultatsCours(int coursId) async {
    return ApiDataSource.client
        .post('/enseignant/cours/$coursId/resultats/publier');
  }

  Future<Map<String, dynamic>> creerEvaluation({
    required int coursId,
    required Map<String, dynamic> donnees,
  }) async {
    final data = await ApiDataSource.client.post(
      '/enseignant/cours/$coursId/evaluations',
      body: donnees,
    );
    return data['evaluation'] as Map<String, dynamic>? ?? const {};
  }

  Future<Map<String, dynamic>> obtenirEvaluation(int evaluationId) async {
    final data =
        await ApiDataSource.client.get('/enseignant/evaluations/$evaluationId');
    return data['evaluation'] as Map<String, dynamic>? ?? const {};
  }

  Future<Map<String, dynamic>> modifierEvaluation({
    required int evaluationId,
    required Map<String, dynamic> donnees,
  }) async {
    final data = await ApiDataSource.client.put(
      '/enseignant/evaluations/$evaluationId',
      body: donnees,
    );
    return data['evaluation'] as Map<String, dynamic>? ?? const {};
  }

  Future<void> archiverEvaluation(int evaluationId) async {
    await ApiDataSource.client.delete('/enseignant/evaluations/$evaluationId');
  }

  Future<Map<String, dynamic>> notesEvaluation(int evaluationId) async {
    return ApiDataSource.client
        .get('/enseignant/evaluations/$evaluationId/notes');
  }

  Future<Map<String, dynamic>> enregistrerNotes({
    required int evaluationId,
    required List<Map<String, dynamic>> notes,
  }) async {
    return ApiDataSource.client.put(
      '/enseignant/evaluations/$evaluationId/notes',
      body: {'notes': notes},
    );
  }

  Future<Map<String, dynamic>> publierEvaluation({
    required int evaluationId,
    bool autoriserNotesManquantes = false,
  }) async {
    final data = await ApiDataSource.client.post(
      '/enseignant/evaluations/$evaluationId/publier',
      body: {'confirmer_notes_manquantes': autoriserNotesManquantes},
    );
    return data['evaluation'] as Map<String, dynamic>? ?? const {};
  }

  Future<Map<String, dynamic>> verrouillerEvaluation(int evaluationId) async {
    final data = await ApiDataSource.client.post(
      '/enseignant/evaluations/$evaluationId/verrouiller',
    );
    return data['evaluation'] as Map<String, dynamic>? ?? const {};
  }

  Future<Map<String, dynamic>> notesEtudiant() async {
    return ApiDataSource.client.get('/etudiant/notes');
  }

  Future<Map<String, dynamic>> notesCoursEtudiant(int coursId) async {
    return ApiDataSource.client.get('/etudiant/cours/$coursId/notes');
  }

  Future<Map<String, dynamic>> resultatsEtudiant() async {
    return ApiDataSource.client.get('/etudiant/resultats');
  }

  Future<List<dynamic>> semestresEtudiant() async {
    final data = await ApiDataSource.client.get('/resultats/mes-semestres');
    return data['semestres'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> apercuSemestreEtudiant(int semestreId) async {
    return ApiDataSource.client
        .get('/resultats/mes-semestres/$semestreId/apercu');
  }

  Future<List<dynamic>> etudiantsResultats() async {
    final data = await ApiDataSource.client.get('/resultats/etudiants');
    return data['etudiants'] as List<dynamic>? ?? const [];
  }

  Future<List<dynamic>> semestresResultats(int etudiantId) async {
    final data = await ApiDataSource.client
        .get('/resultats/etudiants/$etudiantId/semestres');
    return data['semestres'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> apercuSemestre({
    required int etudiantId,
    required int semestreId,
  }) async {
    return ApiDataSource.client.get(
      '/resultats/etudiants/$etudiantId/semestres/$semestreId/apercu',
    );
  }

  Future<Map<String, dynamic>> resultatOfficielSemestreEtudiant(
      int semestreId) async {
    return ApiDataSource.client
        .get('/resultats/mes-semestres/$semestreId/officiel');
  }

  Future<List<dynamic>> deliberations() async {
    final data = await ApiDataSource.client.get('/deliberations');
    return data['sessions'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> creerDeliberation({
    required int promotionId,
    required int anneeAcademiqueId,
    required int semestreId,
  }) async {
    final data = await ApiDataSource.client.post('/deliberations', body: {
      'promotion_id': promotionId,
      'annee_academique_id': anneeAcademiqueId,
      'semestre_id': semestreId,
    });
    return data['session'] as Map<String, dynamic>? ?? data;
  }

  Future<Map<String, dynamic>> deliberationGrille(int sessionId) async {
    return ApiDataSource.client.get('/deliberations/$sessionId/grille');
  }

  Future<Map<String, dynamic>> ajouterMembreDeliberation({
    required int sessionId,
    required int utilisateurId,
    required String qualite,
  }) async {
    return ApiDataSource.client
        .post('/deliberations/$sessionId/membres', body: {
      'utilisateur_id': utilisateurId,
      'qualite': qualite,
      'present': true,
    });
  }

  Future<Map<String, dynamic>> ouvrirDeliberation(int sessionId) async {
    return ApiDataSource.client.post('/deliberations/$sessionId/ouvrir');
  }

  Future<Map<String, dynamic>> enregistrerDecisionDeliberation({
    required int sessionId,
    required int etudiantId,
    required String decision,
  }) async {
    return ApiDataSource.client.post(
        '/deliberations/$sessionId/decisions/$etudiantId',
        body: {'decision': decision});
  }

  Future<Map<String, dynamic>> cloturerDeliberation(int sessionId) async {
    return ApiDataSource.client.post('/deliberations/$sessionId/cloturer');
  }

  Future<Map<String, dynamic>> publierDeliberation(int sessionId) async {
    return ApiDataSource.client.post('/deliberations/$sessionId/publier');
  }

  Future<Map<String, dynamic>> demanderReouvertureDeliberation({
    required int sessionId,
    required String motif,
  }) async {
    return ApiDataSource.client.post(
      '/deliberations/$sessionId/demander-reouverture',
      body: {'motif': motif},
    );
  }
}

class NotesDataSource {
  static const NotesApiService service = NotesApiService();
}
