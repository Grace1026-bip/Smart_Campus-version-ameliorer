import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/mock/mock_faculty_data.dart';
import '../../../data/models/faculty_models.dart';
import '../../../data/services/session_service.dart';
import '../../../shared/layouts/responsive_shell.dart';
import '../../../shared/widgets/chart_widgets.dart';
import '../../../shared/widgets/responsive_grid.dart';
import '../../../shared/widgets/section_panel.dart';
import '../../../shared/widgets/smart_table.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_badge.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _promotion = 'Toutes';
  String _period = 'Semestre actuel';

  @override
  Widget build(BuildContext context) {
    final role = SessionService.currentRole;
    final riskStudents = _riskStudentsFor(role);

    return SmartFacultyShell(
      role: role,
      selectedRoute: AppRoutes.analytics,
      title: _titleFor(role),
      subtitle: _subtitleFor(role),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionPanel(
            title: 'Filtres',
            subtitle: 'Les donnees restent mockees pour le frontend.',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: _promotion,
                    decoration: const InputDecoration(labelText: 'Promotion'),
                    items: const [
                      DropdownMenuItem(value: 'Toutes', child: Text('Toutes')),
                      DropdownMenuItem(value: 'L1', child: Text('L1')),
                      DropdownMenuItem(value: 'L2', child: Text('L2')),
                      DropdownMenuItem(value: 'L3', child: Text('L3')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _promotion = value);
                    },
                  ),
                ),
                SizedBox(
                  width: 230,
                  child: DropdownButtonFormField<String>(
                    initialValue: _period,
                    decoration: const InputDecoration(labelText: 'Periode'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Semestre actuel',
                        child: Text('Semestre actuel'),
                      ),
                      DropdownMenuItem(value: 'Annee', child: Text('Annee')),
                      DropdownMenuItem(value: 'Jury', child: Text('Jury')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _period = value);
                    },
                  ),
                ),
                StatusBadge(
                  label: 'Vue: $_promotion / $_period',
                  color: AppColors.primary,
                  icon: Icons.filter_alt_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          ResponsiveGrid(children: _statsFor(role)),
          const SizedBox(height: 22),
          ResponsiveGrid(
            minItemWidth: 360,
            maxColumns: 2,
            children: _chartsFor(role),
          ),
          const SizedBox(height: 22),
          SmartTable(
            title: _tableTitleFor(role),
            subtitle: 'Donnees visibles selon le perimetre du compte.',
            columns: const [
              DataColumn(label: Text('Nom')),
              DataColumn(label: Text('Promotion')),
              DataColumn(label: Text('Moyenne')),
              DataColumn(label: Text('Echecs')),
              DataColumn(label: Text('Risque')),
            ],
            rows: [
              for (final student in riskStudents)
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

List<Widget> _statsFor(UserRole role) {
  switch (role) {
    case UserRole.teacher:
      return [
        StatCard(
          metric: MockFacultyData.teacherKpis[0],
          icon: Icons.menu_book_rounded,
          color: AppColors.primary,
        ),
        StatCard(
          metric: MockFacultyData.teacherKpis[1],
          icon: Icons.fact_check_rounded,
          color: AppColors.success,
        ),
        const StatCard(
          metric: KpiMetric(
            title: 'Cours fragile',
            value: 'Reseaux',
            trend: '58%',
            description: 'reussite estimee',
          ),
          icon: Icons.warning_amber_rounded,
          color: AppColors.warning,
        ),
        const StatCard(
          metric: KpiMetric(
            title: 'Reclamations',
            value: '1',
            trend: 'note',
            description: 'a verifier',
          ),
          icon: Icons.rate_review_rounded,
          color: AppColors.cyan,
        ),
      ];
    case UserRole.promotionChief:
      return [
        for (var i = 0; i < MockFacultyData.promotionKpis.length; i++)
          StatCard(
            metric: MockFacultyData.promotionKpis[i],
            icon: [
              Icons.groups_rounded,
              Icons.grade_rounded,
              Icons.health_and_safety_rounded,
              Icons.mark_email_unread_rounded,
            ][i],
            color: [
              AppColors.primary,
              AppColors.success,
              AppColors.danger,
              AppColors.warning,
            ][i],
          ),
      ];
    case UserRole.student:
      return [
        for (var i = 0; i < MockFacultyData.studentKpis.length; i++)
          StatCard(
            metric: MockFacultyData.studentKpis[i],
            icon: [
              Icons.grade_rounded,
              Icons.workspace_premium_rounded,
              Icons.menu_book_rounded,
              Icons.mark_email_unread_rounded,
            ][i],
            color: [
              AppColors.primary,
              AppColors.success,
              AppColors.cyan,
              AppColors.warning,
            ][i],
          ),
      ];
    case UserRole.administrator:
    case UserRole.dean:
      return [
        StatCard(
          metric: MockFacultyData.adminKpis[0],
          icon: Icons.groups_rounded,
          color: AppColors.primary,
        ),
        StatCard(
          metric: MockFacultyData.adminKpis[1],
          icon: Icons.co_present_rounded,
          color: AppColors.cyan,
        ),
        StatCard(
          metric: MockFacultyData.decisionKpis[0],
          icon: Icons.trending_up_rounded,
          color: AppColors.success,
        ),
        StatCard(
          metric: MockFacultyData.decisionKpis[1],
          icon: Icons.trending_down_rounded,
          color: AppColors.danger,
        ),
      ];
  }
}

List<Widget> _chartsFor(UserRole role) {
  if (role == UserRole.teacher) {
    return const [
      BarChartCard(
        title: 'Performance de mes cours',
        data: MockFacultyData.performanceByCourse,
      ),
      DonutChartCard(
        title: 'Reclamations liees aux notes',
        data: MockFacultyData.complaintsByCategory,
        centerLabel: '1',
      ),
    ];
  }

  if (role == UserRole.promotionChief || role == UserRole.student) {
    return const [
      LineChartCard(
        title: 'Evolution academique',
        data: MockFacultyData.l2ProgressTrend,
      ),
      BarChartCard(
        title: 'Cours a surveiller',
        data: MockFacultyData.l2CoursePerformance,
      ),
    ];
  }

  return const [
    LineChartCard(
      title: 'Performances par promotion',
      data: MockFacultyData.performanceByPromotion,
    ),
    BarChartCard(
      title: 'Performances par cours',
      data: MockFacultyData.performanceByCourse,
    ),
    DonutChartCard(
      title: 'Reclamations par categorie',
      data: MockFacultyData.complaintsByCategory,
      centerLabel: '124',
    ),
    DonutChartCard(
      title: 'Reclamations par statut',
      data: MockFacultyData.complaintsByStatus,
      centerLabel: '142',
    ),
  ];
}

List<RiskStudent> _riskStudentsFor(UserRole role) {
  if (role == UserRole.promotionChief) {
    return MockFacultyData.riskStudents
        .where((student) => student.promotion == 'L2 Informatique')
        .toList();
  }
  if (role == UserRole.student) {
    return MockFacultyData.riskStudents.take(1).toList();
  }
  return MockFacultyData.riskStudents;
}

String _titleFor(UserRole role) {
  switch (role) {
    case UserRole.teacher:
      return 'Indicateurs de mes cours';
    case UserRole.promotionChief:
      return 'Indicateurs de ma promotion';
    case UserRole.student:
      return 'Mon suivi academique';
    case UserRole.dean:
      return 'Analytics decisionnels';
    case UserRole.administrator:
      return 'Analytics administratifs';
  }
}

String _subtitleFor(UserRole role) {
  switch (role) {
    case UserRole.teacher:
      return 'Lire les tendances utiles pour vos cours et reclamations.';
    case UserRole.promotionChief:
      return 'Suivre les signaux utiles a relayer dans la promotion.';
    case UserRole.student:
      return 'Comprendre votre progression personnelle.';
    case UserRole.dean:
      return 'Indicateurs academiques, reclamations et performances.';
    case UserRole.administrator:
      return 'Vue globale pour controler les services academiques.';
  }
}

String _tableTitleFor(UserRole role) {
  switch (role) {
    case UserRole.promotionChief:
      return 'Etudiants a suivre dans ma promotion';
    case UserRole.teacher:
      return 'Signaux pedagogiques';
    case UserRole.student:
      return 'Mon signal d accompagnement';
    case UserRole.dean:
    case UserRole.administrator:
      return 'Etudiants a risque';
  }
}
