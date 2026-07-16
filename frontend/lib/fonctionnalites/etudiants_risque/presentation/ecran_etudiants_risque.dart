import 'package:flutter/material.dart';

import '../../../commun/composants/badge_statut.dart';
import '../../../commun/composants/carte_statistique.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/tableau_intelligent.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_api.dart';
import '../../../donnees/services/service_enseignant.dart';
import '../../../donnees/services/service_risques.dart';
import '../../../donnees/services/service_session.dart';

class RiskStudentsScreen extends StatefulWidget {
  const RiskStudentsScreen({super.key});

  @override
  State<RiskStudentsScreen> createState() => _RiskStudentsScreenState();
}

class _RiskStudentsScreenState extends State<RiskStudentsScreen> {
  RiskLevel? _selectedLevel;

  @override
  Widget build(BuildContext context) {
    final role = SessionService.currentRole;
    return SmartFacultyShell(
      role: role,
      selectedRoute: AppRoutes.riskStudents,
      title: 'Etudiants a risque',
      subtitle: 'Signaux calcules par FastAPI a partir des notes publiees.',
      body: FutureBuilder<List<dynamic>>(
        future: _load(role),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).messagePourUtilisateur
                : 'Les signaux de risque ne peuvent pas etre charges.';
            return SectionPanel(
              title: 'Donnees indisponibles',
              subtitle: message,
              child: Text(message),
            );
          }
          final all = snapshot.data ?? const [];
          final students = all.where((item) {
            if (_selectedLevel == null || item is! Map) return true;
            return _level('${item['niveau'] ?? item['niveau_risque'] ?? ''}') ==
                _selectedLevel;
          }).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveGrid(children: _stats(all)),
              const SizedBox(height: 22),
              SectionPanel(
                title: 'Filtrer par niveau',
                child: Wrap(
                  spacing: 10,
                  children: [
                    ChoiceChip(
                      label: const Text('Tous'),
                      selected: _selectedLevel == null,
                      onSelected: (_) => setState(() => _selectedLevel = null),
                    ),
                    for (final level in RiskLevel.values)
                      ChoiceChip(
                        label: Text(level.label),
                        selected: _selectedLevel == level,
                        onSelected: (_) =>
                            setState(() => _selectedLevel = level),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SmartTable(
                title: 'Signaux disponibles',
                subtitle: '${students.length} signalement(s) affiche(s).',
                columns: const [
                  DataColumn(label: Text('Etudiant')),
                  DataColumn(label: Text('Cours')),
                  DataColumn(label: Text('Score')),
                  DataColumn(label: Text('Niveau')),
                  DataColumn(label: Text('Motif')),
                ],
                rows: [
                  for (final item in students)
                    if (item is Map)
                      DataRow(cells: [
                        DataCell(Text('${item['nom'] ?? item['etudiant']?['nom'] ?? '-'}')),
                        DataCell(Text('${item['cours'] ?? item['cours']?['intitule'] ?? '-'}')),
                        DataCell(Text('${item['score_risque'] ?? '-'}')),
                        DataCell(StatusBadge.risk(_level(
                            '${item['niveau'] ?? item['niveau_risque'] ?? ''}'))),
                        DataCell(Text('${item['motif'] ?? item['raisons'] ?? '-'}')),
                      ]),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<List<dynamic>> _load(UserRole role) async {
    switch (role) {
      case UserRole.student:
        final data = await RisquesDataSource.service.risquesEtudiant();
        return data['risques'] as List<dynamic>? ?? const [];
      case UserRole.teacher:
        final data = await EnseignantDataSource.service.tableauDeBord();
        return data['etudiants_a_risque'] as List<dynamic>? ?? const [];
      case UserRole.apparitor:
      case UserRole.dean:
      case UserRole.administrator:
        final data = await RisquesDataSource.service.risquesGlobal(taille: 100);
        return data['elements'] as List<dynamic>? ?? const [];
      case UserRole.promotionChief:
      case UserRole.surveillant:
      case UserRole.viceDean:
        throw ApiException(
            'Aucune route de risques n est exposee pour ce role.');
    }
  }
}

List<Widget> _stats(List<dynamic> students) {
  final high = students.where((item) => item is Map &&
      _level('${item['niveau'] ?? item['niveau_risque'] ?? ''}') == RiskLevel.high).length;
  final medium = students.where((item) => item is Map &&
      _level('${item['niveau'] ?? item['niveau_risque'] ?? ''}') == RiskLevel.medium).length;
  return [
    _stat('Risque eleve', high, AppColors.danger),
    _stat('Risque moyen', medium, AppColors.warning),
    _stat('Risque faible', students.length - high - medium, AppColors.success),
    _stat('Total', students.length, AppColors.primary),
  ];
}

StatCard _stat(String title, int value, Color color) => StatCard(
      metric: KpiMetric(
        title: title,
        value: '$value',
        trend: 'donnees reelles',
        description: 'calculees par FastAPI',
      ),
      icon: Icons.health_and_safety_rounded,
      color: color,
    );

RiskLevel _level(String value) {
  switch (value) {
    case 'eleve':
    case 'high':
      return RiskLevel.high;
    case 'moyen':
    case 'medium':
      return RiskLevel.medium;
    default:
      return RiskLevel.low;
  }
}
