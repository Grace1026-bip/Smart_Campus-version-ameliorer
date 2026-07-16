import 'package:flutter/material.dart';

import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_appariteur.dart';
import '../../../donnees/services/service_api.dart';
import '../../../donnees/services/service_session.dart';

class InternshipsScreen extends StatelessWidget {
  const InternshipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = SessionService.currentRole;
    return SmartFacultyShell(
      role: role,
      selectedRoute: AppRoutes.internships,
      title: 'Stages',
      subtitle: 'Consultation des stages exposes par le backend.',
      body: FutureBuilder<List<dynamic>>(
        future: AppariteurDataSource.service.stages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).messagePourUtilisateur
                : 'Les donnees de stages ne peuvent pas etre chargees.';
            return SectionPanel(
              title: 'Donnees de stages indisponibles',
              subtitle: message,
              child: Text(message),
            );
          }
          final stages = snapshot.data ?? const [];
          if (stages.isEmpty) {
            return const SectionPanel(
              title: 'Aucun stage disponible',
              child: Text('Aucune donnee de stage n est disponible.'),
            );
          }
          return Column(
            children: [
              for (final stage in stages)
                SectionPanel(
                  title: '${stage['titre'] ?? stage['intitule'] ?? '-'}',
                  subtitle: '${stage['entreprise'] ?? '-'}',
                  child: Text('${stage['statut'] ?? '-'}'),
                ),
            ],
          );
        },
      ),
    );
  }
}
