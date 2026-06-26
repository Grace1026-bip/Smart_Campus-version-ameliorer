import 'package:flutter/material.dart';

import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/donnees_fictives/donnees_faculte_fictives.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_session.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/carte_statistique.dart';
import '../../../commun/composants/badge_statut.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = SessionService.currentRole;
    const notifications = MockFacultyData.notifications;

    return SmartFacultyShell(
      role: role,
      selectedRoute: AppRoutes.notifications,
      title: 'Notifications',
      subtitle: 'Messages academiques, alertes et annonces institutionnelles.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveGrid(
            children: [
              StatCard(
                metric: KpiMetric(
                  title: 'Notifications',
                  value: '${notifications.length}',
                  trend: 'mock',
                  description: 'messages recents',
                ),
                icon: Icons.notifications_rounded,
                color: AppColors.primary,
              ),
              const StatCard(
                metric: KpiMetric(
                  title: 'Prioritaires',
                  value: '1',
                  trend: 'a lire',
                  description: 'alerte academique',
                ),
                icon: Icons.priority_high_rounded,
                color: AppColors.danger,
              ),
              const StatCard(
                metric: KpiMetric(
                  title: 'Annonces',
                  value: '2',
                  trend: 'cette semaine',
                  description: 'communication',
                ),
                icon: Icons.campaign_rounded,
                color: AppColors.warning,
              ),
              const StatCard(
                metric: KpiMetric(
                  title: 'Canaux',
                  value: '5',
                  trend: 'roles',
                  description: 'audiences ciblees',
                ),
                icon: Icons.groups_rounded,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionPanel(
            title: 'Boite de notifications',
            subtitle: 'Ces messages seront plus tard fournis par l API.',
            child: Column(
              children: [
                for (final notification in notifications)
                  _NotificationCard(notification: notification),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});

  final FacultyNotification notification;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(notification.tone);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_toneIcon(notification.tone), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    StatusBadge(
                      label: notification.audience,
                      color: color,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification.message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  notification.timeLabel,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
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

IconData _toneIcon(NotificationTone tone) {
  switch (tone) {
    case NotificationTone.info:
      return Icons.info_rounded;
    case NotificationTone.success:
      return Icons.check_circle_rounded;
    case NotificationTone.warning:
      return Icons.campaign_rounded;
    case NotificationTone.danger:
      return Icons.priority_high_rounded;
  }
}
