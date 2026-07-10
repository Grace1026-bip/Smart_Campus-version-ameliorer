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

class PromotionChiefDashboardScreen extends StatelessWidget {
  const PromotionChiefDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final promotionRiskStudents = MockFacultyData.riskStudents
        .where((student) => student.promotion == 'L2 Informatique')
        .toList();

    return SmartFacultyShell(
      role: UserRole.promotionChief,
      selectedRoute: AppRoutes.promotionChiefDashboard,
      title: 'Dashboard chef de promotion',
      subtitle: 'Statistiques, etudiants a risque et reclamations collectives.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveGrid(
            children: [
              for (var i = 0; i < MockFacultyData.promotionKpis.length; i++)
                StatCard(
                  metric: MockFacultyData.promotionKpis[i],
                  icon: [
                    Icons.groups_rounded,
                    Icons.grade_rounded,
                    Icons.health_and_safety_rounded,
                    Icons.mark_email_unread_rounded,
                  ][i],
                  color: [
                    AppColors.primary,
                    AppColors.success,
                    AppColors.danger,
                    AppColors.warning,
                  ][i],
                ),
            ],
          ),
          const SizedBox(height: 22),
          const ResponsiveGrid(
            minItemWidth: 330,
            maxColumns: 2,
            children: [
              LineChartCard(
                title: 'Evolution de la promotion',
                data: MockFacultyData.l2ProgressTrend,
              ),
              BarChartCard(
                title: 'Cours a surveiller',
                data: MockFacultyData.l2CoursePerformance,
              ),
            ],
          ),
          const SizedBox(height: 22),
          ResponsiveGrid(
            minItemWidth: 360,
            maxColumns: 2,
            children: [
              SmartTable(
                title: 'Liste des etudiants',
                subtitle: 'Echantillon de la promotion L2 Informatique.',
                columns: const [
                  DataColumn(label: Text('Nom')),
                  DataColumn(label: Text('Matricule')),
                  DataColumn(label: Text('Moyenne')),
                  DataColumn(label: Text('Statut')),
                ],
                rows: [
                  for (final student in MockFacultyData.promotionStudents)
                    DataRow(
                      cells: [
                        DataCell(Text(student.name)),
                        DataCell(Text(student.matricule)),
                        DataCell(Text(student.average.toStringAsFixed(1))),
                        DataCell(Text(student.status)),
                      ],
                    ),
                ],
              ),
              SmartTable(
                title: 'Etudiants a risque',
                subtitle: 'Priorites de suivi pour la promotion.',
                trailing: TextButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.riskStudents),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Voir tout'),
                ),
                columns: const [
                  DataColumn(label: Text('Nom')),
                  DataColumn(label: Text('Moyenne')),
                  DataColumn(label: Text('Echecs')),
                  DataColumn(label: Text('Risque')),
                ],
                rows: [
                  for (final student in promotionRiskStudents)
                    DataRow(
                      cells: [
                        DataCell(Text(student.name)),
                        DataCell(Text(student.average.toStringAsFixed(1))),
                        DataCell(Text('${student.failures}')),
                        DataCell(StatusBadge.risk(student.level)),
                      ],
                    ),
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
                title: 'Reclamations promotion',
                subtitle: 'Suivre les demandes collectives.',
                color: AppColors.warning,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.complaints),
              ),
              FeatureTile(
                icon: Icons.campaign_rounded,
                title: 'Annonces importantes',
                subtitle: 'Relayer les informations de la semaine.',
                color: AppColors.cyan,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.notifications),
              ),
              FeatureTile(
                icon: Icons.fact_check_rounded,
                title: 'Resultats',
                subtitle: 'Analyser les notes de la promotion.',
                color: AppColors.success,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.grades),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const SectionPanel(
            title: 'Annonces importantes',
            subtitle: 'Informations a relayer cette semaine.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoLine(text: 'Depot des fiches de stage avant vendredi.'),
                _InfoLine(
                    text: 'Rattrapage Reseaux informatiques: salle B204.'),
                _InfoLine(text: 'Reunion des chefs de promotion lundi 9h00.'),
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
            color: AppColors.success,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
