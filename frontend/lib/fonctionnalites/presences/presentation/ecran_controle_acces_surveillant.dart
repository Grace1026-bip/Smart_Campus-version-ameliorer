import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/capture_camera_partagee.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../donnees/services/service_api.dart';
import '../../../donnees/services/service_presences.dart';
import '../../../donnees/services/service_session.dart';

class ControleAccesSurveillantScreen extends StatefulWidget {
  const ControleAccesSurveillantScreen({super.key});

  @override
  State<ControleAccesSurveillantScreen> createState() =>
      _ControleAccesSurveillantScreenState();
}

class _ControleAccesSurveillantScreenState
    extends State<ControleAccesSurveillantScreen> {
  final _service = PresencesDataSource.service;
  final _matriculeController = TextEditingController();
  final _coursController = TextEditingController();
  List<dynamic> _seances = const [];
  List<dynamic> _presences = const [];
  Map<String, dynamic>? _selection;
  Map<String, dynamic>? _dernierControle;
  Map<String, dynamic>? _resume;
  Object? _erreur;
  bool _chargement = true;
  bool _actionEnCours = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _matriculeController.dispose();
    _coursController.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final seances = await _service.seances();
      if (!mounted) return;
      final selectionId = _selection?['id'];
      Map<String, dynamic>? selection;
      for (final item in seances) {
        if (item is Map<String, dynamic> && item['id'] == selectionId) {
          selection = item;
          break;
        }
      }
      setState(() {
        _seances = seances;
        _selection = selection;
        _chargement = false;
      });
      if (_selection != null) await _chargerPresences(_selection!);
    } catch (erreur) {
      if (!mounted) return;
      setState(() {
        _erreur = erreur;
        _chargement = false;
      });
    }
  }

  Future<void> _chargerPresences(Map<String, dynamic> seance) async {
    final id = _asInt(seance['id']);
    if (id == null) return;
    try {
      final presences = await _service.presences(id);
      if (!mounted) return;
      setState(() => _presences = presences);
    } catch (erreur) {
      if (!mounted) return;
      setState(() => _erreur = erreur);
    }
  }

  Future<void> _creerSeance() async {
    final coursId = int.tryParse(_coursController.text.trim());
    if (coursId == null || coursId <= 0) {
      _message('Saisissez un identifiant de cours valide.');
      return;
    }
    await _executer(() async {
      await _service.creerSeance(
        coursId: coursId,
        dateSeance: DateTime.now().toIso8601String().substring(0, 10),
        heureDebut: '08:00:00',
        heureFin: '12:00:00',
      );
      _coursController.clear();
      await _charger();
    });
  }

  Future<void> _changerStatut(String action) async {
    final id = _asInt(_selection?['id']);
    if (id == null) return;
    await _executer(() async {
      if (action == 'ouvrir') {
        await _service.ouvrirSeance(id);
      } else {
        final resultat = await _service.fermerSeance(id);
        if (mounted) setState(() => _resume = _map(resultat['resume']));
      }
      await _charger();
    });
  }

  Future<void> _controlerAcces() async {
    final id = _asInt(_selection?['id']);
    final matricule = _matriculeController.text.trim();
    if (id == null || matricule.isEmpty) {
      _message('Selectionnez une seance ouverte et saisissez un matricule.');
      return;
    }
    await _executer(() async {
      final resultat = await _service.controlerAcces(
        seanceId: id,
        matricule: matricule,
      );
      if (!mounted) return;
      setState(() => _dernierControle = resultat);
      await _chargerPresences(_selection!);
    });
  }

  Future<void> _reconnaitre(List<XFile> images) async {
    final id = _asInt(_selection?['id']);
    if (id == null) return;
    await _executer(() async {
      final resultat = await _service.reconnaitreFacial(
        seanceId: id,
        images: images,
      );
      if (!mounted) return;
      setState(() => _dernierControle = resultat);
      await _chargerPresences(_selection!);
    });
  }

  Future<void> _executer(Future<void> Function() action) async {
    setState(() {
      _actionEnCours = true;
      _erreur = null;
    });
    try {
      await action();
    } catch (erreur) {
      if (!mounted) return;
      setState(() => _erreur = erreur);
    } finally {
      if (mounted) setState(() => _actionEnCours = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: SessionService.currentRole,
      selectedRoute: AppRoutes.surveillantAttendance,
      title: 'Controle d acces',
      subtitle: 'Presences manuelles par seance et par cours.',
      actions: [
        IconButton(
            onPressed: _charger,
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh_rounded)),
      ],
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_chargement) return const Center(child: CircularProgressIndicator());
    if (_erreur != null && _seances.isEmpty) {
      return SectionPanel(
        title: 'Seances indisponibles',
        subtitle: 'Le service de presence n a pas repondu.',
        child: Text(_erreur is ApiException
            ? (_erreur! as ApiException).messagePourUtilisateur
            : 'Une erreur est survenue.'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionPanel(
          title: 'Nouvelle seance',
          subtitle: 'Le cours est verifie par le backend.',
          child: Row(
            children: [
              Expanded(
                  child: TextField(
                      controller: _coursController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Identifiant du cours'))),
              const SizedBox(width: 12),
              FilledButton.icon(
                  onPressed: _actionEnCours ? null : _creerSeance,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Creer')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_seances.isEmpty)
          const SectionPanel(
              title: 'Aucune seance',
              subtitle: 'Aucune seance academique n est disponible.',
              child: Text('Creez une seance pour commencer le controle.'))
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in _seances)
                if (item is Map<String, dynamic>) _seanceCard(context, item)
            ],
          ),
        if (_selection != null) ...[
          const SizedBox(height: 18),
          _controlePanel(context),
          if (_resume != null) ...[
            const SizedBox(height: 18),
            _resumePanel(context),
          ],
        ],
        const SizedBox(height: 18),
        if (_selection != null && _selection!['statut'] == 'ouverte')
          SectionPanel(
            title: 'Reconnaissance faciale',
            subtitle: 'Trois captures, puis verification backend.',
            child: CaptureCameraPartagee(onCapturesTerminees: _reconnaitre),
          ),
      ],
    );
  }

  Widget _seanceCard(BuildContext context, Map<String, dynamic> item) {
    final selected = item['id'] == _selection?['id'];
    final cours = item['cours'] is Map
        ? Map<String, dynamic>.from(item['cours'] as Map)
        : const <String, dynamic>{};
    return SizedBox(
      width: 360,
      child: Card(
        color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
        child: InkWell(
          onTap: () {
            setState(() {
              _selection = item;
              _dernierControle = null;
              _resume = null;
              _erreur = null;
            });
            _chargerPresences(item);
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${cours['code'] ?? 'Cours'} - ${cours['intitule'] ?? ''}',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                  '${item['date_seance'] ?? '-'} | ${item['type_cours'] ?? '-'}'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text('${item['statut'] ?? '-'}')),
                if (item['statut'] == 'planifiee')
                  TextButton(
                      onPressed: _actionEnCours
                          ? null
                          : () {
                              setState(() => _selection = item);
                              _changerStatut('ouvrir');
                            },
                      child: const Text('Ouvrir')),
                if (item['statut'] == 'ouverte')
                  TextButton(
                      onPressed: _actionEnCours
                          ? null
                          : () {
                              setState(() => _selection = item);
                              _changerStatut('fermer');
                            },
                      child: const Text('Fermer'))
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _controlePanel(BuildContext context) {
    final selection = _selection!;
    final statut = selection['statut'];
    final resultat = _dernierControle;
    return SectionPanel(
      title: 'Identification manuelle',
      subtitle: 'L autorisation est calculee par FastAPI.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: TextField(
                  controller: _matriculeController,
                  decoration:
                      const InputDecoration(labelText: 'Matricule etudiant'))),
          const SizedBox(width: 12),
          FilledButton.icon(
              onPressed: _actionEnCours || statut != 'ouverte'
                  ? null
                  : _controlerAcces,
              icon: const Icon(Icons.how_to_reg_rounded),
              label: const Text('Controler'))
        ]),
        if (statut != 'ouverte')
          const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                  'La seance doit etre ouverte pour enregistrer une presence.')),
        if (resultat != null) ...[
          const SizedBox(height: 14),
          Text(
              resultat['acces_autorise'] == true
                  ? 'Acces autorise'
                  : 'Acces refuse',
              style: Theme.of(context).textTheme.titleSmall),
          Text('Motif : ${resultat['motif'] ?? '-'}'),
        ],
        if (_presences.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Presences enregistrees (${_presences.length})',
              style: Theme.of(context).textTheme.titleSmall),
          for (final presence in _presences)
            if (presence is Map)
              Row(
                children: [
                  Expanded(
                    child: Text(
                        '${presence['etudiant']?['matricule'] ?? '-'} : ${presence['statut'] ?? '-'}'),
                  ),
                  IconButton(
                    tooltip: 'Corriger avec justification',
                    onPressed: _actionEnCours
                        ? null
                        : () => _demanderCorrection(
                            Map<String, dynamic>.from(presence)),
                    icon: const Icon(Icons.edit_note_rounded),
                  ),
                ],
              ),
        ],
      ]),
    );
  }

  Widget _resumePanel(BuildContext context) {
    final resume = _resume ?? const <String, dynamic>{};
    return SectionPanel(
      title: 'Resume apres fermeture',
      subtitle: 'Les absences manquantes ont ete generees sans doublon.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          Chip(label: Text('Presents : ${resume['presents'] ?? 0}')),
          Chip(label: Text('Retards : ${resume['retards'] ?? 0}')),
          Chip(label: Text('Absents : ${resume['absents'] ?? 0}')),
          Chip(label: Text('Refuses : ${resume['refuses'] ?? 0}')),
          Chip(
              label: Text(
                  'Nouvelles absences : ${resume['absences_creees'] ?? 0}')),
        ],
      ),
    );
  }

  Future<void> _demanderCorrection(Map<String, dynamic> presence) async {
    final seanceId = _asInt(_selection?['id']);
    final presenceId = _asInt(presence['id']);
    if (seanceId == null || presenceId == null) return;
    var nouveauStatut = '${presence['statut'] ?? 'present'}';
    final motifController = TextEditingController();
    final resultat = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Confirmer la correction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: nouveauStatut,
                items: const [
                  DropdownMenuItem(value: 'present', child: Text('Present')),
                  DropdownMenuItem(value: 'retard', child: Text('Retard')),
                  DropdownMenuItem(value: 'absent', child: Text('Absent')),
                  DropdownMenuItem(value: 'refuse', child: Text('Refuse')),
                ],
                onChanged: (value) => setDialogState(
                    () => nouveauStatut = value ?? nouveauStatut),
                decoration: const InputDecoration(labelText: 'Nouveau statut'),
              ),
              TextField(
                controller: motifController,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Motif obligatoire',
                    hintText: 'Justification de la correction'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler')),
            FilledButton(
              onPressed: () {
                if (motifController.text.trim().length < 3) return;
                Navigator.pop(dialogContext, {
                  'nouveau_statut': nouveauStatut,
                  'motif': motifController.text.trim(),
                });
              },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
    motifController.dispose();
    if (resultat == null) return;
    await _executer(() async {
      await _service.corrigerPresence(
        seanceId: seanceId,
        presenceId: presenceId,
        nouveauStatut: resultat['nouveau_statut']!,
        motif: resultat['motif']!,
      );
      await _chargerPresences(_selection!);
      _message('Correction enregistree avec sa justification.');
    });
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static int? _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value');
}
