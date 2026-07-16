import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_appariteur.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/tableau_intelligent.dart';
import '../../../commun/composants/carte_statistique.dart';
import '../../../commun/composants/badge_statut.dart';

class ApparitorStudentsScreen extends StatefulWidget {
  const ApparitorStudentsScreen({super.key});

  @override
  State<ApparitorStudentsScreen> createState() =>
      _ApparitorStudentsScreenState();
}

class _ApparitorStudentsScreenState extends State<ApparitorStudentsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return _ListShell(
      route: AppRoutes.apparitorStudents,
      title: 'Etudiants',
      subtitle: 'Supervision academique des profils etudiants.',
      future: AppariteurDataSource.service.etudiants(),
      builder: (items) {
        final filtered = _filter(
            items, _query, ['nom_complet', 'matricule', 'promotion', 'email']);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveGrid(children: [
              _stat('Etudiants', '${items.length}', 'total',
                  Icons.groups_rounded, AppColors.primary),
              _stat(
                  'Alertes',
                  '${items.fold<int>(0, (sum, item) => sum + _asInt(item['alertes_actives']))}',
                  'actives',
                  Icons.warning_amber_rounded,
                  AppColors.warning),
              _stat(
                  'Reclamations',
                  '${items.fold<int>(0, (sum, item) => sum + _asInt(item['nombre_reclamations']))}',
                  'suivi',
                  Icons.mark_email_unread_rounded,
                  AppColors.cyan),
              _stat(
                  'Credits valides',
                  '${items.fold<int>(0, (sum, item) => sum + _asInt(item['credits_valides']))}',
                  'cumules',
                  Icons.workspace_premium_rounded,
                  AppColors.success),
            ]),
            const SizedBox(height: 22),
            _SearchPanel(
              value: _query,
              label: 'Rechercher par nom, matricule, promotion',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 22),
            SmartTable(
              title: 'Liste des etudiants',
              subtitle: '${filtered.length} etudiant(s).',
              columns: const [
                DataColumn(label: Text('Matricule')),
                DataColumn(label: Text('Nom')),
                DataColumn(label: Text('Promotion')),
                DataColumn(label: Text('Moyenne')),
                DataColumn(label: Text('Credits')),
                DataColumn(label: Text('Reclamations')),
                DataColumn(label: Text('Alertes')),
              ],
              rows: [
                for (final item in filtered)
                  DataRow(cells: [
                    DataCell(Text('${item['matricule'] ?? '-'}')),
                    DataCell(Text('${item['nom_complet'] ?? '-'}')),
                    DataCell(Text('${item['promotion'] ?? '-'}')),
                    DataCell(Text(_formatNumber(item['moyenne_generale']))),
                    DataCell(Text('${item['credits_valides'] ?? 0}')),
                    DataCell(Text('${item['nombre_reclamations'] ?? 0}')),
                    DataCell(Text('${item['alertes_actives'] ?? 0}')),
                  ]),
              ],
            ),
          ],
        );
      },
    );
  }
}

class ApparitorTeachersScreen extends StatelessWidget {
  const ApparitorTeachersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ListShell(
      route: AppRoutes.apparitorTeachers,
      title: 'Enseignants',
      subtitle: 'Cours attribues, publications et reclamations.',
      future: AppariteurDataSource.service.enseignants(),
      builder: (items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveGrid(children: [
            _stat('Enseignants', '${items.length}', 'total',
                Icons.school_rounded, AppColors.primary),
            _stat(
                'Cours',
                '${items.fold<int>(0, (sum, item) => sum + _asInt(item['nombre_cours']))}',
                'attribues',
                Icons.menu_book_rounded,
                AppColors.success),
            _stat(
                'Publications',
                '${items.fold<int>(0, (sum, item) => sum + _asInt(item['nombre_publications']))}',
                'valve',
                Icons.campaign_rounded,
                AppColors.warning),
            _stat(
                'Reclamations',
                '${items.fold<int>(0, (sum, item) => sum + _asInt(item['nombre_reclamations']))}',
                'liees',
                Icons.mark_email_unread_rounded,
                AppColors.cyan),
          ]),
          const SizedBox(height: 22),
          SmartTable(
            title: 'Liste enseignants',
            subtitle: '${items.length} enseignant(s).',
            columns: const [
              DataColumn(label: Text('Nom')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Departement')),
              DataColumn(label: Text('Cours')),
              DataColumn(label: Text('Publications')),
              DataColumn(label: Text('Reclamations')),
            ],
            rows: [
              for (final item in items)
                DataRow(cells: [
                  DataCell(Text('${item['nom_complet'] ?? '-'}')),
                  DataCell(Text('${item['email'] ?? '-'}')),
                  DataCell(Text('${item['departement'] ?? '-'}')),
                  DataCell(Text('${item['nombre_cours'] ?? 0}')),
                  DataCell(Text('${item['nombre_publications'] ?? 0}')),
                  DataCell(Text('${item['nombre_reclamations'] ?? 0}')),
                ]),
            ],
          ),
        ],
      ),
    );
  }
}

