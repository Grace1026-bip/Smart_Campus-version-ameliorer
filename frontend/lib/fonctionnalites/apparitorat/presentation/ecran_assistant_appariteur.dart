import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_appariteur.dart';
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
      subtitle: 'Centre automatique de supervision academique.',
      body: FutureBuilder<Map<String, dynamic>>(
        future: AppariteurDataSource.service.assistant(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return SectionPanel(
              title: 'Donnees indisponibles',
              subtitle: snapshot.error.toString(),
              child: Text(snapshot.error.toString()),
            );
          }

          final data = snapshot.data ?? {};
          final priorities = data['priorites'] as List<dynamic>? ?? const [];
          final actions = data['actions'] as List<dynamic>? ?? const [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveGrid(
                minItemWidth: 260,
                maxColumns: 4,
                children: [
                  for (final insight in priorities)
                    _InsightCard(insight: insight as Map<String, dynamic>),
                ],
              ),
              const SizedBox(height: 22),
              SectionPanel(
                title: 'Suggestions d actions',
                subtitle: 'Priorites calculees depuis les donnees MySQL.',
                child: Column(
                  children: [
                    if (actions.isEmpty)
                      const _ActionLine(
                        icon: Icons.verified_rounded,
                        text: 'Aucune action urgente detectee.',
                      ),
                    for (final action in actions)
                      _ActionLine(
                        icon: Icons.call_made_rounded,
                        text: '$action',
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final Map<String, dynamic> insight;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor('${insight['niveau'] ?? 'info'}');

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
                '${insight['valeur'] ?? 0}',
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
            '${insight['titre'] ?? '-'}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${insight['detail'] ?? '-'}',
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

Color _toneColor(String tone) {
  switch (tone) {
    case 'info':
      return AppColors.primary;
    case 'success':
      return AppColors.success;
    case 'attention':
    case 'warning':
      return AppColors.warning;
    case 'danger':
      return AppColors.danger;
  }
  return AppColors.primary;
}
