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

  Future<List<dynamic>> projets() async {
    throw ApiException('Le module projets/TFC est prevu pour la version 2.');
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
