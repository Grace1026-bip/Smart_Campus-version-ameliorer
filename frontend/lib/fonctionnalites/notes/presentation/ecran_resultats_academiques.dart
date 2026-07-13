import 'package:flutter/material.dart';

import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/badge_statut.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_notes.dart';
import '../../../donnees/services/service_session.dart';

class AcademicResultsScreen extends StatefulWidget {
  const AcademicResultsScreen({super.key});

  @override
  State<AcademicResultsScreen> createState() => _AcademicResultsScreenState();
}

class _AcademicResultsScreenState extends State<AcademicResultsScreen> {
  final _service = NotesDataSource.service;
  List<dynamic> _etudiants = const [];
  List<dynamic> _semestres = const [];
  int? _etudiantId;
  int? _semestreId;
  Map<String, dynamic>? _apercu;
  Map<String, dynamic>? _officiel;
  Object? _erreur;
  bool _chargement = true;

  bool get _estEtudiant => SessionService.currentRole == UserRole.student;

  @override
  void initState() {
    super.initState();
    _chargerPointDeDepart();
  }

  Future<void> _chargerPointDeDepart() async {
    try {
      if (_estEtudiant) {
        _semestres = await _service.semestresEtudiant();
      } else {
        _etudiants = await _service.etudiantsResultats();
        if (_etudiants.isNotEmpty) {
          _etudiantId = _asInt((_etudiants.first as Map)['id']);
          _semestres = await _service.semestresResultats(_etudiantId!);
        }
      }
      if (_semestres.isNotEmpty) {
        _semestreId = _asInt((_semestres.first as Map)['id']);
        await _chargerApercu();
      }
    } catch (erreur) {
      _erreur = erreur;
    }
    if (mounted) setState(() => _chargement = false);
  }

  Future<void> _chargerApercu() async {
    if (_semestreId == null) return;
    final apercu = _estEtudiant
        ? await _service.apercuSemestreEtudiant(_semestreId!)
        : await _service.apercuSemestre(
            etudiantId: _etudiantId!, semestreId: _semestreId!);
    Map<String, dynamic>? officiel;
    if (_estEtudiant) {
      try {
        officiel =
            await _service.resultatOfficielSemestreEtudiant(_semestreId!);
      } catch (_) {
        officiel = null;
      }
    }
    if (mounted) {
      setState(() {
        _apercu = apercu;
        _officiel = officiel;
      });
    }
  }

  Future<void> _changerEtudiant(int? id) async {
    if (id == null) return;
    setState(() {
      _etudiantId = id;
      _semestreId = null;
      _apercu = null;
      _officiel = null;
      _chargement = true;
    });
    try {
      _semestres = await _service.semestresResultats(id);
      if (_semestres.isNotEmpty) {
        _semestreId = _asInt((_semestres.first as Map)['id']);
        await _chargerApercu();
      }
    } catch (erreur) {
      _erreur = erreur;
    }
    if (mounted) setState(() => _chargement = false);
  }

