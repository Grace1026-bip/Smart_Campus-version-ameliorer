import 'package:flutter/material.dart';

import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/donnees_fictives/donnees_faculte_fictives.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_session.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/badge_statut.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = SessionService.currentRole;
    final projects = _projectsForRole(role);
    final selectedProject = projects.first;

    return SmartFacultyShell(
      role: role,
      selectedRoute: AppRoutes.projects,
      title: _titleFor(role),
      subtitle: _subtitleFor(role),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveGrid(
            minItemWidth: 290,
            maxColumns: 3,
            children: [
              for (final project in projects) _ProjectCard(project: project),
            ],
          ),
          const SizedBox(height: 22),
          SectionPanel(
            title: 'Detail du projet',
            subtitle: selectedProject.summary,
            trailing: StatusBadge(
              label: selectedProject.status,
              color: AppColors.success,
              icon: Icons.verified_rounded,
            ),
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
                    _DetailBox(
                      label: 'Promotion',
                      value: selectedProject.promotion,
                    ),
                    _DetailBox(
                      label: 'Avancement',
                      value: '${(selectedProject.progress * 100).round()}%',
                    ),
                    _DetailBox(
                      label: 'Prochain livrable',
                      value: selectedProject.nextDeliverable,
                    ),
                    _DetailBox(
                      label: 'Fenetre de soutenance',
                      value: selectedProject.defenseWindow,
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
              _RoleProjectPanel(role: role),
              SectionPanel(
                title: 'Livrables',
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

class _RoleProjectPanel extends StatelessWidget {
  const _RoleProjectPanel({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    if (role == UserRole.teacher) {
      return SectionPanel(
        title: 'Validation des livrables',
        subtitle: 'Retour pedagogique sur les depots des groupes encadres.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TextField(
              minLines: 3,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Commentaire pour le groupe',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.rate_review_rounded),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Le livrable est marque comme valide.'),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Valider'),
                ),
                OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Une correction sera demandee.'),
                    ),
                  ),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Demander correction'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (role == UserRole.administrator ||
        role == UserRole.apparitor ||
        role == UserRole.dean) {
      return SectionPanel(
        title: role == UserRole.dean
            ? 'Lecture decisionnelle'
            : role == UserRole.apparitor
                ? 'Suivi apparitorat'
                : 'Suivi administratif',
        subtitle: role == UserRole.dean
            ? 'Reperer les projets bloques et soutenances proches.'
            : role == UserRole.apparitor
                ? 'Suivre les projets par promotion et livrable.'
                : 'Controler les groupes, encadreurs et livrables.',
        child: const Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ProjectSignal(icon: Icons.groups_rounded, text: 'Groupes suivis'),
            _ProjectSignal(icon: Icons.school_rounded, text: 'Encadreurs'),
            _ProjectSignal(icon: Icons.event_rounded, text: 'Echeances'),
          ],
        ),
      );
    }

    return SectionPanel(
      title: 'Depot de livrables',
      subtitle: 'Ajoutez un fichier lorsque votre groupe a valide une etape.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
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
              'Selectionner un livrable',
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
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Le livrable est pret a etre joint.'),
                ),
              ),
              icon: const Icon(Icons.attach_file_rounded),
              label: const Text('Joindre un fichier'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectSignal extends StatelessWidget {
  const _ProjectSignal({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, color: AppColors.primary, size: 18),
      label: Text(text),
      backgroundColor: AppColors.primarySoft,
      side: const BorderSide(color: AppColors.border),
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
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
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
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            project.promotion,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
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
              color: AppColors.success,
              fontWeight: FontWeight.w900,
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

class _DeliverableLine extends StatelessWidget {
  const _DeliverableLine({required this.deliverable});

  final ProjectDeliverable deliverable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.description_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deliverable.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Echeance ${_formatDate(deliverable.dueDate)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(
            label: deliverable.status,
            color: deliverable.status == 'Valide'
                ? AppColors.success
                : AppColors.warning,
          ),
        ],
      ),
    );
  }
}

List<AcademicProject> _projectsForRole(UserRole role) {
  final projects = MockFacultyData.projects;
  final user = SessionService.currentUser;

  late final List<AcademicProject> scoped;
  switch (role) {
    case UserRole.student:
      scoped = projects
          .where((project) => project.members.contains(user.name))
          .toList();
      break;
    case UserRole.promotionChief:
      scoped = projects
          .where((project) => project.promotion == user.promotion)
          .toList();
      break;
    case UserRole.teacher:
      scoped =
          projects.where((project) => project.supervisor == user.name).toList();
      break;
    case UserRole.administrator:
    case UserRole.apparitor:
    case UserRole.surveillant:
    case UserRole.dean:
    case UserRole.viceDean:
      scoped = projects;
      break;
  }

  return scoped.isEmpty ? projects : scoped;
}

String _titleFor(UserRole role) {
  switch (role) {
    case UserRole.student:
      return 'Mes projets academiques';
    case UserRole.teacher:
      return 'Projets encadres';
    case UserRole.promotionChief:
      return 'Projets de la promotion';
    case UserRole.apparitor:
    case UserRole.surveillant:
      return 'Projets par promotion';
    case UserRole.dean:
      return 'Suivi des projets';
    case UserRole.viceDean:
      return 'Suivi des projets';
    case UserRole.administrator:
      return 'Gestion des projets';
  }
}

String _subtitleFor(UserRole role) {
  switch (role) {
    case UserRole.student:
      return 'Suivre avancement, membres et livrables de votre groupe.';
    case UserRole.teacher:
      return 'Encadrer les groupes et valider les livrables.';
    case UserRole.promotionChief:
      return 'Reperer les groupes en retard et relayer les echeances.';
    case UserRole.apparitor:
    case UserRole.surveillant:
      return 'Suivre tous les projets, groupes, encadreurs et livrables.';
    case UserRole.dean:
      return 'Lire l avancement global et les points de blocage.';
    case UserRole.viceDean:
      return 'Lire l avancement global et les points de blocage.';
    case UserRole.administrator:
      return 'Controler les groupes, encadreurs, statuts et livrables.';
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
