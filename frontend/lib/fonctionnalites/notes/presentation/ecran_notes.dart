import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/donnees_fictives/donnees_faculte_fictives.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_enseignant.dart';
import '../../../donnees/services/service_etudiant.dart';
import '../../../donnees/services/service_session.dart';
import 'ecran_evaluations_enseignant.dart';
import 'ecran_deliberation.dart';
import 'ecran_resultats_academiques.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/tableau_intelligent.dart';
import '../../../commun/composants/carte_statistique.dart';
import '../../../commun/composants/badge_statut.dart';

class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key, this.initialCourseId});

  final int? initialCourseId;

  @override
  Widget build(BuildContext context) {
    final role = SessionService.currentRole;
    if ({
      UserRole.student,
      UserRole.administrator,
    }.contains(role)) {
      return const AcademicResultsScreen();
    }
    if ({UserRole.apparitor, UserRole.dean, UserRole.viceDean}.contains(role)) {
      return const DeliberationScreen();
    }
    if (role == UserRole.teacher) {
      return TeacherEvaluationsScreen(initialCourseId: initialCourseId);
    }

    return SmartFacultyShell(
      role: role,
      selectedRoute: AppRoutes.grades,
      title: _titleFor(role),
      subtitle: _subtitleFor(role),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveGrid(children: _statCardsFor(role)),
          const SizedBox(height: 22),
          if (role == UserRole.student) ...[
            const _StudentComputedSummary(),
            const SizedBox(height: 22),
          ],
          _mainGradesTable(role),
          const SizedBox(height: 22),
          if (role == UserRole.teacher) ...[
            const _PublishGradesPanel(),
            const SizedBox(height: 22),
          ],
          if (role == UserRole.student) ...[
            const _AcademicHistoryTable(),
          ] else ...[
            _ReadingScopePanel(role: role),
          ],
        ],
      ),
    );
  }
}

