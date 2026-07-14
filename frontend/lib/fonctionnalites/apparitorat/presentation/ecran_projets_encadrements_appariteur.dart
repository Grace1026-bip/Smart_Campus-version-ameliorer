import 'package:flutter/material.dart';

import '../../../commun/composants/badge_statut.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_api.dart';
import '../../../donnees/services/service_appariteur.dart';

class ApparitorProjectsSupervisionsScreen extends StatefulWidget {
  const ApparitorProjectsSupervisionsScreen({super.key});

  @override
  State<ApparitorProjectsSupervisionsScreen> createState() =>
      _ApparitorProjectsSupervisionsScreenState();
}

class _ApparitorProjectsSupervisionsScreenState
    extends State<ApparitorProjectsSupervisionsScreen> {
  final _service = AppariteurDataSource.service;
  final _rechercheController = TextEditingController();
  List<dynamic> _elements = const [];
  List<dynamic> _etudiants = const [];
  List<dynamic> _enseignants = const [];
  Map<String, dynamic>? _detail;
  String? _typeProjet;
  String? _statut;
  bool _sansEncadreur = false;
  Object? _erreur;
  bool _chargement = true;
  bool _actionEnCours = false;

  static const _types = <String, String>{
    'reseaux': 'Reseaux',
    'systemes_embarques': 'Systemes embarques',
    'intelligence_artificielle': 'Intelligence artificielle',
    'genie_logiciel': 'Genie logiciel',
  };

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final resultats = await Future.wait<dynamic>([
        _service.projets(
          typeProjet: _typeProjet,
          statut: _statut,
          recherche: _rechercheController.text,
          sansEncadreur: _sansEncadreur,
        ),
        if (_etudiants.isEmpty) _service.etudiants(),
        if (_enseignants.isEmpty) _service.enseignants(),
      ]);
      if (!mounted) return;
      final projets = resultats[0] as Map<String, dynamic>;
      var index = 1;
      setState(() {
        _elements = projets['elements'] as List<dynamic>? ?? const [];
        if (_etudiants.isEmpty) {
          _etudiants = resultats[index++] as List<dynamic>;
        }
        if (_enseignants.isEmpty) {
          _enseignants = resultats[index] as List<dynamic>;
        }
        _chargement = false;
      });
    } catch (erreur) {
      if (!mounted) return;
      setState(() {
        _erreur = erreur;
        _chargement = false;
      });
    }
  }

  Future<void> _creerProjet() async {
    final draft = await showDialog<_ProjectDraft>(
      context: context,
      builder: (context) => _ProjectDialog(etudiants: _etudiants),
    );
    if (draft == null) return;
    await _executer(
      () => _service.creerProjet(
        etudiantId: draft.etudiantId!,
        titre: draft.titre,
        typeProjet: draft.typeProjet,
        description: draft.description,
      ),
      'Projet academique cree.',
    );
  }

  Future<void> _modifierProjet() async {
    final detail = _detail;
    if (detail == null) return;
    final draft = await showDialog<_ProjectDraft>(
      context: context,
      builder: (context) => _ProjectDialog(initial: detail),
    );
    if (draft == null) return;
    final id = _asInt(detail['id']);
    if (id == null) return;
    await _executer(
      () => _service.modifierProjet(
        id,
        titre: draft.titre,
        typeProjet: draft.typeProjet,
        description: draft.description,
        statut: draft.statut,
      ),
      'Projet modifie.',
    );
  }

  Future<void> _ouvrirDetail(Map<String, dynamic> item) async {
    final id = _asInt(item['id']);
    if (id == null) return;
    setState(() => _actionEnCours = true);
    try {
      final result = await _service.detailProjet(id);
      if (mounted) setState(() => _detail = result);
    } catch (erreur) {
      if (mounted) _afficherErreur(erreur);
    } finally {
      if (mounted) setState(() => _actionEnCours = false);
    }
  }

  Future<void> _attribuer() async {
    final detail = _detail;
    final projetId = _asInt(detail?['id']);
    if (detail == null || projetId == null) return;
    try {
      final type = '${detail['type_projet'] ?? ''}';
      final response = await _service.enseignantsEncadreurs(typeProjet: type);
      if (!mounted) return;
      final teachers = response['elements'] as List<dynamic>? ?? const [];
      final draft = await showDialog<_AssignmentDraft>(
        context: context,
        builder: (context) => _AssignmentDialog(enseignants: teachers),
      );
      if (draft == null) return;
      await _executer(
        () => _service.attribuerEncadrement(
          projetId: projetId,
          enseignantId: draft.enseignantId,
          roleEncadrement: draft.roleEncadrement,
          remplacerPrincipal: draft.remplacerPrincipal,
        ),
        'Encadrement attribue.',
      );
    } catch (erreur) {
      if (mounted) _afficherErreur(erreur);
    }
  }

  Future<void> _configurerSpecialites() async {
    final teacher = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _TeacherDialog(enseignants: _enseignants),
    );
    if (teacher == null) return;
    final id = _asInt(teacher['id']);
    if (id == null) return;
    try {
      final current = await _service.specialitesEnseignant(id);
      if (!mounted) return;
      final types = (current['specialites'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .where((item) => item['actif'] == true)
          .map((item) => '${item['type_projet']}')
          .toSet();
      final selected = await showDialog<List<String>>(
        context: context,
        builder: (context) => _SpecialitesDialog(
          enseignant: teacher,
          initial: types,
        ),
      );
      if (selected == null) return;
      await _executer(
        () => _service.configurerSpecialites(
          enseignantId: id,
          typesProjet: selected,
        ),
        'Specialites mises a jour.',
        reloadDetail: false,
      );
    } catch (erreur) {
      if (mounted) _afficherErreur(erreur);
    }
  }

  Future<void> _desactiver(int encadrementId) async {
    final projetId = _asInt(_detail?['id']);
    if (projetId == null) return;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactiver cet encadrement ?'),
        content: const Text('L historique sera conserve.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Retour'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desactiver'),
          ),
        ],
      ),
    );
    if (confirme != true) return;
    await _executer(
      () => _service.desactiverEncadrement(
        projetId: projetId,
        encadrementId: encadrementId,
      ),
      'Encadrement desactive.',
    );
  }

  Future<void> _archiver() async {
    final id = _asInt(_detail?['id']);
    if (id == null) return;
    await _executer(
      () => _service.archiverProjet(id),
      'Projet archive.',
    );
  }

  Future<void> _executer(
    Future<Map<String, dynamic>> Function() action,
    String message, {
    bool reloadDetail = true,
  }) async {
    setState(() => _actionEnCours = true);
    try {
      final result = await action();
      if (!mounted) return;
      setState(() {
        if (reloadDetail) _detail = result;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      await _charger();
      if (reloadDetail && _detail != null) {
        final id = _asInt(_detail!['id']);
        if (id != null) {
          final fresh = await _service.detailProjet(id);
          if (mounted) setState(() => _detail = fresh);
        }
      }
    } catch (erreur) {
      if (mounted) _afficherErreur(erreur);
    } finally {
      if (mounted) setState(() => _actionEnCours = false);
    }
  }

  void _afficherErreur(Object erreur) {
    final message = erreur is ApiException
        ? erreur.messagePourUtilisateur
        : 'L operation sur le projet a echoue.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.apparitor,
      selectedRoute: AppRoutes.apparitorProjects,
      title: 'Projets et encadrements',
      subtitle: 'Gerer les projets et les enseignants encadreurs compatibles.',
      actions: [
        IconButton(
          onPressed: _chargement ? null : _charger,
          tooltip: 'Actualiser les projets',
          icon: const Icon(Icons.refresh_rounded),
        ),
        OutlinedButton.icon(
          onPressed: _actionEnCours ? null : _configurerSpecialites,
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Specialites'),
        ),
        FilledButton.icon(
          onPressed: _actionEnCours ? null : _creerProjet,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nouveau projet'),
        ),
      ],
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_chargement) return const Center(child: CircularProgressIndicator());
    if (_erreur != null) {
      final message = _erreur is ApiException
          ? (_erreur! as ApiException).messagePourUtilisateur
          : 'Les projets ne peuvent pas etre charges.';
      return SectionPanel(
        title: 'Projets indisponibles',
        subtitle: 'Le serveur n a pas retourne la liste demandee.',
        child: Text(message),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionPanel(
          title: 'Filtres',
          subtitle: 'Rechercher un projet, un etudiant ou un type.',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _rechercheController,
                  decoration: const InputDecoration(
                    labelText: 'Etudiant ou projet',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onSubmitted: (_) => _charger(),
                ),
              ),
              DropdownButton<String?>(
                value: _typeProjet,
                hint: const Text('Tous les types'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Tous les types'),
                  ),
                  for (final item in _types.entries)
                    DropdownMenuItem<String?>(
                      value: item.key,
                      child: Text(item.value),
                    ),
                ],
                onChanged: (value) {
                  setState(() => _typeProjet = value);
                  _charger();
                },
              ),
              DropdownButton<String?>(
                value: _statut,
                hint: const Text('Tous les statuts'),
                items: const [
                  DropdownMenuItem<String?>(
                      value: null, child: Text('Tous les statuts')),
                  DropdownMenuItem<String?>(
                      value: 'propose', child: Text('Propose')),
                  DropdownMenuItem<String?>(
                      value: 'en_cours', child: Text('En cours')),
                  DropdownMenuItem<String?>(
                      value: 'suspendu', child: Text('Suspendu')),
                  DropdownMenuItem<String?>(
                      value: 'termine', child: Text('Termine')),
                  DropdownMenuItem<String?>(
                      value: 'archive', child: Text('Archive')),
                ],
                onChanged: (value) {
                  setState(() => _statut = value);
                  _charger();
                },
              ),
              FilterChip(
                label: const Text('Sans encadreur'),
                selected: _sansEncadreur,
                onSelected: (value) {
                  setState(() => _sansEncadreur = value);
                  _charger();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_elements.isEmpty)
          const SectionPanel(
            title: 'Aucun projet',
            subtitle: 'Modifiez les filtres ou creez un projet academique.',
            child:
                Text('Aucun projet ne correspond aux criteres selectionnes.'),
          )
        else
          ResponsiveGrid(
            minItemWidth: 360,
            maxColumns: 2,
            children: [
              for (final item in _elements)
                if (item is Map<String, dynamic>) _carte(item),
            ],
          ),
        if (_detail != null) ...[
          const SizedBox(height: 18),
          _detailPanel(_detail!),
        ],
      ],
    );
  }

  Widget _carte(Map<String, dynamic> item) {
    final student = _map(item['etudiant']);
    final principal = _map(item['encadreur_principal']);
    return Card(
      child: InkWell(
        onTap: () => _ouvrirDetail(item),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item['titre'] ?? '-'}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  StatusBadge(
                    label: '${item['statut'] ?? '-'}',
                    color: _couleurStatut('${item['statut'] ?? ''}'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                  'Type: ${item['type_projet_libelle'] ?? item['type_projet'] ?? '-'}'),
              Text(
                  'Etudiant: ${student['nom'] ?? '-'} (${student['matricule'] ?? '-'})'),
              Text('Principal: ${principal['enseignant']?['nom'] ?? 'Aucun'}'),
              Text('Co-encadreurs: ${item['nombre_coencadreurs'] ?? 0}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailPanel(Map<String, dynamic> detail) {
    final student = _map(detail['etudiant']);
    final promotion = _map(detail['promotion']);
    final active = detail['encadrements_actifs'] as List<dynamic>? ?? const [];
    final history =
        detail['encadrements_historiques'] as List<dynamic>? ?? const [];
    final archive = detail['statut'] == 'archive';
    return SectionPanel(
      title: 'Detail du projet',
      subtitle: '${detail['titre'] ?? '-'}',
      trailing: Wrap(
        spacing: 8,
        children: [
          IconButton(
            onPressed: _actionEnCours || archive ? null : _modifierProjet,
            tooltip: 'Modifier le projet',
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            onPressed: _actionEnCours || archive ? null : _archiver,
            tooltip: 'Archiver le projet',
            icon: const Icon(Icons.archive_outlined),
          ),
          StatusBadge(
            label: '${detail['statut'] ?? '-'}',
            color: _couleurStatut('${detail['statut'] ?? ''}'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _info('Etudiant',
                  '${student['nom'] ?? '-'} (${student['matricule'] ?? '-'})'),
              _info('Promotion', '${promotion['nom'] ?? '-'}'),
              _info('Type',
                  '${detail['type_projet_libelle'] ?? detail['type_projet'] ?? '-'}'),
            ],
          ),
          if (!archive) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _actionEnCours ? null : _attribuer,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Attribuer un encadreur'),
            ),
          ],
          const SizedBox(height: 14),
          Text('Encadrements actifs',
              style: Theme.of(context).textTheme.titleSmall),
          if (active.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                  'Aucun enseignant compatible n est actuellement attribue.'),
            )
          else
            ...active.whereType<Map<String, dynamic>>().map(_encadrementTile),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Historique', style: Theme.of(context).textTheme.titleSmall),
            ...history.whereType<Map<String, dynamic>>().map(
                  (item) => _encadrementTile(item, historique: true),
                ),
          ],
        ],
      ),
    );
  }

  Widget _encadrementTile(Map<String, dynamic> item,
      {bool historique = false}) {
    final teacher = _map(item['enseignant']);
    final id = _asInt(item['id']);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(historique ? Icons.history_rounded : Icons.person_rounded),
      title: Text('${teacher['nom'] ?? '-'}'),
      subtitle: Text(
        '${item['role_encadrement'] ?? '-'} - ${teacher['departement'] ?? '-'}',
      ),
      trailing: historique
          ? const Text('Desactive')
          : IconButton(
              onPressed:
                  id == null || _actionEnCours ? null : () => _desactiver(id),
              tooltip: 'Desactiver',
              icon: const Icon(Icons.person_remove_alt_1_rounded),
            ),
    );
  }

  Widget _info(String label, String value) => SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 3),
            Text(value, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      );

  Color _couleurStatut(String statut) {
    switch (statut) {
      case 'en_cours':
        return AppColors.success;
      case 'archive':
        return AppColors.textSecondary;
      case 'suspendu':
        return AppColors.warning;
      default:
        return AppColors.terracotta;
    }
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map<String, dynamic> ? value : <String, dynamic>{};

  int? _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value');
}

