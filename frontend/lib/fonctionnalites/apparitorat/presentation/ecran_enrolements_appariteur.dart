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
import '../../../donnees/services/service_session.dart';

class ApparitorEnrollmentsScreen extends StatefulWidget {
  const ApparitorEnrollmentsScreen({super.key});

  @override
  State<ApparitorEnrollmentsScreen> createState() =>
      _ApparitorEnrollmentsScreenState();
}

class _ApparitorEnrollmentsScreenState
    extends State<ApparitorEnrollmentsScreen> {
  final _service = AppariteurDataSource.service;
  final _rechercheController = TextEditingController();
  List<dynamic> _elements = const [];
  List<dynamic> _etudiants = const [];
  List<dynamic> _promotions = const [];
  Map<String, dynamic>? _detail;
  String? _statut;
  int? _promotionId;
  int? _anneeAcademiqueId;
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
    _rechercheController.dispose();
    super.dispose();
  }

  Future<void> _charger({bool chargerReferences = false}) async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final demandes = <Future<dynamic>>[
        _service.enrolements(
          recherche: _rechercheController.text,
          promotionId: _promotionId,
          anneeAcademiqueId: _anneeAcademiqueId,
          statut: _statut,
        ),
      ];
      if (chargerReferences || _promotions.isEmpty) {
        demandes.add(_service.promotions());
      }
      if (chargerReferences || _etudiants.isEmpty) {
        demandes.add(_service.etudiants());
      }
      final resultats = await Future.wait(demandes);
      if (!mounted) return;
      final donnees = resultats.first as Map<String, dynamic>;
      setState(() {
        _elements = donnees['elements'] as List<dynamic>? ?? const [];
        var index = 1;
        if (chargerReferences || _promotions.isEmpty) {
          _promotions = resultats[index++] as List<dynamic>;
        }
        if (chargerReferences || _etudiants.isEmpty) {
          _etudiants = resultats[index] as List<dynamic>;
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

  Future<void> _creer() async {
    final choix = await showDialog<_EnrollmentDraft>(
      context: context,
      builder: (context) => _EnrollmentDialog(
        etudiants: _etudiants,
        promotions: _promotions,
      ),
    );
    if (choix == null) return;
    setState(() => _actionEnCours = true);
    try {
      await _service.creerEnrolement(
        etudiantId: choix.etudiantId,
        promotionId: choix.promotionId,
        anneeAcademiqueId: choix.anneeAcademiqueId,
        dateEnrolement: choix.dateEnrolement,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enrolement cree avec succes.')),
      );
      await _charger();
    } catch (erreur) {
      if (!mounted) return;
      _afficherErreur(erreur);
    } finally {
      if (mounted) setState(() => _actionEnCours = false);
    }
  }

  Future<void> _ouvrirDetail(Map<String, dynamic> item) async {
    final id = _asInt(item['id']);
    if (id == null) return;
    setState(() => _actionEnCours = true);
    try {
      final detail = await _service.detailEnrolement(id);
      if (!mounted) return;
      setState(() => _detail = detail['id'] is int ? detail : detail);
    } catch (erreur) {
      if (mounted) _afficherErreur(erreur);
    } finally {
      if (mounted) setState(() => _actionEnCours = false);
    }
  }

  Future<void> _valider() async {
    final id = _asInt(_detail?['id']);
    if (id == null) return;
    await _executerAction(
      () => _service.validerEnrolement(id),
      'Enrolement valide.',
    );
  }

  Future<void> _annuler() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler l enrolement ?'),
        content: const Text(
          'L historique sera conserve et l enrolement ne sera plus actif.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Retour'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
    if (confirme != true) return;
    final id = _asInt(_detail?['id']);
    if (id == null) return;
    await _executerAction(
      () => _service.annulerEnrolement(id, motif: 'Annulation administrative'),
      'Enrolement annule.',
    );
  }

  Future<void> _executerAction(
    Future<Map<String, dynamic>> Function() action,
    String message,
  ) async {
    setState(() => _actionEnCours = true);
    try {
      final resultat = await action();
      if (!mounted) return;
      setState(() => _detail = resultat['id'] is int ? resultat : resultat);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      await _charger();
    } catch (erreur) {
      if (mounted) _afficherErreur(erreur);
    } finally {
      if (mounted) setState(() => _actionEnCours = false);
    }
  }

  void _afficherErreur(Object erreur) {
    final message = erreur is ApiException
        ? erreur.messagePourUtilisateur
        : 'L operation sur l enrolement a echoue.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.apparitor,
      selectedRoute: AppRoutes.apparitorEnrollments,
      title: 'Enrolements academiques',
      subtitle: 'Rattacher les etudiants a leur promotion et leur annee.',
      actions: [
        IconButton(
          onPressed:
              _chargement ? null : () => _charger(chargerReferences: true),
          tooltip: 'Actualiser les enrolements',
          icon: const Icon(Icons.refresh_rounded),
        ),
        FilledButton.icon(
          onPressed: _actionEnCours ? null : _creer,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nouvel enrolement'),
        ),
      ],
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_chargement) return const Center(child: CircularProgressIndicator());
    if (_erreur != null) {
      final message = _erreur is ApiException
          ? (_erreur! as ApiException).messagePourUtilisateur
          : 'Les enrolements ne peuvent pas etre charges.';
      return SectionPanel(
        title: 'Enrolements indisponibles',
        subtitle: 'Le serveur n a pas retourne la liste demandee.',
        child: Text(message),
      );
    }

    final annees = {
      for (final item in _promotions)
        if (item is Map && item['annee_academique_id'] is num)
          (item['annee_academique_id'] as num).toInt():
              '${item['annee_academique'] ?? item['annee_academique_id']}',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionPanel(
          title: 'Filtres',
          subtitle: 'Rechercher et suivre les statuts des enrôlements.',
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
                    labelText: 'Etudiant ou reference',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onSubmitted: (_) => _charger(),
                ),
              ),
              DropdownButton<int?>(
                value: _promotionId,
                hint: const Text('Toutes les promotions'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Toutes les promotions'),
                  ),
                  for (final item in _promotions)
                    if (item is Map && item['id'] is num)
                      DropdownMenuItem<int?>(
                        value: (item['id'] as num).toInt(),
                        child: Text('${item['nom'] ?? '-'}'),
                      ),
                ],
                onChanged: (value) {
                  setState(() => _promotionId = value);
                  _charger();
                },
              ),
              DropdownButton<int?>(
                value: _anneeAcademiqueId,
                hint: const Text('Toutes les annees'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Toutes les annees'),
                  ),
                  for (final entry in annees.entries)
                    DropdownMenuItem<int?>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                ],
                onChanged: (value) {
                  setState(() => _anneeAcademiqueId = value);
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
                      value: 'en_attente', child: Text('En attente')),
                  DropdownMenuItem<String?>(
                      value: 'valide', child: Text('Valide')),
                  DropdownMenuItem<String?>(
                      value: 'annule', child: Text('Annule')),
                ],
                onChanged: (value) {
                  setState(() => _statut = value);
                  _charger();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_elements.isEmpty)
          const SectionPanel(
            title: 'Aucun enrolement',
            subtitle: 'Modifiez les filtres ou creez un nouvel enrolement.',
            child: Text(
                'Aucun enrolement ne correspond aux criteres selectionnes.'),
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
          _detailPanel(context, _detail!),
        ],
      ],
    );
  }

  Widget _carte(Map<String, dynamic> item) {
    final etudiant = _map(item['etudiant']);
    final promotion = _map(item['promotion']);
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
                      '${etudiant['nom'] ?? '-'}',
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
              Text('Matricule: ${etudiant['matricule'] ?? '-'}'),
              Text('Promotion: ${promotion['nom'] ?? '-'}'),
              const SizedBox(height: 8),
              Text(
                '${item['reference_fiche'] ?? '-'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailPanel(BuildContext context, Map<String, dynamic> detail) {
    final etudiant = _map(detail['etudiant']);
    final promotion = _map(detail['promotion']);
    final annee = _map(detail['annee_academique']);
    final programme = detail['programme'] as List<dynamic>? ?? const [];
    final statut = '${detail['statut'] ?? ''}';
    return SectionPanel(
      title: 'Detail de l enrolement',
      subtitle: '${detail['reference_fiche'] ?? '-'}',
      trailing: StatusBadge(
        label: statut,
        color: _couleurStatut(statut),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 18,
            runSpacing: 12,
            children: [
              _info('Etudiant',
                  '${etudiant['nom'] ?? '-'} (${etudiant['matricule'] ?? '-'})'),
              _info('Promotion', '${promotion['nom'] ?? '-'}'),
              _info('Annee', '${annee['libelle'] ?? '-'}'),
              _info('Date', '${detail['date_enrolement'] ?? '-'}'),
              _info('Cours actifs',
                  '${detail['nombre_cours'] ?? programme.length}'),
              _info('Credits', '${detail['credits_prevus'] ?? '-'}'),
            ],
          ),
          if (programme.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Programme associe',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            for (final cours in programme)
              if (cours is Map)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.menu_book_rounded),
                  title: Text(
                      '${cours['code'] ?? '-'} - ${cours['intitule'] ?? '-'}'),
                  trailing: Text('${cours['credits'] ?? 0} cr.'),
                ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (statut == 'en_attente')
                FilledButton.icon(
                  onPressed: _actionEnCours ? null : _valider,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Valider'),
                ),
              if (statut != 'annule')
                OutlinedButton.icon(
                  onPressed: _actionEnCours ? null : _annuler,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Annuler'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) => SizedBox(
        width: 210,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(label),
          subtitle: Text(value),
        ),
      );

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static int? _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value');

  static Color _couleurStatut(String statut) {
    switch (statut) {
      case 'valide':
        return AppColors.success;
      case 'annule':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }
}

class _EnrollmentDraft {
  const _EnrollmentDraft({
    required this.etudiantId,
    required this.promotionId,
    required this.anneeAcademiqueId,
    required this.dateEnrolement,
  });

  final int etudiantId;
  final int promotionId;
  final int anneeAcademiqueId;
  final String dateEnrolement;
}

class _EnrollmentDialog extends StatefulWidget {
  const _EnrollmentDialog({required this.etudiants, required this.promotions});

  final List<dynamic> etudiants;
  final List<dynamic> promotions;

  @override
  State<_EnrollmentDialog> createState() => _EnrollmentDialogState();
}

class _EnrollmentDialogState extends State<_EnrollmentDialog> {
  int? _etudiantId;
  int? _promotionId;

  Map<String, dynamic>? get _promotion {
    for (final item in widget.promotions) {
      if (item is Map && item['id'] == _promotionId) {
        return Map<String, dynamic>.from(item);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvel enrolement'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Etudiant'),
              items: [
                for (final item in widget.etudiants)
                  if (item is Map && item['id'] is num)
                    DropdownMenuItem<int>(
                      value: (item['id'] as num).toInt(),
                      child: Text(
                          '${item['matricule'] ?? '-'} - ${item['nom'] ?? '-'}'),
                    ),
              ],
              onChanged: (value) => setState(() => _etudiantId = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Promotion'),
              items: [
                for (final item in widget.promotions)
                  if (item is Map && item['id'] is num)
                    DropdownMenuItem<int>(
                      value: (item['id'] as num).toInt(),
                      child: Text('${item['nom'] ?? '-'}'),
                    ),
              ],
              onChanged: (value) => setState(() => _promotionId = value),
            ),
            if (_promotion != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    'Annee: ${_promotion!['annee_academique'] ?? _promotion!['annee_academique_id'] ?? '-'}'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Retour'),
        ),
        FilledButton(
          onPressed: _etudiantId == null ||
                  _promotionId == null ||
                  _promotion == null
              ? null
              : () => Navigator.pop(
                    context,
                    _EnrollmentDraft(
                      etudiantId: _etudiantId!,
                      promotionId: _promotionId!,
                      anneeAcademiqueId:
                          (_promotion!['annee_academique_id'] as num).toInt(),
                      dateEnrolement:
                          DateTime.now().toIso8601String().split('T').first,
                    ),
                  ),
          child: const Text('Creer'),
        ),
      ],
    );
  }
}
