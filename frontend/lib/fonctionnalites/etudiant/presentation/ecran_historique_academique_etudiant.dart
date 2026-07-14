import 'package:flutter/material.dart';

import '../../../commun/composants/panneau_section.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_api.dart';
import '../../../donnees/services/service_etudiant.dart';

class StudentAcademicHistoryScreen extends StatelessWidget {
  const StudentAcademicHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.student,
      selectedRoute: AppRoutes.studentHistory,
      title: 'Historique academique',
      subtitle: 'Cours inscrits et resultats officiellement publies.',
      body: FutureBuilder<Map<String, dynamic>>(
        future: EtudiantDataSource.service.historiqueAcademique(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return SectionPanel(
              title: 'Historique indisponible',
              subtitle: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).messagePourUtilisateur
                  : 'Les donnees academiques ne peuvent pas etre chargees.',
              child: const SizedBox.shrink(),
            );
          }
          final groupes = snapshot.data?['groupes'] as List<dynamic>? ?? const [];
          if (groupes.isEmpty) {
            return const SectionPanel(
              title: 'Aucun historique disponible',
              subtitle: 'Aucune inscription de cours n est encore enregistree.',
              child: SizedBox.shrink(),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final groupe in groupes)
                _HistoryGroup(data: groupe as Map<String, dynamic>),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryGroup extends StatelessWidget {
  const _HistoryGroup({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final annee = data['annee_academique'] as Map?;
    final promotion = data['promotion'] as Map?;
    final semestre = data['semestre'] as Map?;
    final cours = data['cours'] as List<dynamic>? ?? const [];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SectionPanel(
        title: '${annee?['libelle'] ?? '-'} | ${promotion?['nom'] ?? '-'}',
        subtitle: '${semestre?['nom'] ?? '-'} | ${cours.length} cours',
        child: Column(
          children: [
            for (final item in cours)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
                title: Text('${item['code'] ?? '-'} - ${item['intitule'] ?? '-'}'),
                subtitle: Text('${item['nombre_credits'] ?? 0} credits'),
                trailing: _ResultatBadge(resultat: item['resultat'] as Map<String, dynamic>?),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultatBadge extends StatelessWidget {
  const _ResultatBadge({required this.resultat});
  final Map<String, dynamic>? resultat;

  @override
  Widget build(BuildContext context) {
    if (resultat == null) return const Chip(label: Text('Non publie'));
    return Chip(
      avatar: const Icon(Icons.verified_rounded, size: 17, color: AppColors.success),
      label: Text('${resultat!['moyenne'] ?? '-'} | ${resultat!['statut_resultat'] ?? '-'}'),
    );
  }
}
