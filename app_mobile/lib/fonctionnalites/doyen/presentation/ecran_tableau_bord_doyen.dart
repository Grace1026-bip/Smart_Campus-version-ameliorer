import 'package:flutter/material.dart';

import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/donnees_fictives/donnees_faculte_fictives.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/composants_graphiques.dart';
import '../../../commun/composants/tuile_fonctionnalite.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/tableau_intelligent.dart';
import '../../../commun/composants/carte_statistique.dart';
import '../../../commun/composants/badge_statut.dart';

class DeanDashboardScreen extends StatelessWidget {
  const DeanDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.dean,
      selectedRoute: AppRoutes.deanDashboard,
      title: 'Tableau de bord decisionnel',
      subtitle: 'Indicateurs strategiques pour le pilotage de la faculte.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveGrid(
            children: [
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
              StatCard(
                metric: MockFacultyData.decisionKpis[2],
                icon: Icons.grade_rounded,
                color: AppColors.primary,
              ),
              StatCard(
                metric: MockFacultyData.decisionKpis[3],
                icon: Icons.health_and_safety_rounded,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const ResponsiveGrid(
            minItemWidth: 360,
            maxColumns: 2,
            children: [
              LineChartCard(
                title: 'Performances par promotion',
                data: MockFacultyData.performanceByPromotion,
              ),
              BarChartCard(
                title: 'Performances par cours',
                data: MockFacultyData.performanceByCourse,
              ),
              DonutChartCard(
                title: 'Reclamations par statut',
                data: MockFacultyData.complaintsByStatus,
                centerLabel: '142',
              ),
              DonutChartCard(
                title: 'Reclamations par categorie',
                data: MockFacultyData.complaintsByCategory,
                centerLabel: '124',
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
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.analytics),
              ),
              FeatureTile(
                icon: Icons.health_and_safety_rounded,
                title: 'Etudiants a risque',
                subtitle: 'Identifier les priorites d accompagnement.',
                color: AppColors.danger,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.riskStudents),
              ),
              FeatureTile(
                icon: Icons.mark_email_unread_rounded,
                title: 'Reclamations',
                subtitle: 'Mesurer volumes et temps de traitement.',
                color: AppColors.warning,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.complaints),
              ),
              FeatureTile(
                icon: Icons.fact_check_rounded,
                title: 'Notes',
                subtitle: 'Analyser les resultats finaux.',
                color: AppColors.success,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.grades),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SmartTable(
            title: 'Etudiants prioritaires',
            subtitle: 'Synthese des alertes academiques.',
            columns: const [
              DataColumn(label: Text('Nom')),
              DataColumn(label: Text('Promotion')),
              DataColumn(label: Text('Moyenne')),
              DataColumn(label: Text('Echecs')),
              DataColumn(label: Text('Risque')),
            ],
            rows: [
              for (final student in MockFacultyData.riskStudents)
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
