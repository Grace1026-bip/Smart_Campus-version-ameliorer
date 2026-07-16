import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_tableau_de_bord.dart';
import '../../../donnees/services/service_api.dart';
import '../../../donnees/services/service_inscriptions.dart';
import '../../../donnees/services/service_reinitialisations.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/badge_statut.dart';
import '../../../commun/composants/carte_statistique.dart';
import '../../../commun/composants/composants_graphiques.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/tableau_intelligent.dart';
import '../../../commun/composants/tuile_fonctionnalite.dart';

class DeanDashboardScreen extends StatefulWidget {
  const DeanDashboardScreen({super.key});

  @override
  State<DeanDashboardScreen> createState() => _DeanDashboardScreenState();
}

class _DeanDashboardScreenState extends State<DeanDashboardScreen> {
  late Future<Map<String, dynamic>> _future =
      TableauDeBordDataSource.service.donneesDecisionnelles();

  void _refresh() {
    setState(() {
      _future = TableauDeBordDataSource.service.donneesDecisionnelles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.dean,
      selectedRoute: AppRoutes.deanDashboard,
      title: 'Tableau de bord decisionnel',
      subtitle: 'Indicateurs strategiques pour le pilotage de la faculte.',
      actions: [
        IconButton(
          tooltip: 'Actualiser',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return SectionPanel(
              title: 'Donnees indisponibles',
              subtitle: snapshot.error.toString(),
              child: Text(snapshot.error.toString()),
            );
          }

          final data = _DecisionDashboardData(snapshot.data ?? const {});

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveGrid(children: _statCards(data)),
              const SizedBox(height: 22),
              ResponsiveGrid(
                minItemWidth: 360,
                maxColumns: 2,
                children: [
                  LineChartCard(
                    title: 'Taux de reussite par promotion',
                    data: data.performancePromotionChart,
                  ),
                  BarChartCard(
                    title: 'Cours les plus difficiles',
                    data: data.coursDifficilesChart,
                  ),
                  DonutChartCard(
                    title: 'Reclamations par statut',
                    data: data.reclamationsStatutChart,
                    centerLabel: '${data.reclamationsTotal}',
                  ),
                  DonutChartCard(
                    title: 'Risques par niveau',
                    data: data.risquesNiveauChart,
                    centerLabel: '${data.risquesTotal}',
                  ),
                ],
              ),
              const SizedBox(height: 22),
              ResponsiveGrid(
                minItemWidth: 260,
                maxColumns: 4,
                children: [
                  FeatureTile(
                    icon: Icons.insights_rounded,
                    title: 'Analytics complets',
                    subtitle: 'Graphiques par cours et promotion.',
                    meta: '${data.promotions} promotion(s)',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.analytics),
                  ),
                  FeatureTile(
                    icon: Icons.health_and_safety_rounded,
                    title: 'Etudiants a risque',
                    subtitle: 'Priorites d accompagnement.',
                    meta: '${data.risquesTotal} actif(s)',
                    color: AppColors.danger,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.riskStudents),
                  ),
                  FeatureTile(
                    icon: Icons.mark_email_unread_rounded,
                    title: 'Reclamations',
                    subtitle: 'Demandes academiques.',
                    meta: '${data.reclamationsOuvertes} ouverte(s)',
                    color: AppColors.warning,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.complaints),
                  ),
                  FeatureTile(
                    icon: Icons.fact_check_rounded,
                    title: 'Notes',
                    subtitle: 'Resultats consolides.',
                    meta: '${data.resultatsTotal} resultat(s)',
                    color: AppColors.success,
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.grades,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const _DoyenWorkflowPanel(),
              const SizedBox(height: 22),
              SmartTable(
                title: 'Etudiants prioritaires',
                subtitle: '${data.risques.length} signalement(s) recent(s).',
                columns: const [
                  DataColumn(label: Text('Etudiant')),
                  DataColumn(label: Text('Promotion')),
                  DataColumn(label: Text('Cours')),
                  DataColumn(label: Text('Score')),
                  DataColumn(label: Text('Niveau')),
                  DataColumn(label: Text('Signal')),
                ],
                rows: [
                  for (final risque in data.risques)
                    DataRow(
                      cells: [
                        DataCell(Text(_nomEtudiant(risque))),
                        DataCell(Text(_promotionRisque(risque))),
                        DataCell(Text(_coursRisque(risque))),
                        DataCell(Text(_formatNumber(risque['score_risque']))),
                        DataCell(
                          StatusBadge.risk(
                            _riskLevel('${risque['niveau_risque'] ?? ''}'),
                          ),
                        ),
                        DataCell(Text(_raisonRisque(risque))),
                      ],
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DoyenWorkflowPanel extends StatefulWidget {
  const _DoyenWorkflowPanel();

  @override
  State<_DoyenWorkflowPanel> createState() => _DoyenWorkflowPanelState();
}

class _DoyenWorkflowPanelState extends State<_DoyenWorkflowPanel> {
  final _inscriptions = const ApiInscriptionService();
  final _reinitialisations = ReinitialisationsDataSource.service;
  late Future<List<dynamic>> _demandes = _inscriptions.demandesDoyen();
  late Future<List<dynamic>> _reset = _reinitialisations.demandesDoyen();

  Future<void> _actualiser() async {
    setState(() {
      _demandes = _inscriptions.demandesDoyen();
      _reset = _reinitialisations.demandesDoyen();
    });
  }

  Future<void> _approuverCompte(int id) async {
    try {
      await _inscriptions.approuverDoyen(id);
      await _actualiser();
    } on ApiException catch (error) {
      if (mounted) _message(error.messagePourUtilisateur);
    }
  }

  Future<void> _rejeterCompte(int id) async {
    final motif = await _motif('Rejeter la demande de compte');
    if (motif == null) return;
    try {
      await _inscriptions.rejeterDoyen(id, motif: motif);
      await _actualiser();
    } on ApiException catch (error) {
      if (mounted) _message(error.messagePourUtilisateur);
    }
  }

  Future<String?> _motif(String titre) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titre),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Motif'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result?.isEmpty == true ? null : result;
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: 'Demandes a traiter',
      subtitle: 'Comptes et reinitialisations soumis a validation du Doyen.',
      trailing: IconButton(
        tooltip: 'Actualiser les demandes',
        onPressed: _actualiser,
        icon: const Icon(Icons.refresh_rounded),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<List<dynamic>>(
            future: _demandes,
            builder: (context, snapshot) => _requestList(
              snapshot,
              empty: 'Aucune demande de compte en attente.',
              action: (item) => _decisionTile(
                item,
                onApprove: () => _approuverCompte(_id(item)),
                onReject: () => _rejeterCompte(_id(item)),
              ),
            ),
          ),
          const Divider(height: 28),
          FutureBuilder<List<dynamic>>(
            future: _reset,
            builder: (context, snapshot) => _requestList(
              snapshot,
              empty: 'Aucune demande de reinitialisation en attente.',
              action: (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_reset_rounded),
                title: Text('${item['email'] ?? 'Compte'}'),
                subtitle: Text('${item['statut'] ?? 'en_attente'}'),
                trailing: const Text('Traitement API'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestList(
    AsyncSnapshot<List<dynamic>> snapshot, {
    required String empty,
    required Widget Function(Map<String, dynamic>) action,
  }) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const LinearProgressIndicator();
    }
    if (snapshot.hasError) return Text('Demandes indisponibles: ${snapshot.error}');
    final items = snapshot.data ?? const [];
    if (items.isEmpty) return Text(empty);
    return Column(
      children: [
        for (final value in items)
          if (value is Map<String, dynamic>) action(value),
      ],
    );
  }

  Widget _decisionTile(
    Map<String, dynamic> item, {
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.person_add_alt_1_rounded),
      title: Text('${item['email'] ?? '-'}'),
      subtitle: Text('${item['type_demande'] ?? 'compte'} - ${item['statut'] ?? '-'}'),
      trailing: Wrap(
        spacing: 6,
        children: [
          IconButton(
            tooltip: 'Approuver',
            onPressed: onApprove,
            icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
          ),
          IconButton(
            tooltip: 'Rejeter',
            onPressed: onReject,
            icon: const Icon(Icons.cancel_outlined, color: AppColors.danger),
          ),
        ],
      ),
    );
  }

  int _id(Map<String, dynamic> item) =>
      item['id'] is num ? (item['id'] as num).toInt() : int.parse('${item['id']}');
}

List<Widget> _statCards(_DecisionDashboardData data) {
  return [
    StatCard(
      metric: KpiMetric(
        title: 'Taux de reussite',
        value: '${_formatNumber(data.tauxReussite)}%',
        trend: '${data.reussis} reussis',
        description: 'resultats publies',
      ),
      icon: Icons.trending_up_rounded,
      color: AppColors.success,
    ),
    StatCard(
      metric: KpiMetric(
        title: 'Taux d echec',
        value: '${_formatNumber(data.tauxEchec)}%',
        trend: '${data.echoues} echecs',
        description: 'cours a suivre',
      ),
      icon: Icons.trending_down_rounded,
      color: AppColors.danger,
    ),
    StatCard(
      metric: KpiMetric(
        title: 'Cours',
        value: '${data.cours}',
        trend: '${data.promotions} promotions',
        description: 'actifs dans la faculte',
      ),
      icon: Icons.grade_rounded,
      color: AppColors.primary,
    ),
    StatCard(
      metric: KpiMetric(
        title: 'Risques actifs',
        value: '${data.risquesTotal}',
        trend: '${data.risquesEleves} eleve(s)',
        description: 'faible, moyen, eleve',
      ),
      icon: Icons.health_and_safety_rounded,
      color: AppColors.warning,
    ),
  ];
}

class _DecisionDashboardData {
  const _DecisionDashboardData(this.source);

  final Map<String, dynamic> source;

  Map<String, dynamic> get resume =>
      source['resume'] as Map<String, dynamic>? ?? const {};
  Map<String, dynamic> get effectifs =>
      resume['effectifs'] as Map<String, dynamic>? ?? const {};
  Map<String, dynamic> get resultats =>
      resume['resultats'] as Map<String, dynamic>? ?? const {};
  Map<String, dynamic> get risquesResume =>
      resume['risques'] as Map<String, dynamic>? ?? const {};
  Map<String, dynamic> get reclamationsResume =>
      resume['reclamations'] as Map<String, dynamic>? ?? const {};
  Map<String, dynamic> get coursDifficiles =>
      source['cours_difficiles'] as Map<String, dynamic>? ?? const {};
  Map<String, dynamic> get performances =>
      source['performances_promotions'] as Map<String, dynamic>? ?? const {};
  Map<String, dynamic> get risquesGlobal =>
      source['risques_global'] as Map<String, dynamic>? ?? const {};

  List<dynamic> get coursDifficilesElements =>
      coursDifficiles['elements'] as List<dynamic>? ?? const [];
  List<dynamic> get performancesElements =>
      performances['elements'] as List<dynamic>? ?? const [];
  List<dynamic> get risques =>
      risquesGlobal['elements'] as List<dynamic>? ?? const [];

  int get etudiants => _asInt(effectifs['etudiants']);
  int get promotions => _asInt(effectifs['promotions']);
  int get cours => _asInt(effectifs['cours']);
  int get reussis => _asInt(resultats['reussis']);
  int get echoues => _asInt(resultats['echoues']);
  int get resultatsTotal => _asInt(resultats['total']);
  int get risquesTotal => _asInt(risquesResume['total_actifs']);
  int get risquesEleves => _asInt(risquesResume['eleve']);
  int get reclamationsTotal => _asInt(reclamationsResume['total']);
  int get reclamationsOuvertes =>
      _asInt(reclamationsResume['en_attente']) +
      _asInt(reclamationsResume['en_cours']);
  num get tauxReussite => _asNum(resultats['taux_reussite']);
  num get tauxEchec => _asNum(resultats['taux_echec']);

  List<ChartPoint> get performancePromotionChart {
    return [
      for (final item in performancesElements.take(8))
        ChartPoint(
          _promotionLabel(item),
          _asNum(_nested(item, ['resultats', 'taux_reussite'])).toDouble(),
        ),
    ];
  }

  List<ChartPoint> get coursDifficilesChart {
    return [
      for (final item in coursDifficilesElements.take(8))
        ChartPoint(
          _coursLabel(item),
          _asNum(_nested(item, ['resultats', 'taux_echec'])).toDouble(),
        ),
    ];
  }

  List<ChartPoint> get reclamationsStatutChart {
    return [
      ChartPoint(
          'Attente', _asNum(reclamationsResume['en_attente']).toDouble()),
      ChartPoint('Cours', _asNum(reclamationsResume['en_cours']).toDouble()),
      ChartPoint('Resolues', _asNum(reclamationsResume['resolues']).toDouble()),
      ChartPoint('Rejetees', _asNum(reclamationsResume['rejetees']).toDouble()),
    ];
  }

  List<ChartPoint> get risquesNiveauChart {
    return [
      ChartPoint('Faible', _asNum(risquesResume['faible']).toDouble()),
      ChartPoint('Moyen', _asNum(risquesResume['moyen']).toDouble()),
      ChartPoint('Eleve', _asNum(risquesResume['eleve']).toDouble()),
    ];
  }
}

String _nomEtudiant(Map<String, dynamic> risque) {
  final etudiant = risque['etudiant'] as Map?;
  return '${etudiant?['nom'] ?? 'Etudiant #${risque['etudiant_id'] ?? '-'}'}';
}

String _promotionRisque(Map<String, dynamic> risque) {
  final etudiant = risque['etudiant'] as Map?;
  final promotionId = etudiant?['promotion_id'];
  return promotionId == null ? '-' : 'Promotion #$promotionId';
}

String _coursRisque(Map<String, dynamic> risque) {
  final cours = risque['cours'] as Map?;
  final code = cours?['code'];
  final intitule = cours?['intitule'];
  if (code == null && intitule == null) return '-';
  return [code, intitule].whereType<Object>().join(' - ');
}

String _raisonRisque(Map<String, dynamic> risque) {
  final raisons = risque['raisons_detaillees'];
  if (raisons is! List || raisons.isEmpty) return '-';
  final premiere = raisons.first;
  if (premiere is! Map) return '$premiere';
  final critere = premiere['critere'] ?? 'signal';
  final valeur = premiere['valeur'];
  return valeur == null ? '$critere' : '$critere: $valeur';
}

RiskLevel _riskLevel(String value) {
  switch (value) {
    case 'eleve':
    case 'high':
      return RiskLevel.high;
    case 'moyen':
    case 'medium':
      return RiskLevel.medium;
    default:
      return RiskLevel.low;
  }
}

String _promotionLabel(dynamic item) {
  final promotion = item is Map ? item['promotion'] as Map? : null;
  return '${promotion?['nom'] ?? '-'}';
}

String _coursLabel(dynamic item) {
  final cours = item is Map ? item['cours'] as Map? : null;
  return '${cours?['code'] ?? cours?['intitule'] ?? '-'}';
}

dynamic _nested(dynamic source, List<String> keys) {
  var current = source;
  for (final key in keys) {
    if (current is! Map) return null;
    current = current[key];
  }
  return current;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? 0}') ?? 0;
}

num _asNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse('${value ?? 0}') ?? 0;
}

String _formatNumber(dynamic value) {
  final number = _asNum(value);
  return number.toStringAsFixed(number % 1 == 0 ? 0 : 2);
}
