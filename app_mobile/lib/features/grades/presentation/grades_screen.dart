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
import '../../../shared/widgets/status_badge.dart';

class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = SessionService.currentRole;

    return SmartFacultyShell(
      role: role,
      selectedRoute: AppRoutes.grades,
      title: _titleFor(role),
      subtitle: _subtitleFor(role),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveGrid(children: _statCardsFor(role)),
          const SizedBox(height: 22),
          _mainGradesTable(role),
          const SizedBox(height: 22),
          if (role == UserRole.teacher) ...[
            const _PublishGradesPanel(),
            const SizedBox(height: 22),
          ],
          if (role == UserRole.student) ...[
            const _AcademicHistoryTable(),
          ] else ...[
            _ReadingScopePanel(role: role),
          ],
        ],
      ),
    );
  }
}

class _PublishGradesPanel extends StatelessWidget {
  const _PublishGradesPanel();

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: 'Publication des notes',
      subtitle: 'Encoder les resultats uniquement pour vos cours attribues.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 780;
          final fields = [
            DropdownButtonFormField<String>(
              initialValue: 'Bases de donnees avancees',
              decoration: const InputDecoration(
                labelText: 'Cours',
                prefixIcon: Icon(Icons.menu_book_rounded),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Bases de donnees avancees',
                  child: Text('Bases de donnees avancees'),
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
                labelText: 'Matricule etudiant',
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
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('La note est prete a etre publiee.'),
                ),
              ),
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
    );
  }
}

class _AcademicHistoryTable extends StatelessWidget {
  const _AcademicHistoryTable();

  @override
  Widget build(BuildContext context) {
    return SmartTable(
      title: 'Historique academique',
      subtitle: 'Parcours et decisions precedentes.',
      columns: const [
        DataColumn(label: Text('Periode')),
        DataColumn(label: Text('Moyenne')),
        DataColumn(label: Text('Credits')),
        DataColumn(label: Text('Resultat')),
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
    );
  }
}

class _ReadingScopePanel extends StatelessWidget {
  const _ReadingScopePanel({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: 'Perimetre de lecture',
      subtitle: _scopeText(role),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _ScopeChip(icon: Icons.lock_rounded, text: _permissionText(role)),
          _ScopeChip(icon: Icons.verified_rounded, text: _decisionText(role)),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, color: AppColors.primary, size: 18),
      label: Text(text),
      backgroundColor: AppColors.primarySoft,
      side: const BorderSide(color: AppColors.border),
    );
  }
}

