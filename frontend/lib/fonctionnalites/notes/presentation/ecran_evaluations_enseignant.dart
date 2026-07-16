import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_enseignant.dart';
import '../../../donnees/services/service_notes.dart';
import '../../../donnees/services/service_session.dart';
import '../../../commun/composants/badge_statut.dart';
import '../../../commun/composants/carte_statistique.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';

class TeacherEvaluationsScreen extends StatefulWidget {
  const TeacherEvaluationsScreen({super.key, this.initialCourseId});

  final int? initialCourseId;

  @override
  State<TeacherEvaluationsScreen> createState() =>
      _TeacherEvaluationsScreenState();
}

class _TeacherEvaluationsScreenState extends State<TeacherEvaluationsScreen> {
  int? _courseId;
  int? _evaluationId;
  late Future<_EvaluationWorkspace> _future = _load();

  Future<_EvaluationWorkspace> _load() async {
    final courses = await EnseignantDataSource.service.cours();
    if (courses.isEmpty) {
      return const _EvaluationWorkspace();
    }

    final ids = courses.map((course) => _asInt(course['id'])).toSet();
    if (_courseId == null || !ids.contains(_courseId)) {
      _courseId = ids.contains(widget.initialCourseId)
          ? widget.initialCourseId
          : _asInt(courses.first['id']);
    }

    final types = await NotesDataSource.service.typesEvaluations();
    final evaluations =
        await NotesDataSource.service.evaluationsCours(_courseId!);
    final resultats =
        await NotesDataSource.service.apercuResultatsCours(_courseId!);
    final total = evaluations.fold<double>(
      0,
      (sum, item) => sum + _asDouble(item['ponderation']),
    );
    return _EvaluationWorkspace(
      courses: courses,
      types: types,
      evaluations: evaluations,
      resultats: resultats,
      totalPonderation: total,
    );
  }