class ApparitorPromotionsScreen extends StatelessWidget {
  const ApparitorPromotionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ListShell(
      route: AppRoutes.apparitorPromotions,
      title: 'Promotions',
      subtitle: 'Effectifs, cours, moyenne et risques par promotion.',
      future: AppariteurDataSource.service.promotions(),
      builder: (items) => ResponsiveGrid(
        minItemWidth: 360,
        maxColumns: 3,
        children: [
          for (final item in items)
            SectionPanel(
              title: '${item['nom'] ?? '-'}',
              subtitle:
                  '${item['effectif'] ?? 0} etudiant(s) - ${item['nombre_cours'] ?? 0} cours',
              trailing: StatusBadge(
                label: '${item['etudiants_a_risque'] ?? 0} risque(s)',
                color: _asInt(item['etudiants_a_risque']) > 0
                    ? AppColors.warning
                    : AppColors.success,
              ),
              child: Column(
                children: [
                  _InfoLine(label: 'Niveau', value: item['niveau']),
                  _InfoLine(
                      label: 'Enseignants', value: item['nombre_enseignants']),
                  _InfoLine(
                      label: 'Moyenne',
                      value: _formatNumber(item['moyenne_generale'])),
                  _InfoLine(label: 'Reussites', value: item['reussites']),
                  _InfoLine(label: 'Echecs', value: item['echecs']),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.apparitorPromotionDetail,
                        arguments: _asInt(item['id']),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Detail'),
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

class ApparitorPromotionDetailScreen extends StatelessWidget {
  const ApparitorPromotionDetailScreen({super.key, required this.promotionId});

  final int promotionId;

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.apparitor,
      selectedRoute: AppRoutes.apparitorPromotions,
      title: 'Detail promotion',
      subtitle: 'Etudiants, cours, reclamations et risques.',
      actions: [
        IconButton(
          tooltip: 'Retour',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ],
      body: FutureBuilder<Map<String, dynamic>>(
        future: AppariteurDataSource.service.detailPromotion(promotionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError)
            return _ErrorPanel(message: snapshot.error.toString());
          final item = snapshot.data ?? {};
          final students = item['etudiants'] as List<dynamic>? ?? const [];
          final courses = item['cours'] as List<dynamic>? ?? const [];
          final risks = item['risques'] as List<dynamic>? ?? const [];
          final complaints = item['reclamations'] as List<dynamic>? ?? const [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionPanel(
                title: '${item['nom'] ?? '-'}',
                subtitle:
                    '${students.length} etudiant(s), ${courses.length} cours.',
                child: ResponsiveGrid(children: [
                  _stat('Moyenne', _formatNumber(item['moyenne_generale']),
                      '/20', Icons.analytics_rounded, AppColors.primary),
                  _stat('Reussites', '${item['reussites'] ?? 0}', 'notes',
                      Icons.trending_up_rounded, AppColors.success),
                  _stat('Echecs', '${item['echecs'] ?? 0}', 'notes',
                      Icons.trending_down_rounded, AppColors.danger),
                  _stat('Risques', '${risks.length}', 'actifs',
                      Icons.health_and_safety_rounded, AppColors.warning),
                ]),
              ),
              const SizedBox(height: 22),
              ResponsiveGrid(
                minItemWidth: 360,
                maxColumns: 2,
                children: [
                  _MiniTable(
                      title: 'Cours',
                      items: courses,
                      columns: const ['code', 'nom', 'statut_notes']),
                  _MiniTable(
                      title: 'Risques',
                      items: risks,
                      columns: const ['etudiant', 'cours', 'niveau']),
                  _MiniTable(
                      title: 'Reclamations',
                      items: complaints,
                      columns: const ['titre', 'code_cours', 'statut']),
                  _MiniTable(
                      title: 'Etudiants',
                      items: students,
                      columns: const [
                        'matricule',
                        'nom_complet',
                        'moyenne_generale'
                      ]),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class ApparitorCoursesScreen extends StatelessWidget {
  const ApparitorCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ListShell(
      route: AppRoutes.apparitorCourses,
      title: 'Cours',
      subtitle: 'Tous les cours, enseignants responsables et etat des notes.',
      future: AppariteurDataSource.service.cours(),
      builder: (items) => SmartTable(
        title: 'Cours supervises',
        subtitle: '${items.length} cours.',
        columns: const [
          DataColumn(label: Text('Code')),
          DataColumn(label: Text('Cours')),
          DataColumn(label: Text('Promotion')),
          DataColumn(label: Text('Enseignant')),
          DataColumn(label: Text('Credits')),
          DataColumn(label: Text('Heures')),
          DataColumn(label: Text('Etudiants')),
          DataColumn(label: Text('Notes')),
          DataColumn(label: Text('Action')),
        ],
        rows: [
          for (final item in items)
            DataRow(cells: [
              DataCell(Text('${item['code'] ?? '-'}')),
              DataCell(Text('${item['nom'] ?? '-'}')),
              DataCell(Text('${item['promotion'] ?? '-'}')),
              DataCell(Text('${item['enseignant_principal'] ?? '-'}')),
              DataCell(Text('${item['credits'] ?? 0}')),
              DataCell(Text('${item['nombre_heures'] ?? 0}')),
              DataCell(Text('${item['nombre_etudiants'] ?? 0}')),
              DataCell(_notesBadge('${item['statut_notes'] ?? '-'}')),
              DataCell(TextButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(
                  AppRoutes.apparitorCourseDetail,
                  arguments: _asInt(item['id']),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Detail'),
              )),
            ]),
        ],
      ),
    );
  }
}

class ApparitorCourseDetailScreen extends StatelessWidget {
  const ApparitorCourseDetailScreen({super.key, required this.courseId});

  final int courseId;

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.apparitor,
      selectedRoute: AppRoutes.apparitorCourses,
      title: 'Detail cours',
      subtitle: 'Etudiants, notes, valve, reclamations et risques.',
      actions: [
        IconButton(
          tooltip: 'Retour',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ],
      body: FutureBuilder<Map<String, dynamic>>(
        future: AppariteurDataSource.service.detailCours(courseId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError)
            return _ErrorPanel(message: snapshot.error.toString());
          final item = snapshot.data ?? {};
          final stats =
              item['statistiques'] as Map<String, dynamic>? ?? const {};
          final students = item['etudiants'] as List<dynamic>? ?? const [];
          final notes = item['notes'] as List<dynamic>? ?? const [];
          final publications =
              item['publications'] as List<dynamic>? ?? const [];
          final documents = item['documents'] as List<dynamic>? ?? const [];
          final complaints = item['reclamations'] as List<dynamic>? ?? const [];
          final risks = item['risques'] as List<dynamic>? ?? const [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionPanel(
                title: '${item['code'] ?? '-'} ${item['nom'] ?? ''}',
                subtitle:
                    '${item['promotion'] ?? '-'} - ${item['enseignant_principal'] ?? 'Enseignant non attribue'}',
                trailing: _notesBadge('${item['statut_notes'] ?? '-'}'),
                child: ResponsiveGrid(children: [
                  _stat(
                      'Etudiants',
                      '${stats['total_etudiants'] ?? students.length}',
                      'inscrits',
                      Icons.groups_rounded,
                      AppColors.primary),
                  _stat('Moyenne', _formatNumber(stats['moyenne_cours']), '/20',
                      Icons.analytics_rounded, AppColors.cyan),
                  _stat('Reussites', '${stats['reussites'] ?? 0}', 'publiees',
                      Icons.trending_up_rounded, AppColors.success),
                  _stat('Risques', '${risks.length}', 'actifs',
                      Icons.health_and_safety_rounded, AppColors.warning),
                ]),
              ),
              const SizedBox(height: 22),
              SectionPanel(
                title: 'Apercu',
                subtitle: 'Informations academiques du cours.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoLine(label: 'Description', value: item['description']),
                    _InfoLine(label: 'Objectifs', value: item['objectifs']),
                    _InfoLine(label: 'Credits', value: item['credits']),
                    _InfoLine(label: 'Heures', value: item['nombre_heures']),
                    _InfoLine(label: 'Semestre', value: item['semestre']),
                    _InfoLine(
                        label: 'Assistants',
                        value: _joinList(item['assistants'])),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              ResponsiveGrid(
                minItemWidth: 420,
                maxColumns: 2,
                children: [
                  _MiniTable(
                      title: 'Etudiants',
                      items: students,
                      columns: const ['matricule', 'nom_complet', 'moyenne']),
                  _MiniTable(title: 'Notes', items: notes, columns: const [
                    'matricule',
                    'etudiant',
                    'type_note',
                    'valeur',
                    'statut'
                  ]),
                  _MiniTable(
                      title: 'Valve',
                      items: publications,
                      columns: const [
                        'titre',
                        'type_publication',
                        'auteur',
                        'date_publication',
                        'statut'
                      ]),
                  _MiniTable(
                      title: 'Documents',
                      items: documents,
                      columns: const [
                        'titre',
                        'type_document',
                        'date_creation'
                      ]),
                  _MiniTable(
                      title: 'Reclamations',
                      items: complaints,
                      columns: const ['titre', 'etudiant', 'statut']),
                  _MiniTable(title: 'Risques', items: risks, columns: const [
                    'etudiant',
                    'moyenne',
                    'niveau',
                    'motif'
                  ]),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class ApparitorComplaintsScreen extends StatefulWidget {
  const ApparitorComplaintsScreen({super.key});

  @override
  State<ApparitorComplaintsScreen> createState() =>
      _ApparitorComplaintsScreenState();
}

class _ApparitorComplaintsScreenState extends State<ApparitorComplaintsScreen> {
  late Future<List<dynamic>> _future =
      AppariteurDataSource.service.reclamations();
  String? _status;
  String _query = '';

  void _refresh() {
    setState(() => _future = AppariteurDataSource.service.reclamations());
  }

  @override
  Widget build(BuildContext context) {
    return _ListShell(
      route: AppRoutes.apparitorComplaints,
      title: 'Centre de reclamations',
      subtitle: 'Suivi, transmission et cloture des demandes.',
      future: _future,
      actions: [
        IconButton(
          tooltip: 'Actualiser',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      builder: (items) {
        final byStatus = _status == null
            ? items
            : items.where((item) => item['statut'] == _status).toList();
        final filtered = _filter(byStatus, _query, [
          'titre',
          'etudiant',
          'cours',
          'code_cours',
          'enseignant',
          'statut'
        ]);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionPanel(
              title: 'Filtres',
              subtitle: '${filtered.length} reclamation(s).',
              child: SizedBox(
                width: 260,
                child: DropdownButtonFormField<String?>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Statut'),
                  items: const [
                    DropdownMenuItem<String?>(value: null, child: Text('Tous')),
                    DropdownMenuItem(
                        value: 'en_attente', child: Text('En attente')),
                    DropdownMenuItem(
                        value: 'en_cours', child: Text('En cours')),
                    DropdownMenuItem(value: 'resolue', child: Text('Resolue')),
                    DropdownMenuItem(
                        value: 'transmise_apparitorat',
                        child: Text('Transmise')),
                  ],
                  onChanged: (value) => setState(() => _status = value),
                ),
              ),
            ),
            const SizedBox(height: 22),
            _SearchPanel(
              value: _query,
              label: 'Rechercher par etudiant, cours, enseignant',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 22),
            SmartTable(
              title: 'Demandes',
              subtitle: '${filtered.length} demande(s).',
              columns: const [
                DataColumn(label: Text('Objet')),
                DataColumn(label: Text('Etudiant')),
                DataColumn(label: Text('Cours')),
                DataColumn(label: Text('Enseignant')),
                DataColumn(label: Text('Statut')),
                DataColumn(label: Text('Action')),
              ],
              rows: [
                for (final item in filtered)
                  DataRow(cells: [
                    DataCell(Text('${item['titre'] ?? '-'}')),
                    DataCell(Text('${item['etudiant'] ?? '-'}')),
                    DataCell(Text('${item['code_cours'] ?? '-'}')),
                    DataCell(Text('${item['enseignant'] ?? '-'}')),
                    DataCell(_statusBadge('${item['statut'] ?? '-'}')),
                    DataCell(TextButton.icon(
                      onPressed: () => _openComplaint(item),
                      icon: const Icon(Icons.rate_review_rounded, size: 18),
                      label: const Text('Suivre'),
                    )),
                  ]),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _openComplaint(dynamic item) async {
    final detail = await AppariteurDataSource.service
        .detailReclamation(_asInt(item['id']));
    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _ApparitorComplaintDialog(reclamation: detail),
    );
    if (saved == true) _refresh();
  }
}

class ApparitorRisksScreen extends StatefulWidget {
  const ApparitorRisksScreen({super.key});

  @override
  State<ApparitorRisksScreen> createState() => _ApparitorRisksScreenState();
}

class _ApparitorRisksScreenState extends State<ApparitorRisksScreen> {
  String? _level;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return _ListShell(
      route: AppRoutes.apparitorRisks,
      title: 'Etudiants a risque',
      subtitle: 'Risques calcules depuis les moyennes finales publiees.',
      future: AppariteurDataSource.service.risques(),
      builder: (items) {
        final byLevel = _level == null
            ? items
            : items.where((item) => item['niveau'] == _level).toList();
        final filtered = _filter(byLevel, _query, [
          'etudiant',
          'promotion',
          'cours',
          'code_cours',
          'niveau',
          'motif'
        ]);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionPanel(
              title: 'Filtres',
              subtitle: '${filtered.length} risque(s).',
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                      label: const Text('Tous'),
                      selected: _level == null,
                      onSelected: (_) => setState(() => _level = null)),
                  ChoiceChip(
                      label: const Text('Eleve'),
                      selected: _level == 'eleve',
                      onSelected: (_) => setState(() => _level = 'eleve')),
                  ChoiceChip(
                      label: const Text('Moyen'),
                      selected: _level == 'moyen',
                      onSelected: (_) => setState(() => _level = 'moyen')),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _SearchPanel(
              value: _query,
              label: 'Filtrer par promotion, cours ou etudiant',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 22),
            SmartTable(
              title: 'Risques academiques',
              subtitle: '${filtered.length} etudiant(s).',
              columns: const [
                DataColumn(label: Text('Etudiant')),
                DataColumn(label: Text('Promotion')),
                DataColumn(label: Text('Cours')),
                DataColumn(label: Text('Moyenne')),
                DataColumn(label: Text('Niveau')),
                DataColumn(label: Text('Motif')),
              ],
              rows: [
                for (final item in filtered)
                  DataRow(cells: [
                    DataCell(Text('${item['etudiant'] ?? '-'}')),
                    DataCell(Text('${item['promotion'] ?? '-'}')),
                    DataCell(Text('${item['cours'] ?? '-'}')),
                    DataCell(Text(_formatNumber(item['moyenne']))),
                    DataCell(_riskBadge('${item['niveau'] ?? '-'}')),
                    DataCell(Text('${item['motif'] ?? '-'}')),
                  ]),
              ],
            ),
          ],
        );
      },
    );
  }
}

class ApparitorProjectsScreen extends StatelessWidget {
  const ApparitorProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SimpleDataScreen(
      route: AppRoutes.apparitorProjects,
      title: 'Projets academiques',
      subtitle: 'Suivi des groupes, encadreurs, livrables et echeances.',
      future: AppariteurDataSource.service
          .projets()
          .then((data) => data['elements'] as List<dynamic>? ?? const []),
      emptyTitle: 'Aucun projet academique',
      emptyMessage:
          'La table MySQL projets_academiques est prete dans le schema. Les donnees apparaitront apres insertion.',
      columns: const [
        'titre',
        'promotion',
        'encadreur',
        'statut',
        'progression',
        'date_echeance'
      ],
    );
  }
}

class ApparitorInternshipsScreen extends StatelessWidget {
  const ApparitorInternshipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SimpleDataScreen(
      route: AppRoutes.apparitorInternships,
      title: 'Stages',
      subtitle: 'Stages L3, L4 et M2 suivis depuis MySQL.',
      future: AppariteurDataSource.service.stages(),
      emptyTitle: 'Aucun stage enregistre',
      emptyMessage:
          'La table MySQL stages est prete dans le schema. Les suivis apparaitront apres insertion.',
      columns: const [
        'etudiant',
        'promotion',
        'entreprise',
        'maitre_stage',
        'statut',
        'date_fin'
      ],
    );
  }
}

class ApparitorReportsScreen extends StatelessWidget {
  const ApparitorReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.apparitor,
      selectedRoute: AppRoutes.apparitorReports,
      title: 'Rapports',
      subtitle: 'Rapports academiques avec exports PDF et Excel prevus.',
      body: FutureBuilder<Map<String, dynamic>>(
        future: AppariteurDataSource.service.rapports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError)
            return _ErrorPanel(message: snapshot.error.toString());
          final reports =
              snapshot.data?['rapports'] as List<dynamic>? ?? const [];
          return ResponsiveGrid(
            minItemWidth: 320,
            maxColumns: 3,
            children: [
              for (final item in reports)
                SectionPanel(
                  title: '${item['titre'] ?? '-'}',
                  subtitle: '${item['description'] ?? '-'}',
                  child: const Wrap(
                    spacing: 8,
                    children: [
                      StatusBadge(
                          label: 'PDF prevu',
                          color: AppColors.primary,
                          icon: Icons.picture_as_pdf_rounded),
                      StatusBadge(
                          label: 'Excel prevu',
                          color: AppColors.success,
                          icon: Icons.table_chart_rounded),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SimpleDataScreen extends StatelessWidget {
  const _SimpleDataScreen({
    required this.route,
    required this.title,
    required this.subtitle,
    required this.future,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.columns,
  });

  final String route;
  final String title;
  final String subtitle;
  final Future<List<dynamic>> future;
  final String emptyTitle;
  final String emptyMessage;
  final List<String> columns;

  @override
  Widget build(BuildContext context) {
    return _ListShell(
      route: route,
      title: title,
      subtitle: subtitle,
      future: future,
      builder: (items) {
        if (items.isEmpty) {
          return _EmptyPanel(title: emptyTitle, message: emptyMessage);
        }
        return _MiniTable(title: title, items: items, columns: columns);
      },
    );
  }
}

class _ListShell extends StatelessWidget {
  const _ListShell({
    required this.route,
    required this.title,
    required this.subtitle,
    required this.future,
    required this.builder,
    this.actions = const [],
  });

  final String route;
  final String title;
  final String subtitle;
  final Future<List<dynamic>> future;
  final Widget Function(List<dynamic>) builder;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.apparitor,
      selectedRoute: route,
      title: title,
      subtitle: subtitle,
      actions: actions,
      body: FutureBuilder<List<dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError)
            return _ErrorPanel(message: snapshot.error.toString());
          return builder(snapshot.data ?? const []);
        },
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final String value;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: 'Recherche',
      subtitle: 'Filtrer rapidement les donnees affichees.',
      child: SizedBox(
        width: 360,
        child: TextField(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.search_rounded),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _MiniTable extends StatelessWidget {
  const _MiniTable({
    required this.title,
    required this.items,
    required this.columns,
  });

  final String title;
  final List<dynamic> items;
  final List<String> columns;

  @override
  Widget build(BuildContext context) {
    return SmartTable(
      title: title,
      subtitle: '${items.length} ligne(s).',
      columns: [
        for (final column in columns) DataColumn(label: Text(_label(column))),
      ],
      rows: [
        for (final item in items)
          DataRow(cells: [
            for (final column in columns)
              DataCell(Text('${item[column] ?? '-'}')),
          ]),
      ],
    );
  }
}

class _ApparitorComplaintDialog extends StatefulWidget {
  const _ApparitorComplaintDialog({required this.reclamation});

  final Map<String, dynamic> reclamation;

  @override
  State<_ApparitorComplaintDialog> createState() =>
      _ApparitorComplaintDialogState();
}

class _ApparitorComplaintDialogState extends State<_ApparitorComplaintDialog> {
  final _messageController = TextEditingController();
  late String _status = '${widget.reclamation['statut'] ?? 'en_cours'}';
  bool _saving = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responses =
        widget.reclamation['reponses'] as List<dynamic>? ?? const [];
    return AlertDialog(
      title: Text('${widget.reclamation['titre'] ?? 'Reclamation'}'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${widget.reclamation['description'] ?? '-'}'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusBadge(
                      label: '${widget.reclamation['etudiant'] ?? '-'}',
                      color: AppColors.primary),
                  StatusBadge(
                      label: '${widget.reclamation['code_cours'] ?? '-'}',
                      color: AppColors.cyan),
                  _statusBadge(_status),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Statut'),
                items: const [
                  DropdownMenuItem(
                      value: 'en_attente', child: Text('En attente')),
                  DropdownMenuItem(value: 'en_cours', child: Text('En cours')),
                  DropdownMenuItem(
                      value: 'transmise_apparitorat', child: Text('Transmise')),
                  DropdownMenuItem(value: 'resolue', child: Text('Resolue')),
                  DropdownMenuItem(value: 'rejetee', child: Text('Rejetee')),
                ],
                onChanged: (value) =>
                    setState(() => _status = value ?? _status),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageController,
                minLines: 3,
                maxLines: 5,
                decoration:
                    const InputDecoration(labelText: 'Message de suivi'),
              ),
              if (responses.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Historique',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                for (final response in responses)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                        '${response['auteur'] ?? '-'} : ${response['message'] ?? '-'}'),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            child: const Text('Annuler')),
        ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Enregistrement...' : 'Enregistrer')),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await AppariteurDataSource.service.changerStatutReclamation(
        id: _asInt(widget.reclamation['id']),
        statut: _status,
        message: _messageController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              '${value ?? '-'}',
              textAlign: TextAlign.right,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              const Icon(Icons.dataset_rounded,
                  color: AppColors.textSecondary, size: 44),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
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
      title: 'Donnees indisponibles',
      subtitle: message,
      child: Text(message),
    );
  }
}

List<dynamic> _filter(List<dynamic> items, String query, List<String> fields) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return items;
  return items.where((item) {
    final haystack =
        fields.map((field) => '${item[field] ?? ''}').join(' ').toLowerCase();
    return haystack.contains(normalized);
  }).toList();
}

StatCard _stat(
    String title, String value, String trend, IconData icon, Color color) {
  return StatCard(
    metric: KpiMetric(
        title: title, value: value, trend: trend, description: 'donnees MySQL'),
    icon: icon,
    color: color,
  );
}

StatusBadge _notesBadge(String status) {
  if (status == 'publiees')
    return const StatusBadge(label: 'Publiees', color: AppColors.success);
  if (status == 'brouillon')
    return const StatusBadge(label: 'Brouillon', color: AppColors.warning);
  return const StatusBadge(
      label: 'Non encodees', color: AppColors.textSecondary);
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

StatusBadge _riskBadge(String level) {
  if (level == 'eleve')
    return const StatusBadge(label: 'Eleve', color: AppColors.danger);
  if (level == 'moyen')
    return const StatusBadge(label: 'Moyen', color: AppColors.warning);
  return const StatusBadge(label: 'Faible', color: AppColors.success);
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

String _joinList(dynamic value) {
  if (value is List && value.isNotEmpty) {
    return value.map((item) => '$item').join(', ');
  }
  return '-';
}

String _label(String value) {
  return value.replaceAll('_', ' ').toUpperCase();
}
