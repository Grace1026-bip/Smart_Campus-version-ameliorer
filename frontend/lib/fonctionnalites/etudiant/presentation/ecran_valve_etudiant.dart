import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_etudiant.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/carte_statistique.dart';
import '../../../commun/composants/badge_statut.dart';

class StudentValveScreen extends StatelessWidget {
  const StudentValveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.student,
      selectedRoute: AppRoutes.studentValve,
      title: 'Valve etudiante',
      subtitle: 'Publications officielles liees uniquement a vos cours.',
      body: FutureBuilder<List<dynamic>>(
        future: EtudiantDataSource.service.valve(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorPanel(message: snapshot.error.toString());
          }

          return _StudentValveCatalog(courses: snapshot.data ?? const []);
        },
      ),
    );
  }
}

class _StudentValveCatalog extends StatefulWidget {
  const _StudentValveCatalog({required this.courses});

  final List<dynamic> courses;

  @override
  State<_StudentValveCatalog> createState() => _StudentValveCatalogState();
}

class _StudentValveCatalogState extends State<_StudentValveCatalog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final courses = widget.courses.cast<Map<String, dynamic>>();
    final filtered = courses.where((course) {
      final haystack = [
        course['code'],
        course['nom'],
        course['promotion'],
        course['enseignant_principal'],
      ].join(' ').toLowerCase();
      final query = _query.trim().toLowerCase();

      return query.isEmpty || haystack.contains(query);
    }).toList();

    final totalPublications = courses.fold<int>(
      0,
      (sum, item) => sum + _asInt(item['nombre_publications']),
    );
    final newCourses = courses.where((item) => item['nouveau'] == true).length;
    final recentPublications = courses.fold<int>(
      0,
      (sum, item) =>
          sum + ((item['publications_recentes'] as List<dynamic>?)?.length ?? 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveGrid(
          children: [
            StatCard(
              metric: KpiMetric(
                title: 'Cours suivis',
                value: '${courses.length}',
                trend: 'valve',
                description: 'perimetre etudiant',
              ),
              icon: Icons.menu_book_rounded,
              color: AppColors.primary,
            ),
            StatCard(
              metric: KpiMetric(
                title: 'Publications',
                value: '$totalPublications',
                trend: 'officielles',
                description: 'annonces et documents',
              ),
              icon: Icons.campaign_rounded,
              color: AppColors.warning,
            ),
            StatCard(
              metric: KpiMetric(
                title: 'Nouveautes',
                value: '$newCourses',
                trend: 'cours',
                description: 'activite recente',
              ),
              icon: Icons.fiber_new_rounded,
              color: AppColors.success,
            ),
            StatCard(
              metric: KpiMetric(
                title: 'Recentes',
                value: '$recentPublications',
                trend: 'affichees',
                description: 'dernieres publications',
              ),
              icon: Icons.update_rounded,
              color: AppColors.cyan,
            ),
          ],
        ),
        const SizedBox(height: 22),
        SectionPanel(
          title: 'Cours et publications',
          subtitle: '${filtered.length} cours affiche(s).',
          child: SizedBox(
            width: 360,
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Rechercher un cours',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
        ),
        const SizedBox(height: 22),
        if (filtered.isEmpty)
          const _EmptyState(
            icon: Icons.campaign_rounded,
            title: 'Aucune publication',
            message: 'Aucune valve ne correspond a votre recherche.',
          )
        else
          ResponsiveGrid(
            minItemWidth: 360,
            maxColumns: 2,
            children: [
              for (final course in filtered) _ValveCourseCard(course: course),
            ],
          ),
      ],
    );
  }
}

class _ValveCourseCard extends StatelessWidget {
  const _ValveCourseCard({required this.course});

  final Map<String, dynamic> course;

  @override
  Widget build(BuildContext context) {
    final recent =
        course['publications_recentes'] as List<dynamic>? ?? const [];

    return SectionPanel(
      title: '${course['code'] ?? ''} ${course['nom'] ?? ''}',
      subtitle:
          '${course['promotion'] ?? '-'} - ${course['nombre_publications'] ?? 0} publication(s)',
      trailing: course['nouveau'] == true
          ? const StatusBadge(label: 'Nouveau', color: AppColors.success)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recent.isEmpty)
            const Text(
              'Aucune publication recente.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            for (final item in recent.take(3)) ...[
              _MiniPublication(publication: item as Map<String, dynamic>),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(
                AppRoutes.studentValveCourse,
                arguments: _asInt(course['id']),
              ),
              icon: const Icon(Icons.forum_rounded),
              label: const Text('Ouvrir la valve'),
            ),
          ),
        ],
      ),
    );
  }
}

