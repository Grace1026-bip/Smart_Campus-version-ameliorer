import 'service_api.dart';
import 'service_reclamations.dart';
import 'service_risques.dart';
import 'service_tableau_de_bord.dart';

class AppariteurApiService {
  const AppariteurApiService();

  Future<Map<String, dynamic>> tableauDeBord() async {
    final resume = await TableauDeBordDataSource.service.resumeDecisionnel();
    final effectifs = resume['effectifs'] as Map<String, dynamic>? ?? const {};
    final reclamations =
        resume['reclamations'] as Map<String, dynamic>? ?? const {};
    final risques = resume['risques'] as Map<String, dynamic>? ?? const {};

    return {
      'nombre_etudiants': effectifs['etudiants'] ?? 0,
      'nombre_enseignants': effectifs['enseignants'] ?? 0,
      'nombre_promotions': effectifs['promotions'] ?? 0,
      'nombre_cours': effectifs['cours'] ?? 0,
      'reclamations_ouvertes':
          _asInt(reclamations['en_attente']) + _asInt(reclamations['en_cours']),
      'etudiants_a_risque': risques['total_actifs'] ?? 0,
      'projets_actifs': 0,
      'stages_actifs': 0,
      'alertes_importantes': const [],
      'dernieres_activites': const [],
      'graphiques': {
        'risques_par_promotion': const [],
        'cours_par_promotion': const [],
      },
      ...resume,
    };
  }

  Future<List<dynamic>> etudiants() async {
    final data = await ApiDataSource.client.get('/etudiants');
    return data['elements'] as List<dynamic>? ?? const [];
  }

  Future<List<dynamic>> enseignants() async {
    final data = await ApiDataSource.client.get('/enseignants');
    return data['elements'] as List<dynamic>? ?? const [];
  }

