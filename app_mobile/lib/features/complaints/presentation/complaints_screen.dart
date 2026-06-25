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
    final config = _configForRole(role);
    final scopedComplaints = _complaintsForRole(role);
    final complaints = scopedComplaints.where((complaint) {
      final statusOk =
          _statusFilter == null || complaint.status == _statusFilter;
      final typeOk = _typeFilter == null || complaint.type == _typeFilter;
      return statusOk && typeOk;
    }).toList();

    return SmartFacultyShell(
      role: role,
      selectedRoute: AppRoutes.complaints,
      title: config.title,
      subtitle: config.subtitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveGrid(children: _buildStats(scopedComplaints, role)),
          const SizedBox(height: 22),
          if (config.canSubmit) ...[
            SectionPanel(
              title: config.formTitle,
              subtitle: config.formSubtitle,
              child: _ComplaintForm(role: role),
            ),
            const SizedBox(height: 22),
          ],
          SectionPanel(
            title: 'Filtres',
            subtitle: config.filterSubtitle,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<ComplaintStatus?>(
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
                  label: const Text('Reinitialiser'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SmartTable(
            title: config.listTitle,
            subtitle: '${complaints.length} demande(s) affichee(s).',
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Objet')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Demandeur')),
              DataColumn(label: Text('Priorite')),
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
                    DataCell(Text(complaint.priority)),
                    DataCell(StatusBadge.complaint(complaint.status)),
                    DataCell(
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pushNamed(
                          AppRoutes.complaintDetail,
                          arguments: complaint,
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Detail'),
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

  List<Widget> _buildStats(List<Complaint> complaints, UserRole role) {
    final pending = complaints
        .where((item) => item.status == ComplaintStatus.pending)
        .length;
    final inProgress = complaints
        .where((item) => item.status == ComplaintStatus.inProgress)
        .length;
    final resolved = complaints
        .where((item) => item.status == ComplaintStatus.resolved)
        .length;

    return [
      StatCard(
        metric: KpiMetric(
          title: _totalTitle(role),
          value: '${complaints.length}',
          trend: _scopeLabel(role),
          description: 'dans votre perimetre',
        ),
        icon: Icons.mark_email_unread_rounded,
        color: AppColors.primary,
      ),
      StatCard(
        metric: KpiMetric(
          title: 'En attente',
          value: '$pending',
          trend: pending == 0 ? 'stable' : 'a suivre',
          description: 'non traitee(s)',
        ),
        icon: Icons.schedule_rounded,
        color: AppColors.warning,
      ),
      StatCard(
        metric: KpiMetric(
          title: 'En cours',
          value: '$inProgress',
          trend: inProgress == 0 ? 'calme' : 'actif',
          description: 'dossier(s) ouvert(s)',
        ),
        icon: Icons.sync_rounded,
        color: AppColors.cyan,
      ),
      StatCard(
        metric: KpiMetric(
          title: 'Resolues',
          value: '$resolved',
          trend: resolved == 0 ? 'a venir' : 'cloturees',
          description: 'reponse apportee',
        ),
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      ),
    ];
  }
}

class _ComplaintForm extends StatelessWidget {
  const _ComplaintForm({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final isChief = role == UserRole.promotionChief;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final fields = [
          DropdownButtonFormField<ComplaintType>(
            initialValue:
                isChief ? ComplaintType.schedule : ComplaintType.gradeError,
            decoration: const InputDecoration(
              labelText: 'Type de reclamation',
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
          TextField(
            decoration: InputDecoration(
              labelText: isChief ? 'Objet collectif' : 'Objet',
              prefixIcon: const Icon(Icons.subject_rounded),
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
            TextField(
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: isChief
                    ? 'Expliquez la situation de la promotion'
                    : 'Description',
                alignLabelWithHint: true,
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('La reclamation est prete a etre transmise.'),
                  ),
                ),
                icon: const Icon(Icons.send_rounded),
                label: Text(
                  isChief ? 'Soumettre pour la promotion' : 'Soumettre',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ComplaintRoleConfig {
  const _ComplaintRoleConfig({
    required this.title,
    required this.subtitle,
    required this.canSubmit,
    required this.formTitle,
    required this.formSubtitle,
    required this.filterSubtitle,
    required this.listTitle,
  });

  final String title;
  final String subtitle;
  final bool canSubmit;
  final String formTitle;
  final String formSubtitle;
  final String filterSubtitle;
  final String listTitle;
}

_ComplaintRoleConfig _configForRole(UserRole role) {
  switch (role) {
    case UserRole.student:
      return const _ComplaintRoleConfig(
        title: 'Mes reclamations',
        subtitle: 'Soumettre une demande et suivre les reponses recues.',
        canSubmit: true,
        formTitle: 'Nouvelle reclamation',
        formSubtitle: 'Decrivez clairement le probleme et les details utiles.',
        filterSubtitle: 'Retrouvez rapidement vos demandes.',
        listTitle: 'Mes demandes',
      );
    case UserRole.teacher:
      return const _ComplaintRoleConfig(
        title: 'Reclamations academiques',
        subtitle: 'Traiter les demandes liees aux notes et cours attribues.',
        canSubmit: false,
        formTitle: '',
        formSubtitle: '',
        filterSubtitle: 'Les demandes concernent le volet academique.',
        listTitle: 'Demandes a traiter',
      );
    case UserRole.promotionChief:
      return const _ComplaintRoleConfig(
        title: 'Reclamations de promotion',
        subtitle: 'Porter les demandes collectives et suivre leur traitement.',
        canSubmit: true,
        formTitle: 'Reclamation collective',
        formSubtitle: 'A utiliser quand le probleme concerne la promotion.',
        filterSubtitle: 'Vue limitee aux demandes de votre promotion.',
        listTitle: 'Demandes de la promotion',
      );
    case UserRole.dean:
      return const _ComplaintRoleConfig(
        title: 'Suivi des reclamations',
        subtitle: 'Lire les tendances et identifier les points de blocage.',
        canSubmit: false,
        formTitle: '',
        formSubtitle: '',
        filterSubtitle: 'Vue decisionnelle sur les demandes de la faculte.',
        listTitle: 'Demandes recentes',
      );
    case UserRole.administrator:
      return const _ComplaintRoleConfig(
        title: 'Gestion des reclamations',
        subtitle: 'Assigner, suivre et cloturer les demandes administratives.',
        canSubmit: false,
        formTitle: '',
        formSubtitle: '',
        filterSubtitle: 'Vue complete pour le traitement administratif.',
        listTitle: 'Liste des reclamations',
      );
  }
}

List<Complaint> _complaintsForRole(UserRole role) {
  final complaints = MockFacultyData.complaints;
  final user = SessionService.currentUser;

  switch (role) {
    case UserRole.student:
      return complaints.where((item) => item.author == user.name).toList();
    case UserRole.teacher:
      return complaints
          .where((item) => item.type == ComplaintType.gradeError)
          .toList();
    case UserRole.promotionChief:
      return complaints
          .where((item) => item.author.contains('Promotion'))
          .toList();
    case UserRole.administrator:
    case UserRole.dean:
      return complaints;
  }
}

String _scopeLabel(UserRole role) {
  switch (role) {
    case UserRole.student:
      return 'personnel';
    case UserRole.teacher:
      return 'cours';
    case UserRole.promotionChief:
      return 'promotion';
    case UserRole.dean:
      return 'faculte';
    case UserRole.administrator:
      return 'global';
  }
}

String _totalTitle(UserRole role) {
  switch (role) {
    case UserRole.student:
      return 'Mes demandes';
    case UserRole.teacher:
      return 'A traiter';
    case UserRole.promotionChief:
      return 'Collectives';
    case UserRole.dean:
    case UserRole.administrator:
      return 'Total';
  }
}
