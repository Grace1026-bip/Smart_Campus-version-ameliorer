import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../commun/composants/capture_camera_partagee.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_api.dart';
import '../../../donnees/services/service_appariteur.dart';
import '../../../donnees/services/service_biometrie.dart';

class EcranBiometrieAppariteur extends StatefulWidget {
  const EcranBiometrieAppariteur({super.key});

  @override
  State<EcranBiometrieAppariteur> createState() =>
      _EcranBiometrieAppariteurState();
}

class _EcranBiometrieAppariteurState extends State<EcranBiometrieAppariteur> {
  final _appariteur = AppariteurDataSource.service;
  final _biometrie = BiometrieDataSource.service;
  List<dynamic> _etudiants = const [];
  Map<String, dynamic>? _profil;
  int? _etudiantId;
  Object? _erreur;
  bool _chargement = true;
  bool _actionEnCours = false;
  bool _consentement = false;

  @override
  void initState() {
    super.initState();
    _chargerEtudiants();
  }

  Future<void> _chargerEtudiants() async {
    try {
      final etudiants = await _appariteur.etudiants();
      if (!mounted) return;
      setState(() {
        _etudiants = etudiants;
        _chargement = false;
      });
    } catch (erreur) {
      if (mounted) {
        setState(() {
          _erreur = erreur;
          _chargement = false;
        });
      }
    }
  }

  Future<void> _selectionner(int? id) async {
    setState(() {
      _etudiantId = id;
      _profil = null;
      _erreur = null;
    });
    if (id == null) return;
    try {
      final profil = await _biometrie.profilEtudiant(id);
      if (mounted) setState(() => _profil = profil);
    } on ApiException catch (erreur) {
      if (mounted && erreur.statusCode != 404) setState(() => _erreur = erreur);
    }
  }

  Future<void> _enregistrer(List<XFile> images) async {
    final id = _etudiantId;
    if (id == null) return;
    if (!_consentement) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le consentement doit etre confirme avant l enregistrement.')),
      );
      return;
    }
    setState(() {
      _actionEnCours = true;
      _erreur = null;
    });
    try {
      final resultat = await _biometrie.enroler(
        etudiantId: id,
        images: images,
        consentement: true,
      );
      if (!mounted) return;
      setState(() => _profil = resultat);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil biometrique enregistre.')));
    } catch (erreur) {
      if (mounted) setState(() => _erreur = erreur);
    } finally {
      if (mounted) setState(() => _actionEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.apparitor,
      selectedRoute: AppRoutes.apparitorBiometrics,
      title: 'Enrolement biometrique',
      subtitle: 'Captures gerees par Flutter et traitees par FastAPI.',
      actions: [
        IconButton(
            onPressed: _chargerEtudiants,
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh_rounded))
      ],
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_chargement) return const Center(child: CircularProgressIndicator());
    if (_erreur != null && _etudiants.isEmpty) {
      return SectionPanel(
          title: 'Biometrie indisponible', child: Text(_message(_erreur!)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionPanel(
          title: 'Etudiant concerne',
          subtitle:
              'Seul un appariteur authentifie peut lancer cet enrôlement.',
          child: DropdownButtonFormField<int>(
            initialValue: _etudiantId,
            isExpanded: true,
            decoration:
                const InputDecoration(labelText: 'Selectionner un etudiant'),
            items: [
              for (final item in _etudiants)
                if (item is Map && item['id'] is num)
                  DropdownMenuItem<int>(
                      value: (item['id'] as num).toInt(),
                      child: Text(
                          '${item['matricule'] ?? item['id']} - ${item['nom'] ?? ''}')),
            ],
            onChanged: _actionEnCours ? null : _selectionner,
          ),
        ),
        if (_etudiantId != null) ...[
          const SizedBox(height: 16),
          SectionPanel(
            title: 'Etat du profil',
            child: Text(_profil == null
                ? 'Aucun profil actif connu. Une nouvelle capture peut etre lancee.'
                : 'Profil ${_profil!['statut'] ?? 'inconnu'} - ${_profil!['nombre_encodages'] ?? 0} encodages.'),
          ),
          const SizedBox(height: 16),
          SectionPanel(
            title: 'Captures',
            subtitle:
                'Le consentement est confirme par l appariteur avec l action administrative.',
            child: Column(
              children: [
                CheckboxListTile(
                  value: _consentement,
                  onChanged: _actionEnCours ? null : (value) => setState(() => _consentement = value ?? false),
                  title: const Text('Consentement biometrique confirme'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CaptureCameraPartagee(onCapturesTerminees: _enregistrer),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _message(Object erreur) => erreur is ApiException
      ? erreur.messagePourUtilisateur
      : 'Le service biométrique est indisponible.';
}
