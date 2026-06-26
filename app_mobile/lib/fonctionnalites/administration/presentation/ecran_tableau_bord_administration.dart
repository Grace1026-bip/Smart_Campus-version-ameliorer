import 'package:flutter/material.dart';

import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/donnees_fictives/donnees_faculte_fictives.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/composants_graphiques.dart';
import '../../../commun/composants/tuile_fonctionnalite.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/tableau_intelligent.dart';
import '../../../commun/composants/carte_statistique.dart';
import '../../../commun/composants/badge_statut.dart';
import 'ecran_gestion_administration.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.administrator,
      selectedRoute: AppRoutes.adminDashboard,
      title: 'Dashboard administrateur',
      subtitle: 'Vue consolidee des services academiques et administratifs.',
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
                color: AppColors.cyan,
              ),
              StatCard(
                metric: MockFacultyData.adminKpis[2],
                icon: Icons.menu_book_rounded,
                color: AppColors.success,
              ),
              StatCard(
                metric: MockFacultyData.adminKpis[3],
                icon: Icons.mark_email_unread_rounded,
                color: AppColors.warning,
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
                title: 'Gestion des etudiants',
                subtitle: 'Dossiers, promotions et situation academique.',
                meta: '1 284 profils',
                onTap: () => _openManagement(context, 'Etudiants'),
              ),
              FeatureTile(
                icon: Icons.co_present_rounded,
                title: 'Gestion des enseignants',
                subtitle: 'Affectations, cours et responsabilites.',
                meta: '86 enseignants',
                color: AppColors.cyan,
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
                subtitle: 'Unites d enseignement, credits et titulaires.',
                meta: '62 cours',
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
                meta: 'Vue globale',
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
                title: 'Reclamations par statut',
                data: MockFacultyData.complaintsByStatus,
                centerLabel: '142',
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
                subtitle: 'Suivi administratif des demandes etudiantes.',
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
                  DataColumn(label: Text('Service')),
                ],
                rows: [
                  for (final complaint in MockFacultyData.complaints.take(4))
                    DataRow(
                      cells: [
                        DataCell(Text(complaint.id)),
                        DataCell(Text(complaint.title)),
                        DataCell(StatusBadge.complaint(complaint.status)),
                        DataCell(Text(complaint.assignedTo)),
                      ],
                    ),
                ],
              ),
              SectionPanel(
                title: 'Activites recentes',
                subtitle: 'Evenements administratifs de la journee.',
                child: Column(
                  children: [
                    for (final item in MockFacultyData.recentActivities)
                      _ActivityLine(item: item),
                  ],
                ),
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

class _ActivityLine extends StatelessWidget {
  const _ActivityLine({required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.detail,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.timeLabel,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
