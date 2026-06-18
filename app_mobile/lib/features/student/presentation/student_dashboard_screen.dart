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
      title: 'Espace étudiant',
      subtitle:
          'Informations personnelles, notes, projets, stages et réclamations.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionPanel(
            title: 'Profil académique',
            subtitle: user.department,
            child: Wrap(
              spacing: 16,
              runSpacing: 14,
              children: [
                _ProfileInfo(label: 'Nom', value: user.name),
                _ProfileInfo(label: 'Email', value: user.email),
                const _ProfileInfo(label: 'Matricule', value: 'SF-GL-2026-014'),
                const _ProfileInfo(label: 'Statut', value: 'Régulier'),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const ResponsiveGrid(
            children: [
              StatCard(
                metric: KpiMetric(
                  title: 'Moyenne',
                  value: '13,7',
                  trend: '+0,8',
                  description: 'semestre actuel',
                ),
                icon: Icons.grade_rounded,
                color: AppColors.primary,
              ),
              StatCard(
                metric: KpiMetric(
                  title: 'Cours validés',
                  value: '7/8',
                  trend: '87%',
                  description: 'progression académique',
                ),
                icon: Icons.fact_check_rounded,
                color: AppColors.accent,
              ),
              StatCard(
                metric: KpiMetric(
                  title: 'Réclamations',
                  value: '2',
                  trend: '1 en cours',
                  description: 'demandes soumises',
                ),
                icon: Icons.mark_email_unread_rounded,
                color: AppColors.warning,
              ),
              StatCard(
                metric: KpiMetric(
                  title: 'Notifications',
                  value: '5',
                  trend: '2 nouvelles',
                  description: 'messages académiques',
                ),
                icon: Icons.notifications_rounded,
                color: AppColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: 22),
          ResponsiveGrid(
            minItemWidth: 260,
            maxColumns: 4,
            children: [
              FeatureTile(
                icon: Icons.fact_check_rounded,
                title: 'Notes et résultats',
                subtitle: 'Consulter les notes par cours et l’historique.',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.grades),
              ),
              FeatureTile(
                icon: Icons.workspaces_rounded,
                title: 'Projets académiques',
                subtitle: 'Voir les livrables et l’état d’avancement.',
                color: AppColors.violet,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.projects),
              ),
              FeatureTile(
                icon: Icons.business_center_rounded,
                title: 'Stages',
                subtitle: 'Offres, candidatures et validation du stage.',
                color: AppColors.accent,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.internships),
              ),
              FeatureTile(
                icon: Icons.add_comment_rounded,
                title: 'Créer une réclamation',
                subtitle: 'Soumettre et suivre une demande académique.',
                color: AppColors.warning,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.complaints),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SmartTable(
            title: 'Mes dernières notes',
            subtitle: 'Cours publiés pour le semestre actuel.',
            columns: const [
              DataColumn(label: Text('Cours')),
              DataColumn(label: Text('Enseignant')),
              DataColumn(label: Text('Note')),
              DataColumn(label: Text('Résultat')),
            ],
            rows: [
              for (final grade in MockFacultyData.grades.take(3))
                DataRow(
                  cells: [
                    DataCell(Text(grade.course)),
                    DataCell(Text(grade.teacher)),
                    DataCell(Text(grade.grade.toStringAsFixed(1))),
                    DataCell(Text(grade.result)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 22),
          const SectionPanel(
            title: 'Notifications',
            subtitle: 'Messages importants de la faculté.',
            child: Column(
              children: [
                _NotificationLine(
                  icon: Icons.event_available_rounded,
                  title: 'Soutenance blanche',
                  detail: 'Prévue vendredi à 10h00, salle Labo 2.',
                ),
                _NotificationLine(
                  icon: Icons.assignment_turned_in_rounded,
                  title: 'Livrable projet',
                  detail: 'Le rapport intermédiaire est attendu cette semaine.',
                ),
                _NotificationLine(
                  icon: Icons.mark_email_read_rounded,
                  title: 'Réclamation REC-2401',
                  detail: 'Votre dossier est en cours de traitement.',
                  badge: StatusBadge(
                    label: 'En cours',
                    color: AppColors.info,
                    icon: Icons.sync_rounded,
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
              fontWeight: FontWeight.w700,
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
  const _NotificationLine({
    required this.icon,
    required this.title,
    required this.detail,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (badge != null) badge!,
        ],
      ),
    );
  }
}
