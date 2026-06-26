import 'package:flutter/material.dart';

import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/donnees_fictives/donnees_faculte_fictives.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_session.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/tuile_fonctionnalite.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/tableau_intelligent.dart';
import '../../../commun/composants/carte_statistique.dart';
import '../../../commun/composants/badge_statut.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final teacher = SessionService.currentUser.name;
    final courses = MockFacultyData.courseAssignments
        .where((course) => course.teacher == teacher)
        .toList();

    return SmartFacultyShell(
      role: UserRole.teacher,
      selectedRoute: AppRoutes.teacherDashboard,
      title: 'Dashboard enseignant',
      subtitle: 'Cours attribues, publication des notes et suivi pedagogique.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveGrid(
            children: [
              for (var i = 0; i < MockFacultyData.teacherKpis.length; i++)
                StatCard(
                  metric: MockFacultyData.teacherKpis[i],
                  icon: [
                    Icons.menu_book_rounded,
                    Icons.groups_rounded,
                    Icons.workspaces_rounded,
                    Icons.rate_review_rounded,
                  ][i],
                  color: [
                    AppColors.primary,
                    AppColors.success,
                    AppColors.violet,
                    AppColors.warning,
                  ][i],
                ),
            ],
          ),
          const SizedBox(height: 22),
          SmartTable(
            title: 'Cours attribues',
            subtitle: 'Progression de publication par promotion.',
            columns: const [
              DataColumn(label: Text('Cours')),
              DataColumn(label: Text('Promotion')),
              DataColumn(label: Text('Etudiants')),
              DataColumn(label: Text('Publiees')),
              DataColumn(label: Text('Moyenne')),
            ],
            rows: [
              for (final course in courses)
                DataRow(
                  cells: [
                    DataCell(Text(course.course)),
                    DataCell(Text(course.promotion)),
                    DataCell(Text('${course.students}')),
                    DataCell(
                      Text('${course.publishedGrades}/${course.students}'),
                    ),
                    DataCell(Text(course.average.toStringAsFixed(1))),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 22),
          ResponsiveGrid(
            minItemWidth: 270,
            maxColumns: 3,
            children: [
              FeatureTile(
                icon: Icons.upload_file_rounded,
                title: 'Publier les notes',
                subtitle: 'Encoder les resultats de vos cours.',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.grades),
              ),
              FeatureTile(
                icon: Icons.groups_rounded,
                title: 'Etudiants par cours',
                subtitle: 'Lire les listes et performances.',
                color: AppColors.cyan,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.analytics),
              ),
              FeatureTile(
                icon: Icons.workspaces_rounded,
                title: 'Projets encadres',
                subtitle: 'Valider les livrables et retours.',
                color: AppColors.violet,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.projects),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionPanel(
            title: 'Reclamations liees aux cours',
            subtitle: 'Demandes qui peuvent necessiter une verification.',
            child: Column(
              children: [
                for (final complaint in MockFacultyData.complaints
                    .where((item) => item.type == ComplaintType.gradeError)
                    .take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            complaint.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
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
