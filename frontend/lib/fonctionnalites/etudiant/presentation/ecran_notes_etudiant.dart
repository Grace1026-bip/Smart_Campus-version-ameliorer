import 'package:flutter/material.dart';

import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/tableau_intelligent.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_api.dart';
import '../../../donnees/services/service_etudiant.dart';

class StudentNotesScreen extends StatelessWidget {
  const StudentNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.student,
      selectedRoute: AppRoutes.studentNotes,
      title: 'Mes notes',
      subtitle: 'Evaluations publiees de vos cours actuels.',
      body: FutureBuilder<Map<String, dynamic>>(
        future: EtudiantDataSource.service.notes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return SectionPanel(
              title: 'Notes indisponibles',
              subtitle: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).messagePourUtilisateur
                  : 'Les notes ne peuvent pas etre chargees.',
              child: const SizedBox.shrink(),
            );
          }
          final notes = snapshot.data?['notes'] as List<dynamic>? ?? const [];
          if (notes.isEmpty) {
            return const SectionPanel(
              title: 'Aucune note publiee',
              subtitle: 'Les evaluations non publiees restent invisibles.',
              child: SizedBox.shrink(),
            );
          }
          return SmartTable(
            title: 'Notes publiees',
            subtitle: '${notes.length} evaluation(s) visible(s).',
            columns: const [
              DataColumn(label: Text('Cours')),
              DataColumn(label: Text('Evaluation')),
              DataColumn(label: Text('Note')),
              DataColumn(label: Text('Publication')),
            ],
            rows: [
              for (final item in notes)
                DataRow(cells: [
                  DataCell(Text('${(item['cours'] as Map?)?['code'] ?? '-'}')),
                  DataCell(Text('${(item['evaluation'] as Map?)?['titre'] ?? '-'}')),
                  DataCell(Text('${(item['note'] as Map?)?['note_obtenue'] ?? '-'}')),
                  DataCell(Text('${(item['evaluation'] as Map?)?['date_publication'] ?? '-'}')),
                ]),
            ],
          );
        },
      ),
    );
  }
}
