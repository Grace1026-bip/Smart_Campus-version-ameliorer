import 'service_api.dart';
import 'service_notes.dart';
import 'service_reclamations.dart';
import 'service_risques.dart';
import 'service_valve.dart';

class EtudiantApiService {
  const EtudiantApiService();

  Future<Map<String, dynamic>> tableauDeBord() async {
    return ApiDataSource.client.get('/etudiants/moi/tableau-de-bord');
  }

  Future<List<dynamic>> cours() async {
    final data = await ApiDataSource.client.get('/etudiants/moi/cours');
    final cartes = data['cours'] as List<dynamic>? ?? const [];
    return cartes.map(_normaliserCarteCours).toList();
  }

  Future<Map<String, dynamic>> historiqueAcademique() async {
    return ApiDataSource.client.get('/etudiants/moi/historique-academique');
  }

  Future<Map<String, dynamic>> detailCours(int id) async {
    final data = await ValveDataSource.service.valveCoursEtudiant(id);
    final cours = _normaliserCours(data['cours']);
    return {
      ...data,
      'cours': cours,
      ...cours,
    };
  }

  Future<List<dynamic>> valve() async {
    final data = await ValveDataSource.service.valveEtudiant();
    final cartes = data['cours'] as List<dynamic>? ?? const [];
    return cartes.map(_normaliserCarteValve).toList();
  }

  Future<Map<String, dynamic>> valveCours(int id) async {
    final data = await ValveDataSource.service.valveCoursEtudiant(id);
    final publicationsPage =
        data['publications'] as Map<String, dynamic>? ?? const {};
    final publications =
        publicationsPage['elements'] as List<dynamic>? ?? const [];
    final cours = _normaliserCours(data['cours']);

    return {
      ...data,
      'cours': cours,
      'publications': publications.map(_normaliserPublication).toList(),
    };
  }

  Future<Map<String, dynamic>> notes() async {
    return NotesDataSource.service.notesEtudiant();
  }

  Future<List<dynamic>> alertes() async {
    final data = await RisquesDataSource.service.risquesEtudiant();
    final risques = data['risques'] as List<dynamic>? ?? const [];
    return risques.map(_normaliserAlerteRisque).toList();
  }

  Future<List<dynamic>> reclamations() async {
    final data = await ReclamationsDataSource.service.reclamationsEtudiant();
    final elements = data['elements'] as List<dynamic>? ?? const [];
    return elements.map(_normaliserReclamation).toList();
  }

  Future<Map<String, dynamic>> profil() async {
    final data = await tableauDeBord();
    final profilData = data['profil'] as Map<String, dynamic>? ?? const {};
    final nomComplet = [
      profilData['nom'],
      profilData['postnom'],
      profilData['prenom'],
    ].where((item) => item != null && item.toString().trim().isNotEmpty).join(
          ' ',
        );

    return {
      ...profilData,
      'nom_complet': nomComplet,
      'email': profilData['email'],
      'statut': profilData['statut'],
      'promotion': profilData['promotion'] ?? '',
      'matricule': profilData['matricule'] ?? '',
      'annee_academique': profilData['annee_academique'] ?? '',
    };
  }

