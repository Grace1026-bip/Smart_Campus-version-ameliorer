import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/fichier_valve_picker.dart';
import '../../../donnees/services/lien_externe.dart';
import '../../../donnees/services/service_enseignant.dart';
import '../../../donnees/services/service_notifications.dart';
import '../../../donnees/services/service_session.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/carte_statistique.dart';
import '../../../commun/composants/badge_statut.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({
    super.key,
    this.initialCourseId,
    this.initialType,
  });

  final int? initialCourseId;
  final String? initialType;

  @override
  Widget build(BuildContext context) {
    final role = SessionService.currentRole;
    if (role == UserRole.teacher) {
      return _TeacherValveScreen(
        initialCourseId: initialCourseId,
        initialType: initialType,
      );
    }

    return _NotificationsApiScreen(role: role);
  }
}

class _NotificationsApiScreen extends StatefulWidget {
  const _NotificationsApiScreen({required this.role});

  final UserRole role;

  @override
  State<_NotificationsApiScreen> createState() =>
      _NotificationsApiScreenState();
}

class _NotificationsApiScreenState extends State<_NotificationsApiScreen> {
  late Future<Map<String, dynamic>> _future = _load();
  String? _typeFilter;
  bool? _readFilter;

  Future<Map<String, dynamic>> _load() {
    return NotificationsDataSource.service.lister(
      typeNotification: _typeFilter,
      estLue: _readFilter,
    );
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  void _setTypeFilter(String? value) {
    setState(() {
      _typeFilter = value;
      _future = _load();
    });
  }

  void _setReadFilter(bool? value) {
    setState(() {
      _readFilter = value;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: widget.role,
      selectedRoute: AppRoutes.notifications,
      title: 'Notifications',
      subtitle: 'Messages academiques, alertes et annonces institutionnelles.',
      actions: [
        IconButton(
          tooltip: 'Actualiser',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        IconButton(
          tooltip: 'Tout marquer comme lu',
          onPressed: _markAllRead,
          icon: const Icon(Icons.done_all_rounded),
        ),
      ],
      body: FutureBuilder<Map<String, dynamic>>(
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

          final data = snapshot.data ?? const {};
          final notifications = data['elements'] as List<dynamic>? ?? const [];
          final unread = notifications
              .where((item) => item is Map && item['est_lue'] != true)
              .length;
          final important = notifications
              .where(
                (item) =>
                    item is Map &&
                    {
                      'alerte_academique',
                      'reclamation_mise_a_jour',
                    }.contains(item['type_notification']),
              )
              .length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveGrid(
                children: [
                  StatCard(
                    metric: KpiMetric(
                      title: 'Notifications',
                      value: '${data['total'] ?? notifications.length}',
                      trend: 'API',
                      description: 'messages recents',
                    ),
                    icon: Icons.notifications_rounded,
                    color: AppColors.primary,
                  ),
                  StatCard(
                    metric: KpiMetric(
                      title: 'Non lues',
                      value: '$unread',
                      trend: 'a lire',
                      description: 'suivi personnel',
                    ),
                    icon: Icons.mark_email_unread_rounded,
                    color: AppColors.warning,
                  ),
                  StatCard(
                    metric: KpiMetric(
                      title: 'Prioritaires',
                      value: '$important',
                      trend: 'alertes',
                      description: 'risques/reclamations',
                    ),
                    icon: Icons.priority_high_rounded,
                    color: AppColors.danger,
                  ),
                  StatCard(
                    metric: KpiMetric(
                      title: 'Page',
                      value: '${data['page'] ?? 1}/${data['pages'] ?? 1}',
                      trend: '${data['taille'] ?? 20} lignes',
                      description: 'pagination backend',
                    ),
                    icon: Icons.view_list_rounded,
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SectionPanel(
                title: 'Filtres',
                subtitle:
                    '${notifications.length} notification(s) affichee(s).',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 280,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _typeFilter,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: const [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Tous les types'),
                          ),
                          DropdownMenuItem(
                            value: 'nouvelle_note',
                            child: Text('Notes'),
                          ),
                          DropdownMenuItem(
                            value: 'nouvelle_publication',
                            child: Text('Valve'),
                          ),
                          DropdownMenuItem(
                            value: 'reclamation_mise_a_jour',
                            child: Text('Reclamations'),
                          ),
                          DropdownMenuItem(
                            value: 'alerte_academique',
                            child: Text('Alertes academiques'),
                          ),
                          DropdownMenuItem(
                            value: 'information_systeme',
                            child: Text('Systeme'),
                          ),
                        ],
                        onChanged: _setTypeFilter,
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<bool?>(
                        initialValue: _readFilter,
                        decoration: const InputDecoration(labelText: 'Lecture'),
                        items: const [
                          DropdownMenuItem<bool?>(
                            value: null,
                            child: Text('Toutes'),
                          ),
                          DropdownMenuItem(
                            value: false,
                            child: Text('Non lues'),
                          ),
                          DropdownMenuItem(
                            value: true,
                            child: Text('Lues'),
                          ),
                        ],
                        onChanged: _setReadFilter,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _typeFilter = null;
                          _readFilter = null;
                          _future = _load();
                        });
                      },
                      icon: const Icon(Icons.filter_alt_off_rounded),
                      label: const Text('Reinitialiser'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SectionPanel(
                title: 'Boite de notifications',
                subtitle: 'Donnees internes generees par FastAPI.',
                child: Column(
                  children: [
                    if (notifications.isEmpty)
                      const Text('Aucune notification dans ce filtre.'),
                    for (final item in notifications)
                      _ApiNotificationCard(
                        notification: item as Map<String, dynamic>,
                        onRead: _refresh,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _markAllRead() async {
    try {
      await NotificationsDataSource.service.toutMarquerCommeLu();
      _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _TeacherValveScreen extends StatefulWidget {
  const _TeacherValveScreen({this.initialCourseId, this.initialType});

  final int? initialCourseId;
  final String? initialType;

  @override
  State<_TeacherValveScreen> createState() => _TeacherValveScreenState();
}

class _TeacherValveScreenState extends State<_TeacherValveScreen> {
  late Future<_ValveData> _future = _load();
  int? _courseFilter;
  String? _typeFilter;
  final Set<int> _removedPublicationIds = {};

  @override
  void initState() {
    super.initState();
    _courseFilter = widget.initialCourseId;
    _typeFilter = widget.initialType;
  }

  Future<_ValveData> _load() async {
    final warnings = <String>[];
    final courses = await _safeList(
      EnseignantDataSource.service.cours(),
      'Les cours enseignant n ont pas pu etre charges.',
      warnings,
    );
    final publications = await _safeList(
      EnseignantDataSource.service.valve(),
      'Les publications de la valve n ont pas pu etre chargees.',
      warnings,
    );

    return _ValveData(
      courses: courses,
      publications: publications,
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

  void _refresh({int? removedPublicationId}) {
    setState(() {
      if (removedPublicationId != null) {
        _removedPublicationIds.add(removedPublicationId);
      }
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.teacher,
      selectedRoute: AppRoutes.notifications,
      title: 'Valve enseignant',
      subtitle: 'Publications reelles liees uniquement a vos cours.',
      body: FutureBuilder<_ValveData>(
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

          final data = snapshot.data ?? const _ValveData();
          final activePublications = data.publications.where((publication) {
            return !_removedPublicationIds.contains(_asInt(publication['id']));
          }).toList();
          final publications = activePublications.where((publication) {
            final courseOk = _courseFilter == null ||
                publication['cours_id'].toString() == _courseFilter.toString();
            final typeOk = _typeFilter == null ||
                publication['type_publication'] == _typeFilter;
            return courseOk && typeOk;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveGrid(
                children: [
                  StatCard(
                    metric: KpiMetric(
                      title: 'Publications',
                      value: '${activePublications.length}',
                      trend: 'total',
                      description: 'dans vos cours',
                    ),
                    icon: Icons.campaign_rounded,
                    color: AppColors.primary,
                  ),
                  StatCard(
                    metric: KpiMetric(
                      title: 'Importantes',
                      value:
                          '${activePublications.where((p) => p['est_important'] == true).length}',
                      trend: 'prioritaires',
                      description: 'marquees importantes',
                    ),
                    icon: Icons.priority_high_rounded,
                    color: AppColors.danger,
                  ),
                  StatCard(
                    metric: KpiMetric(
                      title: 'Verrouillees',
                      value:
                          '${activePublications.where((p) => p['est_verrouille'] == true).length}',
                      trend: 'non modifiables',
                      description: 'notes ou annonces sensibles',
                    ),
                    icon: Icons.lock_rounded,
                    color: AppColors.warning,
                  ),
                  StatCard(
                    metric: KpiMetric(
                      title: 'Cours',
                      value: '${data.courses.length}',
                      trend: 'attribues',
                      description: 'perimetre visible',
                    ),
                    icon: Icons.menu_book_rounded,
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              if (data.warnings.isNotEmpty) ...[
                _LoadWarningPanel(messages: data.warnings),
                const SizedBox(height: 22),
              ],
              _PublicationForm(
                courses: data.courses,
                initialCourseId: widget.initialCourseId,
                initialType: widget.initialType,
                onSaved: () => _refresh(),
              ),
              const SizedBox(height: 22),
              SectionPanel(
                title: 'Filtres',
                subtitle: 'Filtrer les publications par cours ou type.',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 280,
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
                              child:
                                  Text('${course['code']} - ${course['nom']}'),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _courseFilter = value),
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _typeFilter,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: const [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Tous les types'),
                          ),
                          DropdownMenuItem(
                            value: 'annonce',
                            child: Text('Annonce'),
                          ),
                          DropdownMenuItem(
                            value: 'communique',
                            child: Text('Communique'),
                          ),
                          DropdownMenuItem(
                            value: 'devoir',
                            child: Text('Devoir'),
                          ),
                          DropdownMenuItem(
                            value: 'support_de_cours',
                            child: Text('Support'),
                          ),
                          DropdownMenuItem(
                            value: 'changement_horaire',
                            child: Text('Horaire'),
                          ),
                          DropdownMenuItem(
                            value: 'consigne_examen',
                            child: Text('Consigne'),
                          ),
                          DropdownMenuItem(
                            value: 'rappel',
                            child: Text('Rappel'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _typeFilter = value),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => setState(() {
                        _courseFilter = null;
                        _typeFilter = null;
                      }),
                      icon: const Icon(Icons.filter_alt_off_rounded),
                      label: const Text('Reinitialiser'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SectionPanel(
                title: 'Publications',
                subtitle: '${publications.length} publication(s) affichee(s).',
                child: Column(
                  children: [
                    if (publications.isEmpty)
                      const Text('Aucune publication dans ce filtre.'),
                    for (final publication in publications)
                      _TeacherPublicationCard(
                        publication: publication,
                        onChanged: () => _refresh(),
                        onDeleted: (id) => _refresh(removedPublicationId: id),
                      ),
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

class _PublicationForm extends StatefulWidget {
  const _PublicationForm({
    required this.courses,
    required this.onSaved,
    this.initialCourseId,
    this.initialType,
  });

  final List<dynamic> courses;
  final VoidCallback onSaved;
  final int? initialCourseId;
  final String? initialType;

  @override
  State<_PublicationForm> createState() => _PublicationFormState();
}

class _PublicationFormState extends State<_PublicationForm> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _attachmentController = TextEditingController();
  int? _courseId;
  late String _type;
  String? _pickedFileName;
  String? _pickedFileBase64;
  int? _pickedFileSize;
  bool _important = false;
  bool _publishNow = true;
  bool _pickingFile = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _courseId = widget.initialCourseId;
    _type = _publicationTypes.contains(widget.initialType)
        ? widget.initialType!
        : 'annonce';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _attachmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSelectedCourse = widget.courses.any(
      (course) => _asInt(course['id']) == _courseId,
    );
    if (!hasSelectedCourse) {
      _courseId =
          widget.courses.isEmpty ? null : _asInt(widget.courses.first['id']);
    }

    if (widget.courses.isEmpty) {
      return const SectionPanel(
        title: 'Nouvelle publication',
        subtitle: 'Aucun cours attribue a ce compte.',
        child: Text(
            'La valve sera disponible des qu un cours vous sera attribue.'),
      );
    }

    return SectionPanel(
      title: 'Nouvelle publication',
      subtitle: 'La publication sera associee a un de vos cours.',
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 300,
                child: DropdownButtonFormField<int>(
                  initialValue: _courseId,
                  decoration: const InputDecoration(labelText: 'Cours'),
                  items: [
                    for (final course in widget.courses)
                      DropdownMenuItem<int>(
                        value: _asInt(course['id']),
                        child: Text('${course['code']} - ${course['nom']}'),
                      ),
                  ],
                  onChanged: (value) => setState(() => _courseId = value),
                ),
              ),
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'annonce', child: Text('Annonce')),
                    DropdownMenuItem(
                        value: 'communique', child: Text('Communique')),
                    DropdownMenuItem(value: 'devoir', child: Text('Devoir')),
                    DropdownMenuItem(
                        value: 'support_de_cours', child: Text('Support')),
                    DropdownMenuItem(
                        value: 'changement_horaire',
                        child: Text('Changement horaire')),
                    DropdownMenuItem(
                        value: 'consigne_examen',
                        child: Text('Consigne examen')),
                    DropdownMenuItem(value: 'rappel', child: Text('Rappel')),
                  ],
                  onChanged: (value) => setState(() => _type = value ?? _type),
                ),
              ),
              SizedBox(
                width: 220,
                child: SwitchListTile(
                  value: _important,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Important'),
                  onChanged: (value) => setState(() => _important = value),
                ),
              ),
              SizedBox(
                width: 240,
                child: SwitchListTile(
                  value: _publishNow,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Publier maintenant'),
                  onChanged: (value) => setState(() => _publishNow = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Titre'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Contenu'),
          ),
          const SizedBox(height: 12),
          _AttachmentInput(
            controller: _attachmentController,
            pickedFileName: _pickedFileName,
            pickedFileSize: _pickedFileSize,
            pickingFile: _pickingFile,
            onPickFile: supportsValveFilePicker ? _pickFile : null,
            onClearFile: _clearPickedFile,
            onUrlChanged: (value) {
              if (value.trim().isNotEmpty && _pickedFileName != null) {
                _clearPickedFile();
              }
            },
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.publish_rounded),
              label: Text(
                _saving
                    ? 'Enregistrement...'
                    : _publishNow
                        ? 'Publier'
                        : 'Enregistrer brouillon',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_courseId == null ||
        _titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cours, titre et contenu obligatoires.')),
      );
      return;
    }

    if (_type == 'support_de_cours' &&
        _pickedFileBase64 == null &&
        _attachmentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ajoutez un fichier ou un lien pour le support.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await EnseignantDataSource.service.creerPublication(
        coursId: _courseId!,
        typePublication: _type,
        titre: _titleController.text.trim(),
        contenu: _contentController.text.trim(),
        pieceJointeUrl: _pickedFileBase64 == null &&
                _attachmentController.text.trim().isNotEmpty
            ? _attachmentController.text.trim()
            : null,
        pieceJointeNom: _pickedFileName,
        pieceJointeBase64: _pickedFileBase64,
        estImportant: _important,
        publierMaintenant: _publishNow,
      );
      if (!mounted) return;
      _titleController.clear();
      _contentController.clear();
      _attachmentController.clear();
      setState(() {
        _important = false;
        _publishNow = true;
        _clearPickedFile(setStateNeeded: false);
      });
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publication ajoutee dans la valve.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickFile() async {
    setState(() => _pickingFile = true);
    try {
      final file = await choisirFichierValve();
      if (!mounted || file == null) return;

      if (file.size > 10 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fichier trop volumineux: 10 Mo max.')),
        );
        return;
      }

      setState(() {
        _pickedFileName = file.fileName;
        _pickedFileBase64 = file.base64Content;
        _pickedFileSize = file.size;
        _attachmentController.clear();
      });
    } finally {
      if (mounted) setState(() => _pickingFile = false);
    }
  }

  void _clearPickedFile({bool setStateNeeded = true}) {
    void clear() {
      _pickedFileName = null;
      _pickedFileBase64 = null;
      _pickedFileSize = null;
    }

    if (setStateNeeded) {
      setState(clear);
    } else {
      clear();
    }
  }
}

class _AttachmentInput extends StatelessWidget {
  const _AttachmentInput({
    required this.controller,
    required this.pickedFileName,
    required this.pickedFileSize,
    required this.pickingFile,
    required this.onClearFile,
    required this.onUrlChanged,
    this.onPickFile,
  });

  final TextEditingController controller;
  final String? pickedFileName;
  final int? pickedFileSize;
  final bool pickingFile;
  final Future<void> Function()? onPickFile;
  final VoidCallback onClearFile;
  final ValueChanged<String> onUrlChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 420,
              child: TextField(
                controller: controller,
                onChanged: onUrlChanged,
                decoration: const InputDecoration(
                  labelText: 'Piece jointe ou lien du fichier',
                  prefixIcon: Icon(Icons.attach_file_rounded),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onPickFile == null || pickingFile
                  ? null
                  : () {
                      onPickFile!();
                    },
              icon: pickingFile
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_rounded),
              label: Text(pickingFile ? 'Selection...' : 'Choisir un fichier'),
            ),
          ],
        ),
        if (pickedFileName != null) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusBadge(
                label: '${_shortAttachmentLabel(pickedFileName!)}'
                    ' - ${_formatFileSize(pickedFileSize ?? 0)}',
                color: AppColors.cyan,
                icon: Icons.attach_file_rounded,
              ),
              IconButton(
                tooltip: 'Retirer le fichier',
                onPressed: onClearFile,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TeacherPublicationCard extends StatelessWidget {
  const _TeacherPublicationCard({
    required this.publication,
    required this.onChanged,
    required this.onDeleted,
  });

  final dynamic publication;
  final VoidCallback onChanged;
  final ValueChanged<int> onDeleted;

  @override
  Widget build(BuildContext context) {
    final status = '${publication['statut'] ?? '-'}';
    final ownPublication = publication['est_auteur'] == true;
    final locked = status == 'archivee';
    final color = publication['est_important'] == true
        ? AppColors.danger
        : AppColors.primary;
    final type = '${publication['type_publication'] ?? '-'}';
    final attachment = '${publication['piece_jointe_url'] ?? ''}'.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_publicationTypeIcon(type), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${publication['titre'] ?? '-'}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${publication['auteur'] ?? '-'} - ${publication['date_publication'] ?? '-'}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              StatusBadge(
                label: locked ? 'Archivee' : status,
                color: locked ? AppColors.primary : color,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge(
                label:
                    '${publication['code_cours'] ?? ''} ${publication['cours'] ?? '-'}'
                        .trim(),
                color: AppColors.primary,
                icon: Icons.menu_book_rounded,
              ),
              StatusBadge(
                label: _publicationTypeLabel(type),
                color: color,
                icon: _publicationTypeIcon(type),
              ),
              if (publication['est_important'] == true)
                const StatusBadge(
                  label: 'Important',
                  color: AppColors.danger,
                  icon: Icons.priority_high_rounded,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${publication['contenu'] ?? ''}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (attachment.isNotEmpty) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _openAttachment(context, attachment),
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(_shortAttachmentLabel(attachment)),
            ),
          ],
          if (ownPublication && status == 'brouillon') ...[
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _publish(context),
              icon: const Icon(Icons.publish_rounded),
              label: const Text('Publier'),
            ),
          ],
          if (ownPublication && !locked) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _edit(context),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Modifier'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _delete(context),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Supprimer'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final controller = TextEditingController(
      text: '${publication['contenu'] ?? ''}',
    );
    final content = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la publication'),
        content: TextField(
          controller: controller,
          minLines: 4,
          maxLines: 6,
          decoration: const InputDecoration(labelText: 'Contenu'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (content == null || content.isEmpty) return;

    try {
      await EnseignantDataSource.service.modifierPublication(
        publicationId: _asInt(publication['id']),
        contenu: content,
      );
      onChanged();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _publish(BuildContext context) async {
    try {
      await EnseignantDataSource.service.publierPublication(
        _asInt(publication['id']),
      );
      onChanged();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la publication ?'),
        content: const Text(
          'Cette action est impossible si la publication est verrouillee.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final publicationId = _asInt(publication['id']);
      await EnseignantDataSource.service.supprimerPublication(publicationId);
      onDeleted(publicationId);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _ValveData {
  const _ValveData({
    this.courses = const [],
    this.publications = const [],
    this.warnings = const [],
  });

  final List<dynamic> courses;
  final List<dynamic> publications;
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
          'La page reste ouverte pendant que les donnees API sont corrigees.',
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

class _ApiNotificationCard extends StatelessWidget {
  const _ApiNotificationCard({
    required this.notification,
    required this.onRead,
  });

  final Map<String, dynamic> notification;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    final type =
        '${notification['type_notification'] ?? 'information_systeme'}';
    final read = notification['est_lue'] == true;
    final color = _notificationTypeColor(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: read ? 0.035 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: read ? 0.12 : 0.24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_notificationTypeIcon(type), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${notification['titre'] ?? '-'}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    StatusBadge(
                      label: read ? 'Lue' : 'Non lue',
                      color: read ? AppColors.success : AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${notification['contenu'] ?? '-'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(
                      label: _notificationTypeLabel(type),
                      color: color,
                      icon: _notificationTypeIcon(type),
                    ),
                    StatusBadge(
                      label: '${notification['cree_le'] ?? '-'}',
                      color: AppColors.textSecondary,
                      icon: Icons.schedule_rounded,
                    ),
                    if (!read)
                      TextButton.icon(
                        onPressed: () => _markRead(context),
                        icon: const Icon(Icons.mark_email_read_rounded),
                        label: const Text('Marquer comme lue'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markRead(BuildContext context) async {
    try {
      await NotificationsDataSource.service.marquerCommeLue(
        _asInt(notification['id']),
      );
      onRead();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

const _publicationTypes = [
  'annonce',
  'communique',
  'devoir',
  'support_de_cours',
  'changement_horaire',
  'consigne_examen',
  'rappel',
];

String _publicationTypeLabel(String type) {
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

IconData _publicationTypeIcon(String type) {
  switch (type) {
    case 'devoir':
      return Icons.assignment_rounded;
    case 'support_de_cours':
      return Icons.attach_file_rounded;
    case 'changement_horaire':
      return Icons.event_repeat_rounded;
    case 'consigne_examen':
      return Icons.rule_rounded;
    case 'publication_notes':
      return Icons.fact_check_rounded;
    case 'rappel':
      return Icons.alarm_rounded;
    case 'communique':
      return Icons.record_voice_over_rounded;
    case 'annonce':
    default:
      return Icons.campaign_rounded;
  }
}

String _shortAttachmentLabel(String value) {
  if (value.length <= 42) return value;
  return '${value.substring(0, 18)}...${value.substring(value.length - 18)}';
}

String _formatFileSize(int size) {
  if (size <= 0) return 'taille inconnue';
  if (size < 1024) return '$size o';
  final ko = size / 1024;
  if (ko < 1024) return '${ko.toStringAsFixed(1)} Ko';
  final mo = ko / 1024;
  return '${mo.toStringAsFixed(1)} Mo';
}

void _openAttachment(BuildContext context, String attachment) {
  final url = _attachmentUrl(attachment);
  if (ouvrirLienExterne(url)) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(url)),
  );
}

String _attachmentUrl(String attachment) {
  if (attachment.startsWith('http://') || attachment.startsWith('https://')) {
    return attachment;
  }

  if (attachment.startsWith('/')) {
    return '${ApiConfig.baseUrl}$attachment';
  }

  return attachment;
}

String _notificationTypeLabel(String type) {
  switch (type) {
    case 'nouvelle_note':
      return 'Note';
    case 'nouvelle_publication':
      return 'Valve';
    case 'reclamation_mise_a_jour':
      return 'Reclamation';
    case 'alerte_academique':
      return 'Alerte';
    case 'information_systeme':
      return 'Systeme';
    default:
      return type;
  }
}

IconData _notificationTypeIcon(String type) {
  switch (type) {
    case 'nouvelle_note':
      return Icons.fact_check_rounded;
    case 'nouvelle_publication':
      return Icons.campaign_rounded;
    case 'reclamation_mise_a_jour':
      return Icons.mark_email_unread_rounded;
    case 'alerte_academique':
      return Icons.warning_amber_rounded;
    case 'information_systeme':
      return Icons.info_rounded;
    default:
      return Icons.notifications_rounded;
  }
}

Color _notificationTypeColor(String type) {
  switch (type) {
    case 'nouvelle_note':
      return AppColors.success;
    case 'nouvelle_publication':
      return AppColors.primary;
    case 'reclamation_mise_a_jour':
      return AppColors.violet;
    case 'alerte_academique':
      return AppColors.danger;
    case 'information_systeme':
      return AppColors.cyan;
    default:
      return AppColors.primary;
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? 0}') ?? 0;
}
