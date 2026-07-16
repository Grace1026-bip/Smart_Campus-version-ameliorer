import 'package:flutter/material.dart';

import '../../../commun/composants/panneau_section.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_session.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: SessionService.currentRole,
      selectedRoute: AppRoutes.projects,
      title: 'Projets academiques',
      subtitle: 'Consultation des projets selon les routes autorisees.',
      body: const SectionPanel(
        title: 'Module non expose pour ce role',
        child: Text(
          'Aucune route FastAPI de consultation des projets n est disponible pour ce compte. Les projets reels restent accessibles dans les espaces Etudiant, Enseignant et Appariteur.',
        ),
      ),
    );
  }
}
