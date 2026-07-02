import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/donnees_fictives/donnees_faculte_fictives.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_enseignant.dart';
import '../../../donnees/services/service_etudiant.dart';
import '../../../donnees/services/service_session.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/tableau_intelligent.dart';
import '../../../commun/composants/carte_statistique.dart';
import '../../../commun/composants/badge_statut.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  ComplaintStatus? _statusFilter;
  ComplaintType? _typeFilter;

  @override
  Widget build(BuildContext context) {
    final role = SessionService.currentRole;
    if (role == UserRole.student) {
      return const _StudentComplaintsScreen();
    }
    if (role == UserRole.teacher) {
      return const _TeacherComplaintsScreen();
    }

    final config = _configForRole(role);
    final scopedComplaints = _complaintsForRole(role);
    final complaints = scopedComplaints.where((complaint) {
      final statusOk =
          _statusFilter == null || complaint.status == _statusFilter;
      final typeOk = _typeFilter == null || complaint.type == _typeFilter;
      return statusOk && typeOk;
    }).toList();

    return SmartFacultyShell(
      role: role,
      selectedRoute: AppRoutes.complaints,
      title: config.title,
      subtitle: config.subtitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveGrid(children: _buildStats(scopedComplaints, role)),
          const SizedBox(height: 22),
          if (config.canSubmit) ...[
            SectionPanel(
              title: config.formTitle,
              subtitle: config.formSubtitle,
              child: _ComplaintForm(role: role),
            ),
            const SizedBox(height: 22),
          ],
          SectionPanel(
            title: 'Filtres',
            subtitle: config.filterSubtitle,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<ComplaintStatus?>(
                    initialValue: _statusFilter,
                    decoration: const InputDecoration(labelText: 'Statut'),
                    items: [
                      const DropdownMenuItem<ComplaintStatus?>(
                        value: null,
                        child: Text('Tous les statuts'),
                      ),
                      for (final status in ComplaintStatus.values)
                        DropdownMenuItem<ComplaintStatus?>(
                          value: status,
                          child: Text(status.label),
                        ),
                    ],
                    onChanged: (value) => setState(() => _statusFilter = value),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: DropdownButtonFormField<ComplaintType?>(
                    initialValue: _typeFilter,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: [
                      const DropdownMenuItem<ComplaintType?>(
                        value: null,
                        child: Text('Tous les types'),
                      ),
                      for (final type in ComplaintType.values)
                        DropdownMenuItem<ComplaintType?>(
                          value: type,
                          child: Text(type.label),
                        ),
                    ],
                    onChanged: (value) => setState(() => _typeFilter = value),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _statusFilter = null;
                    _typeFilter = null;
                  }),
                  icon: const Icon(Icons.filter_alt_off_rounded),
                  label: const Text('Reinitialiser'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SmartTable(
            title: config.listTitle,
            subtitle: '${complaints.length} demande(s) affichee(s).',
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Objet')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Demandeur')),
              DataColumn(label: Text('Priorite')),
              DataColumn(label: Text('Statut')),
              DataColumn(label: Text('Action')),
            ],
            rows: [
              for (final complaint in complaints)
                DataRow(
                  cells: [
                    DataCell(Text(complaint.id)),
                    DataCell(Text(complaint.title)),
                    DataCell(Text(complaint.type.label)),
                    DataCell(Text(complaint.author)),
                    DataCell(Text(complaint.priority)),
                    DataCell(StatusBadge.complaint(complaint.status)),
                    DataCell(
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pushNamed(
                          AppRoutes.complaintDetail,
                          arguments: complaint,
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Detail'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStats(List<Complaint> complaints, UserRole role) {
    final pending = complaints
        .where((item) => item.status == ComplaintStatus.pending)
        .length;
    final inProgress = complaints
        .where((item) => item.status == ComplaintStatus.inProgress)
        .length;
    final resolved = complaints
        .where((item) => item.status == ComplaintStatus.resolved)
        .length;

    return [
      StatCard(
        metric: KpiMetric(
          title: _totalTitle(role),
          value: '${complaints.length}',
          trend: _scopeLabel(role),
          description: 'dans votre perimetre',
        ),
        icon: Icons.mark_email_unread_rounded,
        color: AppColors.primary,
      ),
      StatCard(
        metric: KpiMetric(
          title: 'En attente',
          value: '$pending',
          trend: pending == 0 ? 'stable' : 'a suivre',
          description: 'non traitee(s)',
        ),
        icon: Icons.schedule_rounded,
        color: AppColors.warning,
      ),
      StatCard(
        metric: KpiMetric(
          title: 'En cours',
          value: '$inProgress',
          trend: inProgress == 0 ? 'calme' : 'actif',
          description: 'dossier(s) ouvert(s)',
        ),
        icon: Icons.sync_rounded,
        color: AppColors.cyan,
      ),
      StatCard(
        metric: KpiMetric(
          title: 'Resolues',
          value: '$resolved',
          trend: resolved == 0 ? 'a venir' : 'cloturees',
          description: 'reponse apportee',
        ),
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      ),
    ];
  }
}

class _StudentComplaintsScreen extends StatefulWidget {
  const _StudentComplaintsScreen();

  @override
  State<_StudentComplaintsScreen> createState() =>
      _StudentComplaintsScreenState();
}

class _StudentComplaintsScreenState extends State<_StudentComplaintsScreen> {
  late Future<_StudentComplaintData> _future = _load();
  String? _statusFilter;
  int? _courseFilter;

  Future<_StudentComplaintData> _load() async {
    final results = await Future.wait<dynamic>([
      EtudiantDataSource.service.reclamations(),
      EtudiantDataSource.service.cours(),
      EtudiantDataSource.service.notes(),
    ]);
    final notesPayload = results[2] as Map<String, dynamic>;

    return _StudentComplaintData(
      complaints: results[0] as List<dynamic>,
      courses: results[1] as List<dynamic>,
      notes: notesPayload['notes'] as List<dynamic>? ?? const [],
    );
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.student,
      selectedRoute: AppRoutes.complaints,
      title: 'Mes reclamations',
      subtitle: 'Soumettre une demande et suivre les reponses recues.',
      actions: [
        IconButton(
          tooltip: 'Actualiser',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: FutureBuilder<_StudentComplaintData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return SectionPanel(
              title: 'Connexion API impossible',
              subtitle: snapshot.error.toString(),
              child: const Text(ApiConfig.serverUnavailableMessage),
            );
          }

          final data = snapshot.data ??
              const _StudentComplaintData(
                complaints: [],
                courses: [],
                notes: [],
              );
          final complaints = data.complaints.where((item) {
            final statusOk =
                _statusFilter == null || item['statut'] == _statusFilter;
            final courseOk = _courseFilter == null ||
                _asInt(item['cours_id']) == _courseFilter;
            return statusOk && courseOk;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveGrid(children: _studentComplaintStats(data.complaints)),
              const SizedBox(height: 22),
              SectionPanel(
                title: 'Nouvelle reclamation',
                subtitle: 'Choisissez le cours concerne et decrivez le probleme.',
                child: _StudentComplaintForm(data: data, onCreated: _refresh),
              ),
              const SizedBox(height: 22),
              SectionPanel(
                title: 'Filtres',
                subtitle: '${complaints.length} demande(s) affichee(s).',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 260,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _statusFilter,
                        decoration: const InputDecoration(labelText: 'Statut'),
                        items: const [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Tous les statuts'),
                          ),
                          DropdownMenuItem(
                            value: 'en_attente',
                            child: Text('En attente'),
                          ),
                          DropdownMenuItem(
                            value: 'en_cours',
                            child: Text('En cours'),
                          ),
                          DropdownMenuItem(
                            value: 'resolue',
                            child: Text('Resolue'),
                          ),
                          DropdownMenuItem(
                            value: 'rejetee',
                            child: Text('Rejetee'),
                          ),
                          DropdownMenuItem(
                            value: 'transmise_apparitorat',
                            child: Text('Transmise'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _statusFilter = value),
                      ),
                    ),
                    SizedBox(
                      width: 320,
                      child: DropdownButtonFormField<int?>(
                        initialValue: _courseFilter,
                        decoration: const InputDecoration(labelText: 'Cours'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Tous les cours'),
                          ),
                          for (final course in data.courses)
                            DropdownMenuItem<int?>(
                              value: _asInt(course['id']),
                              child: Text(
                                '${course['code'] ?? ''} ${course['nom'] ?? ''}',
                              ),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _courseFilter = value),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SmartTable(
                title: 'Historique',
                subtitle: '${complaints.length} reclamation(s).',
                columns: const [
                  DataColumn(label: Text('Objet')),
                  DataColumn(label: Text('Cours')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Priorite')),
                  DataColumn(label: Text('Statut')),
                  DataColumn(label: Text('Date')),
                ],
                rows: [
                  for (final item in complaints)
                    DataRow(cells: [
                      DataCell(Text('${item['titre'] ?? '-'}')),
                      DataCell(Text('${item['code_cours'] ?? '-'}')),
                      DataCell(Text('${item['type_reclamation'] ?? '-'}')),
                      DataCell(Text('${item['priorite'] ?? '-'}')),
                      DataCell(_statusBadge('${item['statut'] ?? '-'}')),
                      DataCell(Text('${item['date_creation'] ?? '-'}')),
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

class _StudentComplaintForm extends StatefulWidget {
  const _StudentComplaintForm({
    required this.data,
    required this.onCreated,
  });

  final _StudentComplaintData data;
  final VoidCallback onCreated;

  @override
  State<_StudentComplaintForm> createState() => _StudentComplaintFormState();
}

class _StudentComplaintFormState extends State<_StudentComplaintForm> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _courseId;
  int? _noteId;
  String _type = 'note';
  String _priority = 'normale';
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes = widget.data.notes.where((note) {
      return _courseId == null || _asInt(note['cours_id']) == _courseId;
    }).toList();

    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 320,
              child: DropdownButtonFormField<int>(
                initialValue: _courseId,
                decoration: const InputDecoration(
                  labelText: 'Cours concerne',
                  prefixIcon: Icon(Icons.menu_book_rounded),
                ),
                items: [
                  for (final course in widget.data.courses)
                    DropdownMenuItem<int>(
                      value: _asInt(course['id']),
                      child: Text(
                        '${course['code'] ?? ''} ${course['nom'] ?? ''}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _courseId = value;
                  _noteId = null;
                }),
              ),
            ),
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'note', child: Text('Note')),
                  DropdownMenuItem(value: 'cours', child: Text('Cours')),
                  DropdownMenuItem(value: 'horaire', child: Text('Horaire')),
                  DropdownMenuItem(value: 'document', child: Text('Document')),
                  DropdownMenuItem(value: 'autre', child: Text('Autre')),
                ],
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priorite',
                  prefixIcon: Icon(Icons.flag_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'faible', child: Text('Faible')),
                  DropdownMenuItem(value: 'normale', child: Text('Normale')),
                  DropdownMenuItem(value: 'haute', child: Text('Haute')),
                ],
                onChanged: (value) =>
                    setState(() => _priority = value ?? _priority),
              ),
            ),
            SizedBox(
              width: 320,
              child: DropdownButtonFormField<int?>(
                initialValue: _noteId,
                decoration: const InputDecoration(
                  labelText: 'Note concernee',
                  prefixIcon: Icon(Icons.fact_check_rounded),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Aucune note specifique'),
                  ),
                  for (final note in notes)
                    DropdownMenuItem<int?>(
                      value: _asInt(note['id']),
                      child: Text(
                        '${note['type_note'] ?? '-'} - ${note['valeur'] ?? '-'} /20',
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _noteId = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Objet',
            prefixIcon: Icon(Icons.subject_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Description',
            prefixIcon: Icon(Icons.notes_rounded),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _submit,
            icon: const Icon(Icons.send_rounded),
            label: Text(_saving ? 'Envoi...' : 'Soumettre'),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final courseId = _courseId;
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (courseId == null || title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le cours, l objet et la description sont obligatoires.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await EtudiantDataSource.service.creerReclamation(
        coursId: courseId,
        noteId: _noteId,
        titre: title,
        description: description,
        type: _type,
        priorite: _priority,
      );
      _titleController.clear();
      _descriptionController.clear();
      if (!mounted) return;
      setState(() {
        _noteId = null;
        _type = 'note';
        _priority = 'normale';
      });
      widget.onCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reclamation envoyee.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _StudentComplaintData {
  const _StudentComplaintData({
    required this.complaints,
    required this.courses,
    required this.notes,
  });

  final List<dynamic> complaints;
  final List<dynamic> courses;
  final List<dynamic> notes;
}

List<Widget> _studentComplaintStats(List<dynamic> complaints) {
  int count(String status) =>
      complaints.where((item) => item['statut'] == status).length;

  return [
    StatCard(
      metric: KpiMetric(
        title: 'Demandes',
        value: '${complaints.length}',
        trend: 'personnel',
        description: 'reclamations envoyees',
      ),
      icon: Icons.mark_email_unread_rounded,
      color: AppColors.primary,
    ),
    StatCard(
      metric: KpiMetric(
        title: 'En attente',
        value: '${count('en_attente')}',
        trend: 'a lire',
        description: 'pas encore traitee(s)',
      ),
      icon: Icons.schedule_rounded,
      color: AppColors.warning,
    ),
    StatCard(
      metric: KpiMetric(
        title: 'En cours',
        value: '${count('en_cours')}',
        trend: 'traitement',
        description: 'suivi enseignant',
      ),
      icon: Icons.sync_rounded,
      color: AppColors.cyan,
    ),
    StatCard(
      metric: KpiMetric(
        title: 'Resolues',
        value: '${count('resolue')}',
        trend: 'cloture',
        description: 'reponse apportee',
      ),
      icon: Icons.check_circle_rounded,
      color: AppColors.success,
    ),
  ];
}

class _TeacherComplaintsScreen extends StatefulWidget {
  const _TeacherComplaintsScreen();

  @override
  State<_TeacherComplaintsScreen> createState() =>
      _TeacherComplaintsScreenState();
}

class _TeacherComplaintsScreenState extends State<_TeacherComplaintsScreen> {
  late Future<List<dynamic>> _future = EnseignantDataSource.service.reclamations();
  String? _statusFilter;
  int? _courseFilter;

  void _refresh() {
    setState(() => _future = EnseignantDataSource.service.reclamations());
  }

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.teacher,
      selectedRoute: AppRoutes.complaints,
      title: 'Reclamations academiques',
      subtitle: 'Demandes liees uniquement a vos cours.',
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return SectionPanel(
              title: 'Connexion API impossible',
              subtitle: snapshot.error.toString(),
              child: const Text(
                ApiConfig.serverUnavailableMessage,
              ),
            );
          }

          final allComplaints = snapshot.data ?? [];
          final courses = <int, String>{};
          for (final item in allComplaints) {
            final courseId = _asInt(item['cours_id']);
            if (courseId > 0) {
              courses[courseId] = '${item['code_cours'] ?? ''} ${item['cours'] ?? ''}'.trim();
            }
          }

          final complaints = allComplaints.where((item) {
            final statusOk =
                _statusFilter == null || item['statut'] == _statusFilter;
            final courseOk =
                _courseFilter == null || _asInt(item['cours_id']) == _courseFilter;
            return statusOk && courseOk;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveGrid(children: _teacherComplaintStats(allComplaints)),
              const SizedBox(height: 22),
              SectionPanel(
                title: 'Filtres',
                subtitle: 'Limiter par cours ou statut.',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 260,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _statusFilter,
                        decoration: const InputDecoration(labelText: 'Statut'),
                        items: const [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Tous les statuts'),
                          ),
                          DropdownMenuItem(
                            value: 'en_attente',
                            child: Text('En attente'),
                          ),
                          DropdownMenuItem(
                            value: 'en_cours',
                            child: Text('En cours'),
                          ),
                          DropdownMenuItem(
                            value: 'resolue',
                            child: Text('Resolue'),
                          ),
                          DropdownMenuItem(
                            value: 'transmise_apparitorat',
                            child: Text('Transmise apparitorat'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _statusFilter = value),
                      ),
                    ),
                    SizedBox(
                      width: 320,
                      child: DropdownButtonFormField<int?>(
                        initialValue: _courseFilter,
                        decoration: const InputDecoration(labelText: 'Cours'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Tous les cours'),
                          ),
                          for (final entry in courses.entries)
                            DropdownMenuItem<int?>(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _courseFilter = value),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SmartTable(
                title: 'Demandes a traiter',
                subtitle: '${complaints.length} reclamation(s).',
                columns: const [
                  DataColumn(label: Text('Objet')),
                  DataColumn(label: Text('Cours')),
                  DataColumn(label: Text('Etudiant')),
                  DataColumn(label: Text('Priorite')),
                  DataColumn(label: Text('Statut')),
                  DataColumn(label: Text('Action')),
                ],
                rows: [
                  for (final item in complaints)
                    DataRow(cells: [
                      DataCell(Text('${item['titre'] ?? '-'}')),
                      DataCell(Text('${item['code_cours'] ?? '-'}')),
                      DataCell(Text('${item['etudiant'] ?? '-'}')),
                      DataCell(Text('${item['priorite'] ?? '-'}')),
                      DataCell(_statusBadge('${item['statut'] ?? '-'}')),
                      DataCell(
                        TextButton.icon(
                          onPressed: () => _openDetail(item),
                          icon: const Icon(Icons.rate_review_rounded, size: 18),
                          label: const Text('Repondre'),
                        ),
                      ),
                    ]),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openDetail(dynamic item) async {
    final detail =
        await EnseignantDataSource.service.detailReclamation(_asInt(item['id']));
    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _TeacherComplaintDialog(reclamation: detail),
    );
    if (saved == true) _refresh();
  }
}

class _TeacherComplaintDialog extends StatefulWidget {
  const _TeacherComplaintDialog({required this.reclamation});

  final Map<String, dynamic> reclamation;

  @override
  State<_TeacherComplaintDialog> createState() =>
      _TeacherComplaintDialogState();
}

class _TeacherComplaintDialogState extends State<_TeacherComplaintDialog> {
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
    final responses = widget.reclamation['reponses'] as List<dynamic>? ?? [];

    return AlertDialog(
      title: Text('${widget.reclamation['titre'] ?? 'Reclamation'}'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.reclamation['description'] ?? '-'}',
                style: const TextStyle(height: 1.4),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  StatusBadge(
                    label: '${widget.reclamation['cours'] ?? '-'}',
                    color: AppColors.primary,
                  ),
                  StatusBadge(
                    label: '${widget.reclamation['etudiant'] ?? '-'}',
                    color: AppColors.cyan,
                  ),
                  _statusBadge(_status),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Nouveau statut'),
                items: const [
                  DropdownMenuItem(value: 'en_attente', child: Text('En attente')),
                  DropdownMenuItem(value: 'en_cours', child: Text('En cours')),
                  DropdownMenuItem(value: 'resolue', child: Text('Resolue')),
                  DropdownMenuItem(
                    value: 'transmise_apparitorat',
                    child: Text('Transmise apparitorat'),
                  ),
                ],
                onChanged: (value) => setState(() => _status = value ?? _status),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Reponse'),
              ),
              const SizedBox(height: 16),
              if (responses.isNotEmpty) ...[
                Text('Historique', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                for (final response in responses)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${response['auteur'] ?? '-'} : ${response['message'] ?? '-'}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Enregistrement...' : 'Enregistrer'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le message de reponse est obligatoire.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await EnseignantDataSource.service.repondreReclamation(
        reclamationId: _asInt(widget.reclamation['id']),
        message: _messageController.text.trim(),
        statut: _status,
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

List<Widget> _teacherComplaintStats(List<dynamic> complaints) {
  int count(String status) =>
      complaints.where((item) => item['statut'] == status).length;

  return [
    StatCard(
      metric: KpiMetric(
        title: 'Total',
        value: '${complaints.length}',
        trend: 'mes cours',
        description: 'reclamations liees',
      ),
      icon: Icons.mark_email_unread_rounded,
      color: AppColors.primary,
    ),
    StatCard(
      metric: KpiMetric(
        title: 'En attente',
        value: '${count('en_attente')}',
        trend: 'a lire',
        description: 'sans reponse',
      ),
      icon: Icons.schedule_rounded,
      color: AppColors.warning,
    ),
    StatCard(
      metric: KpiMetric(
        title: 'En cours',
        value: '${count('en_cours')}',
        trend: 'traitement',
        description: 'reponse en cours',
      ),
      icon: Icons.sync_rounded,
      color: AppColors.cyan,
    ),
    StatCard(
      metric: KpiMetric(
        title: 'Resolues',
        value: '${count('resolue')}',
        trend: 'cloturees',
        description: 'solution apportee',
      ),
      icon: Icons.check_circle_rounded,
      color: AppColors.success,
    ),
  ];
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
    case 'transmise_apparitorat':
      return const StatusBadge(label: 'Transmise', color: AppColors.primary);
    default:
      return StatusBadge(label: status, color: AppColors.textSecondary);
  }
}

class _ComplaintForm extends StatelessWidget {
  const _ComplaintForm({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final isChief = role == UserRole.promotionChief;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final fields = [
          DropdownButtonFormField<ComplaintType>(
            initialValue:
                isChief ? ComplaintType.schedule : ComplaintType.gradeError,
            decoration: const InputDecoration(
              labelText: 'Type de reclamation',
              prefixIcon: Icon(Icons.category_rounded),
            ),
            items: ComplaintType.values
                .map(
                  (type) =>
                      DropdownMenuItem(value: type, child: Text(type.label)),
                )
                .toList(),
            onChanged: (_) {},
          ),
          TextField(
            decoration: InputDecoration(
              labelText: isChief ? 'Objet collectif' : 'Objet',
              prefixIcon: const Icon(Icons.subject_rounded),
            ),
          ),
        ];

        return Column(
          children: [
            if (compact)
              Column(
                children: [
                  for (final field in fields) ...[
                    field,
                    const SizedBox(height: 12),
                  ],
                ],
              )
            else
              Row(
                children: [
                  for (final field in fields) ...[
                    Expanded(child: field),
                    const SizedBox(width: 12),
                  ],
                ],
              ),
            const SizedBox(height: 12),
            TextField(
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: isChief
                    ? 'Expliquez la situation de la promotion'
                    : 'Description',
                alignLabelWithHint: true,
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('La reclamation est prete a etre transmise.'),
                  ),
                ),
                icon: const Icon(Icons.send_rounded),
                label: Text(
                  isChief ? 'Soumettre pour la promotion' : 'Soumettre',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ComplaintRoleConfig {
  const _ComplaintRoleConfig({
    required this.title,
    required this.subtitle,
    required this.canSubmit,
    required this.formTitle,
    required this.formSubtitle,
    required this.filterSubtitle,
    required this.listTitle,
  });

  final String title;
  final String subtitle;
  final bool canSubmit;
  final String formTitle;
  final String formSubtitle;
  final String filterSubtitle;
  final String listTitle;
}

_ComplaintRoleConfig _configForRole(UserRole role) {
  switch (role) {
    case UserRole.student:
      return const _ComplaintRoleConfig(
        title: 'Mes reclamations',
        subtitle: 'Soumettre une demande et suivre les reponses recues.',
        canSubmit: true,
        formTitle: 'Nouvelle reclamation',
        formSubtitle: 'Decrivez clairement le probleme et les details utiles.',
        filterSubtitle: 'Retrouvez rapidement vos demandes.',
        listTitle: 'Mes demandes',
      );
    case UserRole.teacher:
      return const _ComplaintRoleConfig(
        title: 'Reclamations academiques',
        subtitle: 'Traiter les demandes liees aux notes et cours attribues.',
        canSubmit: false,
        formTitle: '',
        formSubtitle: '',
        filterSubtitle: 'Les demandes concernent le volet academique.',
        listTitle: 'Demandes a traiter',
      );
    case UserRole.promotionChief:
      return const _ComplaintRoleConfig(
        title: 'Reclamations de promotion',
        subtitle: 'Porter les demandes collectives et suivre leur traitement.',
        canSubmit: true,
        formTitle: 'Reclamation collective',
        formSubtitle: 'A utiliser quand le probleme concerne la promotion.',
        filterSubtitle: 'Vue limitee aux demandes de votre promotion.',
        listTitle: 'Demandes de la promotion',
      );
    case UserRole.dean:
      return const _ComplaintRoleConfig(
        title: 'Suivi des reclamations',
        subtitle: 'Lire les tendances et identifier les points de blocage.',
        canSubmit: false,
        formTitle: '',
        formSubtitle: '',
        filterSubtitle: 'Vue decisionnelle sur les demandes de la faculte.',
        listTitle: 'Demandes recentes',
      );
    case UserRole.apparitor:
      return const _ComplaintRoleConfig(
        title: 'Reclamations apparitorat',
        subtitle: 'Prioriser, assigner et suivre les demandes academiques.',
        canSubmit: false,
        formTitle: '',
        formSubtitle: '',
        filterSubtitle: 'Vue complete des demandes utiles au suivi quotidien.',
        listTitle: 'Reclamations a suivre',
      );
    case UserRole.administrator:
      return const _ComplaintRoleConfig(
        title: 'Gestion des reclamations',
        subtitle: 'Assigner, suivre et cloturer les demandes administratives.',
        canSubmit: false,
        formTitle: '',
        formSubtitle: '',
        filterSubtitle: 'Vue complete pour le traitement administratif.',
        listTitle: 'Liste des reclamations',
      );
  }
}

List<Complaint> _complaintsForRole(UserRole role) {
  final complaints = MockFacultyData.complaints;
  final user = SessionService.currentUser;

  switch (role) {
    case UserRole.student:
      return complaints.where((item) => item.author == user.name).toList();
    case UserRole.teacher:
      return complaints
          .where((item) => item.type == ComplaintType.gradeError)
          .toList();
    case UserRole.promotionChief:
      return complaints
          .where((item) => item.author.contains('Promotion'))
          .toList();
    case UserRole.apparitor:
    case UserRole.administrator:
    case UserRole.dean:
      return complaints;
  }
}

String _scopeLabel(UserRole role) {
  switch (role) {
    case UserRole.student:
      return 'personnel';
    case UserRole.teacher:
      return 'cours';
    case UserRole.promotionChief:
      return 'promotion';
    case UserRole.dean:
      return 'faculte';
    case UserRole.apparitor:
      return 'apparitorat';
    case UserRole.administrator:
      return 'global';
  }
}

String _totalTitle(UserRole role) {
  switch (role) {
    case UserRole.student:
      return 'Mes demandes';
    case UserRole.teacher:
      return 'A traiter';
    case UserRole.promotionChief:
      return 'Collectives';
    case UserRole.dean:
    case UserRole.apparitor:
    case UserRole.administrator:
      return 'Total';
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? 0}') ?? 0;
}
