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

class _ProfilBiometriqueResume extends StatelessWidget {
  const _ProfilBiometriqueResume({required this.profil});

  final Map<String, dynamic> profil;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        Text('Statut : ${profil['statut'] ?? 'inconnu'}'),
        Text('Encodages : ${profil['nombre_encodages'] ?? 0}'),
        Text('Date d enrolement : ${profil['date_creation'] ?? '-'}'),
      ],
    );
  }
}

class ActionsEnrolementBiometrique extends StatelessWidget {
  const ActionsEnrolementBiometrique({
    super.key,
    required this.nombreCaptures,
    required this.consentement,
    required this.envoiEnCours,
    required this.onEnregistrer,
    this.onRecommencer,
  });

  final int nombreCaptures;
  final bool consentement;
  final bool envoiEnCours;
  final VoidCallback onEnregistrer;
  final VoidCallback? onRecommencer;

  @override
  Widget build(BuildContext context) {
    final pret = nombreCaptures >= 3 && nombreCaptures <= 5;
    final peutEnregistrer = pret && consentement && !envoiEnCours;
    final indication = envoiEnCours
        ? 'Envoi des captures en cours...'
        : nombreCaptures < 3
            ? 'Encore ${3 - nombreCaptures} capture(s) necessaire(s).'
            : !consentement
                ? 'Confirmez le consentement avant l enregistrement.'
                : 'Pret a enregistrer le profil.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Captures temporaires : $nombreCaptures/5'),
        const SizedBox(height: 6),
        Text(indication),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: peutEnregistrer ? onEnregistrer : null,
          icon: Icon(envoiEnCours ? Icons.hourglass_top : Icons.save_rounded),
          label: Text(
            envoiEnCours
                ? 'Enregistrement en cours...'
                : 'Enregistrer le profil biométrique',
          ),
        ),
        if (onRecommencer != null)
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: envoiEnCours ? null : onRecommencer,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Effacer les captures'),
            ),
          ),
      ],
    );
  }
}

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
  List<XFile> _captures = const [];
  int _cameraVersion = 0;
  int? _etudiantId;
  Object? _erreur;
  String? _messageSucces;
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
      _captures = const [];
      _cameraVersion++;
      _erreur = null;
      _messageSucces = null;
      _consentement = false;
    });
    if (id == null) return;
    try {
      final profil = await _biometrie.profilEtudiant(id);
      if (mounted) setState(() => _profil = _profilActif(profil));
    } on ApiException catch (erreur) {
      if (mounted && erreur.statusCode != 404) setState(() => _erreur = erreur);
    }
  }

  void _capturesChangees(List<XFile> images) {
    if (_actionEnCours) return;
    setState(() {
      _captures = List.unmodifiable(images);
      _erreur = null;
      _messageSucces = null;
    });
  }

  void _effacerCaptures() {
    if (_actionEnCours) return;
    setState(() {
      _captures = const [];
      _erreur = null;
      _messageSucces = null;
      _cameraVersion++;
    });
  }

  Future<void> _enregistrer() async {
    final id = _etudiantId;
    if (id == null) return;
    if (_actionEnCours || _captures.length < 3 || _captures.length > 5) return;
    if (!_consentement) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le consentement doit etre confirme avant l enregistrement.')),
      );
      return;
    }
    setState(() {
      _actionEnCours = true;
      _erreur = null;
      _messageSucces = null;
    });
    try {
      final resultat = await _biometrie.enroler(
        etudiantId: id,
        images: _captures,
        consentement: true,
      );
      final profilActualise = await _biometrie.profilEtudiant(id);
      if (!mounted) return;
      setState(() {
        _profil = _profilActif(profilActualise.isEmpty ? resultat : profilActualise);
        _captures = const [];
        _cameraVersion++;
        _messageSucces = 'Profil biometrique enregistre avec succes.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil biometrique enregistre avec succes.')));
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
          if (_messageSucces != null)
            SectionPanel(
              title: 'Profil enregistre',
              child: Text(_messageSucces!),
            ),
          if (_erreur != null) ...[
            const SizedBox(height: 12),
            SectionPanel(
              title: 'Enregistrement impossible',
              child: Text(_message(_erreur!)),
            ),
          ],
          if (_messageSucces != null || _erreur != null)
            const SizedBox(height: 16),
          SectionPanel(
            title: 'Etat du profil',
            child: _profil == null
                ? const Text(
                    'Aucun profil actif connu. Une nouvelle capture peut etre lancee.',
                  )
                : _ProfilBiometriqueResume(profil: _profil!),
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
                CaptureCameraPartagee(
                  key: ValueKey(_cameraVersion),
                  onCapturesChangees: _capturesChangees,
                ),
                const SizedBox(height: 12),
                ActionsEnrolementBiometrique(
                  nombreCaptures: _captures.length,
                  consentement: _consentement,
                  envoiEnCours: _actionEnCours,
                  onEnregistrer: _enregistrer,
                  onRecommencer: _captures.isEmpty ? null : _effacerCaptures,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Map<String, dynamic> _profilActif(Map<String, dynamic> donnees) {
    final profils = donnees['profils'];
    if (profils is List && profils.isNotEmpty && profils.first is Map) {
      return Map<String, dynamic>.from(profils.first as Map);
    }
    return donnees;
  }

  String _message(Object erreur) => erreur is ApiException
      ? erreur.messagePourUtilisateur
      : 'Le service biométrique est indisponible.';
}
