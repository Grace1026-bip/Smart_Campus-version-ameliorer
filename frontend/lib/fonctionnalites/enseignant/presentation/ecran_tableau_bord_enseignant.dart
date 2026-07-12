import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_api.dart';
import '../../../donnees/services/service_enseignant.dart';
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
    return SmartFacultyShell(
      role: UserRole.teacher,
      selectedRoute: AppRoutes.teacherDashboard,
      title: 'Dashboard enseignant',
      subtitle: 'Cours attribues, valve, notes et reclamations depuis MySQL.',
      body: FutureBuilder<Map<String, dynamic>>(
        future: EnseignantDataSource.service.tableauDeBord(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return SectionPanel(
              title: 'Connexion API impossible',
              subtitle: _messageErreur(snapshot.error!),
              child: Text(_messageErreur(snapshot.error!)),
            );
          }

          final data = snapshot.data ?? {};
          final profil = data['profil'] as Map<String, dynamic>? ?? {};
          final stats = data['statistiques_cours'] as List<dynamic>? ?? [];
          final publications =
              data['publications_recentes'] as List<dynamic>? ?? [];
          final reclamations = data['reclamations'] as List<dynamic>? ?? [];
          final activites = data['dernieres_activites'] as List<dynamic>? ?? [];
          final nombrePublications =
              data['nombre_publications'] ?? publications.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TeacherIdentityPanel(profil: profil, data: data),
              const SizedBox(height: 22),
              ResponsiveGrid(
                minItemWidth: 220,
                maxColumns: 3,
                children: [
                  StatCard(
                    metric: KpiMetric(
                      title: 'Cours attribues',
                      value: '${data['nombre_cours'] ?? 0}',
                      trend: 'actifs',
                      description: 'dans votre perimetre',
                    ),
                    icon: Icons.menu_book_rounded,
                    color: AppColors.primary,
                  ),
                  StatCard(
                    metric: KpiMetric(
                      title: 'Etudiants',
                      value: '${data['nombre_total_etudiants'] ?? 0}',
                      trend: 'concernes',
                      description: 'inscrits aux cours',
                    ),
                    icon: Icons.groups_rounded,
                    color: AppColors.success,
                  ),
                  StatCard(
                    metric: KpiMetric(
                      title: 'Publications',
                      value: '$nombrePublications',
                      trend: 'valve',
                      description: 'annonces et documents',
                    ),
                    icon: Icons.campaign_rounded,
                    color: AppColors.cyan,
                  ),
                  StatCard(
                    metric: KpiMetric(
                      title: 'Reclamations',
                      value: '${data['nombre_reclamations'] ?? 0}',
                      trend:
                          '${data['nombre_reclamations_en_attente'] ?? 0} attente',
                      description: 'liees a vos cours',
                    ),
                    icon: Icons.mark_email_unread_rounded,
                    color: AppColors.violet,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SmartTable(
                title: 'Cours attribues',
                subtitle:
                    'Informations confirmees par les affectations reelles.',
                columns: const [
                  DataColumn(label: Text('Cours')),
                  DataColumn(label: Text('Promotion')),
                  DataColumn(label: Text('Annee')),
                  DataColumn(label: Text('Credits')),
                  DataColumn(label: Text('Heures')),
                  DataColumn(label: Text('Etudiants')),
                ],
                rows: [
                  for (final item in stats)
                    DataRow(
                      cells: [
                        DataCell(Text('${item['cours'] ?? '-'}')),
                        DataCell(Text('${item['promotion'] ?? '-'}')),
                        DataCell(Text('${item['annee_academique'] ?? '-'}')),
                        DataCell(Text('${item['credits'] ?? 0}')),
                        DataCell(Text('${item['nombre_heures'] ?? 0}')),
                        DataCell(Text('${item['nombre_etudiants'] ?? 0}')),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 22),
              ResponsiveGrid(
                minItemWidth: 270,
                maxColumns: 4,
                children: [
                  FeatureTile(
                    icon: Icons.menu_book_rounded,
                    title: 'Mes cours',
                    subtitle: 'Entrer par cours et gerer les donnees.',
                    color: AppColors.primary,
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.teacherCourses),
                  ),
                  FeatureTile(
                    icon: Icons.upload_file_rounded,
                    title: 'Publier les notes',
                    subtitle: 'Encoder, brouillonner puis publier.',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.grades),
                  ),
                  FeatureTile(
                    icon: Icons.campaign_rounded,
                    title: 'Valve',
                    subtitle: 'Publier annonces et documents.',
                    color: AppColors.cyan,
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.notifications),
                  ),
                  FeatureTile(
                    icon: Icons.groups_rounded,
                    title: 'Etudiants a risque',
                    subtitle: 'Voir les moyennes faibles.',
                    color: AppColors.warning,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.riskStudents),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              ResponsiveGrid(
                minItemWidth: 320,
                maxColumns: 3,
                children: [
                  SectionPanel(
                    title: 'Dernieres activites',
                    subtitle: 'Evenements utiles de vos cours.',
                    child: Column(
                      children: [
                        if (activites.isEmpty)
                          const Text('Aucune activite recente.'),
                        for (final item in activites.take(5))
                          _Line(
                            title: '${item['titre'] ?? '-'}',
                            subtitle: '${item['detail'] ?? '-'}',
                            icon: _activityIcon('${item['type'] ?? ''}'),
                          ),
                      ],
                    ),
                  ),
                  SectionPanel(
                    title: 'Publications recentes',
                    subtitle: 'Valve de vos cours.',
                    child: Column(
                      children: [
                        if (publications.isEmpty)
                          const Text('Aucune publication recente.'),
                        for (final item in publications.take(5))
                          _Line(
                            title: '${item['titre'] ?? '-'}',
                            subtitle: '${item['cours'] ?? '-'}',
                            icon: Icons.campaign_rounded,
                          ),
                      ],
                    ),
                  ),
                  SectionPanel(
                    title: 'Reclamations liees aux cours',
                    subtitle: '${data['nombre_reclamations'] ?? 0} demande(s).',
                    child: Column(
                      children: [
                        if (reclamations.isEmpty)
                          const Text('Aucune reclamation pour vos cours.'),
                        for (final item in reclamations.take(5))
                          _Line(
                            title: '${item['titre'] ?? '-'}',
                            subtitle:
                                '${item['etudiant'] ?? '-'} - ${item['statut'] ?? '-'}',
                            icon: Icons.mark_email_unread_rounded,
                          ),
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

class _TeacherIdentityPanel extends StatelessWidget {
  const _TeacherIdentityPanel({
    required this.profil,
    required this.data,
  });

  final Map<String, dynamic> profil;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final name = '${profil['nom_complet'] ?? 'Enseignant'}'.trim();
    final photoUrl = '${profil['photo_url'] ?? ''}'.trim();
    final imageProvider = _teacherImageProvider(photoUrl);

    return SectionPanel(
      title: name.isEmpty ? 'Bonjour' : 'Bonjour $name',
      subtitle: '${profil['departement'] ?? 'Departement'}',
      trailing: const StatusBadge(
        label: 'Compte enseignant',
        color: AppColors.success,
        icon: Icons.verified_rounded,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.primarySoft,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Text(
                    _initials(name),
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                StatusBadge(
                  label: '${data['nombre_cours'] ?? 0} cours',
                  color: AppColors.primary,
                  icon: Icons.menu_book_rounded,
                ),
                StatusBadge(
                  label: '${data['nombre_total_etudiants'] ?? 0} etudiants',
                  color: AppColors.success,
                  icon: Icons.groups_rounded,
                ),
                StatusBadge(
                  label: '${profil['specialites'] ?? 'Cours attribues'}',
                  color: AppColors.cyan,
                  icon: Icons.school_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
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
                Text(
                  subtitle,
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

ImageProvider<Object>? _teacherImageProvider(String photoUrl) {
  if (photoUrl.isEmpty) return null;

  final normalizedPath =
      photoUrl.startsWith('/') ? photoUrl.substring(1) : photoUrl;
  if (normalizedPath.startsWith('assets/')) {
    return AssetImage(normalizedPath);
  }

  if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
    return NetworkImage(photoUrl);
  }

  return null;
}

IconData _activityIcon(String type) {
  switch (type) {
    case 'note':
      return Icons.fact_check_rounded;
    case 'reclamation':
      return Icons.mark_email_unread_rounded;
    case 'risque':
      return Icons.health_and_safety_rounded;
    case 'cours':
      return Icons.menu_book_rounded;
    default:
      return Icons.campaign_rounded;
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'SF';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

String _messageErreur(Object error) {
  if (error is ApiException) return error.messagePourUtilisateur;
  return ApiConfig.serverUnavailableMessage;
}
