import 'service_api.dart';
import 'service_reclamations.dart';
import 'service_risques.dart';
import 'service_valve.dart';

class EnseignantApiService {
  const EnseignantApiService();

  Future<Map<String, dynamic>> profil() async {
    return ApiDataSource.client.get('/enseignants/moi');
  }

  Future<Map<String, dynamic>> tableauDeBord() async {
    final profil = await this.profil();
    final coursListe = await cours();
    final publicationsPayload = await ValveDataSource.service.valveEnseignant();
    final reclamationsListe = await reclamations();

    final publications =
        publicationsPayload['elements'] as List<dynamic>? ?? const [];
    return {
      'profil': {
        ...profil,
        'nom_complet': [
          profil['nom'],
          profil['postnom'],
          profil['prenom'],
        ]
            .where(
              (item) => item != null && item.toString().trim().isNotEmpty,
            )
            .join(' '),
      },
      'nombre_cours': coursListe.length,
      'nombre_total_etudiants': coursListe.fold<int>(
        0,
        (total, item) => total + (item['nombre_etudiants'] as int? ?? 0),
      ),
      'nombre_publications': publications.length,
      'publications_recentes':
          publications.map(_normaliserPublication).toList(),
      'nombre_reclamations': reclamationsListe.length,
      'nombre_reclamations_en_attente': reclamationsListe
          .where((item) => item is Map && item['statut'] == 'en_attente')
          .length,
      'statistiques_cours': coursListe,
      'dernieres_activites': const [],
      'reclamations': reclamationsListe,
    };
  }

  Future<List<dynamic>> cours() async {
    final data = await ApiDataSource.client.get('/enseignants/moi/cours');
    final elements = data['elements'] as List<dynamic>? ?? const [];
    return elements.map(_normaliserCours).toList();
  }

  Future<Map<String, dynamic>> detailCours(int id) async {
    final data = await ApiDataSource.client.get('/enseignants/moi/cours/$id');
    return _normaliserCours(data);
  }

