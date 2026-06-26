import 'package:flutter/material.dart';

import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/donnees_fictives/donnees_faculte_fictives.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_session.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/tableau_intelligent.dart';
import '../../../commun/composants/carte_statistique.dart';
import '../../../commun/composants/badge_statut.dart';

class RiskStudentsScreen extends StatefulWidget {
  const RiskStudentsScreen({super.key});

  @override
  State<RiskStudentsScreen> createState() => _RiskStudentsScreenState();
}

class _RiskStudentsScreenState extends State<RiskStudentsScreen> {
  RiskLevel? _selectedLevel;

  @override
  Widget build(BuildContext context) {
    final role = SessionService.currentRole;
    final scopedStudents = _studentsForRole(role);
    final students = scopedStudents
        .where(
          (student) =>
              _selectedLevel == null || student.level == _selectedLevel,
        )
        .toList();

    return SmartFacultyShell(
      role: role,
      selectedRoute: AppRoutes.riskStudents,
      title: _titleFor(role),
      subtitle: _subtitleFor(role),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveGrid(children: _riskStats(scopedStudents)),
          const SizedBox(height: 22),
          SectionPanel(
            title: 'Filtrer par niveau',
            subtitle: _filterSubtitle(role),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ChoiceChip(
                  label: const Text('Tous'),
                  selected: _selectedLevel == null,
                  onSelected: (_) => setState(() => _selectedLevel = null),
                ),
                for (final level in RiskLevel.values)
                  ChoiceChip(
                    label: Text(level.label),
                    selected: _selectedLevel == level,
                    onSelected: (_) => setState(() => _selectedLevel = level),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (role == UserRole.student) ...[
            SectionPanel(
              title: 'Alerte academique personnelle',
              subtitle: 'Visible uniquement par l etudiant concerne.',
              child: Text(
                students.isEmpty
                    ? 'Aucune alerte academique active pour vos cours publies.'
                    : 'Attention : votre moyenne en ${students.first.course} est faible. Vous etes a risque dans ce cours.',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 22),
          ],
          SmartTable(
            title: _tableTitle(role),
            subtitle: '${students.length} profil(s) affiche(s).',
            columns: const [
              DataColumn(label: Text('Nom')),
              DataColumn(label: Text('Promotion')),
              DataColumn(label: Text('Cours')),
              DataColumn(label: Text('Enseignant')),
              DataColumn(label: Text('Moyenne')),
              DataColumn(label: Text('Echecs')),
              DataColumn(label: Text('Niveau')),
              DataColumn(label: Text('Signal')),
            ],
            rows: [
              for (final student in students)
                DataRow(
                  cells: [
                    DataCell(Text(student.name)),
                    DataCell(Text(student.promotion)),
                    DataCell(Text(student.course)),
                    DataCell(Text(student.teacher)),
                    DataCell(Text(student.average.toStringAsFixed(1))),
                    DataCell(Text('${student.failures}')),
                    DataCell(StatusBadge.risk(student.level)),
                    DataCell(Text(student.reason)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

List<Widget> _riskStats(List<RiskStudent> students) {
  final high = students.where((item) => item.level == RiskLevel.high).length;
  final medium =
      students.where((item) => item.level == RiskLevel.medium).length;
  final low = students.where((item) => item.level == RiskLevel.low).length;
  final lowestAverage = students.isEmpty
      ? 0
      : students
          .map((item) => item.average)
          .reduce((value, element) => value < element ? value : element);

  return [
    StatCard(
      metric: KpiMetric(
        title: 'Risque eleve',
        value: '$high',
        trend: high == 0 ? 'aucun cas' : 'priorite',
        description: 'actions urgentes',
      ),
      icon: Icons.priority_high_rounded,
      color: AppColors.danger,
    ),
    StatCard(
      metric: KpiMetric(
        title: 'Risque moyen',
        value: '$medium',
        trend: medium == 0 ? 'stable' : 'suivi renforce',
        description: 'a surveiller',
      ),
      icon: Icons.warning_amber_rounded,
      color: AppColors.warning,
    ),
    StatCard(
      metric: KpiMetric(
        title: 'Risque faible',
        value: '$low',
        trend: 'prevention',
        description: 'surveillance legere',
      ),
      icon: Icons.trending_down_rounded,
      color: AppColors.success,
    ),
    StatCard(
      metric: KpiMetric(
        title: 'Moyenne basse',
        value: lowestAverage.toStringAsFixed(1),
        trend: 'seuil',
        description: 'profil fragile',
      ),
      icon: Icons.analytics_rounded,
      color: AppColors.primary,
    ),
  ];
}

List<RiskStudent> _studentsForRole(UserRole role) {
  const students = MockFacultyData.riskStudents;
  final user = SessionService.currentUser;
  switch (role) {
    case UserRole.teacher:
      return students.where((student) => student.teacher == user.name).toList();
    case UserRole.promotionChief:
      return students
          .where((student) => student.promotion == user.promotion)
          .toList();
    case UserRole.student:
      return students.where((student) => student.name == user.name).toList();
    case UserRole.apparitor:
    case UserRole.administrator:
    case UserRole.dean:
      return students;
  }
}

String _titleFor(UserRole role) {
  switch (role) {
    case UserRole.promotionChief:
      return 'Risques de ma promotion';
    case UserRole.teacher:
      return 'Signaux pedagogiques';
    case UserRole.apparitor:
      return 'Risques par promotion et cours';
    case UserRole.student:
      return 'Mon accompagnement';
    case UserRole.dean:
      return 'Etudiants a risque';
    case UserRole.administrator:
      return 'Suivi des risques';
  }
}

String _subtitleFor(UserRole role) {
  switch (role) {
    case UserRole.promotionChief:
      return 'Vue limitee aux etudiants de L2 Informatique.';
    case UserRole.teacher:
      return 'Reperer les etudiants fragiles dans les cours suivis.';
    case UserRole.apparitor:
      return 'Vue apparitorat par promotion, cours et niveau de risque.';
    case UserRole.student:
      return 'Comprendre les signaux d accompagnement academique.';
    case UserRole.dean:
      return 'Identifier les priorites d accompagnement facultaires.';
    case UserRole.administrator:
      return 'Suivre moyennes, echecs et niveaux de risque.';
  }
}

String _filterSubtitle(UserRole role) {
  return role == UserRole.promotionChief
      ? 'Le filtre agit seulement sur votre promotion.'
      : 'Le filtre agit sur le perimetre visible par votre role.';
}

String _tableTitle(UserRole role) {
  switch (role) {
    case UserRole.promotionChief:
      return 'Etudiants a suivre dans la promotion';
    case UserRole.teacher:
      return 'Risques dans mes cours';
    case UserRole.student:
      return 'Mes alertes academiques';
    case UserRole.apparitor:
      return 'Etudiants a risque par promotion et cours';
    case UserRole.dean:
    case UserRole.administrator:
      return 'Liste des etudiants a risque';
  }
}
