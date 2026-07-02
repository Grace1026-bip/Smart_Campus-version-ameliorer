import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_etudiant.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/tableau_intelligent.dart';
import '../../../commun/composants/carte_statistique.dart';
import '../../../commun/composants/badge_statut.dart';

class StudentCoursesScreen extends StatelessWidget {
  const StudentCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.student,
      selectedRoute: AppRoutes.studentCourses,
      title: 'Mes cours',
      subtitle: 'Cours officiels de votre promotion depuis MySQL.',
      body: FutureBuilder<List<dynamic>>(
        future: EtudiantDataSource.service.cours(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorPanel(message: snapshot.error.toString());
          }

          return _StudentCoursesCatalog(courses: snapshot.data ?? const []);
        },
      ),
    );
  }
}

class _StudentCoursesCatalog extends StatefulWidget {
  const _StudentCoursesCatalog({required this.courses});

  final List<dynamic> courses;

  @override
  State<_StudentCoursesCatalog> createState() => _StudentCoursesCatalogState();
}

class _StudentCoursesCatalogState extends State<_StudentCoursesCatalog> {
  String _query = '';
  String? _status;

  @override
  Widget build(BuildContext context) {
    final courses = widget.courses.cast<Map<String, dynamic>>();
    final filtered = courses.where((course) {
      final haystack = [
        course['code'],
        course['nom'],
        course['promotion'],
        course['semestre'],
        course['enseignant_principal'],
      ].join(' ').toLowerCase();
      final query = _query.trim().toLowerCase();
      final queryOk = query.isEmpty || haystack.contains(query);
      final statusOk = _status == null || course['statut_notes'] == _status;

      return queryOk && statusOk;
    }).toList();

    final credits = courses.fold<int>(
      0,
      (sum, item) => sum + _asInt(item['credits']),
    );
    final publications = courses.fold<int>(
      0,
      (sum, item) => sum + _asInt(item['nombre_publications']),
    );
    final notesPublished =
        courses.where((item) => item['statut_notes'] == 'publiees').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveGrid(
          children: [
            StatCard(
              metric: KpiMetric(
                title: 'Cours suivis',
                value: '${courses.length}',
                trend: 'promotion',
                description: 'inscriptions actives',
              ),
              icon: Icons.menu_book_rounded,
              color: AppColors.primary,
            ),
            StatCard(
              metric: KpiMetric(
                title: 'Credits',
                value: '$credits',
                trend: 'total',
                description: 'credits des cours',
              ),
              icon: Icons.workspace_premium_rounded,
              color: AppColors.success,
            ),
            StatCard(
              metric: KpiMetric(
                title: 'Valve',
                value: '$publications',
                trend: 'publications',
                description: 'annonces et documents',
              ),
              icon: Icons.campaign_rounded,
              color: AppColors.warning,
            ),
            StatCard(
              metric: KpiMetric(
                title: 'Notes publiees',
                value: '$notesPublished',
                trend: 'cours',
                description: 'resultats disponibles',
              ),
              icon: Icons.fact_check_rounded,
              color: AppColors.cyan,
            ),
          ],
        ),
        const SizedBox(height: 22),
        SectionPanel(
          title: 'Recherche',
          subtitle: '${filtered.length} cours affiche(s).',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 360,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Nom, code, enseignant',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<String?>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Etat des notes'),
                  items: const [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Tous les etats'),
                    ),
                    DropdownMenuItem(
                      value: 'non_encodees',
                      child: Text('Non encodees'),
                    ),
                    DropdownMenuItem(
                      value: 'brouillon',
                      child: Text('En preparation'),
                    ),
                    DropdownMenuItem(
                      value: 'publiees',
                      child: Text('Publiees'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _status = value),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        if (filtered.isEmpty)
          const _EmptyState(
            icon: Icons.menu_book_rounded,
            title: 'Aucun cours trouve',
            message: 'Aucun cours ne correspond aux filtres actuels.',
          )
        else
          ResponsiveGrid(
            minItemWidth: 340,
            maxColumns: 3,
            children: [
              for (final course in filtered) _StudentCourseCard(course: course),
            ],
          ),
      ],
    );
  }
}

class _StudentCourseCard extends StatelessWidget {
  const _StudentCourseCard({required this.course});

  final Map<String, dynamic> course;

