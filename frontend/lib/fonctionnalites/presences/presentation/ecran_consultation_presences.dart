import 'package:flutter/material.dart';

import '../../../commun/composants/panneau_section.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_api.dart';
import '../../../donnees/services/service_presences.dart';
import '../../../donnees/services/service_session.dart';

enum PresenceConsultationMode { etudiant, enseignant, chef }

class ConsultationPresencesScreen extends StatefulWidget {
  const ConsultationPresencesScreen({required this.mode, super.key});

  final PresenceConsultationMode mode;

  @override
  State<ConsultationPresencesScreen> createState() =>
      _ConsultationPresencesScreenState();
}

class _ConsultationPresencesScreenState
    extends State<ConsultationPresencesScreen> {
  final _service = PresencesDataSource.service;
  List<dynamic> _elements = const [];
  List<dynamic> _detail = const [];
  Map<String, dynamic> _resume = const {};
  String? _statut;
  Object? _erreur;
  bool _chargement = true;
  bool _chargementDetail = false;
  int? _selectionId;

  bool get _estEtudiant => widget.mode == PresenceConsultationMode.etudiant;
  bool get _estEnseignant => widget.mode == PresenceConsultationMode.enseignant;

  String get _titre {
    if (_estEtudiant) return 'Mes presences';
    if (_estEnseignant) return 'Presences de mes cours';
    return 'Presences de ma promotion';
  }

  String get _route {
    if (_estEtudiant) return AppRoutes.studentAttendance;
    if (_estEnseignant) return AppRoutes.teacherAttendance;
    return AppRoutes.promotionChiefAttendance;
  }

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      if (_estEtudiant) {
        final donnees = await _service.presencesEtudiant(statut: _statut);
        _elements = donnees['elements'] as List<dynamic>? ?? const [];
        _resume = _map(donnees['resume']);
        _detail = const [];
      } else {
        _elements = _estEnseignant
            ? await _service.seancesEnseignant()
            : await _service.seancesPromotion();
        _detail = const [];
        _resume = const {};
      }
      if (!mounted) return;
      setState(() => _chargement = false);
    } catch (erreur) {
      if (!mounted) return;
      setState(() {
        _erreur = erreur;
        _chargement = false;
      });
    }
  }

  Future<void> _ouvrirDetail(Map<String, dynamic> element) async {
    final id = _asInt(element['id']);
    if (id == null) return;
    setState(() {
      _selectionId = id;
      _chargementDetail = true;
      _erreur = null;
    });
    try {
      _detail = _estEnseignant
          ? await _service.presencesSeanceEnseignant(id)
          : await _service.presencesPromotion(id);
      if (!mounted) return;
      setState(() => _chargementDetail = false);
    } catch (erreur) {
      if (!mounted) return;
      setState(() {
        _erreur = erreur;
        _chargementDetail = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: SessionService.currentRole,
      selectedRoute: _route,
      title: _titre,
      subtitle: _estEtudiant
          ? 'Historique personnel calcule par le backend.'
          : 'Consultation limitee a votre perimetre academique.',
      actions: [
        IconButton(
          onPressed: _charger,
          tooltip: 'Actualiser',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (_chargement) return const Center(child: CircularProgressIndicator());
    if (_erreur != null && _elements.isEmpty) {
      return SectionPanel(
        title: 'Presences indisponibles',
        subtitle: 'Le serveur n a pas retourne les donnees demandees.',
        child: Text(_messageErreur(_erreur)),
      );
    }
    if (_estEtudiant) return _bodyEtudiant(context);
    return _bodyGestionnaire(context);
  }

  Widget _bodyEtudiant(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _resumePanel(context),
        const SizedBox(height: 16),
        SectionPanel(
          title: 'Filtrer par statut',
          subtitle: 'Le taux officiel reste calcule par le backend.',
          child: DropdownButton<String?>(
            value: _statut,
            isExpanded: true,
            items: const [
              DropdownMenuItem<String?>(
                  value: null, child: Text('Tous les statuts')),
              DropdownMenuItem(value: 'present', child: Text('Present')),
              DropdownMenuItem(value: 'retard', child: Text('Retard')),
              DropdownMenuItem(value: 'absent', child: Text('Absent')),
              DropdownMenuItem(value: 'refuse', child: Text('Refus d acces')),
            ],
            onChanged: (value) {
              setState(() => _statut = value);
              _charger();
            },
          ),
        ),
        const SizedBox(height: 16),
        if (_elements.isEmpty)
          const SectionPanel(
            title: 'Aucune presence',
            subtitle: 'Aucun enregistrement ne correspond au filtre.',
            child: Text('Votre historique de presence est vide.'),
          )
        else
          for (final item in _elements)
            if (item is Map<String, dynamic>) ...[
              _presenceCard(context, item),
              const SizedBox(height: 10),
            ],
      ],
    );
  }

  Widget _bodyGestionnaire(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_elements.isEmpty)
          const SectionPanel(
            title: 'Aucune seance',
            subtitle: 'Votre perimetre ne contient aucune seance.',
            child: Text(
                'Les presences apparaitront apres la creation d une seance.'),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in _elements)
                if (item is Map<String, dynamic>) _seanceCard(context, item),
            ],
          ),
        if (_chargementDetail) ...[
          const SizedBox(height: 18),
          const Center(child: CircularProgressIndicator()),
        ],
        if (_detail.isNotEmpty) ...[
          const SizedBox(height: 18),
          SectionPanel(
            title: 'Detail de la seance',
            subtitle: 'Les informations financieres ne sont pas affichees.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in _detail)
                  if (item is Map<String, dynamic>)
                    ListTile(
                      leading: const Icon(Icons.person_outline_rounded),
                      title: Text('${_map(item['etudiant'])['nom'] ?? '-'}'),
                      subtitle:
                          Text('${_map(item['etudiant'])['matricule'] ?? '-'}'),
                      trailing: Text('${item['statut'] ?? '-'}'),
                    ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _resumePanel(BuildContext context) {
    return SectionPanel(
      title: 'Resume',
      subtitle: 'Synthese de vos enregistrements.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _chip('Seances', _resume['total_enregistrements']),
          _chip('Presents', _resume['presents']),
          _chip('Retards', _resume['retards']),
          _chip('Absences', _resume['absents']),
          _chip('Refus', _resume['refuses']),
          _chip('Taux', '${_resume['taux_presence'] ?? 0}%'),
        ],
      ),
    );
  }

  Widget _seanceCard(BuildContext context, Map<String, dynamic> item) {
    final cours = _map(item['cours']);
    final resume = _map(item['resume']);
    return SizedBox(
      width: 360,
      child: Card(
        child: InkWell(
          onTap: () => _ouvrirDetail(item),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${cours['code'] ?? 'Cours'} - ${cours['intitule'] ?? ''}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                    '${item['date_seance'] ?? '-'} | ${item['type_cours'] ?? '-'} | ${item['statut'] ?? '-'}'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: [
                    _chip('P', resume['presents']),
                    _chip('R', resume['retards']),
                    _chip('A', resume['absents']),
                    _chip('X', resume['refuses']),
                  ],
                ),
                if (_selectionId == item['id'])
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Detail selectionne'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _presenceCard(BuildContext context, Map<String, dynamic> item) {
    final seance = _map(item['seance']);
    final cours = _map(seance['cours']);
    final correction = _map(item['correction']);
    return Card(
      child: ListTile(
        leading: Icon(_iconeStatut(item['statut'])),
        title: Text('${cours['code'] ?? 'Cours'} - ${item['statut'] ?? '-'}'),
        subtitle: Text(
            '${seance['date_seance'] ?? '-'} | ${seance['heure_debut'] ?? '-'} - ${seance['heure_fin'] ?? '-'}\n${item['methode_identification'] ?? '-'}'),
        isThreeLine: true,
        trailing:
            correction.isEmpty ? null : const Icon(Icons.edit_note_rounded),
      ),
    );
  }

  Widget _chip(String label, dynamic value) =>
      Chip(label: Text('$label: ${value ?? 0}'));

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static int? _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value');

  static IconData _iconeStatut(dynamic statut) {
    switch (statut) {
      case 'present':
        return Icons.check_circle_outline_rounded;
      case 'retard':
        return Icons.schedule_rounded;
      case 'absent':
        return Icons.cancel_outlined;
      default:
        return Icons.block_outlined;
    }
  }

  static String _messageErreur(Object? erreur) {
    if (erreur is ApiException) return erreur.messagePourUtilisateur;
    return 'Les presences ne peuvent pas etre chargees.';
  }
}
