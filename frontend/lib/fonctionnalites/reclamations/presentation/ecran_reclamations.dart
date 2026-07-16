import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_enseignant.dart';
import '../../../donnees/services/service_etudiant.dart';
import '../../../donnees/services/service_reclamations.dart';
import '../../../donnees/services/service_api.dart';
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
  @override
  Widget build(BuildContext context) {
    final role = SessionService.currentRole;
    if (role == UserRole.student) {
      return const _StudentComplaintsScreen();
    }
    if (role == UserRole.teacher) {
      return const _TeacherComplaintsScreen();
    }

    return const _TreatmentComplaintsScreen();
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
    final warnings = <String>[];
    final complaints = await _safeList(
      EtudiantDataSource.service.reclamations(),
      'Les reclamations n ont pas pu etre chargees.',
      warnings,
    );
    final courses = await _safeList(
      EtudiantDataSource.service.cours(),
      'Les cours n ont pas pu etre charges.',
      warnings,
    );
    final notesPayload = await _safeMap(
      EtudiantDataSource.service.notes(),
      'Les notes n ont pas pu etre chargees.',
      warnings,
    );

    return _StudentComplaintData(
      complaints: complaints,
      courses: courses,
      notes: notesPayload['notes'] as List<dynamic>? ?? const [],
      warnings: warnings,
    );
  }

  Future<List<dynamic>> _safeList(
    Future<List<dynamic>> future,
    String message,
    List<String> warnings,
  ) async {
    try {
      return await future;
    } catch (error) {
      warnings.add('$message ${error.toString()}');
      return const [];
    }
  }

  Future<Map<String, dynamic>> _safeMap(
    Future<Map<String, dynamic>> future,
    String message,
    List<String> warnings,
  ) async {
    try {
      return await future;
    } catch (error) {
      warnings.add('$message ${error.toString()}');
      return const {};
    }
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
              title: 'Donnees indisponibles',
              subtitle: snapshot.error.toString(),
              child: Text(snapshot.error.toString()),
            );
          }

          final data = snapshot.data ??
              const _StudentComplaintData(
                complaints: [],
                courses: [],
                notes: [],
                warnings: [],
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
              if (data.warnings.isNotEmpty) ...[
                const SizedBox(height: 22),
                _LoadWarningPanel(messages: data.warnings),
              ],
              const SizedBox(height: 22),
              SectionPanel(
                title: 'Nouvelle reclamation',
                subtitle:
                    'Choisissez le cours concerne et decrivez le probleme.',
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
          content:
              Text('Le cours, l objet et la description sont obligatoires.'),
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
    required this.warnings,
  });

  final List<dynamic> complaints;
  final List<dynamic> courses;
  final List<dynamic> notes;
  final List<String> warnings;
}

class _LoadWarningPanel extends StatelessWidget {
  const _LoadWarningPanel({required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: 'Chargement partiel',
      subtitle:
          'La page reste disponible, mais certaines donnees secondaires manquent.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final message in messages)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(child: Text(message)),
                ],
              ),
            ),
        ],
      ),
    );
  }
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
  late Future<List<dynamic>> _future =
      EnseignantDataSource.service.reclamations();
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
              title: 'Donnees indisponibles',
              subtitle: snapshot.error.toString(),
              child: Text(snapshot.error.toString()),
            );
          }

          final allComplaints = snapshot.data ?? [];
          final courses = <int, String>{};
          for (final item in allComplaints) {
            final courseId = _asInt(item['cours_id']);
            if (courseId > 0) {
              courses[courseId] =
                  '${item['code_cours'] ?? ''} ${item['cours'] ?? ''}'.trim();
            }
          }

          final complaints = allComplaints.where((item) {
            final statusOk =
                _statusFilter == null || item['statut'] == _statusFilter;
            final courseOk = _courseFilter == null ||
                _asInt(item['cours_id']) == _courseFilter;
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
    final detail = await EnseignantDataSource.service
        .detailReclamation(_asInt(item['id']));
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
                  DropdownMenuItem(
                      value: 'en_attente', child: Text('En attente')),
                  DropdownMenuItem(value: 'en_cours', child: Text('En cours')),
                  DropdownMenuItem(value: 'resolue', child: Text('Resolue')),
                  DropdownMenuItem(
                    value: 'transmise_apparitorat',
                    child: Text('Transmise apparitorat'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _status = value ?? _status),
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
                Text('Historique',
                    style: Theme.of(context).textTheme.titleSmall),
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
    case UserRole.viceDean:
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
    case UserRole.surveillant:
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

class _TreatmentComplaintsScreen extends StatelessWidget {
  const _TreatmentComplaintsScreen();

  @override
  Widget build(BuildContext context) {
    final role = SessionService.currentRole;
    final config = _configForRole(role);
    return SmartFacultyShell(
      role: role,
      selectedRoute: AppRoutes.complaints,
      title: config.title,
      subtitle: config.subtitle,
      body: FutureBuilder<Map<String, dynamic>>(
        future: ReclamationsDataSource.service.reclamationsTraitement(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return SectionPanel(
              title: 'Donnees indisponibles',
              subtitle: _apiMessage(snapshot.error!),
              child: Text(_apiMessage(snapshot.error!)),
            );
          }
          final payload = snapshot.data ?? const {};
          final elements = payload['elements'] as List<dynamic>? ?? const [];
          if (elements.isEmpty) {
            return const SectionPanel(
              title: 'Aucune reclamation',
              child: Text('Aucune reclamation disponible pour ce compte.'),
            );
          }
          return SmartTable(
            title: config.listTitle,
            subtitle: '${elements.length} demande(s) provenant de FastAPI.',
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Objet')),
              DataColumn(label: Text('Categorie')),
              DataColumn(label: Text('Statut')),
              DataColumn(label: Text('Priorite')),
            ],
            rows: [
              for (final item in elements)
                if (item is Map)
                  DataRow(cells: [
                    DataCell(Text('${item['id'] ?? '-'}')),
                    DataCell(Text('${item['objet'] ?? '-'}')),
                    DataCell(Text('${item['categorie'] ?? '-'}')),
                    DataCell(Text('${item['statut'] ?? '-'}')),
                    DataCell(Text('${item['priorite'] ?? '-'}')),
                  ]),
            ],
          );
        },
      ),
    );
  }
}

String _apiMessage(Object error) {
  if (error is ApiException) return error.messagePourUtilisateur;
  return 'Les reclamations ne peuvent pas etre chargees pour le moment.';
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? 0}') ?? 0;
}
