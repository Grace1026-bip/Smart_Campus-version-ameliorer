import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/mock/mock_faculty_data.dart';
import '../../../data/models/faculty_models.dart';
import '../../../data/services/session_service.dart';
import '../../../shared/layouts/responsive_shell.dart';
import '../../../shared/widgets/responsive_grid.dart';
import '../../../shared/widgets/section_panel.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedProject = MockFacultyData.projects.first;

    return SmartFacultyShell(
      role: SessionService.currentRole,
      selectedRoute: AppRoutes.projects,
      title: 'Projets académiques',
      subtitle: 'Liste, encadrement, progression et livrables.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveGrid(
            minItemWidth: 290,
            maxColumns: 3,
            children: [
              for (final project in MockFacultyData.projects)
                _ProjectCard(project: project),
            ],
          ),
          const SizedBox(height: 22),
          SectionPanel(
            title: 'Détail du projet',
            subtitle: selectedProject.title,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 18,
                  runSpacing: 14,
                  children: [
                    _DetailBox(
                      label: 'Encadreur',
                      value: selectedProject.supervisor,
                    ),
                    _DetailBox(label: 'Statut', value: selectedProject.status),
                    _DetailBox(
                      label: 'Avancement',
                      value: '${(selectedProject.progress * 100).round()}%',
                    ),
                    _DetailBox(
                      label: 'Prochain livrable',
                      value: selectedProject.nextDeliverable,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                LinearProgressIndicator(
                  value: selectedProject.progress,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(8),
                  backgroundColor: AppColors.surfaceMuted,
                ),
                const SizedBox(height: 22),
                Text(
                  'Membres du groupe',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final member in selectedProject.members)
                      Chip(
                        avatar: const Icon(Icons.person_rounded, size: 18),
                        label: Text(member),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          ResponsiveGrid(
            minItemWidth: 340,
            maxColumns: 2,
            children: [
              SectionPanel(
                title: 'Dépôt de livrables',
                subtitle: 'Zone visuelle prête pour l’upload côté backend.',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.border,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.cloud_upload_rounded,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Glisser un fichier ou sélectionner un livrable',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'PDF, ZIP, DOCX ou archive de code.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.attach_file_rounded),
                        label: const Text('Sélectionner'),
                      ),
                    ],
                  ),
                ),
              ),
              SectionPanel(
                title: 'Historique des livrables',
                subtitle: selectedProject.id,
                child: Column(
                  children: [
                    for (final deliverable in selectedProject.deliverables)
                      _DeliverableLine(deliverable: deliverable),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project});

  final AcademicProject project;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspaces_rounded, color: AppColors.primary),
              const Spacer(),
              Text(
                '${(project.progress * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            project.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            project.supervisor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: project.progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: AppColors.surfaceMuted,
          ),
          const SizedBox(height: 12),
          Text(
            project.status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailBox extends StatelessWidget {
  const _DetailBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
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

class _DeliverableLine extends StatelessWidget {
  const _DeliverableLine({required this.deliverable});

  final String deliverable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.description_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              deliverable,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.accent),
        ],
      ),
    );
  }
}
