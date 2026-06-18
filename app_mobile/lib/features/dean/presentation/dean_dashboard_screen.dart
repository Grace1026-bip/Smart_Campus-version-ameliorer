import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/mock/mock_faculty_data.dart';
import '../../../data/models/faculty_models.dart';
import '../../../shared/layouts/responsive_shell.dart';
import '../../../shared/widgets/chart_widgets.dart';
import '../../../shared/widgets/feature_tile.dart';
import '../../../shared/widgets/responsive_grid.dart';
import '../../../shared/widgets/smart_table.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_badge.dart';

class DeanDashboardScreen extends StatelessWidget {
  const DeanDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.dean,
      selectedRoute: AppRoutes.deanDashboard,
      title: 'Tableau de bord décisionnel',
      subtitle: 'Indicateurs stratégiques pour le pilotage de la faculté.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveGrid(
            children: [
              StatCard(
                metric: MockFacultyData.decisionKpis[0],
                icon: Icons.trending_up_rounded,
                color: AppColors.accent,
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
                icon: Icons.timer_rounded,
                color: AppColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const ResponsiveGrid(
            minItemWidth: 360,
            maxColumns: 2,
            children: [
              LineChartCard(
                title: 'Taux de réussite par promotion',
                data: MockFacultyData.performanceByPromotion,
              ),
              DonutChartCard(
                title: 'Réclamations par catégorie',
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
                subtitle: 'Graphiques détaillés par cours et promotion.',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.analytics),
              ),
              FeatureTile(
                icon: Icons.health_and_safety_rounded,
                title: 'Étudiants à risque',
                subtitle: 'Identifier les priorités d’accompagnement.',
                color: AppColors.danger,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.riskStudents),
              ),
              FeatureTile(
                icon: Icons.mark_email_unread_rounded,
                title: 'Réclamations',
                subtitle: 'Mesurer les volumes et temps de traitement.',
                color: AppColors.warning,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.complaints),
              ),
              FeatureTile(
                icon: Icons.fact_check_rounded,
                title: 'Notes',
                subtitle: 'Analyser les résultats finaux.',
                color: AppColors.accent,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.grades),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SmartTable(
            title: 'Étudiants prioritaires',
            subtitle: 'Synthèse des alertes académiques.',
            columns: const [
              DataColumn(label: Text('Nom')),
              DataColumn(label: Text('Promotion')),
              DataColumn(label: Text('Moyenne')),
              DataColumn(label: Text('Échecs')),
              DataColumn(label: Text('Risque')),
            ],
            rows: [
              for (final student in MockFacultyData.riskStudents.take(3))
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
