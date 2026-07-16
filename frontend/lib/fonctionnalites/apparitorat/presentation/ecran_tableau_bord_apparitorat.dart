import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_appariteur.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/tuile_fonctionnalite.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/carte_statistique.dart';
import '../../../commun/composants/badge_statut.dart';
import '../../../commun/composants/composants_graphiques.dart';

class ApparitorDashboardScreen extends StatelessWidget {
  const ApparitorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.apparitor,
      selectedRoute: AppRoutes.apparitorDashboard,
      title: 'Dashboard appariteur',
      subtitle: 'Supervision academique par promotion, cours, risques et reclamations.',
      body: FutureBuilder<Map<String, dynamic>>(
        future: AppariteurDataSource.service.tableauDeBord(),
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

          final data = snapshot.data ?? {};
          final activities = data['dernieres_activites'] as List<dynamic>? ?? const [];
          final alerts = data['alertes_importantes'] as List<dynamic>? ?? const [];
          final charts = data['graphiques'] as Map<String, dynamic>? ?? const {};
          final risksByPromotion = _chartPoints(charts['risques_par_promotion']);
          final coursesByPromotion = _chartPoints(charts['cours_par_promotion']);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveGrid(children: [
                _stat('Etudiants', '${data['nombre_etudiants'] ?? 0}', 'total', Icons.groups_rounded, AppColors.primary),
                _stat('Enseignants', '${data['nombre_enseignants'] ?? 0}', 'total', Icons.school_rounded, AppColors.success),
                _stat('Promotions', '${data['nombre_promotions'] ?? 0}', 'actives', Icons.account_tree_rounded, AppColors.cyan),
                _stat('Cours', '${data['nombre_cours'] ?? 0}', 'ouverts', Icons.menu_book_rounded, AppColors.primaryDark),
                _stat('Reclamations', '${data['reclamations_ouvertes'] ?? 0}', 'ouvertes', Icons.mark_email_unread_rounded, AppColors.warning),
                _stat('Risques', '${data['etudiants_a_risque'] ?? 0}', 'etudiants', Icons.health_and_safety_rounded, AppColors.danger),
                _stat('Projets', '${data['projets_actifs'] ?? 0}', 'actifs', Icons.workspaces_rounded, AppColors.violet),
                _stat('Stages', '${data['stages_actifs'] ?? 0}', 'actifs', Icons.business_center_rounded, AppColors.cyan),
              ]),
              const SizedBox(height: 22),
              ResponsiveGrid(
                minItemWidth: 240,
                maxColumns: 4,
                children: [
                  _tile(context, Icons.groups_rounded, 'Etudiants', AppRoutes.apparitorStudents, AppColors.primary),
                  _tile(context, Icons.school_rounded, 'Enseignants', AppRoutes.apparitorTeachers, AppColors.success),
                  _tile(context, Icons.account_tree_rounded, 'Promotions', AppRoutes.apparitorPromotions, AppColors.cyan),
                  _tile(context, Icons.menu_book_rounded, 'Cours', AppRoutes.apparitorCourses, AppColors.primaryDark),
                  _tile(context, Icons.mark_email_unread_rounded, 'Reclamations', AppRoutes.apparitorComplaints, AppColors.warning),
                  _tile(context, Icons.health_and_safety_rounded, 'Risques', AppRoutes.apparitorRisks, AppColors.danger),
                  _tile(context, Icons.auto_awesome_rounded, 'Assistant', AppRoutes.apparitorAssistant, AppColors.violet),
                  _tile(context, Icons.summarize_rounded, 'Rapports', AppRoutes.apparitorReports, AppColors.primary),
                ],
              ),
              const SizedBox(height: 22),
              ResponsiveGrid(
                minItemWidth: 360,
                maxColumns: 2,
                children: [
                  BarChartCard(title: 'Cours par promotion', data: coursesByPromotion),
                  BarChartCard(title: 'Risques par promotion', data: risksByPromotion),
                ],
              ),
              const SizedBox(height: 22),
              ResponsiveGrid(
                minItemWidth: 360,
                maxColumns: 2,
                children: [
                  SectionPanel(
                    title: 'Alertes importantes',
                    subtitle: '${alerts.length} alerte(s).',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (alerts.isEmpty) const Text('Aucune alerte importante.'),
                        for (final alert in alerts)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: StatusBadge(
                              label: '${alert['message'] ?? '-'}',
                              color: '${alert['niveau'] ?? ''}' == 'danger' ? AppColors.danger : AppColors.warning,
                              icon: Icons.warning_amber_rounded,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SectionPanel(
                    title: 'Dernieres activites',
                    subtitle: 'Flux academique recent.',
                    child: Column(
                      children: [
                        if (activities.isEmpty) const Text('Aucune activite recente.'),
                        for (final item in activities.take(6))
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.history_rounded, color: AppColors.primary),
                            title: Text('${item['titre'] ?? '-'}'),
                            subtitle: Text('${item['detail'] ?? '-'}'),
                          ),
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
}

StatCard _stat(String title, String value, String trend, IconData icon, Color color) {
  return StatCard(
    metric: KpiMetric(title: title, value: value, trend: trend, description: 'donnees MySQL'),
    icon: icon,
    color: color,
  );
}

FeatureTile _tile(BuildContext context, IconData icon, String title, String route, Color color) {
  return FeatureTile(
    icon: icon,
    title: title,
    subtitle: 'Ouvrir le module',
    color: color,
    onTap: () => Navigator.of(context).pushNamed(route),
  );
}

List<ChartPoint> _chartPoints(dynamic source) {
  if (source is! List) return const [];
  return [
    for (final item in source)
      if (item is Map)
        ChartPoint(
          '${item['label'] ?? '-'}',
          (item['value'] is num)
              ? (item['value'] as num).toDouble()
              : double.tryParse('${item['value'] ?? 0}') ?? 0,
        ),
  ];
}
