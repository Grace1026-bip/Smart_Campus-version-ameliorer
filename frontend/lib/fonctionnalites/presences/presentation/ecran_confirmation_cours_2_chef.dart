import 'package:flutter/material.dart';

import '../../../commun/composants/panneau_section.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../donnees/services/service_api.dart';
import '../../../donnees/services/service_presences.dart';
import '../../../donnees/services/service_session.dart';

class ConfirmationCours2ChefScreen extends StatefulWidget {
  const ConfirmationCours2ChefScreen({super.key});

  @override
  State<ConfirmationCours2ChefScreen> createState() =>
      _ConfirmationCours2ChefScreenState();
}

class _ConfirmationCours2ChefScreenState
    extends State<ConfirmationCours2ChefScreen> {
  final _service = PresencesDataSource.service;
  List<dynamic> _seances = const [];
  Object? _erreur;
  bool _chargement = true;
  int? _actionId;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    try {
      final seances = await _service.seancesPromotion();
      if (!mounted) return;
      setState(() {
        _seances = seances;
        _erreur = null;
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

  Future<void> _confirmer(int id) async {
    setState(() => _actionId = id);
    try {
      await _service.confirmerCours2(id);
      await _charger();
    } catch (erreur) {
      if (!mounted) return;
      setState(() => _erreur = erreur);
    } finally {
      if (mounted) setState(() => _actionId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: SessionService.currentRole,
      selectedRoute: AppRoutes.promotionChiefAttendance,
      title: 'Confirmation du cours 2',
      subtitle: 'Seances de votre promotion uniquement.',
      actions: [
        IconButton(
            onPressed: _charger,
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh_rounded))
      ],
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (_chargement) return const Center(child: CircularProgressIndicator());
    if (_erreur != null) {
      return SectionPanel(
          title: 'Acces indisponible',
          subtitle: 'La seance n a pas pu etre chargee.',
          child: Text(_erreur is ApiException
              ? (_erreur! as ApiException).messagePourUtilisateur
              : 'Une erreur est survenue.'));
    }
    if (_seances.isEmpty) {
      return const SectionPanel(
          title: 'Aucune seance',
          subtitle: 'Votre promotion ne contient aucune seance.',
          child: Text('Aucune confirmation de cours 2 n est disponible.'));
    }
    return Column(children: [
      for (final item in _seances)
        if (item is Map<String, dynamic>)
          Card(
            child: ListTile(
              title: Text(
                  '${item['cours']?['code'] ?? 'Cours'} - ${item['type_cours'] ?? '-'}'),
              subtitle: Text(
                  '${item['date_seance'] ?? '-'} | ${item['statut'] ?? '-'}'),
              trailing: item['type_cours'] == 'cours_2'
                  ? FilledButton(
                      onPressed: item['confirme_cours_2'] == true ||
                              item['statut'] != 'ouverte' ||
                              _actionId != null
                          ? null
                          : () => _confirmer(item['id'] as int),
                      child: Text(item['confirme_cours_2'] == true
                          ? 'Confirme'
                          : 'Confirmer'))
                  : const Text('Cours 1'),
            ),
          ),
    ]);
  }
}
