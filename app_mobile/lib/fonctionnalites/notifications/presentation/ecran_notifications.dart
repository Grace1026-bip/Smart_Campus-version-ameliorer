import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/donnees_fictives/donnees_faculte_fictives.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/fichier_valve_picker.dart';
import '../../../donnees/services/lien_externe.dart';
import '../../../donnees/services/service_enseignant.dart';
import '../../../donnees/services/service_session.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/carte_statistique.dart';
import '../../../commun/composants/badge_statut.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = SessionService.currentRole;
    if (role == UserRole.teacher) return const _TeacherValveScreen();

    const notifications = MockFacultyData.notifications;

    return SmartFacultyShell(
      role: role,
      selectedRoute: AppRoutes.notifications,
      title: 'Notifications',
      subtitle: 'Messages academiques, alertes et annonces institutionnelles.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveGrid(
            children: [
              StatCard(
                metric: KpiMetric(
                  title: 'Notifications',
                  value: '${notifications.length}',
                  trend: 'mock',
                  description: 'messages recents',
                ),
                icon: Icons.notifications_rounded,
                color: AppColors.primary,
              ),
              const StatCard(
                metric: KpiMetric(
                  title: 'Prioritaires',
                  value: '1',
                  trend: 'a lire',
                  description: 'alerte academique',
                ),
                icon: Icons.priority_high_rounded,
                color: AppColors.danger,
              ),
              const StatCard(
                metric: KpiMetric(
                  title: 'Annonces',
                  value: '2',
                  trend: 'cette semaine',
                  description: 'communication',
                ),
                icon: Icons.campaign_rounded,
                color: AppColors.warning,
              ),
              const StatCard(
                metric: KpiMetric(
                  title: 'Canaux',
                  value: '5',
                  trend: 'roles',
                  description: 'audiences ciblees',
                ),
                icon: Icons.groups_rounded,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionPanel(
            title: 'Boite de notifications',
            subtitle: 'Ces messages seront plus tard fournis par l API.',
            child: Column(
              children: [
                for (final notification in notifications)
                  _NotificationCard(notification: notification),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherValveScreen extends StatefulWidget {
  const _TeacherValveScreen();

  @override
  State<_TeacherValveScreen> createState() => _TeacherValveScreenState();
}

class _TeacherValveScreenState extends State<_TeacherValveScreen> {
  late Future<_ValveData> _future = _load();
  int? _courseFilter;
  String? _typeFilter;
  final Set<int> _removedPublicationIds = {};

  Future<_ValveData> _load() async {
    final results = await Future.wait([
      EnseignantDataSource.service.cours(),
      EnseignantDataSource.service.valve(),
    ]);

    return _ValveData(
      courses: results[0] as List<dynamic>,
      publications: results[1] as List<dynamic>,
    );
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
              _PublicationForm(courses: data.courses, onSaved: () => _refresh()),
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
                              child: Text('${course['code']} - ${course['nom']}'),
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
                            value: 'publication_notes',
                            child: Text('Notes'),
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
  const _PublicationForm({required this.courses, required this.onSaved});

  final List<dynamic> courses;
  final VoidCallback onSaved;

  @override
  State<_PublicationForm> createState() => _PublicationFormState();
}

class _PublicationFormState extends State<_PublicationForm> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _attachmentController = TextEditingController();
  int? _courseId;
  String _type = 'annonce';
  String? _pickedFileName;
  String? _pickedFileBase64;
  int? _pickedFileSize;
  bool _important = false;
  bool _pickingFile = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _attachmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _courseId ??= widget.courses.isEmpty ? null : _asInt(widget.courses.first['id']);

    if (widget.courses.isEmpty) {
      return const SectionPanel(
        title: 'Nouvelle publication',
        subtitle: 'Aucun cours attribue a ce compte.',
        child: Text('La valve sera disponible des qu un cours vous sera attribue.'),
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
                    DropdownMenuItem(value: 'communique', child: Text('Communique')),
                    DropdownMenuItem(value: 'devoir', child: Text('Devoir')),
                    DropdownMenuItem(value: 'support_de_cours', child: Text('Support')),
                    DropdownMenuItem(value: 'publication_notes', child: Text('Notes')),
                    DropdownMenuItem(value: 'changement_horaire', child: Text('Changement horaire')),
                    DropdownMenuItem(value: 'consigne_examen', child: Text('Consigne examen')),
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
          if (_type == 'publication_notes') ...[
            const SizedBox(height: 12),
            const _NotesPublicationHint(),
          ],
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
              label: Text(_saving ? 'Publication...' : 'Publier'),
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
      );
      if (!mounted) return;
      _titleController.clear();
      _contentController.clear();
      _attachmentController.clear();
      setState(() {
        _important = false;
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

class _NotesPublicationHint extends StatelessWidget {
  const _NotesPublicationHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.fact_check_rounded, color: AppColors.primary),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Les cotes officielles se publient depuis le module Notes.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.grades),
          icon: const Icon(Icons.open_in_new_rounded),
          label: const Text('Ouvrir Notes'),
        ),
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
    final locked = publication['est_verrouille'] == true;
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
                label:
                    locked ? 'Verrouillee' : '${publication['statut'] ?? '-'}',
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
          if (!locked) ...[
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
      await EnseignantDataSource.service
          .supprimerPublication(publicationId);
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
  });

  final List<dynamic> courses;
  final List<dynamic> publications;
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});

  final FacultyNotification notification;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(notification.tone);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
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
            child: Icon(_toneIcon(notification.tone), color: color),
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
                        notification.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    StatusBadge(
                      label: notification.audience,
                      color: color,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification.message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  notification.timeLabel,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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

Color _toneColor(NotificationTone tone) {
  switch (tone) {
    case NotificationTone.info:
      return AppColors.primary;
    case NotificationTone.success:
      return AppColors.success;
    case NotificationTone.warning:
      return AppColors.warning;
    case NotificationTone.danger:
      return AppColors.danger;
  }
}

IconData _toneIcon(NotificationTone tone) {
  switch (tone) {
    case NotificationTone.info:
      return Icons.info_rounded;
    case NotificationTone.success:
      return Icons.check_circle_rounded;
    case NotificationTone.warning:
      return Icons.campaign_rounded;
    case NotificationTone.danger:
      return Icons.priority_high_rounded;
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? 0}') ?? 0;
}