class _ProjectDraft {
  const _ProjectDraft({
    this.etudiantId,
    required this.titre,
    required this.typeProjet,
    this.description,
    this.statut,
  });

  final int? etudiantId;
  final String titre;
  final String typeProjet;
  final String? description;
  final String? statut;
}

class _ProjectDialog extends StatefulWidget {
  const _ProjectDialog({this.etudiants = const [], this.initial});

  final List<dynamic> etudiants;
  final Map<String, dynamic>? initial;

  @override
  State<_ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<_ProjectDialog> {
  late final TextEditingController _titre;
  late final TextEditingController _description;
  late String _type;
  late String _statut;
  int? _etudiantId;

  static const _types = {
    'reseaux': 'Reseaux',
    'systemes_embarques': 'Systemes embarques',
    'intelligence_artificielle': 'Intelligence artificielle',
    'genie_logiciel': 'Genie logiciel',
  };

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titre = TextEditingController(text: '${initial?['titre'] ?? ''}');
    _description =
        TextEditingController(text: '${initial?['description'] ?? ''}');
    _type = '${initial?['type_projet'] ?? 'genie_logiciel'}';
    _statut = '${initial?['statut'] ?? 'propose'}';
  }

  @override
  void dispose() {
    _titre.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final edit = widget.initial != null;
    return AlertDialog(
      title: Text(edit ? 'Modifier le projet' : 'Nouveau projet'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!edit)
                DropdownButtonFormField<int>(
                  initialValue: _etudiantId,
                  decoration: const InputDecoration(labelText: 'Etudiant'),
                  items: [
                    for (final item in widget.etudiants)
                      if (item is Map && item['id'] is num)
                        DropdownMenuItem<int>(
                          value: (item['id'] as num).toInt(),
                          child: Text(
                              '${item['matricule'] ?? '-'} - ${_nom(item)}'),
                        ),
                  ],
                  onChanged: (value) => setState(() => _etudiantId = value),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _titre,
                decoration: const InputDecoration(labelText: 'Titre'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type de projet'),
                items: [
                  for (final item in _types.entries)
                    DropdownMenuItem(value: item.key, child: Text(item.value)),
                ],
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
              const SizedBox(height: 12),
              if (edit)
                DropdownButtonFormField<String>(
                  initialValue: _statut,
                  decoration: const InputDecoration(labelText: 'Statut'),
                  items: const [
                    DropdownMenuItem(value: 'propose', child: Text('Propose')),
                    DropdownMenuItem(
                        value: 'en_cours', child: Text('En cours')),
                    DropdownMenuItem(
                        value: 'suspendu', child: Text('Suspendu')),
                    DropdownMenuItem(value: 'termine', child: Text('Termine')),
                  ],
                  onChanged: (value) =>
                      setState(() => _statut = value ?? _statut),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Retour')),
        FilledButton(
          onPressed: () {
            if (_titre.text.trim().isEmpty || (!edit && _etudiantId == null)) {
              return;
            }
            Navigator.pop(
              context,
              _ProjectDraft(
                etudiantId: _etudiantId,
                titre: _titre.text,
                typeProjet: _type,
                description: _description.text,
                statut: edit ? _statut : null,
              ),
            );
          },
          child: Text(edit ? 'Enregistrer' : 'Creer'),
        ),
      ],
    );
  }

  String _nom(Map item) =>
      '${item['utilisateur']?['prenom'] ?? ''} ${item['utilisateur']?['nom'] ?? ''}'
          .trim();
}

class _AssignmentDraft {
  const _AssignmentDraft({
    required this.enseignantId,
    required this.roleEncadrement,
    required this.remplacerPrincipal,
  });

  final int enseignantId;
  final String roleEncadrement;
  final bool remplacerPrincipal;
}

class _AssignmentDialog extends StatefulWidget {
  const _AssignmentDialog({required this.enseignants});

  final List<dynamic> enseignants;

  @override
  State<_AssignmentDialog> createState() => _AssignmentDialogState();
}

class _AssignmentDialogState extends State<_AssignmentDialog> {
  int? _enseignantId;
  String _role = 'principal';
  bool _remplacer = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Attribuer un encadreur'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.enseignants.isEmpty)
              const Text(
                  'Aucun enseignant compatible n est disponible pour ce type de projet.')
            else
              DropdownButtonFormField<int>(
                initialValue: _enseignantId,
                decoration:
                    const InputDecoration(labelText: 'Enseignant compatible'),
                items: [
                  for (final item in widget.enseignants)
                    if (item is Map && item['id'] is num)
                      DropdownMenuItem<int>(
                        value: (item['id'] as num).toInt(),
                        child: Text(
                            '${item['nom'] ?? '-'} - ${item['departement'] ?? '-'}'),
                      ),
                ],
                onChanged: (value) => setState(() => _enseignantId = value),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: 'principal', child: Text('Principal')),
                DropdownMenuItem(
                    value: 'co_encadreur', child: Text('Co-encadreur')),
              ],
              onChanged: (value) => setState(() => _role = value ?? _role),
            ),
            if (_role == 'principal')
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _remplacer,
                onChanged: (value) =>
                    setState(() => _remplacer = value ?? false),
                title: const Text('Remplacer le principal actuel'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Retour')),
        FilledButton(
          onPressed: _enseignantId == null
              ? null
              : () => Navigator.pop(
                    context,
                    _AssignmentDraft(
                      enseignantId: _enseignantId!,
                      roleEncadrement: _role,
                      remplacerPrincipal: _remplacer,
                    ),
                  ),
          child: const Text('Attribuer'),
        ),
      ],
    );
  }
}

