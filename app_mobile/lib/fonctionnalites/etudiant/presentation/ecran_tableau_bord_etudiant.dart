import 'package:flutter/material.dart';

import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_etudiant.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/tuile_fonctionnalite.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/tableau_intelligent.dart';
import '../../../commun/composants/carte_statistique.dart';
import '../../../commun/composants/badge_statut.dart';
import '../../../core/config/api_config.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.student,
      selectedRoute: AppRoutes.studentDashboard,
      title: 'Dashboard etudiant',
      subtitle: 'Cours, valve, notes, alertes et reclamations depuis la base.',
      body: FutureBuilder<Map<String, dynamic>>(
        future: EtudiantDataSource.service.tableauDeBord(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorPanel(message: snapshot.error.toString());
          }

          final data = snapshot.data ?? {};
          final profil = data['profil'] as Map<String, dynamic>? ?? {};
          final annonces = data['dernieres_annonces'] as List<dynamic>? ?? [];
          final alertes = data['alertes'] as List<dynamic>? ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionPanel(
                title: 'Bonjour ${profil['nom_complet'] ?? ''}',
                subtitle:
                    '${profil['promotion'] ?? ''} - ${profil['annee_academique'] ?? ''}',
                trailing: const StatusBadge(
                  label: 'Compte approuve',
                  color: AppColors.success,
                  icon: Icons.verified_rounded,
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 14,
                  children: [
                    _ProfileInfo(
                      label: 'Matricule',
                      value: '${profil['matricule'] ?? '-'}',
                    ),
                    _ProfileInfo(
                      label: 'Email',
                      value: '${profil['email'] ?? '-'}',
                    ),
                    _ProfileInfo(
                      label: 'Promotion',
                      value: '${profil['promotion'] ?? '-'}',
                    ),
                    _ProfileInfo(
                      label: 'Statut',
                      value: '${profil['statut'] ?? '-'}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              ResponsiveGrid(
                children: [
                  StatCard(
                    metric: KpiMetric(
                      title: 'Cours suivis',
                      value: '${data['nombre_cours'] ?? 0}',
                      trend: 'promotion',
                      description: '${profil['promotion'] ?? ''}',
                    ),
                    icon: Icons.menu_book_rounded,
                    color: AppColors.cyan,
                  ),
                  StatCard(
                    metric: KpiMetric(
                      title: 'Moyenne generale',
                      value: _formatNumber(data['moyenne_generale']),
                      trend: '/20',
                      description: 'notes publiees',
                    ),
                    icon: Icons.grade_rounded,
                    color: AppColors.primary,
                  ),
                  StatCard(
                    metric: KpiMetric(
                      title: 'Credits valides',
                      value: '${data['credits_valides'] ?? 0}',
                      trend: '${data['credits_restants'] ?? 0} restants',
                      description: 'calcul automatique',
                    ),
                    icon: Icons.workspace_premium_rounded,
                    color: AppColors.success,
                  ),
                  StatCard(
                    metric: KpiMetric(
                      title: 'Reclamations',
                      value: '${data['reclamations_en_cours'] ?? 0}',
                      trend: 'en cours',
                      description: 'suivi personnel',
                    ),
                    icon: Icons.mark_email_unread_rounded,
                    color: AppColors.warning,
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
                    subtitle: 'Notes publiees uniquement.',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.grades),
                  ),
                  FeatureTile(
                    icon: Icons.campaign_rounded,
                    title: 'Valve',
                    subtitle: 'Publications de vos cours.',
                    color: AppColors.cyan,
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.notifications),
                  ),
                  FeatureTile(
                    icon: Icons.warning_amber_rounded,
                    title: 'Alertes',
                    subtitle: 'Risques et progression.',
                    color: AppColors.warning,
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.notifications),
                  ),
                  FeatureTile(
                    icon: Icons.add_comment_rounded,
                    title: 'Reclamation',
                    subtitle: 'Signaler une note ou un cours.',
                    color: AppColors.success,
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
                    title: 'Dernieres annonces',
                    subtitle: 'Publications recentes de vos cours.',
                    columns: const [
                      DataColumn(label: Text('Cours')),
                      DataColumn(label: Text('Titre')),
                      DataColumn(label: Text('Type')),
                    ],
                    rows: [
                      for (final item in annonces.take(5))
                        DataRow(
                          cells: [
                            DataCell(Text('${item['code_cours'] ?? '-'}')),
                            DataCell(Text('${item['titre'] ?? '-'}')),
                            DataCell(
                                Text('${item['type_publication'] ?? '-'}')),
                          ],
                        ),
                    ],
                  ),
                  SectionPanel(
                    title: 'Alertes academiques',
                    subtitle: 'Generees a partir des notes publiees.',
                    child: Column(
                      children: [
                        if (alertes.isEmpty)
                          const Text('Aucune alerte academique active.'),
                        for (final item in alertes.take(5))
                          _AlertLine(item: item as Map<String, dynamic>),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
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

class _AlertLine extends StatelessWidget {
  const _AlertLine({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_rounded, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['titre'] ?? '-'}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item['message'] ?? ''}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
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

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: 'Connexion API impossible',
      subtitle: message,
      child: const Text(ApiConfig.serverUnavailableMessage),
    );
  }
}

String _formatNumber(dynamic value) {
  if (value == null) return '-';
  if (value is num) return value.toStringAsFixed(2);
  return value.toString();
}
