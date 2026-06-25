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
    final role = SessionService.currentRole;
    final canUpdateStatus = _canUpdateStatus(role, complaint);

    return SmartFacultyShell(
      role: role,
      selectedRoute: AppRoutes.complaintDetail,
      title: 'Detail ${complaint.id}',
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
                _DetailItem(label: 'Priorite', value: complaint.priority),
                _DetailItem(label: 'Service', value: complaint.assignedTo),
                _DetailItem(
                  label: 'Creee le',
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
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 22),
          if (canUpdateStatus)
            SectionPanel(
              title: role == UserRole.teacher
                  ? 'Reponse academique'
                  : 'Traitement administratif',
              subtitle: 'Mettez a jour le statut apres verification.',
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
                  const SizedBox(
                    width: 320,
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Commentaire',
                        prefixIcon: Icon(Icons.rate_review_rounded),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Le statut est pret a etre enregistre.'),
                      ),
                    ),
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Enregistrer'),
                  ),
                ],
              ),
            )
          else
            SectionPanel(
              title: 'Suivi du dossier',
              subtitle: 'Le changement de statut est reserve au service.',
              child: Text(
                _readOnlyMessage(role),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 22),
          SectionPanel(
            title: 'Historique de traitement',
            child: Column(
              children: [
                for (var i = 0; i < complaint.history.length; i++)
                  _TimelineItem(
                    item: complaint.history[i],
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

bool _canUpdateStatus(UserRole role, Complaint complaint) {
  if (role == UserRole.administrator) return true;
  return role == UserRole.teacher && complaint.type == ComplaintType.gradeError;
}

String _readOnlyMessage(UserRole role) {
  switch (role) {
    case UserRole.student:
      return 'Vous pouvez suivre chaque etape et attendre la reponse du service assigne.';
    case UserRole.promotionChief:
      return 'Vous suivez l avancement de la demande collective pour informer la promotion.';
    case UserRole.dean:
      return 'Cette vue sert au pilotage. Les actions operationnelles restent aux services concernes.';
    case UserRole.teacher:
      return 'Cette demande ne releve pas directement de vos cours.';
    case UserRole.administrator:
      return 'Le dossier est consultable en lecture simple.';
  }
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
  const _TimelineItem({required this.item, required this.isLast});

  final ComplaintHistory item;
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
              Container(width: 2, height: 48, color: AppColors.border),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.actor} - ${_formatDateShort(item.date)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _formatDateShort(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