class StudentCourseValveScreen extends StatelessWidget {
  const StudentCourseValveScreen({super.key, required this.courseId});

  final int courseId;

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.student,
      selectedRoute: AppRoutes.studentValveCourse,
      title: 'Valve du cours',
      subtitle: 'Fil academique officiel du cours selectionne.',
      actions: [
        IconButton(
          tooltip: 'Retour',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ],
      body: FutureBuilder<Map<String, dynamic>>(
        future: EtudiantDataSource.service.valveCours(courseId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorPanel(message: snapshot.error.toString());
          }

          final data = snapshot.data ?? {};
          final course = data['cours'] as Map<String, dynamic>? ?? {};
          final publications = data['publications'] as List<dynamic>? ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionPanel(
                title: '${course['code'] ?? ''} - ${course['nom'] ?? ''}',
                subtitle:
                    '${course['promotion'] ?? '-'} | ${course['semestre'] ?? '-'} | ${course['annee_academique'] ?? '-'}',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _InfoChip(
                      icon: Icons.campaign_rounded,
                      label: '${publications.length} publications',
                    ),
                    _InfoChip(
                      icon: Icons.person_rounded,
                      label: '${course['enseignant_principal'] ?? '-'}',
                    ),
                    _InfoChip(
                      icon: Icons.workspace_premium_rounded,
                      label: '${course['credits'] ?? 0} credits',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (publications.isEmpty)
                const _EmptyState(
                  icon: Icons.campaign_rounded,
                  title: 'Valve vide',
                  message: 'Ce cours ne contient pas encore de publication.',
                )
              else
                Column(
                  children: [
                    for (final publication in publications) ...[
                      _PublicationCard(
                        publication: publication as Map<String, dynamic>,
                        courseLabel:
                            '${course['code'] ?? ''} ${course['nom'] ?? ''}',
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniPublication extends StatelessWidget {
  const _MiniPublication({required this.publication});

  final Map<String, dynamic> publication;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${publication['titre'] ?? '-'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_typeLabel('${publication['type_publication'] ?? '-'}')} - ${publication['date_publication'] ?? '-'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PublicationCard extends StatelessWidget {
  const _PublicationCard({
    required this.publication,
    required this.courseLabel,
  });

  final Map<String, dynamic> publication;
  final String courseLabel;

  @override
  Widget build(BuildContext context) {
    final attachment = '${publication['piece_jointe_url'] ?? ''}'.trim();
    final important = publication['est_important'] == true;

    return SectionPanel(
      title: '${publication['titre'] ?? '-'}',
      subtitle:
          '${publication['auteur'] ?? '-'} - ${publication['date_publication'] ?? '-'}',
      trailing: StatusBadge(
        label: _typeLabel('${publication['type_publication'] ?? '-'}'),
        color: important ? AppColors.warning : AppColors.primary,
        icon: important ? Icons.priority_high_rounded : Icons.campaign_rounded,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(icon: Icons.menu_book_rounded, label: courseLabel),
              if (important)
                const _InfoChip(
                  icon: Icons.priority_high_rounded,
                  label: 'Important',
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${publication['contenu'] ?? '-'}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (attachment.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.attach_file_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      attachment,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, color: AppColors.primary, size: 18),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: AppColors.primarySoft,
      side: const BorderSide(color: AppColors.border),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 42),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
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

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? 0}') ?? 0;
}

String _typeLabel(String type) {
  switch (type) {
    case 'annonce':
      return 'Annonce';
    case 'communique':
      return 'Communique';
    case 'devoir':
      return 'Devoir';
    case 'support_de_cours':
      return 'Document';
    case 'changement_horaire':
      return 'Horaire';
    case 'consigne_examen':
      return 'Consigne';
    case 'publication_notes':
      return 'Notes';
    case 'rappel':
      return 'Rappel';
    default:
      return type;
  }
}
