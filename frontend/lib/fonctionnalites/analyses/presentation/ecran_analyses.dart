import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/donnees_fictives/donnees_faculte_fictives.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_session.dart';
import '../../../donnees/services/service_tableau_de_bord.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/composants_graphiques.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/tableau_intelligent.dart';
import '../../../commun/composants/carte_statistique.dart';
import '../../../commun/composants/badge_statut.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _promotion = 'Toutes';
  String _period = 'Semestre actuel';

  @override
  Widget build(BuildContext context) {
    final role = SessionService.currentRole;
    if (_usesDecisionApi(role)) {
      return _DecisionAnalyticsScreen(role: role);
    }

    final riskStudents = _riskStudentsFor(role);

    return SmartFacultyShell(
      role: role,
      selectedRoute: AppRoutes.analytics,
      title: _titleFor(role),
      subtitle: _subtitleFor(role),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionPanel(
            title: 'Filtres',
            subtitle: 'Vue limitee au perimetre du compte.',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: _promotion,
                    decoration: const InputDecoration(labelText: 'Promotion'),
                    items: const [
                      DropdownMenuItem(value: 'Toutes', child: Text('Toutes')),
                      DropdownMenuItem(value: 'L1', child: Text('L1')),
                      DropdownMenuItem(value: 'L2', child: Text('L2')),
                      DropdownMenuItem(value: 'L3', child: Text('L3')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _promotion = value);
                    },
                  ),
                ),
                SizedBox(
                  width: 230,
                  child: DropdownButtonFormField<String>(
                    initialValue: _period,
                    decoration: const InputDecoration(labelText: 'Periode'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Semestre actuel',
                        child: Text('Semestre actuel'),
                      ),
                      DropdownMenuItem(value: 'Annee', child: Text('Annee')),
                      DropdownMenuItem(value: 'Jury', child: Text('Jury')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _period = value);
                    },
                  ),
                ),
                StatusBadge(
                  label: 'Vue: $_promotion / $_period',
                  color: AppColors.primary,
                  icon: Icons.filter_alt_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          ResponsiveGrid(children: _statsFor(role)),
          const SizedBox(height: 22),
          ResponsiveGrid(
            minItemWidth: 360,
            maxColumns: 2,
            children: _chartsFor(role),
          ),
          const SizedBox(height: 22),
          SmartTable(
            title: _tableTitleFor(role),
            subtitle: 'Donnees visibles selon le perimetre du compte.',
            columns: const [
              DataColumn(label: Text('Nom')),
              DataColumn(label: Text('Promotion')),
              DataColumn(label: Text('Moyenne')),
              DataColumn(label: Text('Echecs')),
              DataColumn(label: Text('Risque')),
            ],
            rows: [
              for (final student in riskStudents)
                DataRow(
                  cells: [
                    DataCell(Text(student.name)),
                    DataCell(Text(student.promotion)),
                    DataCell(Text(student.average.toStringAsFixed(1))),
                    DataCell(Text('${student.failures}')),
                    DataCell(StatusBadge.risk(student.level)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DecisionAnalyticsScreen extends StatefulWidget {
  const _DecisionAnalyticsScreen({required this.role});

  final UserRole role;

  @override
  State<_DecisionAnalyticsScreen> createState() =>
      _DecisionAnalyticsScreenState();
}

class _DecisionAnalyticsScreenState extends State<_DecisionAnalyticsScreen> {
  late Future<Map<String, dynamic>> _future =
      TableauDeBordDataSource.service.donneesDecisionnelles();
  String? _riskLevel;

  void _refresh() {
    setState(() {
      _future = TableauDeBordDataSource.service.donneesDecisionnelles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: widget.role,
      selectedRoute: AppRoutes.analytics,
      title: _titleFor(widget.role),
      subtitle: _subtitleFor(widget.role),
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
              title: 'Connexion API impossible',
              subtitle: snapshot.error.toString(),
              child: const Text(ApiConfig.serverUnavailableMessage),
            );
          }

          final data = _DecisionAnalyticsData(snapshot.data ?? const {});
          final risques = data.risques.where((risque) {
            return _riskLevel == null || risque['niveau_risque'] == _riskLevel;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionPanel(
                title: 'Filtres',
                subtitle: '${risques.length} risque(s) affiche(s).',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ChoiceChip(
                      label: const Text('Tous'),
                      selected: _riskLevel == null,
                      onSelected: (_) => setState(() => _riskLevel = null),
                    ),
                    ChoiceChip(
                      label: const Text('Faible'),
                      selected: _riskLevel == 'faible',
                      onSelected: (_) => setState(() => _riskLevel = 'faible'),
                    ),
                    ChoiceChip(
                      label: const Text('Moyen'),
                      selected: _riskLevel == 'moyen',
                      onSelected: (_) => setState(() => _riskLevel = 'moyen'),
                    ),
                    ChoiceChip(
                      label: const Text('Eleve'),
                      selected: _riskLevel == 'eleve',
                      onSelected: (_) => setState(() => _riskLevel = 'eleve'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              ResponsiveGrid(children: _decisionStats(data)),
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
                    title: 'Taux d echec par cours',
                    data: data.coursDifficilesChart,
                  ),
                  DonutChartCard(
                    title: 'Reclamations par categorie',
                    data: data.reclamationsCategorieChart,
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
                minItemWidth: 420,
                maxColumns: 2,
                children: [
                  SmartTable(
                    title: 'Cours difficiles',
                    subtitle:
                        '${data.coursDifficiles.length} cours analyse(s).',
                    columns: const [
                      DataColumn(label: Text('Cours')),
                      DataColumn(label: Text('Inscrits')),
                      DataColumn(label: Text('Reussite')),
                      DataColumn(label: Text('Echec')),
                      DataColumn(label: Text('Risques')),
                    ],
                    rows: [
                      for (final item in data.coursDifficiles.take(8))
                        DataRow(
                          cells: [
                            DataCell(Text(_apiCoursLabel(item))),
                            DataCell(Text('${item['inscrits'] ?? 0}')),
                            DataCell(
                              Text(
                                '${_apiFormatNumber(_apiNested(item, [
                                      'resultats',
                                      'taux_reussite'
                                    ]))}%',
                              ),
                            ),
                            DataCell(
                              Text(
                                '${_apiFormatNumber(_apiNested(item, [
                                      'resultats',
                                      'taux_echec'
                                    ]))}%',
                              ),
                            ),
                            DataCell(
                              Text(
                                '${_apiNested(item, [
                                          'risques_actifs',
                                          'total'
                                        ]) ?? 0}',
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  SmartTable(
                    title: 'Risques prioritaires',
                    subtitle: '${risques.length} signalement(s).',
                    columns: const [
                      DataColumn(label: Text('Etudiant')),
                      DataColumn(label: Text('Cours')),
                      DataColumn(label: Text('Score')),
                      DataColumn(label: Text('Niveau')),
                      DataColumn(label: Text('Signal')),
                    ],
                    rows: [
                      for (final risque in risques)
                        DataRow(
                          cells: [
                            DataCell(Text(_apiNomEtudiant(risque))),
                            DataCell(Text(_apiCoursRisque(risque))),
                            DataCell(
                              Text(_apiFormatNumber(risque['score_risque'])),
                            ),
                            DataCell(
                              StatusBadge.risk(
                                _apiRiskLevel(
                                  '${risque['niveau_risque'] ?? ''}',
                                ),
                              ),
                            ),
                            DataCell(Text(_apiRaisonRisque(risque))),
                          ],
                        ),
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

List<Widget> _decisionStats(_DecisionAnalyticsData data) {
  return [
    StatCard(
      metric: KpiMetric(
        title: 'Taux de reussite',
        value: '${_apiFormatNumber(data.tauxReussite)}%',
        trend: '${data.reussis} reussis',
        description: 'resultats publies',
      ),
      icon: Icons.trending_up_rounded,
      color: AppColors.success,
    ),
    StatCard(
      metric: KpiMetric(
        title: 'Taux d echec',
        value: '${_apiFormatNumber(data.tauxEchec)}%',
        trend: '${data.echoues} echecs',
        description: 'cours sensibles',
      ),
      icon: Icons.trending_down_rounded,
      color: AppColors.danger,
    ),
    StatCard(
      metric: KpiMetric(
        title: 'Risques actifs',
        value: '${data.risquesTotal}',
        trend: '${data.risquesEleves} eleve(s)',
        description: 'detection precoce',
      ),
      icon: Icons.health_and_safety_rounded,
      color: AppColors.warning,
    ),
    StatCard(
      metric: KpiMetric(
        title: 'Reclamations',
        value: '${data.reclamationsTotal}',
        trend: '${data.reclamationsOuvertes} ouvertes',
        description: 'suivi academique',
      ),
      icon: Icons.mark_email_unread_rounded,
      color: AppColors.primary,
    ),
  ];
}

class _DecisionAnalyticsData {
  const _DecisionAnalyticsData(this.source);

  final Map<String, dynamic> source;

  Map<String, dynamic> get resume =>
      source['resume'] as Map<String, dynamic>? ?? const {};
  Map<String, dynamic> get resultats =>
      resume['resultats'] as Map<String, dynamic>? ?? const {};
  Map<String, dynamic> get risquesResume =>
      resume['risques'] as Map<String, dynamic>? ?? const {};
  Map<String, dynamic> get reclamationsResume =>
      resume['reclamations'] as Map<String, dynamic>? ?? const {};
  Map<String, dynamic> get coursDifficilesPayload =>
      source['cours_difficiles'] as Map<String, dynamic>? ?? const {};
  Map<String, dynamic> get performancesPayload =>
      source['performances_promotions'] as Map<String, dynamic>? ?? const {};
  Map<String, dynamic> get reclamationsPayload =>
      source['reclamations_dashboard'] as Map<String, dynamic>? ?? const {};
  Map<String, dynamic> get risquesGlobalPayload =>
      source['risques_global'] as Map<String, dynamic>? ?? const {};

  List<dynamic> get coursDifficiles =>
      coursDifficilesPayload['elements'] as List<dynamic>? ?? const [];
  List<dynamic> get performances =>
      performancesPayload['elements'] as List<dynamic>? ?? const [];
  List<dynamic> get risques =>
      risquesGlobalPayload['elements'] as List<dynamic>? ?? const [];
  Map<String, dynamic> get categories =>
      reclamationsPayload['par_categorie'] as Map<String, dynamic>? ?? const {};

  int get reussis => _apiAsInt(resultats['reussis']);
  int get echoues => _apiAsInt(resultats['echoues']);
  int get risquesTotal => _apiAsInt(risquesResume['total_actifs']);
  int get risquesEleves => _apiAsInt(risquesResume['eleve']);
  int get reclamationsTotal => _apiAsInt(reclamationsResume['total']);
  int get reclamationsOuvertes =>
      _apiAsInt(reclamationsResume['en_attente']) +
      _apiAsInt(reclamationsResume['en_cours']);
  num get tauxReussite => _apiAsNum(resultats['taux_reussite']);
  num get tauxEchec => _apiAsNum(resultats['taux_echec']);

  List<ChartPoint> get performancePromotionChart {
    return [
      for (final item in performances.take(8))
        ChartPoint(
          _apiPromotionLabel(item),
          _apiAsNum(_apiNested(item, ['resultats', 'taux_reussite']))
              .toDouble(),
        ),
    ];
  }

  List<ChartPoint> get coursDifficilesChart {
    return [
      for (final item in coursDifficiles.take(8))
        ChartPoint(
          _apiCoursLabel(item),
          _apiAsNum(_apiNested(item, ['resultats', 'taux_echec'])).toDouble(),
        ),
    ];
  }

  List<ChartPoint> get reclamationsCategorieChart {
    return [
      ChartPoint('Notes', _apiAsNum(categories['erreur_note']).toDouble()),
      ChartPoint(
          'Inscription', _apiAsNum(categories['inscription']).toDouble()),
      ChartPoint('Cours', _apiAsNum(categories['cours']).toDouble()),
      ChartPoint(
          'Document', _apiAsNum(categories['document_academique']).toDouble()),
      ChartPoint('Autre', _apiAsNum(categories['autre']).toDouble()),
    ];
  }

  List<ChartPoint> get risquesNiveauChart {
    return [
      ChartPoint('Faible', _apiAsNum(risquesResume['faible']).toDouble()),
      ChartPoint('Moyen', _apiAsNum(risquesResume['moyen']).toDouble()),
      ChartPoint('Eleve', _apiAsNum(risquesResume['eleve']).toDouble()),
    ];
  }
}

List<Widget> _statsFor(UserRole role) {
  switch (role) {
    case UserRole.teacher:
      return [
        StatCard(
          metric: MockFacultyData.teacherKpis[0],
          icon: Icons.menu_book_rounded,
          color: AppColors.primary,
        ),
        StatCard(
          metric: MockFacultyData.teacherKpis[1],
          icon: Icons.fact_check_rounded,
          color: AppColors.success,
        ),
        const StatCard(
          metric: KpiMetric(
            title: 'Cours fragile',
            value: 'Reseaux',
            trend: '58%',
            description: 'reussite estimee',
          ),
          icon: Icons.warning_amber_rounded,
          color: AppColors.warning,
        ),
        const StatCard(
          metric: KpiMetric(
            title: 'Reclamations',
            value: '1',
            trend: 'note',
            description: 'a verifier',
          ),
          icon: Icons.rate_review_rounded,
          color: AppColors.cyan,
        ),
      ];
    case UserRole.promotionChief:
      return [
        for (var i = 0; i < MockFacultyData.promotionKpis.length; i++)
          StatCard(
            metric: MockFacultyData.promotionKpis[i],
            icon: [
              Icons.groups_rounded,
              Icons.grade_rounded,
              Icons.health_and_safety_rounded,
              Icons.mark_email_unread_rounded,
            ][i],
            color: [
              AppColors.primary,
              AppColors.success,
              AppColors.danger,
              AppColors.warning,
            ][i],
          ),
      ];
    case UserRole.student:
      return [
        for (var i = 0; i < MockFacultyData.studentKpis.length; i++)
          StatCard(
            metric: MockFacultyData.studentKpis[i],
            icon: [
              Icons.grade_rounded,
              Icons.workspace_premium_rounded,
              Icons.menu_book_rounded,
              Icons.mark_email_unread_rounded,
            ][i],
            color: [
              AppColors.primary,
              AppColors.success,
              AppColors.cyan,
              AppColors.warning,
            ][i],
          ),
      ];
    case UserRole.administrator:
    case UserRole.apparitor:
    case UserRole.dean:
      return [
        StatCard(
          metric: MockFacultyData.adminKpis[0],
          icon: Icons.groups_rounded,
          color: AppColors.primary,
        ),
        StatCard(
          metric: MockFacultyData.adminKpis[1],
          icon: Icons.co_present_rounded,
          color: AppColors.cyan,
        ),
        StatCard(
          metric: MockFacultyData.decisionKpis[0],
          icon: Icons.trending_up_rounded,
          color: AppColors.success,
        ),
        StatCard(
          metric: MockFacultyData.decisionKpis[1],
          icon: Icons.trending_down_rounded,
          color: AppColors.danger,
        ),
      ];
  }
}

List<Widget> _chartsFor(UserRole role) {
  if (role == UserRole.teacher) {
    return const [
      BarChartCard(
        title: 'Performance de mes cours',
        data: MockFacultyData.performanceByCourse,
      ),
      DonutChartCard(
        title: 'Reclamations liees aux notes',
        data: MockFacultyData.complaintsByCategory,
        centerLabel: '1',
      ),
    ];
  }

  if (role == UserRole.promotionChief || role == UserRole.student) {
    return const [
      LineChartCard(
        title: 'Evolution academique',
        data: MockFacultyData.l2ProgressTrend,
      ),
      BarChartCard(
        title: 'Cours a surveiller',
        data: MockFacultyData.l2CoursePerformance,
      ),
    ];
  }

  return const [
    LineChartCard(
      title: 'Performances par promotion',
      data: MockFacultyData.performanceByPromotion,
    ),
    BarChartCard(
      title: 'Performances par cours',
      data: MockFacultyData.performanceByCourse,
    ),
    DonutChartCard(
      title: 'Reclamations par categorie',
      data: MockFacultyData.complaintsByCategory,
      centerLabel: '124',
    ),
    DonutChartCard(
      title: 'Reclamations par statut',
      data: MockFacultyData.complaintsByStatus,
      centerLabel: '142',
    ),
  ];
}

List<RiskStudent> _riskStudentsFor(UserRole role) {
  if (role == UserRole.promotionChief) {
    return MockFacultyData.riskStudents
        .where((student) => student.promotion == 'L2 Informatique')
        .toList();
  }
  if (role == UserRole.student) {
    final user = SessionService.currentUser;
    return MockFacultyData.riskStudents
        .where((student) => student.name == user.name)
        .toList();
  }
  return MockFacultyData.riskStudents;
}

bool _usesDecisionApi(UserRole role) {
  return role == UserRole.administrator ||
      role == UserRole.apparitor ||
      role == UserRole.dean;
}

String _titleFor(UserRole role) {
  switch (role) {
    case UserRole.teacher:
      return 'Indicateurs de mes cours';
    case UserRole.promotionChief:
      return 'Indicateurs de ma promotion';
    case UserRole.student:
      return 'Mon suivi academique';
    case UserRole.dean:
      return 'Analytics decisionnels';
    case UserRole.apparitor:
      return 'Analytics apparitorat';
    case UserRole.administrator:
      return 'Analytics administratifs';
  }
}

String _subtitleFor(UserRole role) {
  switch (role) {
    case UserRole.teacher:
      return 'Lire les tendances utiles pour vos cours et reclamations.';
    case UserRole.promotionChief:
      return 'Suivre les signaux utiles a relayer dans la promotion.';
    case UserRole.student:
      return 'Comprendre votre progression personnelle.';
    case UserRole.dean:
      return 'Indicateurs academiques, reclamations et performances.';
    case UserRole.apparitor:
      return 'Indicateurs par promotion, cours, notes et risques.';
    case UserRole.administrator:
      return 'Vue globale pour controler les services academiques.';
  }
}

String _tableTitleFor(UserRole role) {
  switch (role) {
    case UserRole.promotionChief:
      return 'Etudiants a suivre dans ma promotion';
    case UserRole.teacher:
      return 'Signaux pedagogiques';
    case UserRole.student:
      return 'Mon signal d accompagnement';
    case UserRole.dean:
    case UserRole.apparitor:
    case UserRole.administrator:
      return 'Etudiants a risque';
  }
}

String _apiPromotionLabel(dynamic item) {
  final promotion = item is Map ? item['promotion'] as Map? : null;
  return '${promotion?['nom'] ?? '-'}';
}

String _apiCoursLabel(dynamic item) {
  final cours = item is Map ? item['cours'] as Map? : null;
  return '${cours?['code'] ?? cours?['intitule'] ?? '-'}';
}

String _apiNomEtudiant(Map<String, dynamic> risque) {
  final etudiant = risque['etudiant'] as Map?;
  return '${etudiant?['nom'] ?? 'Etudiant #${risque['etudiant_id'] ?? '-'}'}';
}

String _apiCoursRisque(Map<String, dynamic> risque) {
  final cours = risque['cours'] as Map?;
  final code = cours?['code'];
  final intitule = cours?['intitule'];
  if (code == null && intitule == null) return '-';
  return [code, intitule].whereType<Object>().join(' - ');
}

String _apiRaisonRisque(Map<String, dynamic> risque) {
  final raisons = risque['raisons_detaillees'];
  if (raisons is! List || raisons.isEmpty) return '-';
  final premiere = raisons.first;
  if (premiere is! Map) return '$premiere';
  final critere = premiere['critere'] ?? 'signal';
  final valeur = premiere['valeur'];
  return valeur == null ? '$critere' : '$critere: $valeur';
}

RiskLevel _apiRiskLevel(String value) {
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

dynamic _apiNested(dynamic source, List<String> keys) {
  var current = source;
  for (final key in keys) {
    if (current is! Map) return null;
    current = current[key];
  }
  return current;
}

int _apiAsInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? 0}') ?? 0;
}

num _apiAsNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse('${value ?? 0}') ?? 0;
}

String _apiFormatNumber(dynamic value) {
  final number = _apiAsNum(value);
  return number.toStringAsFixed(number % 1 == 0 ? 0 : 2);
}
