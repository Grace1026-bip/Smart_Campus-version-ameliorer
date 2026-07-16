import 'package:flutter/material.dart';

import '../../../commun/composants/panneau_section.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_session.dart';
import 'ecran_deliberation.dart';
import 'ecran_evaluations_enseignant.dart';
import 'ecran_resultats_academiques.dart';

class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key, this.initialCourseId});

  final int? initialCourseId;

  @override
  Widget build(BuildContext context) {
    final role = SessionService.currentRole;
    if (role == UserRole.student) return const AcademicResultsScreen();
    if (role == UserRole.teacher) {
      return TeacherEvaluationsScreen(initialCourseId: initialCourseId);
    }
    if ({UserRole.apparitor, UserRole.dean, UserRole.viceDean}
        .contains(role)) {
      return const DeliberationScreen();
    }
    return SmartFacultyShell(
      role: role,
      selectedRoute: AppRoutes.grades,
      title: 'Notes et resultats',
      subtitle: 'Consultation limitee aux donnees exposees par FastAPI.',
      body: const SectionPanel(
        title: 'Donnees non disponibles pour ce role',
        child: Text(
          'Aucune route de consultation des notes n est exposee pour ce compte.',
        ),
      ),
    );
  }
}
