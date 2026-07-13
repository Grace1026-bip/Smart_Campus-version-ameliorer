import 'package:flutter/material.dart';

import '../../../commun/composants/badge_statut.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../donnees/services/service_enseignant.dart';
import '../../../donnees/services/service_session.dart';
import '../../../donnees/services/service_api.dart';

class TeacherSupervisionsScreen extends StatefulWidget {
  const TeacherSupervisionsScreen({super.key});

  @override
  State<TeacherSupervisionsScreen> createState() =>
      _TeacherSupervisionsScreenState();
}

class _TeacherSupervisionsScreenState extends State<TeacherSupervisionsScreen> {
  final _service = EnseignantDataSource.service;
  List<dynamic> _elements = const [];
  Map<String, dynamic>? _detail;
  Object? _erreur;
  bool _chargement = true;
  bool _chargementDetail = false;

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
      final elements = await _service.encadrements();
      if (!mounted) return;
      setState(() {
        _elements = elements;
        _detail = null;
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

  Future<void> _ouvrirDetail(Map<String, dynamic> item) async {
    final id = _asInt(item['encadrement_id'] ?? item['id']);
    if (id == null) return;
    setState(() => _chargementDetail = true);
    try {
      final detail = await _service.detailEncadrement(id);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _chargementDetail = false;
      });
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
      selectedRoute: AppRoutes.teacherSupervisions,
      title: 'Mes encadrements',
      subtitle: 'Projets et etudiants qui vous sont attribues.',
      actions: [
        IconButton(
          onPressed: _charger,
          tooltip: 'Actualiser mes encadrements',
          icon: const Icon(Icons.refresh_rounded),
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
          : 'Les encadrements ne peuvent pas etre charges.';
      return SectionPanel(
        title: 'Encadrements indisponibles',
        subtitle: 'Le serveur n a pas retourne la liste demandee.',
        child: Text(message),
      );
    }
    if (_elements.isEmpty) {
      return const SectionPanel(
        title: 'Aucun encadrement',
        subtitle: 'Votre espace enseignant est a jour.',
        child: Text(
          'Aucun projet ne vous est actuellement attribue en encadrement.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionPanel(
          title: 'Synthese',
          subtitle: 'Les attributions sont gerees par l appariteur.',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              Chip(
                avatar: const Icon(Icons.workspaces_rounded, size: 18),
                label: Text('${_elements.length} projet(s) encadre(s)'),
              ),
              Chip(
                avatar: const Icon(Icons.groups_rounded, size: 18),
                label: Text('${_elements.map(_studentKey).toSet().length} etudiant(s)'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          minItemWidth: 330,
          maxColumns: 2,
          children: [
            for (final item in _elements)
              if (item is Map<String, dynamic>) _projectCard(context, item),
          ],
        ),
        if (_chargementDetail) ...[
          const SizedBox(height: 18),
          const Center(child: CircularProgressIndicator()),
        ],
        if (_detail != null) ...[
          const SizedBox(height: 18),
          _detailPanel(context, _detail!),
        ],
      ],
    );
  }

  Widget _projectCard(BuildContext context, Map<String, dynamic> item) {
    final projet = _map(item['projet']);
    final etudiant = _map(item['etudiant']);
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${projet['titre'] ?? item['titre'] ?? '-'}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  StatusBadge(
                    label: '${projet['statut'] ?? item['statut'] ?? '-'}',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${etudiant['matricule'] ?? '-'} - ${etudiant['nom'] ?? '-'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('${item['type_projet_libelle'] ?? '-'}')),
                  Chip(label: Text('${item['role_encadrement'] ?? '-'}')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailPanel(BuildContext context, Map<String, dynamic> detail) {
    final projet = _map(detail['projet']);
    final etudiant = _map(detail['etudiant']);
    final promotion = _map(projet['promotion']);
    final annee = _map(projet['annee_academique']);
    final autres = detail['autres_encadreurs'] as List<dynamic>? ?? const [];
    return SectionPanel(
      title: '${projet['titre'] ?? detail['titre'] ?? 'Projet'}',
      subtitle: '${projet['description'] ?? 'Aucune description fournie.'}',
      trailing: StatusBadge(
        label: '${detail['type_projet_libelle'] ?? '-'}',
        color: Theme.of(context).colorScheme.secondary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 18,
            runSpacing: 12,
            children: [
              _info('Etudiant', '${etudiant['matricule'] ?? '-'} - ${etudiant['nom'] ?? '-'}'),
              _info('Promotion', '${promotion['nom'] ?? '-'}'),
              _info('Annee', '${annee['libelle'] ?? '-'}'),
              _info('Statut', '${projet['statut'] ?? detail['statut'] ?? '-'}'),
              _info('Role', '${detail['role_encadrement'] ?? '-'}'),
              _info('Attribution', '${detail['date_attribution'] ?? '-'}'),
            ],
          ),
          if (autres.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Autres encadreurs', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in autres)
                  if (item is Map) Chip(label: Text('${item['nom'] ?? '-'} (${item['role_encadrement'] ?? '-'})')),
              ],
            ),
          ],
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

  static Map<String, dynamic> _map(dynamic value) => value is Map
      ? Map<String, dynamic>.from(value)
      : <String, dynamic>{};

  static String _studentKey(dynamic item) {
    if (item is! Map) return '';
    final etudiant = item['etudiant'];
    return etudiant is Map ? '${etudiant['id'] ?? etudiant['matricule']}' : '';
  }

  static int? _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value');
}