SmartTable _mainGradesTable(UserRole role) {
  if (role == UserRole.teacher) {
    return SmartTable(
      title: 'Mes cours attribues',
      subtitle: 'Progression de publication par promotion.',
      columns: const [
        DataColumn(label: Text('Cours')),
        DataColumn(label: Text('Promotion')),
        DataColumn(label: Text('Etudiants')),
        DataColumn(label: Text('Notes publiees')),
        DataColumn(label: Text('Moyenne')),
      ],
      rows: [
        for (final course in MockFacultyData.courseAssignments)
          DataRow(
            cells: [
              DataCell(Text(course.course)),
              DataCell(Text(course.promotion)),
              DataCell(Text('${course.students}')),
              DataCell(Text('${course.publishedGrades}/${course.students}')),
              DataCell(Text(course.average.toStringAsFixed(1))),
            ],
          ),
      ],
    );
  }

  return SmartTable(
    title:
        role == UserRole.student ? 'Mes notes par cours' : 'Resultats a suivre',
    subtitle: _tableSubtitle(role),
    columns: const [
      DataColumn(label: Text('Cours')),
      DataColumn(label: Text('Enseignant')),
      DataColumn(label: Text('Credits')),
      DataColumn(label: Text('Note')),
      DataColumn(label: Text('Resultat')),
    ],
    rows: [
      for (final grade in MockFacultyData.grades)
        DataRow(
          cells: [
            DataCell(Text(grade.course)),
            DataCell(Text(grade.teacher)),
            DataCell(Text('${grade.credits}')),
            DataCell(Text(grade.grade.toStringAsFixed(1))),
            DataCell(
              StatusBadge(
                label: grade.result,
                color: grade.result == 'Valide'
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ),
          ],
        ),
    ],
  );
}

List<Widget> _statCardsFor(UserRole role) {
  switch (role) {
    case UserRole.teacher:
      return [
        for (var i = 0; i < MockFacultyData.teacherKpis.length; i++)
          StatCard(
            metric: MockFacultyData.teacherKpis[i],
            icon: [
              Icons.menu_book_rounded,
              Icons.upload_file_rounded,
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
      ];
    case UserRole.promotionChief:
      return const [
        StatCard(
          metric: KpiMetric(
            title: 'Moyenne promo',
            value: '12,9',
            trend: '+0,3',
            description: 'L2 Informatique',
          ),
          icon: Icons.groups_rounded,
          color: AppColors.primary,
        ),
        StatCard(
          metric: KpiMetric(
            title: 'Cours critiques',
            value: '2',
            trend: 'a relayer',
            description: 'moyenne basse',
          ),
          icon: Icons.warning_amber_rounded,
          color: AppColors.warning,
        ),
        StatCard(
          metric: KpiMetric(
            title: 'Notes publiees',
            value: '87%',
            trend: 'semestre',
            description: 'progression',
          ),
          icon: Icons.fact_check_rounded,
          color: AppColors.success,
        ),
        StatCard(
          metric: KpiMetric(
            title: 'Rattrapages',
            value: '18',
            trend: 'prevision',
            description: 'etudiants concernes',
          ),
          icon: Icons.event_repeat_rounded,
          color: AppColors.cyan,
        ),
      ];
    case UserRole.administrator:
    case UserRole.dean:
      return [
        StatCard(
          metric: MockFacultyData.decisionKpis[0],
          icon: Icons.trending_up_rounded,
          color: AppColors.success,
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
        const StatCard(
          metric: KpiMetric(
            title: 'Cours sensibles',
            value: '4',
            trend: 'a suivre',
            description: 'moyenne faible',
          ),
          icon: Icons.query_stats_rounded,
          color: AppColors.warning,
        ),
      ];
    case UserRole.student:
      return [
        for (var i = 0; i < MockFacultyData.studentKpis.length; i++)
          StatCard(
            metric: MockFacultyData.studentKpis[i],
            icon: [
              Icons.grade_rounded,
              Icons.workspace_premium_rounded,
              Icons.menu_book_rounded,
              Icons.warning_amber_rounded,
            ][i],
            color: [
              AppColors.primary,
              AppColors.success,
              AppColors.cyan,
              AppColors.warning,
            ][i],
          ),
      ];
  }
}

String _titleFor(UserRole role) {
  switch (role) {
    case UserRole.teacher:
      return 'Publication des notes';
    case UserRole.promotionChief:
      return 'Resultats de la promotion';
    case UserRole.dean:
      return 'Synthese des resultats';
    case UserRole.administrator:
      return 'Suivi academique';
    case UserRole.student:
      return 'Mes notes et resultats';
  }
}

String _subtitleFor(UserRole role) {
  switch (role) {
    case UserRole.teacher:
      return 'Encoder les notes et suivre vos cours attribues.';
    case UserRole.promotionChief:
      return 'Lire les tendances utiles pour accompagner la promotion.';
    case UserRole.dean:
      return 'Analyser les resultats finaux et les cours sensibles.';
    case UserRole.administrator:
      return 'Controler la publication et la coherence des resultats.';
    case UserRole.student:
      return 'Consulter les notes publiees et votre historique academique.';
  }
}

String _tableSubtitle(UserRole role) {
  switch (role) {
    case UserRole.promotionChief:
      return 'Lecture synthetique des cours suivis par la promotion.';
    case UserRole.dean:
      return 'Cours qui alimentent la lecture decisionnelle.';
    case UserRole.administrator:
      return 'Apercu de controle avant consolidation.';
    case UserRole.student:
      return 'Resultats publies dans le systeme academique.';
    case UserRole.teacher:
      return '';
  }
}

String _scopeText(UserRole role) {
  switch (role) {
    case UserRole.teacher:
      return 'Vous pouvez publier uniquement les notes de vos cours.';
    case UserRole.promotionChief:
      return 'Vous consultez les resultats de votre promotion sans modification.';
    case UserRole.dean:
      return 'Vous disposez d une lecture consolidee pour la decision.';
    case UserRole.administrator:
      return 'Vous controlez la coherence des donnees academiques.';
    case UserRole.student:
      return '';
  }
}

String _permissionText(UserRole role) {
  switch (role) {
    case UserRole.teacher:
      return 'Publication autorisee';
    case UserRole.promotionChief:
      return 'Lecture promotion';
    case UserRole.dean:
      return 'Lecture faculte';
    case UserRole.administrator:
      return 'Controle global';
    case UserRole.student:
      return 'Lecture personnelle';
  }
}

String _decisionText(UserRole role) {
  switch (role) {
    case UserRole.teacher:
      return 'Validation par jury';
    case UserRole.promotionChief:
      return 'Relais etudiant';
    case UserRole.dean:
      return 'Pilotage decisionnel';
    case UserRole.administrator:
      return 'Preparation jury';
    case UserRole.student:
      return 'Suivi individuel';
  }
}
