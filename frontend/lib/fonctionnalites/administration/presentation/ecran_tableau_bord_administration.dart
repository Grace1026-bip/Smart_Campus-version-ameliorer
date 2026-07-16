import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_tableau_de_bord.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/badge_statut.dart';
import '../../../commun/composants/carte_statistique.dart';
import '../../../commun/composants/composants_graphiques.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/tableau_intelligent.dart';
import '../../../commun/composants/tuile_fonctionnalite.dart';
import 'ecran_gestion_administration.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
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
      role: UserRole.administrator,
      selectedRoute: AppRoutes.adminDashboard,
      title: 'Dashboard administrateur',
      subtitle: 'Vue consolidee des services academiques et administratifs.',
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

          final data = _AdminDashboardData(snapshot.data ?? const {});

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveGrid(children: _statCards(data)),
              const SizedBox(height: 22),
              ResponsiveGrid(
                minItemWidth: 260,
                maxColumns: 3,
                children: [
                  FeatureTile(
                    icon: Icons.person_search_rounded,
                    title: 'Gestion des etudiants',
                    subtitle: 'Dossiers, promotions et situation academique.',
                    meta: '${data.etudiants} profil(s)',
                    onTap: () => _openManagement(context, 'Etudiants'),
                  ),
                  FeatureTile(
                    icon: Icons.co_present_rounded,
                    title: 'Gestion des enseignants',
                    subtitle: 'Affectations, cours et responsabilites.',
                    meta: '${data.enseignants} enseignant(s)',
                    color: AppColors.cyan,
                    onTap: () => _openManagement(context, 'Enseignants'),
                  ),
                  FeatureTile(
                    icon: Icons.account_tree_rounded,
                    title: 'Gestion des promotions',
                    subtitle: 'Niveaux, cohortes et chefs de promotion.',
                    meta: '${data.promotions} promotion(s)',
                    color: AppColors.violet,
                    onTap: () => _openManagement(context, 'Promotions'),
                  ),
                  FeatureTile(
                    icon: Icons.menu_book_rounded,
                    title: 'Gestion des cours',
                    subtitle: 'Unites d enseignement, credits et titulaires.',
                    meta: '${data.cours} cours',
                    color: AppColors.success,
                    onTap: () => _openManagement(context, 'Cours'),
                  ),
                  FeatureTile(
                    icon: Icons.manage_accounts_rounded,
                    title: 'Gestion des utilisateurs',
                    subtitle: 'Roles, acces et comptes institutionnels.',
                    meta: '5 roles actifs',
                    color: AppColors.info,
                    onTap: () => _openManagement(context, 'Utilisateurs'),
                  ),
                  FeatureTile(
                    icon: Icons.insights_rounded,
                    title: 'Analytics',
                    subtitle: 'Indicateurs decisionnels de la faculte.',
                    meta: '${data.resultatsTotal} resultat(s)',
                    color: AppColors.primaryDark,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.analytics),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              ResponsiveGrid(
                minItemWidth: 360,
                maxColumns: 2,
                children: [
                  BarChartCard(
                    title: 'Performances par promotion',
                    data: data.performancePromotionChart,
                  ),
                  DonutChartCard(
                    title: 'Reclamations par statut',
                    data: data.reclamationsStatutChart,
                    centerLabel: '${data.reclamationsTotal}',
                  ),
                ],
              ),
              const SizedBox(height: 22),
              ResponsiveGrid(
                minItemWidth: 360,
                maxColumns: 2,
                children: [
                  SmartTable(
                    title: 'Reclamations recentes',
                    subtitle: '${data.reclamationsRecentes.length} demande(s).',
                    trailing: TextButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pushNamed(AppRoutes.complaints),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Ouvrir'),
                    ),
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Objet')),
                      DataColumn(label: Text('Statut')),
                      DataColumn(label: Text('Priorite')),
                    ],
                    rows: [
                      for (final item in data.reclamationsRecentes.take(6))
                        DataRow(
                          cells: [
                            DataCell(Text('${item['id'] ?? '-'}')),
                            DataCell(Text('${item['objet'] ?? '-'}')),
                            DataCell(_statusBadge('${item['statut'] ?? '-'}')),
                            DataCell(Text('${item['priorite'] ?? '-'}')),
                          ],
                        ),
                    ],
                  ),
                  SectionPanel(
                    title: 'Signaux academiques',
                    subtitle:
                        '${data.risques.length} alerte(s) prioritaire(s).',
                    child: Column(
                      children: [
                        if (data.risques.isEmpty)
                          const Text('Aucun risque academique actif.'),
                        for (final risque in data.risques.take(6))
                          _SignalLine(risque: risque),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _openManagement(BuildContext context, String category) {
    Navigator.of(context).pushNamed(
      AppRoutes.adminManagement,
      arguments: AdminManagementArgs(category),
    );
  }
}

List<Widget> _statCards(_AdminDashboardData data) {
  return [
    StatCard(
      metric: KpiMetric(
        title: 'Etudiants',
        value: '${data.etudiants}',
        trend: 'inscrits',
        description: 'profils academiques',
      ),
      icon: Icons.groups_rounded,
      color: AppColors.primary,
    ),
    StatCard(
      metric: KpiMetric(
        title: 'Enseignants',
        value: '${data.enseignants}',
        trend: 'actifs',
        description: 'comptes enseignants',
      ),
      icon: Icons.co_present_rounded,
      color: AppColors.cyan,
    ),
    StatCard(
      metric: KpiMetric(
        title: 'Cours',
        value: '${data.cours}',
        trend: '${data.promotions} promotions',
        description: 'unites suivies',
      ),
      icon: Icons.menu_book_rounded,
      color: AppColors.success,
    ),
    StatCard(
      metric: KpiMetric(
        title: 'Reclamations',
        value: '${data.reclamationsTotal}',
        trend: '${data.reclamationsOuvertes} ouvertes',
        description: 'traitement academique',
      ),
      icon: Icons.mark_email_unread_rounded,
      color: AppColors.warning,
    ),
  ];
}

class _SignalLine extends StatelessWidget {
  const _SignalLine({required this.risque});

  final Map<String, dynamic> risque;

  @override
  Widget build(BuildContext context) {
    final level = '${risque['niveau_risque'] ?? ''}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _riskColor(level).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.health_and_safety_rounded,
              color: _riskColor(level),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nomEtudiant(risque),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_coursRisque(risque)} - score ${_formatNumber(risque['score_risque'])}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge.risk(_riskLevel(level)),
        ],
      ),
    );
  }
}

