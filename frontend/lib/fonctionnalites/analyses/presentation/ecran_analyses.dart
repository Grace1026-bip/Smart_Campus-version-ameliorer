import 'package:flutter/material.dart';

import '../../../commun/composants/badge_statut.dart';
import '../../../commun/composants/carte_statistique.dart';
import '../../../commun/composants/composants_graphiques.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/tableau_intelligent.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_api.dart';
import '../../../donnees/services/service_session.dart';
import '../../../donnees/services/service_tableau_de_bord.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = SessionService.currentRole;
    return SmartFacultyShell(
      role: role,
      selectedRoute: AppRoutes.analytics,
      title: 'Analyses decisionnelles',
      subtitle: 'Indicateurs calcules par FastAPI depuis MySQL.',
      body: FutureBuilder<Map<String, dynamic>>(
        future: TableauDeBordDataSource.service.donneesDecisionnelles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).messagePourUtilisateur
                : 'Les analyses ne peuvent pas etre chargees.';
            return SectionPanel(
              title: 'Donnees indisponibles',
              subtitle: message,
              child: Text(message),
            );
          }
          final data = _AnalyticsData(snapshot.data ?? const {});
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveGrid(children: [
                _stat('Taux de reussite', '${data.successRate}%',
                    AppColors.success),
                _stat('Taux d echec', '${data.failureRate}%', AppColors.danger),
                _stat('Risques actifs', '${data.risksTotal}', AppColors.warning),
                _stat('Reclamations', '${data.complaintsTotal}', AppColors.primary),
              ]),
              const SizedBox(height: 22),
              ResponsiveGrid(
                minItemWidth: 360,
                maxColumns: 2,
                children: [
                  BarChartCard(
                    title: 'Taux de reussite par promotion',
                    data: data.promotionChart,
                  ),
                  DonutChartCard(
                    title: 'Reclamations par statut',
                    data: data.complaintChart,
                    centerLabel: '${data.complaintsTotal}',
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SmartTable(
                title: 'Cours analyses',
                subtitle: '${data.courses.length} ligne(s) provenant de FastAPI.',
                columns: const [
                  DataColumn(label: Text('Cours')),
                  DataColumn(label: Text('Inscrits')),
                  DataColumn(label: Text('Reussite')),
                  DataColumn(label: Text('Echec')),
                  DataColumn(label: Text('Risques')),
                ],
                rows: [
                  for (final item in data.courses)
                    DataRow(cells: [
                      DataCell(Text(_courseLabel(item))),
                      DataCell(Text('${item['inscrits'] ?? 0}')),
                      DataCell(Text('${_number(_nested(item, ['resultats', 'taux_reussite']))}%')),
                      DataCell(Text('${_number(_nested(item, ['resultats', 'taux_echec']))}%')),
                      DataCell(Text('${_nested(item, ['risques_actifs', 'total']) ?? 0}')),
                    ]),
                ],
              ),
              const SizedBox(height: 22),
              SectionPanel(
                title: 'Risques prioritaires',
                subtitle: '${data.risks.length} signalement(s).',
                child: Column(
                  children: [
                    if (data.risks.isEmpty)
                      const Text('Aucun risque academique actif.'),
                    for (final risk in data.risks.take(8))
                      ListTile(
                        leading: StatusBadge.risk(_risk('${risk['niveau_risque'] ?? ''}')),
                        title: Text('${risk['etudiant_id'] ?? '-'} - ${risk['cours_id'] ?? '-'}'),
                        subtitle: Text('Score ${risk['score_risque'] ?? '-'}'),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

StatCard _stat(String title, String value, Color color) => StatCard(
      metric: KpiMetric(
        title: title,
        value: value,
        trend: 'donnees reelles',
        description: 'calculees par FastAPI',
      ),
      icon: Icons.insights_rounded,
      color: color,
    );

class _AnalyticsData {
  const _AnalyticsData(this.source);
  final Map<String, dynamic> source;

  Map<String, dynamic> get resume =>
      source['resume'] as Map<String, dynamic>? ?? const {};
  Map<String, dynamic> get resultats =>
      resume['resultats'] as Map<String, dynamic>? ?? const {};
  Map<String, dynamic> get risques =>
      resume['risques'] as Map<String, dynamic>? ?? const {};
  Map<String, dynamic> get reclamations =>
      resume['reclamations'] as Map<String, dynamic>? ?? const {};
  List<dynamic> get courses =>
      (source['cours_difficiles'] as Map<String, dynamic>?)?['elements']
          as List<dynamic>? ?? const [];
  List<dynamic> get performances =>
      (source['performances_promotions'] as Map<String, dynamic>?)?['elements']
          as List<dynamic>? ?? const [];
  List<dynamic> get risks =>
      (source['risques_global'] as Map<String, dynamic>?)?['elements']
          as List<dynamic>? ?? const [];
  num get successRate => _numberValue(resultats['taux_reussite']);
  num get failureRate => _numberValue(resultats['taux_echec']);
  int get risksTotal => _int(risques['total_actifs']);
  int get complaintsTotal => _int(reclamations['total']);

  List<ChartPoint> get promotionChart => [
        for (final item in performances.take(8))
          ChartPoint(
            '${(item['promotion'] as Map?)?['nom'] ?? '-'}',
            _numberValue(_nested(item, ['resultats', 'taux_reussite']))
                .toDouble(),
          ),
      ];

  List<ChartPoint> get complaintChart => [
        ChartPoint('Attente', _int(reclamations['en_attente']).toDouble()),
        ChartPoint('En cours', _int(reclamations['en_cours']).toDouble()),
        ChartPoint('Resolues', _int(reclamations['resolues']).toDouble()),
        ChartPoint('Rejetees', _int(reclamations['rejetees']).toDouble()),
      ];
}

String _courseLabel(dynamic item) {
  final course = item is Map ? item['cours'] as Map? : null;
  return '${course?['code'] ?? '-'} - ${course?['intitule'] ?? '-'}';
}

dynamic _nested(dynamic source, List<String> keys) {
  var value = source;
  for (final key in keys) {
    if (value is! Map) return null;
    value = value[key];
  }
  return value;
}

int _int(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
num _numberValue(dynamic value) => value is num ? value : num.tryParse('$value') ?? 0;
String _number(dynamic value) => _numberValue(value).toStringAsFixed(2);

RiskLevel _risk(String value) {
  if (value == 'eleve') return RiskLevel.high;
  if (value == 'moyen') return RiskLevel.medium;
  return RiskLevel.low;
}