  Future<List<dynamic>> valve() async {
    final data = await ValveDataSource.service.valveEnseignant();
    final elements = data['elements'] as List<dynamic>? ?? const [];
    return elements.map(_normaliserPublication).toList();
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
    bool publierMaintenant = true,
  }) async {
    final publication = await ValveDataSource.service.creerPublication(
      coursId: coursId,
      typePublication: typePublication,
      titre: titre,
      contenu: contenu,
      estImportante: estImportant,
      publierMaintenant: publierMaintenant,
    );
    return {'publication': publication};
  }

  Future<Map<String, dynamic>> modifierPublication({
    required int publicationId,
    String? typePublication,
    String? titre,
    String? contenu,
    String? pieceJointeUrl,
    bool? estImportant,
  }) async {
    final publication = await ValveDataSource.service.modifierPublication(
      publicationId: publicationId,
      donnees: {
        if (typePublication != null) 'type_publication': typePublication,
        if (titre != null) 'titre': titre,
        if (contenu != null) 'contenu': contenu,
        if (estImportant != null) 'est_importante': estImportant,
      },
    );
    return {'publication': publication};
  }

  Future<void> supprimerPublication(int publicationId) async {
    await ValveDataSource.service.archiverPublication(publicationId);
  }

  Future<Map<String, dynamic>> publierPublication(int publicationId) async {
    final publication =
        await ValveDataSource.service.publierPublication(publicationId);
    return {'publication': publication};
  }

  Future<List<dynamic>> etudiantsCours(int id) async {
    throw ApiException(
      'La route FastAPI de consultation des etudiants inscrits a un cours enseignant n est pas encore exposee.',
    );
  }

  Future<Map<String, dynamic>> notesCours(int id) async {
    return ApiDataSource.client.get('/enseignant/cours/$id/evaluations');
  }

  Future<Map<String, dynamic>> enregistrerBrouillon({
    required int coursId,
    required List<Map<String, dynamic>> notes,
  }) async {
    throw ApiException(
      'L encodage Flutter doit maintenant passer par une evaluation precise.',
    );
  }

  Future<Map<String, dynamic>> publierNotes(int coursId) async {
    throw ApiException(
      'La publication FastAPI se fait evaluation par evaluation.',
    );
  }

  Future<List<dynamic>> etudiantsRisque(int coursId) async {
    final data = await RisquesDataSource.service
        .risquesCoursEnseignant(coursId: coursId);
    return data['elements'] as List<dynamic>? ?? const [];
  }

  Future<List<dynamic>> reclamations() async {
    final data = await ReclamationsDataSource.service.reclamationsTraitement();
    final elements = data['elements'] as List<dynamic>? ?? const [];
    return elements.map(_normaliserReclamation).toList();
  }

  Future<Map<String, dynamic>> detailReclamation(int reclamationId) async {
    final data = await ReclamationsDataSource.service
        .detailReclamationTraitement(reclamationId);
    return _normaliserReclamation(data);
  }

  Future<Map<String, dynamic>> repondreReclamation({
    required int reclamationId,
    required String message,
    String statut = 'en_cours',
  }) async {
    await ReclamationsDataSource.service.ajouterMessageTraitement(
      reclamationId: reclamationId,
      message: message,
    );
    final reclamation = await ReclamationsDataSource.service.traiterReclamation(
      reclamationId: reclamationId,
      statut: statut == 'transmise_apparitorat' ? 'en_cours' : statut,
      reponseEtudiant: message,
    );
    return {'reclamation': _normaliserReclamation(reclamation)};
  }

  Map<String, dynamic> _normaliserCours(dynamic item) {
    if (item is! Map<String, dynamic>) return const {};
    final promotion = item['promotion'];
    final semestre = item['semestre'];
    final annee = item['annee_academique'];
    return {
      ...item,
      'nom': item['nom'] ?? item['intitule'] ?? '',
      'course': item['intitule'] ?? item['nom'] ?? '',
      'promotion_details': promotion is Map ? promotion : null,
      'promotion': promotion is Map ? promotion['nom'] ?? '' : promotion ?? '',
      'semestre_details': semestre is Map ? semestre : null,
      'semestre': semestre is Map ? semestre['nom'] ?? '' : semestre ?? '',
      'annee_academique': annee is Map ? annee['libelle'] ?? '' : annee ?? '',
      'credits': item['credits'] ?? item['nombre_credits'] ?? 0,
      'students': item['nombre_etudiants'] ?? 0,
      'publishedGrades': item['notes_publiees'] ?? 0,
      'average': item['moyenne'] ?? 0,
      'locked': item['verrouille'] ?? false,
    };
  }

  Map<String, dynamic> _normaliserPublication(dynamic item) {
    if (item is! Map<String, dynamic>) return const {};
    final cours = item['cours'] as Map?;
    return {
      ...item,
      'cours_id': cours?['id'] ?? item['cours_id'],
      'cours': cours?['intitule'] ?? cours?['code'] ?? item['cours'],
      'code_cours': cours?['code'] ?? item['code_cours'],
      'date_publication': item['publie_le'] ?? item['date_publication'],
      'est_important': item['est_importante'] ?? item['est_important'] ?? false,
    };
  }

  Map<String, dynamic> _normaliserReclamation(dynamic item) {
    if (item is! Map<String, dynamic>) return const {};
    final cours = item['cours'] as Map?;
    final etudiant = item['etudiant'] as Map?;
    return {
      ...item,
      'titre': item['objet'] ?? item['titre'] ?? '',
      'type_reclamation': item['categorie'] ?? item['type_reclamation'] ?? '',
      'code_cours': cours?['code'] ?? item['code_cours'] ?? '',
      'cours': cours?['intitule'] ?? item['cours'] ?? '',
      'cours_id': cours?['id'] ?? item['cours_id'],
      'etudiant': etudiant?['nom'] ?? item['etudiant'] ?? '',
      'reponses': item['messages'] ?? item['reponses'] ?? const [],
    };
  }
}

class EnseignantDataSource {
  static const EnseignantApiService service = EnseignantApiService();
}
