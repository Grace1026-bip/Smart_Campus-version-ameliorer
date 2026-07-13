import 'package:flutter/material.dart';

import '../../../commun/composants/badge_statut.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_notes.dart';
import '../../../donnees/services/service_session.dart';

class DeliberationScreen extends StatefulWidget {
  const DeliberationScreen({super.key});

  @override
  State<DeliberationScreen> createState() => _DeliberationScreenState();
}

class _DeliberationScreenState extends State<DeliberationScreen> {
  final _service = NotesDataSource.service;
  final _promotion = TextEditingController();
  final _annee = TextEditingController();
  final _semestre = TextEditingController();
  final _membre = TextEditingController();
  final _motif = TextEditingController();
  List<dynamic> _sessions = const [];
  Map<String, dynamic>? _session;
  Map<String, dynamic>? _grille;
  Object? _erreur;
  bool _chargement = true;

  UserRole get _role => SessionService.currentRole;
  bool get _organisation =>
      _role == UserRole.dean || _role == UserRole.viceDean;
  bool get _appariteur => _role == UserRole.apparitor;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _promotion.dispose();
    _annee.dispose();
    _semestre.dispose();
    _membre.dispose();
    _motif.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      _sessions = await _service.deliberations();
      if (_sessions.isNotEmpty) await _selectionner(_sessions.first as Map);
    } catch (erreur) {
      _erreur = erreur;
    }
    if (mounted) setState(() => _chargement = false);
  }

  Future<void> _selectionner(Map session) async {
    final id = _asInt(session['id']);
    if (id == null) return;
    try {
      final grille = await _service.deliberationGrille(id);
      if (mounted) {
        setState(() {
          _session = Map<String, dynamic>.from(session);
          _grille = grille;
        });
      }
    } catch (erreur) {
      if (mounted) setState(() => _erreur = erreur);
    }
  }

  Future<void> _creer() async {
    try {
      final session = await _service.creerDeliberation(
        promotionId: int.parse(_promotion.text),
        anneeAcademiqueId: int.parse(_annee.text),
        semestreId: int.parse(_semestre.text),
      );
      await _charger();
      if (mounted) setState(() => _session = session);
    } catch (erreur) {
      if (mounted) setState(() => _erreur = erreur);
    }
  }

  Future<void> _action(
      Future<Map<String, dynamic>> Function(int) operation) async {
    final id = _asInt(_session?['id']);
    if (id == null) return;
    try {
      await operation(id);
      await _charger();
    } catch (erreur) {
      if (mounted) setState(() => _erreur = erreur);
    }
  }

  Future<void> _ajouterPresident() async {
    final sessionId = _asInt(_session?['id']);
    final membreId = int.tryParse(_membre.text);
    if (sessionId == null || membreId == null) return;
    try {
      await _service.ajouterMembreDeliberation(
        sessionId: sessionId,
        utilisateurId: membreId,
        qualite: 'president',
      );
      await _charger();
    } catch (erreur) {
      if (mounted) setState(() => _erreur = erreur);
    }
  }

  Future<void> _enregistrerDecision(int etudiantId, String decision) async {
    final sessionId = _asInt(_session?['id']);
    if (sessionId == null) return;
    try {
      await _service.enregistrerDecisionDeliberation(
        sessionId: sessionId,
        etudiantId: etudiantId,
        decision: decision,
      );
      await _charger();
    } catch (erreur) {
      if (mounted) setState(() => _erreur = erreur);
    }
  }

  Future<void> _reouvrir() async {
    final sessionId = _asInt(_session?['id']);
    if (sessionId == null || _motif.text.trim().isEmpty) return;
    try {
      await _service.demanderReouvertureDeliberation(
        sessionId: sessionId,
        motif: _motif.text.trim(),
      );
      await _charger();
    } catch (erreur) {
      if (mounted) setState(() => _erreur = erreur);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: _role,
      selectedRoute: AppRoutes.deliberations,
      title: 'Deliberation LMD',
      subtitle: _appariteur
          ? 'Preparation et publication apres cloture du jury.'
          : 'Sessions, grille et decisions du jury.',
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_chargement) return const Center(child: CircularProgressIndicator());
    if (_erreur != null) {
      return SectionPanel(
          title: 'Deliberation indisponible',
          subtitle: 'Le backend a refuse ou interrompu l operation.',
          child: Text('$_erreur'));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_organisation) _creationPanel(),
      _sessionsPanel(),
      if (_grille != null) _grillePanel(context),
    ]);
  }

  Widget _creationPanel() => SectionPanel(
        title: 'Creer une session',
        subtitle: 'Les identifiants sont verifies par le backend.',
        child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              _idField(_promotion, 'Promotion'),
              _idField(_annee, 'Annee'),
              _idField(_semestre, 'Semestre'),
              FilledButton.icon(
                  onPressed: _creer,
                  icon: const Icon(Icons.add),
                  label: const Text('Creer')),
            ]),
      );

  Widget _idField(TextEditingController controller, String label) => SizedBox(
      width: 150,
      child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label)));

  Widget _sessionsPanel() => SectionPanel(
        title: 'Sessions de deliberation',
        subtitle: 'Une session ouverte est traitee par son jury affecte.',
        child: DropdownButtonFormField<int>(
          initialValue: _asInt(_session?['id']),
          items: [
            for (final item in _sessions)
              if (item is Map)
                DropdownMenuItem(
                    value: _asInt(item['id']),
                    child: Text('Session ${item['id']} - ${item['statut']}'))
          ],
          onChanged: (id) {
            final item = _sessions.whereType<Map>().firstWhere(
                (value) => _asInt(value['id']) == id,
                orElse: () => <String, dynamic>{});
            _selectionner(item);
          },
          decoration: const InputDecoration(labelText: 'Session'),
        ),
      );

  Widget _grillePanel(BuildContext context) {
    final session = _session ?? const <String, dynamic>{};
    final etudiants = (_grille?['etudiants'] as List<dynamic>? ?? const []);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 16),
      SectionPanel(
          title: 'Etat du jury',
          subtitle: 'La decision finale reste liee a la session.',
          child: Wrap(spacing: 10, runSpacing: 10, children: [
            StatusBadge(
                label: '${session['statut'] ?? '-'}',
                color: Theme.of(context).colorScheme.primary),
            if (_organisation && session['statut'] == 'preparation')
              SizedBox(
                  width: 150,
                  child: TextField(
                      controller: _membre,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'ID president'))),
            if (_organisation && session['statut'] == 'preparation')
              FilledButton.icon(
                  onPressed: _ajouterPresident,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Designer')),
            if (_organisation && session['statut'] == 'preparation')
              FilledButton.icon(
                  onPressed: () => _action(_service.ouvrirDeliberation),
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Ouvrir')),
            if (_role == UserRole.teacher && session['statut'] == 'ouverte')
              FilledButton.icon(
                  onPressed: () => _action(_service.cloturerDeliberation),
                  icon: const Icon(Icons.lock),
                  label: const Text('Cloturer')),
            if (_appariteur && session['statut'] == 'cloturee')
              FilledButton.icon(
                  onPressed: () => _action(_service.publierDeliberation),
                  icon: const Icon(Icons.publish),
                  label: const Text('Publier')),
            if (_organisation &&
                (session['statut'] == 'cloturee' ||
                    session['statut'] == 'publiee'))
              SizedBox(
                  width: 260,
                  child: TextField(
                      controller: _motif,
                      decoration: const InputDecoration(
                          labelText: 'Motif de reouverture'))),
            if (_organisation &&
                (session['statut'] == 'cloturee' ||
                    session['statut'] == 'publiee'))
              FilledButton.icon(
                  onPressed: _reouvrir,
                  icon: const Icon(Icons.replay),
                  label: const Text('Nouvelle version')),
          ])),
      for (final item in etudiants)
        if (item is Map) _ligneEtudiant(context, item),
    ]);
  }

  Widget _ligneEtudiant(BuildContext context, Map item) {
    final etudiantId = _asInt(item['etudiant']?['id']);
    final decision =
        '${item['decision_enregistree'] ?? item['proposition_decision'] ?? 'DEF'}';
    return Card(
        child: ListTile(
            title: Text(
                '${item['etudiant']?['matricule'] ?? '-'} - ${item['etudiant']?['nom'] ?? '-'}'),
            subtitle: Text(
                'Moyenne: ${item['moyenne_ponderee_sur_20'] ?? '-'} /20 | Credits: ${item['credits_capitalises'] ?? 0}/${item['credits_prevus'] ?? 0}'),
            trailing: _role == UserRole.teacher &&
                    _session?['statut'] == 'ouverte' &&
                    etudiantId != null
                ? DropdownButton<String>(
                    value: decision,
                    items: const [
                      DropdownMenuItem(value: 'ADM', child: Text('ADM')),
                      DropdownMenuItem(value: 'COMP', child: Text('COMP')),
                      DropdownMenuItem(value: 'DEF', child: Text('DEF')),
                      DropdownMenuItem(value: 'AJ', child: Text('AJ')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _enregistrerDecision(etudiantId, value);
                      }
                    })
                : StatusBadge(
                    label: decision,
                    color: Theme.of(context).colorScheme.primary)));
  }

  static int? _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value');
}
