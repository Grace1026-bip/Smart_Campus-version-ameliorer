import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/mock/mock_faculty_data.dart';
import '../../../data/models/faculty_models.dart';
import '../../../shared/layouts/responsive_shell.dart';
import '../../../shared/widgets/feature_tile.dart';
import '../../../shared/widgets/responsive_grid.dart';
import '../../../shared/widgets/section_panel.dart';
import '../../../shared/widgets/smart_table.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_badge.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.teacher,
      selectedRoute: AppRoutes.teacherDashboard,
      title: 'Dashboard enseignant',
      subtitle: 'Cours attribués, publication des notes et suivi pédagogique.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResponsiveGrid(
            children: [
              StatCard(
                metric: KpiMetric(
                  title: 'Cours attribués',
                  value: '3',
                  trend: '2 promotions',
                  description: 'semestre actuel',
                ),
                icon: Icons.menu_book_rounded,
                color: AppColors.primary,
              ),
              StatCard(
                metric: KpiMetric(
                  title: 'Notes publiées',
                  value: '181',
                  trend: '76%',
                  description: 'copies encodées',
                ),
                icon: Icons.upload_file_rounded,
                color: AppColors.accent,
              ),
              StatCard(
                metric: KpiMetric(
                  title: 'Projets suivis',
                  value: '8',
                  trend: '3 critiques',
                  description: 'groupes encadrés',
                ),
                icon: Icons.workspaces_rounded,
                color: AppColors.violet,
              ),
              StatCard(
                metric: KpiMetric(
                  title: 'Réponses',
                  value: '14',
                  trend: '+6',
                  description: 'réclamations traitées',
                ),
                icon: Icons.forum_rounded,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 22),
          SmartTable(
            title: 'Cours attribués',
            subtitle: 'Progression de publication par promotion.',
            columns: const [
              DataColumn(label: Text('Cours')),
              DataColumn(label: Text('Promotion')),
              DataColumn(label: Text('Étudiants')),
              DataColumn(label: Text('Notes publiées')),
            ],
            rows: [
              for (final course in MockFacultyData.courseAssignments)
                DataRow(
                  cells: [
                    DataCell(Text(course.course)),
                    DataCell(Text(course.promotion)),
                    DataCell(Text('${course.students}')),
                    DataCell(
                      Text('${course.publishedGrades}/${course.students}'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 22),
          ResponsiveGrid(
            minItemWidth: 300,
            maxColumns: 3,
            children: [
              FeatureTile(
                icon: Icons.upload_file_rounded,
                title: 'Publier les notes',
                subtitle: 'Encoder les résultats et préparer la validation.',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.grades),
              ),
              FeatureTile(
                icon: Icons.groups_rounded,
                title: 'Étudiants par cours',
                subtitle: 'Consulter les listes et les performances.',
                color: AppColors.secondary,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.analytics),
              ),
              FeatureTile(
                icon: Icons.rate_review_rounded,
                title: 'Réclamations académiques',
                subtitle: 'Répondre aux demandes liées aux notes.',
                color: AppColors.warning,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.complaints),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionPanel(
            title: 'Réclamations à traiter',
            subtitle: 'Demandes assignées au volet académique.',
            child: Column(
              children: [
                for (final complaint
                    in MockFacultyData.complaints
                        .where((item) => item.type == ComplaintType.gradeError)
                        .take(2))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            complaint.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        StatusBadge.complaint(complaint.status),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
