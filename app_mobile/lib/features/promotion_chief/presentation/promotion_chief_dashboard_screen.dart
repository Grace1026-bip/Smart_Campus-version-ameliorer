import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/mock/mock_faculty_data.dart';
import '../../../data/models/faculty_models.dart';
import '../../../shared/layouts/responsive_shell.dart';
import '../../../shared/widgets/chart_widgets.dart';
import '../../../shared/widgets/feature_tile.dart';
import '../../../shared/widgets/responsive_grid.dart';
import '../../../shared/widgets/section_panel.dart';
import '../../../shared/widgets/smart_table.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_badge.dart';

class PromotionChiefDashboardScreen extends StatelessWidget {
  const PromotionChiefDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.promotionChief,
      selectedRoute: AppRoutes.promotionChiefDashboard,
      title: 'Espace chef de promotion',
      subtitle:
          'Suivi de promotion, réclamations collectives et signaux de risque.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResponsiveGrid(
            children: [
              StatCard(
                metric: KpiMetric(
                  title: 'Étudiants',
                  value: '276',
                  trend: 'L2 info',
                  description: 'promotion suivie',
                ),
                icon: Icons.groups_rounded,
                color: AppColors.primary,
              ),
              StatCard(
                metric: KpiMetric(
                  title: 'À risque',
                  value: '18',
                  trend: '6 élevés',
                  description: 'alertes pédagogiques',
                ),
                icon: Icons.health_and_safety_rounded,
                color: AppColors.danger,
              ),
              StatCard(
                metric: KpiMetric(
                  title: 'Réclamations',
                  value: '24',
                  trend: '7 ouvertes',
                  description: 'promotion',
                ),
                icon: Icons.mark_email_unread_rounded,
                color: AppColors.warning,
              ),
              StatCard(
                metric: KpiMetric(
                  title: 'Moyenne',
                  value: '12,9',
                  trend: '+0,3',
                  description: 'promotion',
                ),
                icon: Icons.insights_rounded,
                color: AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const ResponsiveGrid(
            minItemWidth: 330,
            maxColumns: 2,
            children: [
              LineChartCard(
                title: 'Évolution de la promotion',
                data: MockFacultyData.performanceByPromotion,
              ),
              BarChartCard(
                title: 'Cours à surveiller',
                data: MockFacultyData.performanceByCourse,
              ),
            ],
          ),
          const SizedBox(height: 22),
          SmartTable(
            title: 'Étudiants à risque',
            subtitle: 'Priorités de suivi pour la promotion.',
            trailing: TextButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.riskStudents),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Voir tout'),
            ),
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
          const SizedBox(height: 22),
          ResponsiveGrid(
            minItemWidth: 260,
            maxColumns: 3,
            children: [
              FeatureTile(
                icon: Icons.mark_email_unread_rounded,
                title: 'Réclamations promotion',
                subtitle: 'Suivre les demandes collectives.',
                color: AppColors.warning,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.complaints),
              ),
              FeatureTile(
                icon: Icons.campaign_rounded,
                title: 'Informations importantes',
                subtitle: 'Centraliser les annonces à relayer.',
                color: AppColors.secondary,
                onTap: () {},
              ),
              FeatureTile(
                icon: Icons.fact_check_rounded,
                title: 'Résultats',
                subtitle: 'Analyser les notes de la promotion.',
                color: AppColors.accent,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.grades),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const SectionPanel(
            title: 'Informations importantes',
            subtitle: 'Annonces à suivre cette semaine.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoLine(text: 'Dépôt des fiches de stage avant vendredi.'),
                _InfoLine(
                  text: 'Rattrapage Réseaux informatiques: salle B204.',
                ),
                _InfoLine(text: 'Réunion des chefs de promotion lundi 9h00.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.accent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
