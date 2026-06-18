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
import 'admin_management_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.administrator,
      selectedRoute: AppRoutes.adminDashboard,
      title: 'Dashboard administrateur',
      subtitle: 'Vue consolidée des services académiques et administratifs.',
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () {},
          icon: const Icon(Icons.notifications_rounded),
        ),
      ],
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
                metric: MockFacultyData.adminKpis[2],
                icon: Icons.mark_email_unread_rounded,
                color: AppColors.warning,
              ),
              StatCard(
                metric: MockFacultyData.adminKpis[3],
                icon: Icons.business_center_rounded,
                color: AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 22),
          ResponsiveGrid(
            minItemWidth: 260,
            maxColumns: 3,
            children: [
              FeatureTile(
                icon: Icons.person_search_rounded,
                title: 'Gestion des étudiants',
                subtitle: 'Dossiers, promotions, statut académique.',
                meta: '1 284 profils',
                onTap: () => _openManagement(context, 'Étudiants'),
              ),
              FeatureTile(
                icon: Icons.co_present_rounded,
                title: 'Gestion des enseignants',
                subtitle: 'Affectations, cours et responsabilités.',
                meta: '86 enseignants',
                color: AppColors.secondary,
                onTap: () => _openManagement(context, 'Enseignants'),
              ),
              FeatureTile(
                icon: Icons.account_tree_rounded,
                title: 'Gestion des promotions',
                subtitle: 'Niveaux, cohortes et chefs de promotion.',
                meta: '14 promotions',
                color: AppColors.violet,
                onTap: () => _openManagement(context, 'Promotions'),
              ),
              FeatureTile(
                icon: Icons.menu_book_rounded,
                title: 'Gestion des cours',
                subtitle: 'Unités d’enseignement, crédits et titulaires.',
                meta: '62 cours',
                color: AppColors.accent,
                onTap: () => _openManagement(context, 'Cours'),
              ),
              FeatureTile(
                icon: Icons.manage_accounts_rounded,
                title: 'Gestion des utilisateurs',
                subtitle: 'Rôles, accès et comptes institutionnels.',
                meta: '5 rôles actifs',
                color: AppColors.info,
                onTap: () => _openManagement(context, 'Utilisateurs'),
              ),
              FeatureTile(
                icon: Icons.insights_rounded,
                title: 'Analytics',
                subtitle: 'Indicateurs décisionnels de la faculté.',
                meta: 'Dashboard complet',
                color: AppColors.primaryDark,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.analytics),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const ResponsiveGrid(
            minItemWidth: 360,
            maxColumns: 2,
            children: [
              BarChartCard(
                title: 'Performances par promotion',
                data: MockFacultyData.performanceByPromotion,
              ),
              DonutChartCard(
                title: 'Réclamations par statut',
                data: MockFacultyData.complaintsByStatus,
                centerLabel: '142',
              ),
            ],
          ),
          const SizedBox(height: 22),
          SmartTable(
            title: 'Réclamations récentes',
            subtitle: 'Suivi administratif des demandes étudiantes.',
            trailing: TextButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.complaints),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Ouvrir'),
            ),
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Objet')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Statut')),
              DataColumn(label: Text('Assignée à')),
            ],
            rows: [
              for (final complaint in MockFacultyData.complaints)
                DataRow(
                  cells: [
                    DataCell(Text(complaint.id)),
                    DataCell(Text(complaint.title)),
                    DataCell(Text(complaint.type.label)),
                    DataCell(StatusBadge.complaint(complaint.status)),
                    DataCell(Text(complaint.assignedTo)),
                  ],
                ),
            ],
          ),
        ],
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
