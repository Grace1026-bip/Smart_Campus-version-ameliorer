import 'package:flutter/material.dart';

import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/donnees_fictives/donnees_faculte_fictives.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/badge_statut.dart';

class ApparitorAssistantScreen extends StatelessWidget {
  const ApparitorAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.apparitor,
      selectedRoute: AppRoutes.apparitorAssistant,
      title: 'Assistant Appariteur',
      subtitle: 'Resume quotidien simule des priorites academiques.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveGrid(
            minItemWidth: 260,
            maxColumns: 4,
            children: [
              for (final insight in MockFacultyData.apparitorInsights)
                _InsightCard(insight: insight),
            ],
          ),
          const SizedBox(height: 22),
          const SectionPanel(
            title: 'Suggestions d actions',
            subtitle: 'Assistant simule avec donnees fictives.',
            child: Column(
              children: [
                _ActionLine(
                  icon: Icons.call_made_rounded,
                  text: 'Relancer Pr. David Mutombo pour Programmation Web L2.',
                ),
                _ActionLine(
                  icon: Icons.mark_email_unread_rounded,
                  text: 'Assigner les reclamations en attente a l apparitorat.',
                ),
                _ActionLine(
                  icon: Icons.health_and_safety_rounded,
                  text: 'Generer la liste des etudiants L1 a risque eleve.',
                ),
                _ActionLine(
                  icon: Icons.workspaces_rounded,
                  text: 'Verifier les livrables de projets L3 non deposes.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionPanel(
            title: 'Resume par promotion',
            subtitle: 'Vue rapide pour preparer le suivi quotidien.',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                StatusBadge(
                    label: 'L1: 5 risques eleves', color: AppColors.danger),
                StatusBadge(
                    label: 'L2: notes Web attendues', color: AppColors.warning),
                StatusBadge(
                    label: 'L3: 3 livrables manquants', color: AppColors.info),
                StatusBadge(
                    label: 'M2: stages actifs', color: AppColors.success),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final ApparitorInsight insight;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(insight.tone);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
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
              Icon(Icons.auto_awesome_rounded, color: color),
              const Spacer(),
              Text(
                insight.metric,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            insight.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            insight.detail,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionLine extends StatelessWidget {
  const _ActionLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _toneColor(NotificationTone tone) {
  switch (tone) {
    case NotificationTone.info:
      return AppColors.primary;
    case NotificationTone.success:
      return AppColors.success;
    case NotificationTone.warning:
      return AppColors.warning;
    case NotificationTone.danger:
      return AppColors.danger;
  }
}