class _AdminDashboardData {
  const _AdminDashboardData(this.source);

  final Map<String, dynamic> source;

  Map<String, dynamic> get resume =>
      source['resume'] as Map<String, dynamic>? ?? const {};
  Map<String, dynamic> get effectifs =>
      resume['effectifs'] as Map<String, dynamic>? ?? const {};
  Map<String, dynamic> get resultats =>
      resume['resultats'] as Map<String, dynamic>? ?? const {};
  Map<String, dynamic> get reclamationsResume =>
      resume['reclamations'] as Map<String, dynamic>? ?? const {};
  Map<String, dynamic> get performances =>
      source['performances_promotions'] as Map<String, dynamic>? ?? const {};
  Map<String, dynamic> get reclamationsTraitement =>
      source['reclamations_traitement'] as Map<String, dynamic>? ?? const {};
  Map<String, dynamic> get risquesGlobal =>
      source['risques_global'] as Map<String, dynamic>? ?? const {};

  List<dynamic> get performancesElements =>
      performances['elements'] as List<dynamic>? ?? const [];
  List<dynamic> get reclamationsRecentes =>
      reclamationsTraitement['elements'] as List<dynamic>? ?? const [];
  List<dynamic> get risques =>
      risquesGlobal['elements'] as List<dynamic>? ?? const [];

  int get etudiants => _asInt(effectifs['etudiants']);
  int get enseignants => _asInt(effectifs['enseignants']);
  int get promotions => _asInt(effectifs['promotions']);
  int get cours => _asInt(effectifs['cours']);
  int get resultatsTotal => _asInt(resultats['total']);
  int get reclamationsTotal => _asInt(reclamationsResume['total']);
  int get reclamationsOuvertes =>
      _asInt(reclamationsResume['en_attente']) +
      _asInt(reclamationsResume['en_cours']);

  List<ChartPoint> get performancePromotionChart {
    return [
      for (final item in performancesElements.take(8))
        ChartPoint(
          _promotionLabel(item),
          _asNum(_nested(item, ['resultats', 'taux_reussite'])).toDouble(),
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
}

StatusBadge _statusBadge(String status) {
  switch (status) {
    case 'en_attente':
      return const StatusBadge(label: 'En attente', color: AppColors.warning);
    case 'en_cours':
      return const StatusBadge(label: 'En cours', color: AppColors.cyan);
    case 'resolue':
      return const StatusBadge(label: 'Resolue', color: AppColors.success);
    case 'rejetee':
      return const StatusBadge(label: 'Rejetee', color: AppColors.danger);
    default:
      return StatusBadge(label: status, color: AppColors.textSecondary);
  }
}

String _nomEtudiant(Map<String, dynamic> risque) {
  final etudiant = risque['etudiant'] as Map?;
  return '${etudiant?['nom'] ?? 'Etudiant #${risque['etudiant_id'] ?? '-'}'}';
}

String _coursRisque(Map<String, dynamic> risque) {
  final cours = risque['cours'] as Map?;
  final code = cours?['code'];
  final intitule = cours?['intitule'];
  if (code == null && intitule == null) return '-';
  return [code, intitule].whereType<Object>().join(' - ');
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

Color _riskColor(String value) {
  switch (_riskLevel(value)) {
    case RiskLevel.high:
      return AppColors.danger;
    case RiskLevel.medium:
      return AppColors.warning;
    case RiskLevel.low:
      return AppColors.success;
  }
}

String _promotionLabel(dynamic item) {
  final promotion = item is Map ? item['promotion'] as Map? : null;
  return '${promotion?['nom'] ?? '-'}';
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
