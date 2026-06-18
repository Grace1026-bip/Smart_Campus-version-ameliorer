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

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  ComplaintStatus? _statusFilter;
  ComplaintType? _typeFilter;

  @override
  Widget build(BuildContext context) {
    final role = SessionService.currentRole;
    final complaints = MockFacultyData.complaints.where((complaint) {
      final statusOk =
          _statusFilter == null || complaint.status == _statusFilter;
      final typeOk = _typeFilter == null || complaint.type == _typeFilter;
      return statusOk && typeOk;
    }).toList();

    return SmartFacultyShell(
      role: role,
      selectedRoute: AppRoutes.complaints,
      title: 'Gestion des réclamations',
      subtitle: 'Liste, création, statut et historique de traitement.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResponsiveGrid(
            children: [
              StatCard(
                metric: KpiMetric(
                  title: 'Total',
                  value: '142',
                  trend: '+12',
                  description: 'ce semestre',
                ),
                icon: Icons.mark_email_unread_rounded,
                color: AppColors.primary,
              ),
              StatCard(
                metric: KpiMetric(
                  title: 'En attente',
                  value: '36',
                  trend: '25%',
                  description: 'à assigner',
                ),
                icon: Icons.schedule_rounded,
                color: AppColors.warning,
              ),
              StatCard(
                metric: KpiMetric(
                  title: 'Résolues',
                  value: '64',
                  trend: '+18%',
                  description: 'traitées',
                ),
                icon: Icons.check_circle_rounded,
                color: AppColors.accent,
              ),
              StatCard(
                metric: KpiMetric(
                  title: 'Délai moyen',
                  value: '2,4 j',
                  trend: '-18%',
                  description: 'temps de traitement',
                ),
                icon: Icons.timer_rounded,
                color: AppColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionPanel(
            title: 'Nouvelle réclamation',
            subtitle: 'Formulaire mock prêt à envoyer vers le futur backend.',
            child: _ComplaintForm(),
          ),
          const SizedBox(height: 22),
          SectionPanel(
            title: 'Filtres',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<ComplaintStatus?>(
                    key: ValueKey(_statusFilter),
                    initialValue: _statusFilter,
                    decoration: const InputDecoration(labelText: 'Statut'),
                    items: [
                      const DropdownMenuItem<ComplaintStatus?>(
                        value: null,
                        child: Text('Tous les statuts'),
                      ),
                      for (final status in ComplaintStatus.values)
                        DropdownMenuItem<ComplaintStatus?>(
                          value: status,
                          child: Text(status.label),
                        ),
                    ],
                    onChanged: (value) => setState(() => _statusFilter = value),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: DropdownButtonFormField<ComplaintType?>(
                    key: ValueKey(_typeFilter),
                    initialValue: _typeFilter,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: [
                      const DropdownMenuItem<ComplaintType?>(
                        value: null,
                        child: Text('Tous les types'),
                      ),
                      for (final type in ComplaintType.values)
                        DropdownMenuItem<ComplaintType?>(
                          value: type,
                          child: Text(type.label),
                        ),
                    ],
                    onChanged: (value) => setState(() => _typeFilter = value),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _statusFilter = null;
                    _typeFilter = null;
                  }),
                  icon: const Icon(Icons.filter_alt_off_rounded),
                  label: const Text('Réinitialiser'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SmartTable(
            title: 'Liste des réclamations',
            subtitle: '${complaints.length} demande(s) affichée(s).',
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Objet')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Demandeur')),
              DataColumn(label: Text('Statut')),
              DataColumn(label: Text('Action')),
            ],
            rows: [
              for (final complaint in complaints)
                DataRow(
                  cells: [
                    DataCell(Text(complaint.id)),
                    DataCell(Text(complaint.title)),
                    DataCell(Text(complaint.type.label)),
                    DataCell(Text(complaint.author)),
                    DataCell(StatusBadge.complaint(complaint.status)),
                    DataCell(
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pushNamed(
                          AppRoutes.complaintDetail,
                          arguments: complaint,
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Détail'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComplaintForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final fields = [
          DropdownButtonFormField<ComplaintType>(
            initialValue: ComplaintType.gradeError,
            decoration: const InputDecoration(
              labelText: 'Type de réclamation',
              prefixIcon: Icon(Icons.category_rounded),
            ),
            items: ComplaintType.values
                .map(
                  (type) =>
                      DropdownMenuItem(value: type, child: Text(type.label)),
                )
                .toList(),
            onChanged: (_) {},
          ),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Objet',
              prefixIcon: Icon(Icons.subject_rounded),
            ),
          ),
        ];

        return Column(
          children: [
            if (compact)
              Column(
                children: [
                  for (final field in fields) ...[
                    field,
                    const SizedBox(height: 12),
                  ],
                ],
              )
            else
              Row(
                children: [
                  for (final field in fields) ...[
                    Expanded(child: field),
                    const SizedBox(width: 12),
                  ],
                ],
              ),
            const SizedBox(height: 12),
            const TextField(
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.send_rounded),
                label: const Text('Soumettre'),
              ),
            ),
          ],
        );
      },
    );
  }
}