// Legacy notes table retained for historical navigation screens.
// ignore: unused_element
class _StudentApiGradesScreen extends StatelessWidget {
  const _StudentApiGradesScreen();

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.student,
      selectedRoute: AppRoutes.grades,
      title: 'Mes notes et resultats',
      subtitle: 'Notes publiees uniquement depuis la base de donnees.',
      body: FutureBuilder<Map<String, dynamic>>(
        future: EtudiantDataSource.service.notes(),
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

          final data = snapshot.data ?? {};
          final notes = data['notes'] as List<dynamic>? ?? [];
          final resume = data['resume'] as Map<String, dynamic>? ?? {};

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveGrid(
                children: [
                  StatCard(
                    metric: KpiMetric(
                      title: 'Moyenne generale',
                      value: _formatApiNumber(resume['moyenne_generale']),
                      trend: '/20',
                      description: 'ponderee par credits',
                    ),
                    icon: Icons.grade_rounded,
                    color: AppColors.primary,
                  ),
                  StatCard(
                    metric: KpiMetric(
                      title: 'Credits valides',
                      value: '${resume['credits_valides'] ?? 0}',
                      trend: '${resume['credits_restants'] ?? 0} restants',
                      description: 'notes publiees',
                    ),
                    icon: Icons.workspace_premium_rounded,
                    color: AppColors.success,
                  ),
                  StatCard(
                    metric: KpiMetric(
                      title: 'Notes publiees',
                      value: '${resume['notes_publiees'] ?? 0}',
                      trend: 'visibles',
                      description: 'brouillons masques',
                    ),
                    icon: Icons.fact_check_rounded,
                    color: AppColors.cyan,
                  ),
                  StatCard(
                    metric: KpiMetric(
                      title: 'Cours echoues',
                      value: '${resume['cours_echoues'] ?? 0}',
                      trend: 'a suivre',
                      description: 'moyenne finale < 10',
                    ),
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SmartTable(
                title: 'Notes publiees',
                subtitle: '${notes.length} ligne(s) visible(s).',
                columns: const [
                  DataColumn(label: Text('Cours')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Note')),
                  DataColumn(label: Text('Credits')),
                  DataColumn(label: Text('Resultat')),
                  DataColumn(label: Text('Publication')),
                ],
                rows: [
                  for (final note in notes)
                    DataRow(
                      cells: [
                        DataCell(Text('${note['cours'] ?? '-'}')),
                        DataCell(Text('${note['type_note'] ?? '-'}')),
                        DataCell(Text(_formatApiNumber(note['valeur']))),
                        DataCell(Text('${note['credits'] ?? 0}')),
                        DataCell(Text('${note['resultat'] ?? '-'}')),
                        DataCell(Text('${note['date_publication'] ?? '-'}')),
                      ],
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

class _TeacherApiGradesScreen extends StatefulWidget {
  // Legacy widget retained for non-API history screens; teacher routing uses TeacherEvaluationsScreen.
  // ignore: unused_element_parameter
  const _TeacherApiGradesScreen({this.initialCourseId});

  final int? initialCourseId;

  @override
  State<_TeacherApiGradesScreen> createState() =>
      _TeacherApiGradesScreenState();
}

class _TeacherApiGradesScreenState extends State<_TeacherApiGradesScreen> {
  int? _selectedCourseId;

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.initialCourseId;
  }

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.teacher,
      selectedRoute: AppRoutes.grades,
      title: 'Publication des notes',
      subtitle: 'Cours attribues et etat de publication depuis MySQL.',
      body: FutureBuilder<List<dynamic>>(
        future: EnseignantDataSource.service.cours(),
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

          final courses = snapshot.data ?? [];
          final hasSelectedCourse = courses.any(
            (course) => _asInt(course['id']) == _selectedCourseId,
          );
          if (!hasSelectedCourse) {
            _selectedCourseId =
                courses.isEmpty ? null : _asInt(courses.first['id']);
          }
          final matchingCourses = courses
              .where((course) => _asInt(course['id']) == _selectedCourseId)
              .toList();
          final selectedCourse = matchingCourses.isNotEmpty
              ? matchingCourses.first
              : courses.isEmpty
                  ? null
                  : courses.first;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionPanel(
                title: 'Cours a encoder',
                subtitle:
                    'Vous ne voyez que les cours qui vous sont attribues.',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 360,
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedCourseId,
                        decoration: const InputDecoration(labelText: 'Cours'),
                        items: [
                          for (final course in courses)
                            DropdownMenuItem<int>(
                              value: _asInt(course['id']),
                              child:
                                  Text('${course['code']} - ${course['nom']}'),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedCourseId = value),
                      ),
                    ),
                    if (selectedCourse != null)
                      StatusBadge(
                        label: '${selectedCourse['statut_notes'] ?? '-'}',
                        color: selectedCourse['statut_notes'] == 'publiees'
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    if (selectedCourse != null)
                      StatusBadge(
                        label:
                            '${selectedCourse['nombre_etudiants'] ?? 0} etudiants',
                        color: AppColors.primary,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (_selectedCourseId == null)
                const SectionPanel(
                  title: 'Aucun cours',
                  child: Text('Aucun cours attribue a ce compte enseignant.'),
                )
              else
                _TeacherCourseGradesEditor(courseId: _selectedCourseId!),
            ],
          );
        },
      ),
    );
  }
}

class _TeacherCourseGradesEditor extends StatelessWidget {
  const _TeacherCourseGradesEditor({required this.courseId});

  final int courseId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TeacherGradeData>(
      future: _load(courseId),
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

        return _TeacherGradeEditor(
          key: ValueKey(courseId),
          courseId: courseId,
          data: snapshot.data ?? const _TeacherGradeData(),
        );
      },
    );
  }

  Future<_TeacherGradeData> _load(int courseId) async {
    final warnings = <String>[];
    final students = await _safeList(
      EnseignantDataSource.service.etudiantsCours(courseId),
      'La liste des etudiants n a pas pu etre chargee.',
      warnings,
    );
    final notesPayload = await _safeMap(
      EnseignantDataSource.service.notesCours(courseId),
      'Les notes existantes n ont pas pu etre chargees.',
      warnings,
    );

    return _TeacherGradeData(
      students: students,
      notes: notesPayload['notes'] as List<dynamic>? ?? const [],
      stats: notesPayload['statistiques'] as Map<String, dynamic>? ?? const {},
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
}

class _TeacherGradeEditor extends StatefulWidget {
  const _TeacherGradeEditor({
    super.key,
    required this.courseId,
    required this.data,
  });

  final int courseId;
  final _TeacherGradeData data;

  @override
  State<_TeacherGradeEditor> createState() => _TeacherGradeEditorState();
}

class _TeacherGradeEditorState extends State<_TeacherGradeEditor> {
  final Map<int, TextEditingController> _interrogations = {};
  final Map<int, TextEditingController> _tps = {};
  final Map<int, TextEditingController> _examens = {};
  String _query = '';
  bool _onlyIncomplete = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void dispose() {
    for (final controller in [
      ..._interrogations.values,
      ..._tps.values,
      ..._examens.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initControllers() {
    final values = <int, Map<String, dynamic>>{};
    for (final note in widget.data.notes) {
      final studentId = _asInt(note['etudiant_id']);
      final type = '${note['type_code'] ?? ''}';
      values.putIfAbsent(studentId, () => {})[type] = note['valeur'];
    }

    for (final student in widget.data.students) {
      final id = _asInt(student['id']);
      _interrogations[id] = TextEditingController(
          text: _formatEditable(values[id]?['interrogation']));
      _tps[id] = TextEditingController(
          text: _formatEditable(values[id]?['travail_pratique']));
      _examens[id] =
          TextEditingController(text: _formatEditable(values[id]?['examen']));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.data.stats;
    final filteredStudents = widget.data.students.where((student) {
      final haystack = [
        student['nom_complet'],
        student['matricule'],
        student['promotion'],
        student['email'],
      ].join(' ').toLowerCase();
      final queryOk = _query.trim().isEmpty ||
          haystack.contains(_query.trim().toLowerCase());
      final incompleteOk = !_onlyIncomplete || _missingValues(student);

      return queryOk && incompleteOk;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveGrid(
          children: [
            StatCard(
              metric: KpiMetric(
                title: 'Moyenne',
                value: _formatApiNumber(stats['moyenne_cours']),
                trend: '/20',
                description: 'notes publiees',
              ),
              icon: Icons.analytics_rounded,
              color: AppColors.primary,
            ),
            StatCard(
              metric: KpiMetric(
                title: 'Brouillons',
                value: '${stats['notes_brouillon'] ?? 0}',
                trend: 'non visibles',
                description: 'cote etudiant',
              ),
              icon: Icons.edit_note_rounded,
              color: AppColors.warning,
            ),
            StatCard(
              metric: KpiMetric(
                title: 'Publiees',
                value: '${stats['moyennes_publiees'] ?? 0}',
                trend: 'visibles',
                description: 'moyennes finales',
              ),
              icon: Icons.fact_check_rounded,
              color: AppColors.success,
            ),
            StatCard(
              metric: KpiMetric(
                title: 'A risque',
                value: '${stats['etudiants_a_risque'] ?? 0}',
                trend: '< 12/20',
                description: 'suivi conseille',
              ),
              icon: Icons.health_and_safety_rounded,
              color: AppColors.danger,
            ),
          ],
        ),
        if (widget.data.warnings.isNotEmpty) ...[
          const SizedBox(height: 22),
          _LoadWarningPanel(messages: widget.data.warnings),
        ],
        const SizedBox(height: 22),
        SectionPanel(
          title: 'Pilotage de l encodage',
          subtitle:
              '${filteredStudents.length} etudiant(s) affiche(s) sur ${widget.data.students.length}.',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 360,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Rechercher un etudiant',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              FilterChip(
                selected: _onlyIncomplete,
                avatar: const Icon(Icons.rule_rounded),
                label: const Text('Lignes incompletes'),
                onSelected: (value) => setState(() => _onlyIncomplete = value),
              ),
              StatusBadge(
                label: '${_missingCount()} incomplet(s)',
                color: _missingCount() == 0
                    ? AppColors.success
                    : AppColors.warning,
                icon: Icons.pending_actions_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SmartTable(
          title: 'Encodage des notes',
          subtitle: 'Moyenne finale = interrogation 20% + TP 30% + examen 50%.',
          trailing: Wrap(
            spacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed:
                    _saving || widget.data.students.isEmpty ? null : _saveDraft,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Enregistrer'),
              ),
              ElevatedButton.icon(
                onPressed:
                    _saving || widget.data.students.isEmpty ? null : _publish,
                icon: const Icon(Icons.publish_rounded),
                label: const Text('Publier'),
              ),
            ],
          ),
          columns: const [
            DataColumn(label: Text('Etudiant')),
            DataColumn(label: Text('Matricule')),
            DataColumn(label: Text('Interro')),
            DataColumn(label: Text('TP')),
            DataColumn(label: Text('Examen')),
            DataColumn(label: Text('Moyenne')),
          ],
          rows: [
            for (final student in filteredStudents)
              DataRow(cells: [
                DataCell(Text('${student['nom_complet'] ?? '-'}')),
                DataCell(Text('${student['matricule'] ?? '-'}')),
                DataCell(_noteField(_interrogations[_asInt(student['id'])]!)),
                DataCell(_noteField(_tps[_asInt(student['id'])]!)),
                DataCell(_noteField(_examens[_asInt(student['id'])]!)),
                DataCell(Text(_formatApiNumber(student['moyenne']))),
              ]),
          ],
        ),
      ],
    );
  }

  Widget _noteField(TextEditingController controller) {
    return SizedBox(
      width: 82,
      child: TextField(
        controller: controller,
        enabled: !_saving,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          isDense: true,
          suffixText: '/20',
        ),
      ),
    );
  }

  bool _missingValues(dynamic student) {
    final id = _asInt(student['id']);

    return _interrogations[id]!.text.trim().isEmpty ||
        _tps[id]!.text.trim().isEmpty ||
        _examens[id]!.text.trim().isEmpty;
  }

  int _missingCount() {
    return widget.data.students.where(_missingValues).length;
  }

  Future<void> _saveDraft() async {
    setState(() => _saving = true);
    try {
      await EnseignantDataSource.service.enregistrerBrouillon(
        coursId: widget.courseId,
        notes: _payload(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notes enregistrees en brouillon.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publish() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publier les notes ?'),
        content: const Text(
          'Apres publication, les notes deviennent visibles par les etudiants et sont verrouillees.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Publier'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await EnseignantDataSource.service.enregistrerBrouillon(
        coursId: widget.courseId,
        notes: _payload(),
      );
      await EnseignantDataSource.service.publierNotes(widget.courseId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notes publiees et valve mise a jour.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<Map<String, dynamic>> _payload() {
    return [
      for (final student in widget.data.students)
        {
          'etudiant_id': _asInt(student['id']),
          'interrogation':
              _parseNote(_interrogations[_asInt(student['id'])]!.text),
          'travail_pratique': _parseNote(_tps[_asInt(student['id'])]!.text),
          'examen': _parseNote(_examens[_asInt(student['id'])]!.text),
        },
    ];
  }
}

class _TeacherGradeData {
  const _TeacherGradeData({
    this.students = const [],
    this.notes = const [],
    this.stats = const {},
    this.warnings = const [],
  });

  final List<dynamic> students;
  final List<dynamic> notes;
  final Map<String, dynamic> stats;
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
          'L encodage reste accessible, certaines donnees seront rechargees ensuite.',
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

class _PublishGradesPanel extends StatelessWidget {
  const _PublishGradesPanel();

  @override
  Widget build(BuildContext context) {
    final teacher = SessionService.currentUser.name;
    final courses = MockFacultyData.courseAssignments
        .where((course) => course.teacher == teacher)
        .toList();

    return SectionPanel(
      title: 'Saisie et publication des cotes',
      subtitle:
          'Le professeur encode uniquement ses cours, puis publie et verrouille.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 780;
              final fields = [
                DropdownButtonFormField<String>(
                  initialValue: courses.first.course,
                  decoration: const InputDecoration(
                    labelText: 'Cours',
                    prefixIcon: Icon(Icons.menu_book_rounded),
                  ),
                  items: [
                    for (final course in courses)
                      DropdownMenuItem(
                        value: course.course,
                        child: Text(course.course),
                      ),
                  ],
                  onChanged: (_) {},
                ),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Matricule etudiant',
                    prefixIcon: Icon(Icons.badge_rounded),
                  ),
                ),
                const TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Cote /20',
                    prefixIcon: Icon(Icons.pin_rounded),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La cote est prete a etre enregistree.'),
                    ),
                  ),
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Enregistrer'),
                ),
              ];

              if (compact) {
                return Column(
                  children: [
                    for (final field in fields) ...[
                      field,
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final field in fields) ...[
                    Expanded(child: field),
                    const SizedBox(width: 12),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          const _TeacherGradeDraftTable(),
        ],
      ),
    );
  }
}

class _StudentComputedSummary extends StatelessWidget {
  const _StudentComputedSummary();

  @override
  Widget build(BuildContext context) {
    final grades = _gradesForRole(UserRole.student)
        .where((grade) => grade.published)
        .toList();
    final credits = grades
        .where((grade) => grade.grade >= 10)
        .fold<int>(0, (sum, grade) => sum + grade.credits);
    final weightedCredits =
        grades.fold<int>(0, (sum, grade) => sum + grade.credits);
    final weightedScore = grades.fold<double>(
      0,
      (sum, grade) => sum + (grade.grade * grade.credits),
    );
    final average = weightedCredits == 0 ? 0 : weightedScore / weightedCredits;

    return SectionPanel(
      title: 'Calcul automatique',
      subtitle: 'Moyenne et credits calcules sur les notes publiees.',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          StatusBadge(
            label: 'Moyenne generale ${average.toStringAsFixed(1)}/20',
            color: AppColors.primary,
            icon: Icons.grade_rounded,
          ),
          StatusBadge(
            label: 'Credits valides $credits/$weightedCredits',
            color: AppColors.success,
            icon: Icons.workspace_premium_rounded,
          ),
          const StatusBadge(
            label: 'Risques mis a jour apres publication',
            color: AppColors.warning,
            icon: Icons.health_and_safety_rounded,
          ),
        ],
      ),
    );
  }
}

class _TeacherGradeDraftTable extends StatelessWidget {
  const _TeacherGradeDraftTable();

  @override
  Widget build(BuildContext context) {
    final teacher = SessionService.currentUser.name;
    final rows = MockFacultyData.grades
        .where((grade) => grade.teacher == teacher)
        .toList();

    return SmartTable(
      title: 'Etudiants inscrits et cotes',
      subtitle: 'Modification autorisee avant verrouillage.',
      columns: const [
        DataColumn(label: Text('Etudiant')),
        DataColumn(label: Text('Promotion')),
        DataColumn(label: Text('Cours')),
        DataColumn(label: Text('Cote')),
        DataColumn(label: Text('Publication')),
        DataColumn(label: Text('Action')),
      ],
      rows: [
        for (final grade in rows)
          DataRow(
            cells: [
              DataCell(Text(grade.student)),
              DataCell(Text(grade.promotion)),
              DataCell(Text(grade.course)),
              DataCell(
                SizedBox(
                  width: 74,
                  child: TextFormField(
                    initialValue:
                        grade.published ? grade.grade.toStringAsFixed(1) : '',
                    enabled: !grade.locked,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true),
                  ),
                ),
              ),
              DataCell(
                StatusBadge(
                  label: grade.published ? 'Publiee' : 'Brouillon',
                  color:
                      grade.published ? AppColors.success : AppColors.warning,
                ),
              ),
              DataCell(
                Wrap(
                  spacing: 6,
                  children: [
                    TextButton(
                      onPressed: grade.locked
                          ? null
                          : () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Note publiee en simulation.'),
                                ),
                              ),
                      child: const Text('Publier'),
                    ),
                    TextButton(
                      onPressed: grade.published && !grade.locked
                          ? () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Notes verrouillees en simulation.'),
                                ),
                              )
                          : null,
                      child: const Text('Verrouiller'),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _AcademicHistoryTable extends StatelessWidget {
  const _AcademicHistoryTable();

  @override
  Widget build(BuildContext context) {
    return SmartTable(
      title: 'Historique academique',
      subtitle: 'Parcours et decisions precedentes.',
      columns: const [
        DataColumn(label: Text('Periode')),
        DataColumn(label: Text('Moyenne')),
        DataColumn(label: Text('Credits')),
        DataColumn(label: Text('Resultat')),
      ],
      rows: [
        for (final item in MockFacultyData.academicHistory)
          DataRow(
            cells: [
              DataCell(Text(item.period)),
              DataCell(Text(item.average.toStringAsFixed(1))),
              DataCell(Text('${item.credits}')),
              DataCell(Text(item.result)),
            ],
          ),
      ],
    );
  }
}

class _ReadingScopePanel extends StatelessWidget {
  const _ReadingScopePanel({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: 'Perimetre de lecture',
      subtitle: _scopeText(role),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _ScopeChip(icon: Icons.lock_rounded, text: _permissionText(role)),
          _ScopeChip(icon: Icons.verified_rounded, text: _decisionText(role)),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, color: AppColors.primary, size: 18),
      label: Text(text),
      backgroundColor: AppColors.primarySoft,
      side: const BorderSide(color: AppColors.border),
    );
  }
}

SmartTable _mainGradesTable(UserRole role) {
  if (role == UserRole.teacher) {
    final teacher = SessionService.currentUser.name;
    final courses = MockFacultyData.courseAssignments
        .where((course) => course.teacher == teacher)
        .toList();

    return SmartTable(
      title: 'Mes cours attribues',
      subtitle: 'Progression de publication par promotion.',
      columns: const [
        DataColumn(label: Text('Cours')),
        DataColumn(label: Text('Promotion')),
        DataColumn(label: Text('Etudiants')),
        DataColumn(label: Text('Notes publiees')),
        DataColumn(label: Text('Moyenne')),
        DataColumn(label: Text('Verrouille')),
      ],
      rows: [
        for (final course in courses)
          DataRow(
            cells: [
              DataCell(Text(course.course)),
              DataCell(Text(course.promotion)),
              DataCell(Text('${course.students}')),
              DataCell(Text('${course.publishedGrades}/${course.students}')),
              DataCell(Text(course.average.toStringAsFixed(1))),
              DataCell(
                StatusBadge(
                  label: course.locked ? 'Oui' : 'Non',
                  color: course.locked ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
      ],
    );
  }

  return SmartTable(
    title:
        role == UserRole.student ? 'Mes notes par cours' : 'Resultats a suivre',
    subtitle: _tableSubtitle(role),
    columns: const [
      DataColumn(label: Text('Cours')),
      DataColumn(label: Text('Enseignant')),
      DataColumn(label: Text('Credits')),
      DataColumn(label: Text('Note')),
      DataColumn(label: Text('Moyenne cours')),
      DataColumn(label: Text('Resultat')),
      DataColumn(label: Text('Etat')),
    ],
    rows: [
      for (final grade in _gradesForRole(role))
        DataRow(
          cells: [
            DataCell(Text(grade.course)),
            DataCell(Text(grade.teacher)),
            DataCell(Text('${grade.credits}')),
            DataCell(
                Text(grade.published ? grade.grade.toStringAsFixed(1) : '-')),
            DataCell(
              Text(grade.published
                  ? grade.courseAverage.toStringAsFixed(1)
                  : '-'),
            ),
            DataCell(
              StatusBadge(
                label: grade.result,
                color: grade.result == 'Valide'
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ),
            DataCell(
              StatusBadge(
                label: grade.locked
                    ? 'Verrouillee'
                    : grade.published
                        ? 'Publiee'
                        : 'Brouillon',
                color: grade.locked
                    ? AppColors.primary
                    : grade.published
                        ? AppColors.success
                        : AppColors.warning,
              ),
            ),
          ],
        ),
    ],
  );
}

List<Widget> _statCardsFor(UserRole role) {
  switch (role) {
    case UserRole.teacher:
      return [
        for (var i = 0; i < MockFacultyData.teacherKpis.length; i++)
          StatCard(
            metric: MockFacultyData.teacherKpis[i],
            icon: [
              Icons.menu_book_rounded,
              Icons.upload_file_rounded,
              Icons.workspaces_rounded,
              Icons.rate_review_rounded,
            ][i],
            color: [
              AppColors.primary,
              AppColors.success,
              AppColors.violet,
              AppColors.warning,
            ][i],
          ),
      ];
    case UserRole.promotionChief:
      return const [
        StatCard(
          metric: KpiMetric(
            title: 'Moyenne promo',
            value: '12,9',
            trend: '+0,3',
            description: 'L2 Informatique',
          ),
          icon: Icons.groups_rounded,
          color: AppColors.primary,
        ),
        StatCard(
          metric: KpiMetric(
            title: 'Cours critiques',
            value: '2',
            trend: 'a relayer',
            description: 'moyenne basse',
          ),
          icon: Icons.warning_amber_rounded,
          color: AppColors.warning,
        ),
        StatCard(
          metric: KpiMetric(
            title: 'Notes publiees',
            value: '87%',
            trend: 'semestre',
            description: 'progression',
          ),
          icon: Icons.fact_check_rounded,
          color: AppColors.success,
        ),
        StatCard(
          metric: KpiMetric(
            title: 'Rattrapages',
            value: '18',
            trend: 'prevision',
            description: 'etudiants concernes',
          ),
          icon: Icons.event_repeat_rounded,
          color: AppColors.cyan,
        ),
      ];
    case UserRole.administrator:
    case UserRole.apparitor:
    case UserRole.dean:
    case UserRole.viceDean:
      return [
        StatCard(
          metric: MockFacultyData.decisionKpis[0],
          icon: Icons.trending_up_rounded,
          color: AppColors.success,
        ),
        StatCard(
          metric: MockFacultyData.decisionKpis[1],
          icon: Icons.trending_down_rounded,
          color: AppColors.danger,
        ),
        StatCard(
          metric: MockFacultyData.decisionKpis[2],
          icon: Icons.grade_rounded,
          color: AppColors.primary,
        ),
        const StatCard(
          metric: KpiMetric(
            title: 'Cours sensibles',
            value: '4',
            trend: 'a suivre',
            description: 'moyenne faible',
          ),
          icon: Icons.query_stats_rounded,
          color: AppColors.warning,
        ),
      ];
    case UserRole.student:
      return [
        for (var i = 0; i < MockFacultyData.studentKpis.length; i++)
          StatCard(
            metric: MockFacultyData.studentKpis[i],
            icon: [
              Icons.grade_rounded,
              Icons.workspace_premium_rounded,
              Icons.menu_book_rounded,
              Icons.warning_amber_rounded,
            ][i],
            color: [
              AppColors.primary,
              AppColors.success,
              AppColors.cyan,
              AppColors.warning,
            ][i],
          ),
      ];
  }
}

String _titleFor(UserRole role) {
  switch (role) {
    case UserRole.teacher:
      return 'Publication des notes';
    case UserRole.promotionChief:
      return 'Resultats de la promotion';
    case UserRole.dean:
      return 'Synthese des resultats';
    case UserRole.viceDean:
      return 'Synthese des resultats';
    case UserRole.apparitor:
      return 'Suivi des notes et credits';
    case UserRole.administrator:
      return 'Suivi academique';
    case UserRole.student:
      return 'Mes notes et resultats';
  }
}

String _subtitleFor(UserRole role) {
  switch (role) {
    case UserRole.teacher:
      return 'Encoder les notes et suivre vos cours attribues.';
    case UserRole.promotionChief:
      return 'Lire les tendances utiles pour accompagner la promotion.';
    case UserRole.dean:
      return 'Analyser les resultats finaux et les cours sensibles.';
    case UserRole.viceDean:
      return 'Analyser les resultats finaux et les cours sensibles.';
    case UserRole.apparitor:
      return 'Verifier les publications, credits, moyennes et verrouillages.';
    case UserRole.administrator:
      return 'Controler la publication et la coherence des resultats.';
    case UserRole.student:
      return 'Consulter les notes publiees et votre historique academique.';
  }
}

String _tableSubtitle(UserRole role) {
  switch (role) {
    case UserRole.promotionChief:
      return 'Lecture synthetique des cours suivis par la promotion.';
    case UserRole.dean:
      return 'Cours qui alimentent la lecture decisionnelle.';
    case UserRole.viceDean:
      return 'Cours qui alimentent la lecture decisionnelle.';
    case UserRole.apparitor:
      return 'Lecture par promotion et par cours pour suivi apparitorat.';
    case UserRole.administrator:
      return 'Apercu de controle avant consolidation.';
    case UserRole.student:
      return 'Resultats publies dans le systeme academique.';
    case UserRole.teacher:
      return '';
  }
}

String _scopeText(UserRole role) {
  switch (role) {
    case UserRole.teacher:
      return 'Vous pouvez publier uniquement les notes de vos cours.';
    case UserRole.promotionChief:
      return 'Vous consultez les resultats de votre promotion sans modification.';
    case UserRole.dean:
      return 'Vous disposez d une lecture consolidee pour la decision.';
    case UserRole.viceDean:
      return 'Vous disposez d une lecture consolidee pour la decision.';
    case UserRole.apparitor:
      return 'Vous controlez les notes publiees par promotion et par cours.';
    case UserRole.administrator:
      return 'Vous controlez la coherence des donnees academiques.';
    case UserRole.student:
      return '';
  }
}

String _permissionText(UserRole role) {
  switch (role) {
    case UserRole.teacher:
      return 'Publication autorisee';
    case UserRole.promotionChief:
      return 'Lecture promotion';
    case UserRole.dean:
      return 'Lecture faculte';
    case UserRole.viceDean:
      return 'Lecture faculte';
    case UserRole.apparitor:
      return 'Lecture apparitorat';
    case UserRole.administrator:
      return 'Controle global';
    case UserRole.student:
      return 'Lecture personnelle';
  }
}

String _decisionText(UserRole role) {
  switch (role) {
    case UserRole.teacher:
      return 'Validation par jury';
    case UserRole.promotionChief:
      return 'Relais etudiant';
    case UserRole.dean:
      return 'Pilotage decisionnel';
    case UserRole.viceDean:
      return 'Pilotage decisionnel';
    case UserRole.apparitor:
      return 'Relance des publications';
    case UserRole.administrator:
      return 'Preparation jury';
    case UserRole.student:
      return 'Suivi individuel';
  }
}

List<CourseGrade> _gradesForRole(UserRole role) {
  final user = SessionService.currentUser;
  switch (role) {
    case UserRole.student:
      return MockFacultyData.grades
          .where((grade) => grade.student == user.name && grade.published)
          .toList();
    case UserRole.teacher:
      return MockFacultyData.grades
          .where((grade) => grade.teacher == user.name)
          .toList();
    case UserRole.promotionChief:
      return MockFacultyData.grades
          .where((grade) => grade.promotion == user.promotion)
          .toList();
    case UserRole.apparitor:
    case UserRole.administrator:
    case UserRole.dean:
      return MockFacultyData.grades;
    case UserRole.viceDean:
      return MockFacultyData.grades;
  }
}

String _formatApiNumber(dynamic value) {
  if (value == null) return '-';
  if (value is num) return value.toStringAsFixed(2);
  return value.toString();
}

String _formatEditable(dynamic value) {
  if (value == null) return '';
  if (value is num) return value.toStringAsFixed(2);
  return value.toString();
}

double? _parseNote(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? 0}') ?? 0;
}
