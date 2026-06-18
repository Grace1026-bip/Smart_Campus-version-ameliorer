import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/mock/mock_faculty_data.dart';
import '../../../data/models/faculty_models.dart';
import '../../../data/services/session_service.dart';
import '../../../shared/layouts/responsive_shell.dart';
import '../../../shared/widgets/section_panel.dart';
import '../../../shared/widgets/status_badge.dart';

class ComplaintDetailScreen extends StatefulWidget {
  ComplaintDetailScreen({super.key, Complaint? complaint})
    : complaint = complaint ?? MockFacultyData.complaints.first;

  final Complaint complaint;

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  late ComplaintStatus _status = widget.complaint.status;

  @override
  Widget build(BuildContext context) {
    final complaint = widget.complaint;

    return SmartFacultyShell(
      role: SessionService.currentRole,
      selectedRoute: AppRoutes.complaintDetail,
      title: 'Détail ${complaint.id}',
      subtitle: complaint.title,
      actions: [
        IconButton(
          tooltip: 'Retour',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionPanel(
            title: 'Informations',
            trailing: StatusBadge.complaint(_status),
            child: Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _DetailItem(label: 'Type', value: complaint.type.label),
                _DetailItem(label: 'Demandeur', value: complaint.author),
                _DetailItem(label: 'Assignée à', value: complaint.assignedTo),
                _DetailItem(
                  label: 'Créée le',
                  value: _formatDate(complaint.createdAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SectionPanel(
            title: 'Description',
            child: Text(
              complaint.description,
              style: const TextStyle(
                color: AppColors.textPrimary,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 22),
          SectionPanel(
            title: 'Changement de statut',
            subtitle: 'Simulation frontend du traitement administratif.',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 260,
                  child: DropdownButtonFormField<ComplaintStatus>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Statut'),
                    items: ComplaintStatus.values
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.label),
                          ),
                        )
                        .toList(),
                    onChanged: (status) {
                      if (status != null) setState(() => _status = status);
                    },
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Enregistrer'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SectionPanel(
            title: 'Historique de traitement',
            child: Column(
              children: [
                for (var i = 0; i < complaint.history.length; i++)
                  _TimelineItem(
                    text: complaint.history[i],
                    isLast: i == complaint.history.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.text, required this.isLast});

  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 36, color: AppColors.border),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
