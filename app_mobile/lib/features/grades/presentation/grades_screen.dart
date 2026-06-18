import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/mock/mock_faculty_data.dart';
import '../../../data/models/faculty_models.dart';
import '../../../data/services/session_service.dart';
import '../../../shared/layouts/responsive_shell.dart';
import '../../../shared/widgets/responsive_grid.dart';
import '../../../shared/widgets/section_panel.dart';
import '../../../shared/widgets/smart_table.dart';
import '../../../shared/widgets/stat_card.dart';

class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = SessionService.currentRole;
    final isTeacher = role == UserRole.teacher;

    return SmartFacultyShell(
      role: role,
      selectedRoute: AppRoutes.grades,
      title: 'Notes et résultats',
      subtitle: isTeacher
          ? 'Publication des notes et suivi par cours.'
          : 'Consultation des cours, moyennes et historique académique.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResponsiveGrid(
            children: [
              StatCard(
                metric: KpiMetric(
                  title: 'Moyenne',
                  value: '13,7',
                  trend: '+0,8',
                  description: 'semestre',
                ),
                icon: Icons.grade_rounded,
                color: AppColors.primary,
              ),
              StatCard(
                metric: KpiMetric(
                  title: 'Crédits',
                  value: '26',
                  trend: 'sur 30',
                  description: 'validés',
                ),
                icon: Icons.workspace_premium_rounded,
                color: AppColors.accent,
              ),
              StatCard(
                metric: KpiMetric(
                  title: 'Résultat final',
                  value: 'Admis',
                  trend: 'provisoire',
                  description: 'jury à venir',
                ),
                icon: Icons.verified_rounded,
                color: AppColors.secondary,
              ),
              StatCard(
                metric: KpiMetric(
                  title: 'Cours à reprendre',
                  value: '1',
                  trend: 'Réseaux',
                  description: 'alerte',
                ),
                icon: Icons.warning_amber_rounded,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 22),
          SmartTable(
            title: 'Notes par cours',
            subtitle: 'Résultats publiés dans le système académique.',
            columns: const [
              DataColumn(label: Text('Cours')),
              DataColumn(label: Text('Enseignant')),
              DataColumn(label: Text('Crédits')),
              DataColumn(label: Text('Note')),
              DataColumn(label: Text('Résultat')),
            ],
            rows: [
              for (final grade in MockFacultyData.grades)
                DataRow(
                  cells: [
                    DataCell(Text(grade.course)),
                    DataCell(Text(grade.teacher)),
                    DataCell(Text('${grade.credits}')),
                    DataCell(Text(grade.grade.toStringAsFixed(1))),
                    DataCell(Text(grade.result)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 22),
          if (isTeacher) ...[
            SectionPanel(
              title: 'Publication des notes',
              subtitle: 'Formulaire enseignant prêt pour la future API.',
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 780;
                  final fields = [
                    DropdownButtonFormField<String>(
                      initialValue: 'Bases de données avancées',
                      decoration: const InputDecoration(
                        labelText: 'Cours',
                        prefixIcon: Icon(Icons.menu_book_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Bases de données avancées',
                          child: Text('Bases de données avancées'),
                        ),
                        DropdownMenuItem(
                          value: 'Algorithmique II',
                          child: Text('Algorithmique II'),
                        ),
                      ],
                      onChanged: (_) {},
                    ),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Matricule étudiant',
                        prefixIcon: Icon(Icons.badge_rounded),
                      ),
                    ),
                    const TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Note /20',
                        prefixIcon: Icon(Icons.pin_rounded),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.publish_rounded),
                      label: const Text('Publier'),
                    ),
                  ];

                  if (compact) {
                    return Column(
                      children: [
                        for (final field in fields) ...[
                          field,
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final field in fields) ...[
                        Expanded(child: field),
                        const SizedBox(width: 12),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 22),
          ],
          SmartTable(
            title: 'Historique académique',
            subtitle: 'Parcours et décisions précédentes.',
            columns: const [
              DataColumn(label: Text('Période')),
              DataColumn(label: Text('Moyenne')),
              DataColumn(label: Text('Crédits')),
              DataColumn(label: Text('Résultat')),
            ],
            rows: [
              for (final item in MockFacultyData.academicHistory)
                DataRow(
                  cells: [
                    DataCell(Text(item.period)),
                    DataCell(Text(item.average.toStringAsFixed(1))),
                    DataCell(Text('${item.credits}')),
                    DataCell(Text(item.result)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
