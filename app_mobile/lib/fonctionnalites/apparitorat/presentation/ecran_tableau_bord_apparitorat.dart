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

class ApparitorDashboardScreen extends StatelessWidget {
  const ApparitorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.apparitor,
      selectedRoute: AppRoutes.apparitorDashboard,
      title: 'Dashboard appariteur',
      subtitle: 'Suivi academique par promotion, cours, notes et risques.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveGrid(
            children: [
              StatCard(
                metric: MockFacultyData.adminKpis[0],
                icon: Icons.groups_rounded,
                color: AppColors.primary,
              ),
              StatCard(
                metric: MockFacultyData.adminKpis[2],
                icon: Icons.menu_book_rounded,
                color: AppColors.cyan,
              ),
              const StatCard(
                metric: KpiMetric(
                  title: 'Notes non publiees',
                  value: '1',
                  trend: 'Programmation Web',
                  description: 'cours a relancer',
                ),
                icon: Icons.pending_actions_rounded,
                color: AppColors.warning,
              ),
              StatCard(
                metric: MockFacultyData.decisionKpis[3],
                icon: Icons.health_and_safety_rounded,
                color: AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 22),
          ResponsiveGrid(
            minItemWidth: 260,
            maxColumns: 4,
            children: [
              FeatureTile(
                icon: Icons.auto_awesome_rounded,
                title: 'Assistant Appariteur',
                subtitle: 'Priorites, alertes et actions suggerees.',
                color: AppColors.primaryDark,
                onTap: () => Navigator.of(context)
                    .pushNamed(AppRoutes.apparitorAssistant),
              ),
              FeatureTile(
                icon: Icons.fact_check_rounded,
                title: 'Notes et credits',
                subtitle: 'Verifier publications et verrouillages.',
                color: AppColors.success,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.grades),
              ),
              FeatureTile(
                icon: Icons.health_and_safety_rounded,
                title: 'Risques',
                subtitle: 'Par promotion, cours et niveau.',
                color: AppColors.danger,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.riskStudents),
              ),
              FeatureTile(
                icon: Icons.workspaces_rounded,
                title: 'Projets',
                subtitle: 'Suivi des livrables par promotion.',
                color: AppColors.violet,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.projects),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const ResponsiveGrid(
            minItemWidth: 360,
            maxColumns: 2,
            children: [
              BarChartCard(
                title: 'Risques par promotion',
                data: MockFacultyData.performanceByPromotion,
              ),
              BarChartCard(
                title: 'Cours sensibles',
                data: MockFacultyData.performanceByCourse,
              ),
            ],
          ),
          const SizedBox(height: 22),
          SmartTable(
            title: 'Cours et publication des notes',
            subtitle: 'Controle apparitorat par cours et promotion.',
            columns: const [
              DataColumn(label: Text('Cours')),
              DataColumn(label: Text('Promotion')),
              DataColumn(label: Text('Enseignant')),
              DataColumn(label: Text('Publiees')),
              DataColumn(label: Text('Verrouille')),
            ],
            rows: [
              for (final course in MockFacultyData.courseAssignments)
                DataRow(
                  cells: [
                    DataCell(Text(course.course)),
                    DataCell(Text(course.promotion)),
                    DataCell(Text(course.teacher)),
                    DataCell(
                        Text('${course.publishedGrades}/${course.students}')),
                    DataCell(
                      StatusBadge(
                        label: course.locked ? 'Oui' : 'Non',
                        color: course.locked
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
