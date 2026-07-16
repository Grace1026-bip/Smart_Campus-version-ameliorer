import 'package:flutter/material.dart';

import '../../../commun/composants/panneau_section.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_api.dart';
import '../../../donnees/services/service_presences.dart';
import '../../../donnees/services/service_session.dart';

class PromotionChiefDashboardScreen extends StatelessWidget {
  const PromotionChiefDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.promotionChief,
      selectedRoute: AppRoutes.promotionChiefDashboard,
      title: 'Dashboard chef de promotion',
      subtitle: 'Suivi de la promotion a partir des donnees disponibles.',
      body: FutureBuilder<List<dynamic>>(
        future: PresencesDataSource.service.seancesPromotion(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).messagePourUtilisateur
                : 'Les donnees de la promotion ne peuvent pas etre chargees.';
            return SectionPanel(
              title: 'Donnees indisponibles',
              subtitle: message,
              child: Text(message),
            );
          }
          final sessions = snapshot.data ?? const [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionPanel(
                title: 'Seances de la promotion',
                subtitle: '${sessions.length} seance(s) provenant de FastAPI.',
                child: sessions.isEmpty
                    ? const Text('Aucune seance academique disponible.')
                    : Column(
                        children: [
                          for (final session in sessions)
                            ListTile(
                              leading: const Icon(Icons.fact_check_rounded,
                                  color: AppColors.primary),
                              title: Text(
                                  '${session['cours']?['intitule'] ?? session['cours'] ?? '-'}'),
                              subtitle: Text(
                                  '${session['date_seance'] ?? '-'} - ${session['statut'] ?? '-'}'),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context)
                    .pushNamed(AppRoutes.promotionChiefAttendance),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Confirmer le cours 2'),
              ),
            ],
          );
        },
      ),
    );
  }
}
