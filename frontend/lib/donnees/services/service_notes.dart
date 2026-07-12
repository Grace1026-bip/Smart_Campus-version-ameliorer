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
}

class NotesDataSource {
  static const NotesApiService service = NotesApiService();
}
