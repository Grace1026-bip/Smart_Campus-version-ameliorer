import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/mock/mock_faculty_data.dart';
import '../../../data/models/faculty_models.dart';
import '../../../data/services/session_service.dart';
import '../../../shared/layouts/responsive_shell.dart';
import '../../../shared/widgets/chart_widgets.dart';
import '../../../shared/widgets/responsive_grid.dart';
import '../../../shared/widgets/smart_table.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_badge.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: SessionService.currentRole,
      selectedRoute: AppRoutes.analytics,
      title: 'Analytics',
      subtitle: 'Indicateurs académiques, réclamations et performances.',
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
                metric: MockFacultyData.adminKpis[1],
                icon: Icons.co_present_rounded,
                color: AppColors.secondary,
              ),
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
                title: 'Réclamations par catégorie',
                data: MockFacultyData.complaintsByCategory,
                centerLabel: '124',
              ),
              DonutChartCard(
                title: 'Réclamations par statut',
                data: MockFacultyData.complaintsByStatus,
                centerLabel: '142',
              ),
            ],
          ),
          const SizedBox(height: 22),
          const ResponsiveGrid(
            minItemWidth: 240,
            maxColumns: 4,
            children: [
              StatCard(
                metric: KpiMetric(
                  title: 'Moyenne générale',
                  value: '13,7',
                  trend: '+0,8',
                  description: 'sur 20',
                ),
                icon: Icons.grade_rounded,
                color: AppColors.primary,
              ),
              StatCard(
                metric: KpiMetric(
                  title: 'Temps moyen',
                  value: '2,4 j',
                  trend: '-18%',
                  description: 'traitement',
                ),
                icon: Icons.timer_rounded,
                color: AppColors.secondary,
              ),
              StatCard(
                metric: KpiMetric(
                  title: 'Étudiants à risque',
                  value: '18',
                  trend: '6 élevés',
                  description: 'suivi prioritaire',
                ),
                icon: Icons.health_and_safety_rounded,
                color: AppColors.danger,
              ),
              StatCard(
                metric: KpiMetric(
                  title: 'Stages',
                  value: '219',
                  trend: '+15%',
                  description: 'validés',
                ),
                icon: Icons.business_center_rounded,
                color: AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 22),
          SmartTable(
            title: 'Étudiants à risque',
            subtitle: 'Données utilisées par le tableau de bord décisionnel.',
            columns: const [
              DataColumn(label: Text('Nom')),
              DataColumn(label: Text('Promotion')),
              DataColumn(label: Text('Moyenne')),
              DataColumn(label: Text('Échecs')),
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