  @override
  Widget build(BuildContext context) {
    final assistants = course['assistants'] is List
        ? (course['assistants'] as List).join(', ')
        : '${course['assistants'] ?? ''}';

    return SectionPanel(
      title: '${course['code'] ?? ''} ${course['nom'] ?? ''}',
      subtitle: '${course['promotion'] ?? '-'} - ${course['semestre'] ?? '-'}',
      trailing: _notesBadge('${course['statut_notes'] ?? '-'}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.workspace_premium_rounded,
                label: '${course['credits'] ?? 0} credits',
              ),
              _InfoChip(
                icon: Icons.schedule_rounded,
                label: '${course['nombre_heures'] ?? 0} h',
              ),
              _InfoChip(
                icon: Icons.campaign_rounded,
                label: '${course['nombre_publications'] ?? 0} publications',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoLine(
            label: 'Enseignant',
            value: course['enseignant_principal'] ?? '-',
          ),
          _InfoLine(
            label: 'Assistants',
            value: assistants.trim().isEmpty ? '-' : assistants,
          ),
          _InfoLine(
            label: 'Derniere publication',
            value: course['derniere_publication'] ?? '-',
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(
                AppRoutes.studentCourseDetail,
                arguments: _asInt(course['id']),
              ),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Ouvrir'),
            ),
          ),
        ],
      ),
    );
  }
}

class StudentCourseDetailScreen extends StatelessWidget {
  const StudentCourseDetailScreen({super.key, required this.courseId});

  final int courseId;

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.student,
      selectedRoute: AppRoutes.studentCourseDetail,
      title: 'Detail du cours',
      subtitle: 'Apercu, valve, notes, documents et reclamations du cours.',
      actions: [
        IconButton(
          tooltip: 'Retour',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ],
      body: FutureBuilder<Map<String, dynamic>>(
        future: EtudiantDataSource.service.detailCours(courseId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorPanel(message: snapshot.error.toString());
          }

          final course = snapshot.data ?? {};
          final notes = course['notes'] as List<dynamic>? ?? [];
          final publications = course['publications'] as List<dynamic>? ?? [];
          final documents = course['documents'] as List<dynamic>? ?? [];
          final complaints = course['reclamations'] as List<dynamic>? ?? [];
          final stats = course['statistiques'] as Map<String, dynamic>? ?? {};

          return DefaultTabController(
            length: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionPanel(
                  title: '${course['code'] ?? ''} - ${course['nom'] ?? ''}',
                  subtitle:
                      '${course['promotion'] ?? '-'} | ${course['semestre'] ?? '-'} | ${course['annee_academique'] ?? '-'}',
                  trailing: _notesBadge('${course['statut_notes'] ?? '-'}'),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _InfoChip(
                        icon: Icons.workspace_premium_rounded,
                        label: '${course['credits'] ?? 0} credits',
                      ),
                      _InfoChip(
                        icon: Icons.schedule_rounded,
                        label: '${course['nombre_heures'] ?? 0} heures',
                      ),
                      _InfoChip(
                        icon: Icons.campaign_rounded,
                        label: '${publications.length} publications',
                      ),
                      _InfoChip(
                        icon: Icons.fact_check_rounded,
                        label: '${notes.length} notes publiees',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Apercu'),
                    Tab(text: 'Valve'),
                    Tab(text: 'Notes'),
                    Tab(text: 'Documents'),
                    Tab(text: 'Reclamations'),
                    Tab(text: 'Statistiques'),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 620,
                  child: TabBarView(
                    children: [
                      _OverviewTab(course: course),
                      _PublicationsTab(
                        courseId: _asInt(course['id']),
                        publications: publications,
                      ),
                      _NotesTab(notes: notes),
                      _DocumentsTab(documents: documents),
                      _ComplaintsTab(complaints: complaints),
                      _StatsTab(stats: stats),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.course});

  final Map<String, dynamic> course;

  @override
  Widget build(BuildContext context) {
    final assistants = course['assistants'] is List
        ? (course['assistants'] as List).join(', ')
        : '${course['assistants'] ?? ''}';

    return SingleChildScrollView(
      child: ResponsiveGrid(
        minItemWidth: 360,
        maxColumns: 2,
        children: [
          SectionPanel(
            title: 'Informations du cours',
            subtitle: 'Structure officielle du cours.',
            child: Column(
              children: [
                _InfoLine(label: 'Code', value: course['code']),
                _InfoLine(label: 'Promotion', value: course['promotion']),
                _InfoLine(label: 'Niveau', value: course['niveau']),
                _InfoLine(label: 'Semestre', value: course['semestre']),
                _InfoLine(label: 'Credits', value: course['credits']),
                _InfoLine(label: 'Heures', value: course['nombre_heures']),
              ],
            ),
          ),
          SectionPanel(
            title: 'Encadrement',
            subtitle: 'Equipe pedagogique associee.',
            child: Column(
              children: [
                _InfoLine(
                  label: 'Enseignant principal',
                  value: course['enseignant_principal'] ?? '-',
                ),
                _InfoLine(
                  label: 'Assistants',
                  value: assistants.trim().isEmpty ? '-' : assistants,
                ),
                _InfoLine(
                  label: 'Etat des notes',
                  value: _statusLabel('${course['statut_notes'] ?? '-'}'),
                ),
              ],
            ),
          ),
          SectionPanel(
            title: 'Description',
            subtitle: 'Presentation academique.',
            child: _Paragraph(value: course['description']),
          ),
          SectionPanel(
            title: 'Objectifs',
            subtitle: 'Competences visees.',
            child: _Paragraph(value: course['objectifs']),
          ),
        ],
      ),
    );
  }
}

class _PublicationsTab extends StatelessWidget {
  const _PublicationsTab({required this.courseId, required this.publications});

  final int courseId;
  final List<dynamic> publications;

  @override
  Widget build(BuildContext context) {
    if (publications.isEmpty) {
      return const _EmptyState(
        icon: Icons.campaign_rounded,
        title: 'Aucune publication',
        message: 'La valve de ce cours ne contient pas encore de publication.',
      );
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(
              AppRoutes.studentValveCourse,
              arguments: courseId,
            ),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Voir le fil complet'),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: publications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = publications[index] as Map<String, dynamic>;
              return _PublicationCard(publication: item);
            },
          ),
        ),
      ],
    );
  }
}

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.notes});

  final List<dynamic> notes;

  @override
  Widget build(BuildContext context) {
    return SmartTable(
      title: 'Notes publiees',
      subtitle: '${notes.length} note(s) visible(s).',
      columns: const [
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Note')),
        DataColumn(label: Text('Credits')),
        DataColumn(label: Text('Resultat')),
        DataColumn(label: Text('Publication')),
      ],
      rows: [
        for (final item in notes)
          DataRow(cells: [
            DataCell(Text('${item['type_note'] ?? '-'}')),
            DataCell(Text(_formatNumber(item['valeur']))),
            DataCell(Text('${item['credits'] ?? 0}')),
            DataCell(_resultBadge('${item['resultat'] ?? '-'}')),
            DataCell(Text('${item['date_publication'] ?? '-'}')),
          ]),
      ],
    );
  }
}

