import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/mock/mock_faculty_data.dart';
import '../../../data/models/faculty_models.dart';
import '../../../data/services/session_service.dart';
import '../../../shared/layouts/responsive_shell.dart';
import '../../../shared/widgets/feature_tile.dart';
import '../../../shared/widgets/responsive_grid.dart';
import '../../../shared/widgets/section_panel.dart';
import '../../../shared/widgets/smart_table.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_badge.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SessionService.currentUser;

    return SmartFacultyShell(
      role: UserRole.student,
      selectedRoute: AppRoutes.studentDashboard,
      title: 'Dashboard etudiant',
      subtitle: 'Notes, cours, projets, stages et reclamations personnelles.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionPanel(
            title: 'Bonjour ${user.name}',
            subtitle: user.department,
            trailing: const StatusBadge(
              label: 'Regulier',
              color: AppColors.success,
              icon: Icons.verified_rounded,
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 14,
              children: [
                _ProfileInfo(label: 'Matricule', value: user.matricule),
                _ProfileInfo(label: 'Email', value: user.email),
                const _ProfileInfo(label: 'Semestre', value: 'S6 en cours'),
                const _ProfileInfo(
                    label: 'Resultat', value: 'Admis provisoire'),
              ],
            ),
          ),
          const SizedBox(height: 22),
          ResponsiveGrid(
            children: [
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
            ],
          ),
          const SizedBox(height: 22),
          ResponsiveGrid(
            minItemWidth: 250,
            maxColumns: 4,
            children: [
              FeatureTile(
                icon: Icons.fact_check_rounded,
                title: 'Mes notes',
                subtitle: 'Consulter les resultats par cours.',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.grades),
              ),
              FeatureTile(
                icon: Icons.workspaces_rounded,
                title: 'Mes projets',
                subtitle: 'Avancement, membres et livrables.',
                color: AppColors.violet,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.projects),
              ),
              FeatureTile(
                icon: Icons.business_center_rounded,
                title: 'Mes stages',
                subtitle: 'Offres, candidatures et suivi.',
                color: AppColors.success,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.internships),
              ),
              FeatureTile(
                icon: Icons.add_comment_rounded,
                title: 'Reclamation',
                subtitle: 'Soumettre une demande academique.',
                color: AppColors.warning,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.complaints),
              ),
            ],
          ),
          const SizedBox(height: 22),
          ResponsiveGrid(
            minItemWidth: 360,
            maxColumns: 2,
            children: [
              SmartTable(
                title: 'Mes dernieres notes',
                subtitle: 'Cours publies pour le semestre actuel.',
                columns: const [
                  DataColumn(label: Text('Cours')),
                  DataColumn(label: Text('Note')),
                  DataColumn(label: Text('Resultat')),
                ],
                rows: [
                  for (final grade in MockFacultyData.grades.take(4))
                    DataRow(
                      cells: [
                        DataCell(Text(grade.course)),
                        DataCell(Text(grade.grade.toStringAsFixed(1))),
                        DataCell(Text(grade.result)),
                      ],
                    ),
                ],
              ),
              SectionPanel(
                title: 'Notifications',
                subtitle: 'Messages importants pour votre parcours.',
                child: Column(
                  children: [
                    for (final item in MockFacultyData.notifications.take(3))
                      _NotificationLine(item: item),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  const _ProfileInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationLine extends StatelessWidget {
  const _NotificationLine({required this.item});

  final FacultyNotification item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_rounded, color: AppColors.primary),
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
                  item.message,
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
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