  Future<List<dynamic>> enrolements() async {
    final data = await ApiDataSource.client.get('/etudiants/moi/enrolements');
    return data['elements'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> detailEnrolement(int id) async {
    return ApiDataSource.client.get('/etudiants/moi/enrolements/$id');
  }

  Future<List<int>> telechargerFicheEnrolement(int id) async {
    return ApiDataSource.client
        .getBytes('/etudiants/moi/enrolements/$id/fiche');
  }

  Future<List<dynamic>> projetsAcademiques() async {
    final data = await ApiDataSource.client.get('/etudiants/moi/projets');
    return data['elements'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> detailProjetAcademique(int id) async {
    return ApiDataSource.client.get('/etudiants/moi/projets/$id');
  }

  Future<Map<String, dynamic>> soumettreProjet({
    required String titre,
    required String typeProjet,
    String? description,
  }) async {
    return ApiDataSource.client.post(
      '/etudiants/moi/projets',
      body: {
        'titre': titre.trim(),
        'type_projet': typeProjet,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      },
    );
  }

  Future<Map<String, dynamic>> modifierProfil(
    Map<String, dynamic> donnees,
  ) async {
    throw ApiException(
      'La modification du profil etudiant n est pas encore exposee par le backend FastAPI.',
    );
  }

  Future<Map<String, dynamic>> creerReclamation({
    required int coursId,
    int? noteId,
    required String titre,
    required String description,
    String type = 'note',
    String priorite = 'normale',
  }) async {
    final reclamation = await ReclamationsDataSource.service.creerReclamation(
      coursId: coursId,
      noteId: noteId,
      categorie: _categorieReclamation(type),
      objet: titre,
      description: description,
      priorite: _prioriteReclamation(priorite),
    );
    return {'reclamation': reclamation};
  }

  Map<String, dynamic> _normaliserCarteCours(dynamic item) {
    if (item is! Map<String, dynamic>) return const {};
    final cours = _normaliserCours(item['cours']);
    return {
      ...cours,
      'enseignant_principal': _nomEnseignant(item['enseignant_principal']),
      'assistants': item['assistants'] ?? const [],
      'nombre_publications': item['nombre_publications'] ?? 0,
      'nombre_nouveautes': item['nombre_nouveautes'] ?? 0,
      'nouveau': item['a_nouveau_contenu'] == true,
      'notes_disponibles': item['notes_disponibles'] == true,
      'derniere_publication': item['derniere_publication'],
    };
  }

  Map<String, dynamic> _normaliserCarteValve(dynamic item) {
    final carte = _normaliserCarteCours(item);
    final derniere = carte['derniere_publication'];
    return {
      ...carte,
      'publications_recentes': [
        if (derniere is Map<String, dynamic>)
          _normaliserPublication(
            derniere,
            codeCours: carte['code']?.toString(),
          ),
      ],
    };
  }

  Map<String, dynamic> _normaliserCours(dynamic item) {
    if (item is! Map<String, dynamic>) return const {};
    return {
      ...item,
      'nom': item['nom'] ?? item['intitule'] ?? '',
      'credits': item['credits'] ?? item['nombre_credits'] ?? 0,
      'promotion': item['promotion'] ?? '',
    };
  }

  Map<String, dynamic> _normaliserPublication(
    dynamic item, {
    String? codeCours,
  }) {
    if (item is! Map<String, dynamic>) return const {};
    return {
      ...item,
      'code_cours': codeCours ?? (item['cours'] as Map?)?['code'] ?? '',
      'date_publication': item['publie_le'] ?? item['date_publication'],
      'est_important': item['est_importante'] ?? item['est_important'] ?? false,
      'auteur': (item['auteur'] as Map?)?['nom'] ?? item['auteur'] ?? '',
    };
  }

  Map<String, dynamic> _normaliserReclamation(dynamic item) {
    if (item is! Map<String, dynamic>) return const {};
    final cours = item['cours'] as Map?;
    return {
      ...item,
      'titre': item['objet'] ?? item['titre'] ?? '',
      'type_reclamation': item['categorie'] ?? item['type_reclamation'] ?? '',
      'code_cours': cours?['code'] ?? item['code_cours'] ?? '',
      'cours_id': cours?['id'] ?? item['cours_id'],
      'date_creation': item['cree_le'] ?? item['date_creation'],
    };
  }

  Map<String, dynamic> _normaliserAlerteRisque(dynamic item) {
    if (item is! Map<String, dynamic>) return const {};
    final cours = item['cours'] as Map?;
    final niveauRisque = item['niveau_risque']?.toString() ?? 'faible';
    final raisons = item['raisons_detaillees'] as List<dynamic>? ?? const [];
    final score = item['score_risque']?.toString() ?? '-';

    return {
      ...item,
      'niveau': _niveauAlerte(niveauRisque),
      'titre': 'Risque academique ${_libelleNiveauRisque(niveauRisque)}',
      'message': raisons.isEmpty
          ? 'Score de risque : $score.'
          : raisons.map((raison) => raison.toString()).join(' '),
      'code_cours': cours?['code'] ?? '',
      'cours': cours?['intitule'] ?? '',
      'date_creation': item['calcule_le'],
      'lue': true,
    };
  }

  String _nomEnseignant(dynamic enseignant) {
    if (enseignant is Map<String, dynamic>) {
      return enseignant['nom']?.toString() ?? '';
    }
    return enseignant?.toString() ?? '';
  }

  String _categorieReclamation(String type) {
    switch (type) {
      case 'note':
        return 'erreur_note';
      case 'cours':
      case 'horaire':
        return 'cours';
      case 'document':
        return 'document_academique';
      default:
        return 'autre';
    }
  }

  String _prioriteReclamation(String priorite) {
    switch (priorite) {
      case 'haute':
      case 'elevee':
        return 'elevee';
      case 'urgente':
        return 'urgente';
      case 'faible':
        return 'faible';
      default:
        return 'normale';
    }
  }

  String _niveauAlerte(String niveauRisque) {
    switch (niveauRisque) {
      case 'eleve':
        return 'danger';
      case 'moyen':
        return 'attention';
      default:
        return 'info';
    }
  }

  String _libelleNiveauRisque(String niveauRisque) {
    switch (niveauRisque) {
      case 'eleve':
        return 'eleve';
      case 'moyen':
        return 'moyen';
      default:
        return 'faible';
    }
  }

}

class EtudiantDataSource {
  static const EtudiantApiService service = EtudiantApiService();
}