  Future<List<dynamic>> promotions() async {
    final data = await ApiDataSource.client.get('/promotions');
    return data['elements'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> detailPromotion(int id) async {
    return ApiDataSource.client.get('/promotions/$id');
  }

  Future<List<dynamic>> cours() async {
    final data = await ApiDataSource.client.get('/cours');
    return data['elements'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> enrolements({
    int page = 1,
    int taille = 20,
    String? recherche,
    int? anneeAcademiqueId,
    int? promotionId,
    String? statut,
  }) async {
    return ApiDataSource.client.get(
      '/appariteur/enrolements',
      query: {
        'page': page,
        'taille': taille,
        if (recherche != null && recherche.trim().isNotEmpty)
          'recherche': recherche.trim(),
        if (anneeAcademiqueId != null) 'annee_academique_id': anneeAcademiqueId,
        if (promotionId != null) 'promotion_id': promotionId,
        if (statut != null) 'statut': statut,
      },
    );
  }

  Future<Map<String, dynamic>> creerEnrolement({
    required int etudiantId,
    required int promotionId,
    required int anneeAcademiqueId,
    required String dateEnrolement,
  }) async {
    return ApiDataSource.client.post(
      '/appariteur/enrolements',
      body: {
        'etudiant_id': etudiantId,
        'promotion_id': promotionId,
        'annee_academique_id': anneeAcademiqueId,
        'date_enrolement': dateEnrolement,
      },
    );
  }

  Future<Map<String, dynamic>> detailEnrolement(int id) async {
    return ApiDataSource.client.get('/appariteur/enrolements/$id');
  }

  Future<Map<String, dynamic>> modifierEnrolement(
    int id, {
    int? etudiantId,
    int? promotionId,
    int? anneeAcademiqueId,
    String? dateEnrolement,
  }) async {
    return ApiDataSource.client.patch(
      '/appariteur/enrolements/$id',
      body: {
        if (etudiantId != null) 'etudiant_id': etudiantId,
        if (promotionId != null) 'promotion_id': promotionId,
        if (anneeAcademiqueId != null) 'annee_academique_id': anneeAcademiqueId,
        if (dateEnrolement != null) 'date_enrolement': dateEnrolement,
      },
    );
  }

  Future<Map<String, dynamic>> validerEnrolement(int id) async {
    return ApiDataSource.client.post('/appariteur/enrolements/$id/valider');
  }

  Future<Map<String, dynamic>> annulerEnrolement(
    int id, {
    String? motif,
  }) async {
    return ApiDataSource.client.post(
      '/appariteur/enrolements/$id/annuler',
      body: {
        if (motif != null && motif.trim().isNotEmpty) 'motif': motif.trim()
      },
    );
  }

  Future<Map<String, dynamic>> donneesFicheEnrolement(int id) async {
    return ApiDataSource.client
        .get('/appariteur/enrolements/$id/fiche/donnees');
  }

  Future<Map<String, dynamic>> detailCours(int id) async {
    return ApiDataSource.client.get('/cours/$id');
  }

  Future<List<dynamic>> reclamations() async {
    final data = await ReclamationsDataSource.service.reclamationsTraitement();
    final elements = data['elements'] as List<dynamic>? ?? const [];
    return elements.map(_normaliserReclamation).toList();
  }

  Future<Map<String, dynamic>> detailReclamation(int id) async {
    final data =
        await ReclamationsDataSource.service.detailReclamationTraitement(id);
    return _normaliserReclamation(data);
  }

  Future<Map<String, dynamic>> changerStatutReclamation({
    required int id,
    required String statut,
    String message = '',
  }) async {
    final reclamation = await ReclamationsDataSource.service.traiterReclamation(
      reclamationId: id,
      statut: statut,
      commentaire: message.trim().isEmpty ? null : message.trim(),
      reponseEtudiant: message.trim().isEmpty ? null : message.trim(),
    );
    return _normaliserReclamation(reclamation);
  }

  Future<List<dynamic>> risques() async {
    final data = await RisquesDataSource.service.risquesGlobal();
    return data['elements'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> projets({
    String? typeProjet,
    int? promotionId,
    int? anneeAcademiqueId,
    String? statut,
    int? etudiantId,
    int? enseignantId,
    String? recherche,
    bool sansEncadreur = false,
    bool avecEncadreur = false,
  }) async {
    return ApiDataSource.client.get(
      '/appariteur/projets',
      query: {
        if (typeProjet != null) 'type_projet': typeProjet,
        if (promotionId != null) 'promotion_id': promotionId,
        if (anneeAcademiqueId != null) 'annee_academique_id': anneeAcademiqueId,
        if (statut != null) 'statut': statut,
        if (etudiantId != null) 'etudiant_id': etudiantId,
        if (enseignantId != null) 'enseignant_id': enseignantId,
        if (recherche != null && recherche.trim().isNotEmpty)
          'recherche': recherche.trim(),
        if (sansEncadreur) 'sans_encadreur': true,
        if (avecEncadreur) 'avec_encadreur': true,
      },
    );
  }

  Future<Map<String, dynamic>> creerProjet({
    required int etudiantId,
    required String titre,
    required String typeProjet,
    String? description,
  }) async {
    return ApiDataSource.client.post(
      '/appariteur/projets',
      body: {
        'etudiant_id': etudiantId,
        'titre': titre.trim(),
        'type_projet': typeProjet,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      },
    );
  }

  Future<Map<String, dynamic>> detailProjet(int id) async {
    return ApiDataSource.client.get('/appariteur/projets/$id');
  }

  Future<Map<String, dynamic>> decisionProjet({
    required int projetId,
    required String action,
    String? motif,
  }) async {
    return ApiDataSource.client.post(
      '/appariteur/projets/$projetId/decision',
      body: {
        'action': action,
        if (motif != null && motif.trim().isNotEmpty) 'motif': motif.trim(),
      },
    );
  }

  Future<Map<String, dynamic>> modifierProjet(
    int id, {
    String? titre,
    String? typeProjet,
    String? description,
    String? statut,
  }) async {
    return ApiDataSource.client.patch(
      '/appariteur/projets/$id',
      body: {
        if (titre != null) 'titre': titre.trim(),
        if (typeProjet != null) 'type_projet': typeProjet,
        if (description != null) 'description': description.trim(),
        if (statut != null) 'statut': statut,
      },
    );
  }

  Future<Map<String, dynamic>> archiverProjet(int id) async {
    return ApiDataSource.client.post('/appariteur/projets/$id/archiver');
  }

  Future<Map<String, dynamic>> enseignantsEncadreurs({
    String? typeProjet,
    String? recherche,
  }) async {
    return ApiDataSource.client.get(
      '/appariteur/enseignants-encadreurs',
      query: {
        if (typeProjet != null) 'type_projet': typeProjet,
        if (recherche != null && recherche.trim().isNotEmpty)
          'recherche': recherche.trim(),
      },
    );
  }

  Future<Map<String, dynamic>> specialitesEnseignant(int enseignantId) async {
    return ApiDataSource.client
        .get('/appariteur/enseignants-encadreurs/$enseignantId/specialites');
  }

  Future<Map<String, dynamic>> configurerSpecialites({
    required int enseignantId,
    required List<String> typesProjet,
  }) async {
    return ApiDataSource.client.put(
      '/appariteur/enseignants-encadreurs/$enseignantId/specialites',
      body: {'types_projet': typesProjet},
    );
  }

  Future<Map<String, dynamic>> attribuerEncadrement({
    required int projetId,
    required int enseignantId,
    required String roleEncadrement,
    bool remplacerPrincipal = false,
  }) async {
    return ApiDataSource.client.post(
      '/appariteur/projets/$projetId/encadrements',
      body: {
        'enseignant_id': enseignantId,
        'role_encadrement': roleEncadrement,
        if (remplacerPrincipal) 'remplacer_principal': true,
      },
    );
  }

  Future<Map<String, dynamic>> modifierEncadrement({
    required int projetId,
    required int encadrementId,
    required String roleEncadrement,
  }) async {
    return ApiDataSource.client.patch(
      '/appariteur/projets/$projetId/encadrements/$encadrementId',
      body: {'role_encadrement': roleEncadrement},
    );
  }

  Future<Map<String, dynamic>> desactiverEncadrement({
    required int projetId,
    required int encadrementId,
  }) async {
    return ApiDataSource.client.post(
      '/appariteur/projets/$projetId/encadrements/$encadrementId/desactiver',
    );
  }

  Future<List<dynamic>> stages() async {
    throw ApiException('Le module stages est prevu pour la version 2.');
  }

  Future<Map<String, dynamic>> assistant() async {
    throw ApiException(
        'L assistant IA academique est prevu pour la version 2.');
  }

  Future<Map<String, dynamic>> rapports() async {
    return {
      'resume': await TableauDeBordDataSource.service.resumeDecisionnel(),
      'cours_difficiles':
          await TableauDeBordDataSource.service.coursDifficiles(),
      'performances_promotions':
          await TableauDeBordDataSource.service.performancesPromotions(),
      'reclamations': await TableauDeBordDataSource.service.reclamations(),
      'risques': await TableauDeBordDataSource.service.risques(),
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

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? 0}') ?? 0;
  }
}

class AppariteurDataSource {
  static const AppariteurApiService service = AppariteurApiService();
}
