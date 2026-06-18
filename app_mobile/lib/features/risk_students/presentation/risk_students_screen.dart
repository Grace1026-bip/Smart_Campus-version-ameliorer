import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/mock/mock_faculty_data.dart';
import '../../../data/models/faculty_models.dart';
import '../../../data/services/session_service.dart';
import '../../../shared/layouts/responsive_shell.dart';
import '../../../shared/widgets/responsive_grid.dart';
import '../../../shared/widgets/section_panel.dart';
import '../../../shared/widgets/smart_table.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_badge.dart';

class RiskStudentsScreen extends StatefulWidget {
  const RiskStudentsScreen({super.key});

  @override
  State<RiskStudentsScreen> createState() => _RiskStudentsScreenState();
}

class _RiskStudentsScreenState extends State<RiskStudentsScreen> {
  RiskLevel? _selectedLevel;

  @override
  Widget build(BuildContext context) {
    final students = MockFacultyData.riskStudents
        .where(
          (student) =>
              _selectedLevel == null || student.level == _selectedLevel,
        )
        .toList();

    return SmartFacultyShell(
      role: SessionService.currentRole,
      selectedRoute: AppRoutes.riskStudents,
      title: 'Étudiants à risque',
      subtitle: 'Suivi des moyennes, échecs et niveaux de risque.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResponsiveGrid(
            children: [
              StatCard(
                metric: KpiMetric(
                  title: 'Risque élevé',
                  value: '6',
                  trend: '+2',
                  description: 'actions urgentes',
                ),
                icon: Icons.priority_high_rounded,
                color: AppColors.danger,
              ),
              StatCard(
                metric: KpiMetric(
                  title: 'Risque moyen',
                  value: '12',
                  trend: '-1',
                  description: 'suivi renforcé',
                ),
                icon: Icons.warning_amber_rounded,
                color: AppColors.warning,
              ),
              StatCard(
                metric: KpiMetric(
                  title: 'Risque faible',
                  value: '31',
                  trend: 'stable',
                  description: 'surveillance',
                ),
                icon: Icons.trending_down_rounded,
                color: AppColors.accent,
              ),
              StatCard(
                metric: KpiMetric(
                  title: 'Moyenne critique',
                  value: '9,8',
                  trend: 'seuil',
                  description: 'promotion L2',
                ),
                icon: Icons.analytics_rounded,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionPanel(
            title: 'Filtrer par niveau',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
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
                    onSelected: (_) => setState(() => _selectedLevel = level),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SmartTable(
            title: 'Liste des étudiants à risque',
            subtitle: '${students.length} profil(s) affiché(s).',
            columns: const [
              DataColumn(label: Text('Nom')),
              DataColumn(label: Text('Promotion')),
              DataColumn(label: Text('Moyenne')),
              DataColumn(label: Text('Échecs')),
              DataColumn(label: Text('Niveau')),
            ],
            rows: [
              for (final student in students)
                DataRow(
                  cells: [
                    DataCell(Text(student.name)),
                    DataCell(Text(student.promotion)),
                    DataCell(Text(student.average.toStringAsFixed(1))),
                    DataCell(Text('${student.failures}')),
                    DataCell(StatusBadge.risk(student.level)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