class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab({required this.documents});

  final List<dynamic> documents;

  @override
  Widget build(BuildContext context) {
    return SmartTable(
      title: 'Documents du cours',
      subtitle: '${documents.length} document(s).',
      columns: const [
        DataColumn(label: Text('Titre')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Lien')),
        DataColumn(label: Text('Date')),
      ],
      rows: [
        for (final item in documents)
          DataRow(cells: [
            DataCell(Text('${item['titre'] ?? '-'}')),
            DataCell(Text('${item['type_document'] ?? '-'}')),
            DataCell(SelectableText('${item['url_document'] ?? '-'}')),
            DataCell(Text('${item['date_creation'] ?? '-'}')),
          ]),
      ],
    );
  }
}

class _ComplaintsTab extends StatelessWidget {
  const _ComplaintsTab({required this.complaints});

  final List<dynamic> complaints;

  @override
  Widget build(BuildContext context) {
    return SmartTable(
      title: 'Mes reclamations du cours',
      subtitle: '${complaints.length} demande(s).',
      trailing: FilledButton.icon(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.complaints),
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('Nouvelle'),
      ),
      columns: const [
        DataColumn(label: Text('Objet')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Priorite')),
        DataColumn(label: Text('Statut')),
        DataColumn(label: Text('Date')),
      ],
      rows: [
        for (final item in complaints)
          DataRow(cells: [
            DataCell(Text('${item['titre'] ?? '-'}')),
            DataCell(Text('${item['type_reclamation'] ?? '-'}')),
            DataCell(Text('${item['priorite'] ?? '-'}')),
            DataCell(_statusBadge('${item['statut'] ?? '-'}')),
            DataCell(Text('${item['date_creation'] ?? '-'}')),
          ]),
      ],
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab({required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    return ResponsiveGrid(
      children: [
        StatCard(
          metric: KpiMetric(
            title: 'Moyenne du cours',
            value: _formatNumber(stats['moyenne_cours']),
            trend: '/20',
            description: 'moyennes publiees',
          ),
          icon: Icons.analytics_rounded,
          color: AppColors.primary,
        ),
        StatCard(
          metric: KpiMetric(
            title: 'Reussite',
            value: '${_formatNumber(stats['taux_reussite'])}%',
            trend: '${stats['reussites'] ?? 0} valide(s)',
            description: 'moyenne >= 10',
          ),
          icon: Icons.trending_up_rounded,
          color: AppColors.success,
        ),
        StatCard(
          metric: KpiMetric(
            title: 'Echec',
            value: '${_formatNumber(stats['taux_echec'])}%',
            trend: '${stats['echecs'] ?? 0} echec(s)',
            description: 'moyenne < 10',
          ),
          icon: Icons.trending_down_rounded,
          color: AppColors.danger,
        ),
        StatCard(
          metric: KpiMetric(
            title: 'A risque',
            value: '${stats['etudiants_a_risque'] ?? 0}',
            trend: 'cours',
            description: 'moyenne < 12',
          ),
          icon: Icons.health_and_safety_rounded,
          color: AppColors.warning,
        ),
      ],
    );
  }
}

class _PublicationCard extends StatelessWidget {
  const _PublicationCard({required this.publication});

  final Map<String, dynamic> publication;

  @override
  Widget build(BuildContext context) {
    final attachment = '${publication['piece_jointe_url'] ?? ''}'.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.campaign_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${publication['titre'] ?? '-'}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    StatusBadge(
                      label: _typeLabel('${publication['type_publication'] ?? '-'}'),
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${publication['auteur'] ?? '-'} - ${publication['date_publication'] ?? '-'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${publication['contenu'] ?? '-'}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (attachment.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoChip(
                    icon: Icons.attach_file_rounded,
                    label: attachment,
                  ),
                ],
              ],
            ),
          ),
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              '${value ?? '-'}',
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph({required this.value});

  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final text = '${value ?? ''}'.trim();

    return Text(
      text.isEmpty ? '-' : text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        height: 1.45,
        fontWeight: FontWeight.w600,
      ),
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

StatusBadge _notesBadge(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('publie')) {
    return const StatusBadge(label: 'Notes publiees', color: AppColors.success);
  }
  if (normalized.contains('brouillon')) {
    return const StatusBadge(label: 'En preparation', color: AppColors.warning);
  }
  return const StatusBadge(label: 'Non encodees', color: AppColors.textSecondary);
}

StatusBadge _statusBadge(String status) {
  switch (status) {
    case 'en_attente':
      return const StatusBadge(label: 'En attente', color: AppColors.warning);
    case 'en_cours':
      return const StatusBadge(label: 'En cours', color: AppColors.cyan);
    case 'resolue':
      return const StatusBadge(label: 'Resolue', color: AppColors.success);
    case 'rejetee':
      return const StatusBadge(label: 'Rejetee', color: AppColors.danger);
    case 'transmise':
    case 'transmise_apparitorat':
      return const StatusBadge(label: 'Transmise', color: AppColors.primary);
    default:
      return StatusBadge(label: status, color: AppColors.textSecondary);
  }
}

StatusBadge _resultBadge(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('reuss') || normalized.contains('valide')) {
    return StatusBadge(label: status, color: AppColors.success);
  }
  if (normalized.contains('echec') || normalized.contains('non')) {
    return StatusBadge(label: status, color: AppColors.danger);
  }
  return StatusBadge(label: status, color: AppColors.textSecondary);
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? 0}') ?? 0;
}

String _formatNumber(dynamic value) {
  if (value == null) return '-';
  if (value is num) return value.toStringAsFixed(2);
  return value.toString();
}

String _statusLabel(String status) {
  switch (status) {
    case 'publiees':
      return 'Notes publiees';
    case 'brouillon':
      return 'En preparation';
    case 'non_encodees':
      return 'Non encodees';
    default:
      return status;
  }
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