  Future<void> _changerSemestre(int? id) async {
    if (id == null) return;
    setState(() {
      _semestreId = id;
      _apercu = null;
      _officiel = null;
      _chargement = true;
    });
    try {
      await _chargerApercu();
    } catch (erreur) {
      _erreur = erreur;
    }
    if (mounted) setState(() => _chargement = false);
  }

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: SessionService.currentRole,
      selectedRoute: AppRoutes.grades,
      title:
          _estEtudiant ? 'Mes resultats semestriels' : 'Resultats semestriels',
      subtitle: _estEtudiant
          ? 'Resultats publies, credits et etat provisoire.'
          : 'Apercu academique securise pour les responsables autorises.',
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_chargement && _apercu == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erreur != null) {
      return SectionPanel(
        title: 'Apercu indisponible',
        subtitle: _erreur.toString(),
        child: const Text(
            'Les resultats academiques ne peuvent pas etre charges.'),
      );
    }
    if (!_estEtudiant && _etudiants.isEmpty) {
      return const SectionPanel(
        title: 'Aucun etudiant actif',
        subtitle: 'Aucun apercu semestriel n est disponible.',
        child: SizedBox.shrink(),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_estEtudiant) _selecteurEtudiant(),
        _selecteurSemestre(),
        const SizedBox(height: 18),
        if (_apercu == null)
          const SectionPanel(
            title: 'Aucun semestre selectionne',
            subtitle: 'Aucune donnee academique a afficher.',
            child: SizedBox.shrink(),
          )
        else
          Column(children: [
            if (_estEtudiant &&
                ((_officiel?['resultats'] as List<dynamic>?)?.isEmpty ?? true))
              const SectionPanel(
                  title: 'Resultat en attente de deliberation',
                  subtitle: 'Ce resultat n est pas encore officiel.',
                  child: SizedBox.shrink()),
            if (_estEtudiant &&
                ((_officiel?['resultats'] as List<dynamic>?)?.isNotEmpty ??
                    false))
              _panneauOfficiel(
                  context,
                  (_officiel!['resultats'] as List<dynamic>).first
                      as Map<String, dynamic>),
            _panneauApercu(context, _apercu!),
          ]),
      ],
    );
  }

  Widget _selecteurEtudiant() {
    return SectionPanel(
      title: 'Etudiant concerne',
      subtitle: 'Le backend controle le perimetre academique.',
      child: DropdownButtonFormField<int>(
        initialValue: _etudiantId,
        items: [
          for (final item in _etudiants)
            if (item is Map)
              DropdownMenuItem<int>(
                value: _asInt(item['id']),
                child:
                    Text('${item['matricule'] ?? '-'} - ${item['nom'] ?? '-'}'),
              ),
        ],
        onChanged: _changerEtudiant,
        decoration: const InputDecoration(labelText: 'Etudiant'),
      ),
    );
  }

  Widget _selecteurSemestre() {
    return SectionPanel(
      title: 'Periode academique',
      subtitle: 'Les donnees sont calculees pour l annee active.',
      child: DropdownButtonFormField<int>(
        initialValue: _semestreId,
        items: [
          for (final item in _semestres)
            if (item is Map)
              DropdownMenuItem<int>(
                value: _asInt(item['id']),
                child: Text(
                    '${item['nom'] ?? '-'} - ${(item['annee_academique'] as Map?)?['libelle'] ?? '-'}'),
              ),
        ],
        onChanged: _changerSemestre,
        decoration: const InputDecoration(labelText: 'Semestre'),
      ),
    );
  }

  Widget _panneauApercu(BuildContext context, Map<String, dynamic> apercu) {
    final cours = apercu['cours'] as List<dynamic>? ?? const [];
    final etudiant = apercu['etudiant'] as Map?;
    final semestre = apercu['semestre'] as Map?;
    final provisoire = apercu['etat'] == 'provisoire';
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionPanel(
          title: '${etudiant?['nom'] ?? '-'} - ${semestre?['nom'] ?? '-'}',
          subtitle:
              '${apercu['annee_academique']?['libelle'] ?? '-'} | ${apercu['mention'] ?? ''}',
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              StatusBadge(
                label: provisoire ? 'Provisoire' : 'Incomplet',
                color: provisoire
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
              Chip(
                  label: Text(
                      'Moyenne: ${_format(apercu['moyenne_semestre_sur_20'] ?? apercu['moyenne_semestre_sur_100'])}/${apercu['moyenne_semestre_sur_20'] != null ? '20' : '100'}')),
              Chip(
                  label: Text(
                      'Credits: ${apercu['credits_acquis'] ?? 0}/${apercu['credits_prevus'] ?? 0}')),
              Chip(label: Text('Restants: ${apercu['credits_restants'] ?? 0}')),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final item in cours)
          if (item is Map) _carteCours(context, item),
        if ((apercu['raisons_incompletude'] as List<dynamic>? ?? const [])
            .isNotEmpty)
          SectionPanel(
            title: 'Blocages',
            subtitle: 'Le semestre ne peut pas etre considere comme complet.',
            child: Text(
                (apercu['raisons_incompletude'] as List<dynamic>).join(', ')),
          ),
      ],
    );
  }

  Widget _panneauOfficiel(BuildContext context, Map<String, dynamic> officiel) {
    return SectionPanel(
      title: 'Resultat officiel publie',
      subtitle: 'Publication du ${officiel['date_publication'] ?? '-'}',
      child: Wrap(spacing: 10, runSpacing: 8, children: [
        StatusBadge(
            label: '${officiel['decision'] ?? '-'}',
            color: Theme.of(context).colorScheme.primary),
        Chip(
            label: Text(
                'Moyenne: ${_format(officiel['moyenne_ponderee_sur_20'])}/20')),
        Chip(
            label: Text(
                'Credits capitalises: ${officiel['credits_capitalises'] ?? 0}')),
        Chip(
            label: Text(
                'Credits non capitalises: ${officiel['credits_non_capitalises'] ?? 0}')),
      ]),
    );
  }

  Widget _carteCours(BuildContext context, Map item) {
    final status = '${item['statut_validation'] ?? 'en_attente'}';
    final acquis = status == 'acquis';
    return Card(
      child: ListTile(
        title: Text('${item['code'] ?? '-'} - ${item['intitule'] ?? '-'}'),
        subtitle: Text(
          'Resultat: ${_format(item['resultat_publie_sur_100'])}/100 | Credits: ${item['credits_acquis'] ?? 0}/${item['credits_prevus'] ?? 0}',
        ),
        trailing: StatusBadge(
          label: acquis
              ? 'Acquis'
              : status == 'non_acquis'
                  ? 'Non acquis'
                  : 'En attente',
          color: acquis
              ? Theme.of(context).colorScheme.primary
              : status == 'non_acquis'
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  static int? _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value');

  static String _format(dynamic value) {
    if (value == null) return '-';
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    return number == null ? '-' : number.toStringAsFixed(2);
  }
}
