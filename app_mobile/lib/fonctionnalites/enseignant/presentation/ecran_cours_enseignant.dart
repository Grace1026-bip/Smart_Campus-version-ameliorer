import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_enseignant.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/tableau_intelligent.dart';
import '../../../commun/composants/carte_statistique.dart';
import '../../../commun/composants/badge_statut.dart';

class TeacherCoursesScreen extends StatelessWidget {
  const TeacherCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.teacher,
      selectedRoute: AppRoutes.teacherCourses,
      title: 'Mes cours',
      subtitle: 'Cours attribues a votre compte enseignant.',
      body: FutureBuilder<List<dynamic>>(
        future: EnseignantDataSource.service.cours(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorPanel(message: snapshot.error.toString());
          }

          final courses = snapshot.data ?? [];
          return _CoursesCatalog(courses: courses);
        },
      ),
    );
  }
}

class _CoursesCatalog extends StatefulWidget {
  const _CoursesCatalog({required this.courses});

  final List<dynamic> courses;

  @override
  State<_CoursesCatalog> createState() => _CoursesCatalogState();
}

class _CoursesCatalogState extends State<_CoursesCatalog> {
  String _query = '';
  String? _status;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.courses.where((item) {
      final course = item as Map<String, dynamic>;
      final haystack = [
        course['code'],
        course['nom'],
        course['promotion'],
        course['semestre'],
      ].join(' ').toLowerCase();
      final queryOk = _query.trim().isEmpty ||
          haystack.contains(_query.trim().toLowerCase());
      final statusOk = _status == null || course['statut_notes'] == _status;

      return queryOk && statusOk;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveGrid(
          children: [
            StatCard(
              metric: KpiMetric(
                title: 'Cours',
                value: '${widget.courses.length}',
                trend: 'attribues',
                description: 'perimetre enseignant',
              ),
              icon: Icons.menu_book_rounded,
              color: AppColors.primary,
            ),
            StatCard(
              metric: KpiMetric(
                title: 'Etudiants',
                value:
                    '${widget.courses.fold<int>(0, (sum, item) => sum + _asInt(item['nombre_etudiants']))}',
                trend: 'inscrits',
                description: 'tous vos cours',
              ),
              icon: Icons.groups_rounded,
              color: AppColors.success,
            ),
            StatCard(
              metric: KpiMetric(
                title: 'Notes publiees',
                value:
                    '${widget.courses.where((item) => item['statut_notes'] == 'publiees').length}',
                trend: 'cours',
                description: 'deja visibles',
              ),
              icon: Icons.fact_check_rounded,
              color: AppColors.cyan,
            ),
            StatCard(
              metric: KpiMetric(
                title: 'Valve',
                value:
                    '${widget.courses.fold<int>(0, (sum, item) => sum + _asInt(item['nombre_publications']))}',
                trend: 'publications',
                description: 'annonces et supports',
              ),
              icon: Icons.campaign_rounded,
              color: AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: 22),
        SectionPanel(
          title: 'Rechercher un cours',
          subtitle: '${filtered.length} cours affiche(s).',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 360,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Nom, code, promotion',
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
                      child: Text('Brouillon'),
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
        ResponsiveGrid(
          minItemWidth: 340,
          maxColumns: 3,
          children: [
            for (final course in filtered)
              _CourseCard(course: course as Map<String, dynamic>),
          ],
        ),
      ],
    );
  }
}

class TeacherCourseDetailScreen extends StatelessWidget {
  const TeacherCourseDetailScreen({super.key, required this.courseId});

  final int courseId;

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.teacher,
      selectedRoute: AppRoutes.teacherCourses,
      title: 'Detail du cours',
      subtitle: 'Apercu complet du cours et de ses donnees reelles.',
      actions: [
        IconButton(
          tooltip: 'Retour',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ],
      body: FutureBuilder<Map<String, dynamic>>(
        future: EnseignantDataSource.service.detailCours(courseId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorPanel(message: snapshot.error.toString());
          }

          final course = snapshot.data ?? {};
          final students = course['etudiants'] as List<dynamic>? ?? [];
          final notes = course['notes'] as List<dynamic>? ?? [];
          final publications = course['publications'] as List<dynamic>? ?? [];
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
                        icon: Icons.schedule_rounded,
                        label: '${course['nombre_heures'] ?? 0} heures',
                      ),
                      _InfoChip(
                        icon: Icons.workspace_premium_rounded,
                        label: '${course['credits'] ?? 0} credits',
                      ),
                      _InfoChip(
                        icon: Icons.groups_rounded,
                        label: '${students.length} etudiants',
                      ),
                      _InfoChip(
                        icon: Icons.campaign_rounded,
                        label: '${publications.length} publications',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Apercu'),
                    Tab(text: 'Etudiants'),
                    Tab(text: 'Notes'),
                    Tab(text: 'Valve'),
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
                      _StudentsTab(students: students),
                      _NotesTab(notes: notes),
                      _PublicationsTab(publications: publications),
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

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});

  final Map<String, dynamic> course;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: '${course['code'] ?? ''} - ${course['nom'] ?? ''}',
      subtitle: '${course['promotion'] ?? '-'} | ${course['semestre'] ?? '-'}',
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
                label: '${course['nombre_heures'] ?? 0} heures',
              ),
              _InfoChip(
                icon: Icons.groups_rounded,
                label: '${course['nombre_etudiants'] ?? 0} etudiants',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoLine(label: 'Annee academique', value: course['annee_academique']),
          _InfoLine(label: 'Assistants', value: _join(course['assistants'])),
          _InfoLine(
            label: 'Derniere valve',
            value: course['derniere_publication'] ?? 'Aucune publication',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(
                  AppRoutes.teacherCourseDetail,
                  arguments: _asInt(course['id']),
                ),
                icon: const Icon(Icons.manage_search_rounded),
                label: const Text('Ouvrir'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.grades),
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Notes'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.notifications),
                icon: const Icon(Icons.campaign_rounded),
                label: const Text('Valve'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.course});

  final Map<String, dynamic> course;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: 'Apercu pedagogique',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
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
                icon: Icons.groups_rounded,
                label: '${course['promotion'] ?? '-'}',
              ),
              _InfoChip(
                icon: Icons.person_rounded,
                label: '${course['enseignant_principal'] ?? '-'}',
              ),
            ],
          ),
          const SizedBox(height: 18),
          _Paragraph(title: 'Description', value: course['description']),
          _Paragraph(title: 'Objectifs', value: course['objectifs']),
          _Paragraph(title: 'Assistants', value: _join(course['assistants'])),
          _Paragraph(
            title: 'Modalites d evaluation',
            value: course['modalites_evaluation'],
          ),
        ],
      ),
    );
  }
}