class _TeacherDialog extends StatelessWidget {
  const _TeacherDialog({required this.enseignants});

  final List<dynamic> enseignants;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choisir un enseignant'),
      content: SizedBox(
        width: 500,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: enseignants.length,
          itemBuilder: (context, index) {
            final item = enseignants[index];
            if (item is! Map<String, dynamic>) return const SizedBox.shrink();
            return ListTile(
              title: Text(
                  '${item['utilisateur']?['prenom'] ?? ''} ${item['utilisateur']?['nom'] ?? ''}'
                      .trim()),
              subtitle: Text(
                  '${item['matricule_agent'] ?? '-'} - ${item['departement'] ?? '-'}'),
              onTap: () => Navigator.pop(context, item),
            );
          },
        ),
      ),
    );
  }
}

class _SpecialitesDialog extends StatefulWidget {
  const _SpecialitesDialog({required this.enseignant, required this.initial});

  final Map<String, dynamic> enseignant;
  final Set<String> initial;

  @override
  State<_SpecialitesDialog> createState() => _SpecialitesDialogState();
}

class _SpecialitesDialogState extends State<_SpecialitesDialog> {
  late final Set<String> _selected = {...widget.initial};

  static const _types = {
    'reseaux': 'Reseaux',
    'systemes_embarques': 'Systemes embarques',
    'intelligence_artificielle': 'Intelligence artificielle',
    'genie_logiciel': 'Genie logiciel',
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Specialites - ${widget.enseignant['nom'] ?? '-'}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in _types.entries)
            CheckboxListTile(
              value: _selected.contains(item.key),
              title: Text(item.value),
              onChanged: (value) => setState(() {
                if (value == true) {
                  _selected.add(item.key);
                } else {
                  _selected.remove(item.key);
                }
              }),
            ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Retour')),
        FilledButton(
            onPressed: () => Navigator.pop(context, _selected.toList()),
            child: const Text('Enregistrer')),
      ],
    );
  }
}