  void _refresh() {
    setState(() {
      _evaluationId = null;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.teacher,
      selectedRoute: AppRoutes.grades,
      title: 'Evaluations et notes',
      subtitle: 'Saisissez les notes des etudiants de vos cours attribues.',
      body: FutureBuilder<_EvaluationWorkspace>(
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

          final workspace = snapshot.data ?? const _EvaluationWorkspace();
          if (workspace.courses.isEmpty) {
            return const SectionPanel(
              title: 'Aucun cours attribue',
              child: Text('Aucun cours ne vous est actuellement attribue.'),
            );
          }

          final remaining = (100 - workspace.totalPonderation).clamp(0, 100);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionPanel(
                title: 'Cours et evaluations',
                subtitle: 'La ponderation active ne peut pas depasser 100%.',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 360,
                      child: DropdownButtonFormField<int>(
                        initialValue: _courseId,
                        decoration: const InputDecoration(labelText: 'Cours'),
                        items: [
                          for (final course in workspace.courses)
                            DropdownMenuItem<int>(
                              value: _asInt(course['id']),
                              child:
                                  Text('${course['code']} - ${course['nom']}'),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _courseId = value;
                            _evaluationId = null;
                            _future = _load();
                          });
                        },
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: workspace.types.isEmpty
                          ? null
                          : () => _createEvaluation(workspace.types),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Nouvelle evaluation'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ResponsiveGrid(
                children: [
                  StatCard(
                    metric: KpiMetric(
                      title: 'Evaluations',
                      value: '${workspace.evaluations.length}',
                      trend: 'actives',
                      description: 'dans ce cours',
                    ),
                    icon: Icons.assignment_rounded,
                    color: AppColors.primary,
                  ),
                  StatCard(
                    metric: KpiMetric(
                      title: 'Ponderation',
                      value:
                          '${workspace.totalPonderation.toStringAsFixed(2)}%',
                      trend: 'utilisee',
                      description: 'sur 100%',
                    ),
                    icon: Icons.pie_chart_rounded,
                    color: AppColors.secondary,
                  ),
                  StatCard(
                    metric: KpiMetric(
                      title: 'Restant',
                      value: '${remaining.toStringAsFixed(2)}%',
                      trend: 'disponible',
                      description: 'pour ce cours',
                    ),
                    icon: Icons.hourglass_bottom_rounded,
                    color:
                        remaining == 0 ? AppColors.success : AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _CourseResultsPanel(
                resultats: workspace.resultats,
                onPublished: _refresh,
              ),
              const SizedBox(height: 18),
              if (workspace.evaluations.isEmpty)
                const SectionPanel(
                  title: 'Aucune evaluation',
                  child: Text('Creez la premiere evaluation de ce cours.'),
                )
              else
                for (final evaluation in workspace.evaluations)
                  _EvaluationCard(
                    evaluation: evaluation,
                    onNotes: () => setState(
                      () => _evaluationId = _asInt(evaluation['id']),
                    ),
                    onEdit: () => _editEvaluation(evaluation, workspace.types),
                    onPublish: () => _publishEvaluation(evaluation),
                  ),
              if (_evaluationId != null) ...[
                const SizedBox(height: 18),
                _TeacherNotesPanel(
                  key: ValueKey(_evaluationId),
                  evaluationId: _evaluationId!,
                  onChanged: _refresh,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _createEvaluation(List<dynamic> types) async {
    final values = await _evaluationDialog(types: types);
    if (values == null || !mounted) return;
    try {
      await NotesDataSource.service.creerEvaluation(
        coursId: _courseId!,
        donnees: values,
      );
      _refresh();
      _message('Evaluation creee en brouillon.');
    } catch (error) {
      _message(error.toString());
    }
  }

  Future<void> _editEvaluation(
    Map<String, dynamic> evaluation,
    List<dynamic> types,
  ) async {
    if (evaluation['statut'] != 'brouillon' ||
        evaluation['est_verrouillee'] == true) {
      _message('Seule une evaluation en brouillon peut etre modifiee.');
      return;
    }
    final values = await _evaluationDialog(
      types: types,
      initial: evaluation,
    );
    if (values == null || !mounted) return;
    try {
      await NotesDataSource.service.modifierEvaluation(
        evaluationId: _asInt(evaluation['id']),
        donnees: values,
      );
      _refresh();
      _message('Evaluation modifiee.');
    } catch (error) {
      _message(error.toString());
    }
  }

  Future<void> _publishEvaluation(Map<String, dynamic> evaluation) async {
    if (evaluation['statut'] != 'brouillon') return;
    try {
      await NotesDataSource.service.publierEvaluation(
        evaluationId: _asInt(evaluation['id']),
      );
      _refresh();
      _message('Evaluation publiee.');
    } catch (error) {
      _message(error.toString());
    }
  }

  Future<Map<String, dynamic>?> _evaluationDialog({
    required List<dynamic> types,
    Map<String, dynamic>? initial,
  }) async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController(text: '${initial?['titre'] ?? ''}');
    final maximum = TextEditingController(
      text: initial == null ? '20' : _formatNumber(initial['note_maximale']),
    );
    final weight = TextEditingController(
      text: initial == null ? '' : _formatNumber(initial['ponderation']),
    );
    var typeId = _asInt(
      initial?['type_evaluation_id'] ??
          (types.isEmpty ? 0 : _asInt(types.first['id'])),
    );
    final values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(initial == null
              ? 'Nouvelle evaluation'
              : 'Modifier l evaluation'),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: typeId,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: [
                      for (final type in types)
                        DropdownMenuItem<int>(
                          value: _asInt(type['id']),
                          child: Text('${type['nom']}'),
                        ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => typeId = value ?? typeId),
                  ),
                  TextFormField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Titre'),
                    validator: (value) =>
                        value == null || value.trim().length < 2
                            ? 'Titre obligatoire'
                            : null,
                  ),
                  TextFormField(
                    controller: maximum,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Note maximale'),
                    validator: _positiveValidator,
                  ),
                  TextFormField(
                    controller: weight,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Ponderation (%)'),
                    validator: _positiveValidator,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(context).pop({
                  'type_evaluation_id': typeId,
                  'titre': title.text.trim(),
                  'note_maximale':
                      double.parse(maximum.text.replaceAll(',', '.')),
                  'ponderation': double.parse(weight.text.replaceAll(',', '.')),
                });
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    maximum.dispose();
    weight.dispose();
    return values;
  }

  String? _positiveValidator(String? value) {
    final number = double.tryParse((value ?? '').replaceAll(',', '.'));
    return number == null || number <= 0 ? 'Valeur strictement positive' : null;
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CourseResultsPanel extends StatelessWidget {
  const _CourseResultsPanel({
    required this.resultats,
    required this.onPublished,
  });

  final Map<String, dynamic> resultats;
  final VoidCallback onPublished;

  @override
  Widget build(BuildContext context) {
    final etudiants = resultats['etudiants'] as List<dynamic>? ?? const [];
    final etat = '${resultats['etat'] ?? 'incomplet'}';
    final verrouille = etat == 'verrouille';
    final peutPublier = resultats['peut_publier'] == true && !verrouille;
    return SectionPanel(
      title: 'Apercu des resultats du cours',
      subtitle: 'Calcul backend sur 100, sans convertir une absence en zero.',
      trailing: StatusBadge(
        label: etat,
        color: verrouille
            ? AppColors.success
            : etat == 'publie'
                ? AppColors.primary
                : AppColors.warning,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              StatusBadge(
                label:
                    'Ponderation ${_formatNumber(resultats['total_ponderation'])}%',
                color: AppColors.secondary,
                icon: Icons.pie_chart_outline_rounded,
              ),
              StatusBadge(
                label:
                    '${resultats['notes_manquantes'] ?? 0} note(s) manquante(s)',
                color: (resultats['notes_manquantes'] ?? 0) == 0
                    ? AppColors.success
                    : AppColors.warning,
                icon: Icons.pending_actions_rounded,
              ),
              if (peutPublier)
                ElevatedButton.icon(
                  onPressed: () => _publish(context),
                  icon: const Icon(Icons.publish_rounded),
                  label: const Text('Publier les notes du cours'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (etudiants.isEmpty)
            const Text('Aucun etudiant actif concerne par ce cours.')
          else
            for (final etudiant in etudiants)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 230,
                      child: Text(
                        '${etudiant['nom'] ?? '-'} (${etudiant['matricule'] ?? '-'})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'Provisoire: ${_formatNumber(etudiant['resultat_provisoire_sur_100'])}/100',
                    ),
                    if ((etudiant['notes_manquantes'] as List<dynamic>? ??
                            const [])
                        .isNotEmpty)
                      const StatusBadge(
                        label: 'Incomplet',
                        color: AppColors.warning,
                      ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _publish(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publier les notes du cours ?'),
        content: const Text(
          'Les evaluations seront publiees et verrouillees. Les notes ne seront plus modifiables.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await NotesDataSource.service.publierResultatsCours(
        _asInt(resultats['cours_id']),
      );
      onPublished();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Notes du cours publiees et verrouillees.')),
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _EvaluationCard extends StatelessWidget {
  const _EvaluationCard({
    required this.evaluation,
    required this.onNotes,
    required this.onEdit,
    required this.onPublish,
  });

  final Map<String, dynamic> evaluation;
  final VoidCallback onNotes;
  final VoidCallback onEdit;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final status = '${evaluation['statut'] ?? '-'}';
    final published = status == 'publiee';
    final type = evaluation['type_evaluation'] as Map?;
    return SectionPanel(
      title: '${evaluation['titre'] ?? '-'}',
      subtitle:
          '${type?['nom'] ?? 'Type non precise'} - note maximale ${evaluation['note_maximale'] ?? '-'}',
      trailing: StatusBadge(
        label: evaluation['est_verrouillee'] == true ? 'Verrouillee' : status,
        color: published ? AppColors.success : AppColors.warning,
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          StatusBadge(
            label: '${evaluation['ponderation'] ?? 0}%',
            color: AppColors.secondary,
            icon: Icons.pie_chart_outline_rounded,
          ),
          OutlinedButton.icon(
            onPressed: onNotes,
            icon: const Icon(Icons.people_alt_rounded),
            label: Text(published ? 'Consulter les notes' : 'Saisir les notes'),
          ),
          if (!published) ...[
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Modifier'),
            ),
            ElevatedButton.icon(
              onPressed: onPublish,
              icon: const Icon(Icons.publish_rounded),
              label: const Text('Publier'),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeacherNotesPanel extends StatefulWidget {
  const _TeacherNotesPanel({
    super.key,
    required this.evaluationId,
    required this.onChanged,
  });

  final int evaluationId;
  final VoidCallback onChanged;

  @override
  State<_TeacherNotesPanel> createState() => _TeacherNotesPanelState();
}

class _TeacherNotesPanelState extends State<_TeacherNotesPanel> {
  late Future<Map<String, dynamic>> _future = _load();
  final Map<int, TextEditingController> _controllers = {};
  double _maximum = double.infinity;
  bool _saving = false;

  Future<Map<String, dynamic>> _load() async {
    final data =
        await NotesDataSource.service.notesEvaluation(widget.evaluationId);
    _maximum = _asDouble((data['evaluation'] as Map?)?['note_maximale']);
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    final notes = {
      for (final note in (data['notes'] as List<dynamic>? ?? const []))
        _asInt(note['etudiant_id']): note,
    };
    for (final student in (data['etudiants'] as List<dynamic>? ?? const [])) {
      final id = _asInt(student['id']);
      final note = notes[id];
      _controllers[id] = TextEditingController(
        text: note == null ? '' : _formatNumber(note['note_obtenue']),
      );
    }
    return data;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return SectionPanel(
            title: 'Notes indisponibles',
            subtitle: snapshot.error.toString(),
            child: Text(snapshot.error.toString()),
          );
        }

        final data = snapshot.data ?? const {};
        final evaluation =
            data['evaluation'] as Map<String, dynamic>? ?? const {};
        final students = data['etudiants'] as List<dynamic>? ?? const [];
        final readOnly = evaluation['statut'] != 'brouillon' ||
            evaluation['est_verrouillee'] == true;
        return SectionPanel(
          title: 'Notes - ${evaluation['titre'] ?? '-'}',
          subtitle:
              '${students.length} etudiant(s), bareme ${evaluation['note_maximale'] ?? '-'}',
          trailing: readOnly
              ? const StatusBadge(
                  label: 'Lecture seule', color: AppColors.success)
              : ElevatedButton.icon(
                  onPressed: _saving || students.isEmpty ? null : _save,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Enregistrer'),
                ),
          child: students.isEmpty
              ? const Text('Aucun etudiant actif inscrit a ce cours.')
              : Column(
                  children: [
                    for (final student in students)
                      _studentRow(
                          student, readOnly, evaluation['note_maximale']),
                  ],
                ),
        );
      },
    );
  }

  Widget _studentRow(dynamic student, bool readOnly, dynamic maximum) {
    final id = _asInt(student['id']);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 220,
            child: Text(
              '${student['nom'] ?? '-'}\n${student['matricule'] ?? '-'}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 140,
            child: TextField(
              controller: _controllers[id],
              enabled: !readOnly && !_saving,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Note',
                suffixText: '/ ${_formatNumber(maximum)}',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Text(
            _controllers[id]!.text.trim().isEmpty ? 'Absente' : 'Saisie',
            style: TextStyle(
              color: _controllers[id]!.text.trim().isEmpty
                  ? AppColors.textSecondary
                  : AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final notes = <Map<String, dynamic>>[];
    for (final entry in _controllers.entries) {
      final value = entry.value.text.trim().replaceAll(',', '.');
      if (value.isEmpty) continue;
      final number = double.tryParse(value);
      if (number == null || number < 0 || number > _maximum) {
        _message('Chaque note doit etre comprise entre 0 et $_maximum.');
        return;
      }
      notes.add({'etudiant_id': entry.key, 'note_obtenue': number});
    }
    if (notes.isEmpty) {
      _message('Saisissez au moins une note ou laissez la ligne absente.');
      return;
    }

    setState(() => _saving = true);
    try {
      await NotesDataSource.service.enregistrerNotes(
        evaluationId: widget.evaluationId,
        notes: notes,
      );
      if (!mounted) return;
      setState(() => _future = _load());
      widget.onChanged();
      _message('Notes enregistrees en brouillon.');
    } catch (error) {
      _message(error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EvaluationWorkspace {
  const _EvaluationWorkspace({
    this.courses = const [],
    this.types = const [],
    this.evaluations = const [],
    this.resultats = const {},
    this.totalPonderation = 0,
  });

  final List<dynamic> courses;
  final List<dynamic> types;
  final List<dynamic> evaluations;
  final Map<String, dynamic> resultats;
  final double totalPonderation;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('${value ?? 0}'.replaceAll(',', '.')) ?? 0;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? 0}') ?? 0;
}

String _formatNumber(dynamic value) {
  if (value == null) return '';
  if (value is num) return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
  return value.toString();
}