class _StudentsTab extends StatefulWidget {
  const _StudentsTab({required this.students});

  final List<dynamic> students;

  @override
  State<_StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<_StudentsTab> {
  String _query = '';
  bool _riskOnly = false;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.students.where((item) {
      final haystack = [
        item['matricule'],
        item['nom_complet'],
        item['promotion'],
        item['email'],
      ].join(' ').toLowerCase();
      final queryOk = _query.trim().isEmpty ||
          haystack.contains(_query.trim().toLowerCase());
      final riskOk = !_riskOnly ||
          (item['moyenne'] is num && (item['moyenne'] as num) < 12);

      return queryOk && riskOk;
    }).toList();

    return Column(
      children: [
        SectionPanel(
          title: 'Recherche et filtres',
          subtitle: '${filtered.length} etudiant(s) affiche(s).',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 360,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Nom, matricule ou email',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              FilterChip(
                selected: _riskOnly,
                avatar: const Icon(Icons.health_and_safety_rounded),
                label: const Text('A risque'),
                onSelected: (value) => setState(() => _riskOnly = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: SmartTable(
            title: 'Etudiants inscrits',
            subtitle: '${widget.students.length} etudiant(s) dans le cours.',
            columns: const [
              DataColumn(label: Text('Matricule')),
              DataColumn(label: Text('Nom')),
              DataColumn(label: Text('Promotion')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Moyenne')),
            ],
            rows: [
              for (final item in filtered)
                DataRow(cells: [
                  DataCell(Text('${item['matricule'] ?? '-'}')),
                  DataCell(Text('${item['nom_complet'] ?? '-'}')),
                  DataCell(Text('${item['promotion'] ?? '-'}')),
                  DataCell(Text('${item['email'] ?? '-'}')),
                  DataCell(Text(_formatNumber(item['moyenne']))),
                ]),
            ],
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
      title: 'Notes du cours',
      subtitle: '${notes.length} note(s).',
      trailing: ElevatedButton.icon(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.grades),
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Encoder'),
      ),
      columns: const [
        DataColumn(label: Text('Etudiant')),
        DataColumn(label: Text('Matricule')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Valeur')),
        DataColumn(label: Text('Statut')),
      ],
      rows: [
        for (final item in notes)
          DataRow(cells: [
            DataCell(Text('${item['etudiant'] ?? '-'}')),
            DataCell(Text('${item['matricule'] ?? '-'}')),
            DataCell(Text('${item['type_note'] ?? '-'}')),
            DataCell(Text(_formatNumber(item['valeur']))),
            DataCell(_notesBadge('${item['statut'] ?? '-'}')),
          ]),
      ],
    );
  }
}

class _PublicationsTab extends StatelessWidget {
  const _PublicationsTab({required this.publications});

  final List<dynamic> publications;

  @override
  Widget build(BuildContext context) {
    return SmartTable(
      title: 'Valve du cours',
      subtitle: '${publications.length} publication(s).',
      trailing: ElevatedButton.icon(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.notifications),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Publier'),
      ),
      columns: const [
        DataColumn(label: Text('Titre')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Statut')),
        DataColumn(label: Text('Important')),
        DataColumn(label: Text('Date')),
      ],
      rows: [
        for (final item in publications)
          DataRow(cells: [
            DataCell(Text('${item['titre'] ?? '-'}')),
            DataCell(Text('${item['type_publication'] ?? '-'}')),
            DataCell(_notesBadge('${item['statut'] ?? '-'}')),
            DataCell(Text(item['est_important'] == true ? 'Oui' : 'Non')),
            DataCell(Text('${item['date_publication'] ?? '-'}')),
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
      title: 'Reclamations du cours',
      subtitle: '${complaints.length} demande(s).',
      trailing: ElevatedButton.icon(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.complaints),
        icon: const Icon(Icons.rate_review_rounded),
        label: const Text('Traiter'),
      ),
      columns: const [
        DataColumn(label: Text('Titre')),
        DataColumn(label: Text('Etudiant')),
        DataColumn(label: Text('Priorite')),
        DataColumn(label: Text('Statut')),
      ],
      rows: [
        for (final item in complaints)
          DataRow(cells: [
            DataCell(Text('${item['titre'] ?? '-'}')),
            DataCell(Text('${item['etudiant'] ?? '-'}')),
            DataCell(Text('${item['priorite'] ?? '-'}')),
            DataCell(_notesBadge('${item['statut'] ?? '-'}')),
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
            title: 'Taux reussite',
            value: '${_formatNumber(stats['taux_reussite'])}%',
            trend: '${stats['reussites'] ?? 0} reussite(s)',
            description: 'moyenne >= 10',
          ),
          icon: Icons.trending_up_rounded,
          color: AppColors.success,
        ),
        StatCard(
          metric: KpiMetric(
            title: 'Taux echec',
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
            trend: 'moyenne < 12',
            description: 'suivi conseille',
          ),
          icon: Icons.health_and_safety_rounded,
          color: AppColors.warning,
        ),
      ],
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
      label: Text(label),
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
      padding: const EdgeInsets.only(bottom: 8),
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
  const _Paragraph({required this.title, required this.value});

  final String title;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(
            '${value ?? '-'}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
              fontWeight: FontWeight.w600,
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

StatusBadge _notesBadge(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('publie') || normalized.contains('resolue')) {
    return StatusBadge(label: status, color: AppColors.success);
  }
  if (normalized.contains('brouillon') || normalized == 'en_cours') {
    return StatusBadge(label: status, color: AppColors.warning);
  }
  if (normalized.contains('verrouille')) {
    return StatusBadge(label: status, color: AppColors.primary);
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

String _join(dynamic value) {
  if (value is List) return value.isEmpty ? '-' : value.join(', ');
  return '${value ?? '-'}';
}
