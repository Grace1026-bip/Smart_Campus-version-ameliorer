import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_etudiant.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/carte_statistique.dart';
import '../../../commun/composants/badge_statut.dart';

class StudentAlertsScreen extends StatefulWidget {
  const StudentAlertsScreen({super.key});

  @override
  State<StudentAlertsScreen> createState() => _StudentAlertsScreenState();
}

class _StudentAlertsScreenState extends State<StudentAlertsScreen> {
  late Future<List<dynamic>> _future = EtudiantDataSource.service.alertes();
  String? _levelFilter;

  void _refresh() {
    setState(() => _future = EtudiantDataSource.service.alertes());
  }

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.student,
      selectedRoute: AppRoutes.studentAlerts,
      title: 'Alertes et notifications',
      subtitle: 'Risques, reponses aux reclamations et signaux academiques.',
      actions: [
        IconButton(
          tooltip: 'Actualiser',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorPanel(message: snapshot.error.toString());
          }

          final allAlerts = snapshot.data ?? const [];
          final alerts = allAlerts.where((item) {
            return _levelFilter == null || item['niveau'] == _levelFilter;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveGrid(children: _stats(allAlerts)),
              const SizedBox(height: 22),
              SectionPanel(
                title: 'Filtres',
                subtitle: '${alerts.length} alerte(s) affichee(s).',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 260,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _levelFilter,
                        decoration: const InputDecoration(labelText: 'Niveau'),
                        items: const [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Tous les niveaux'),
                          ),
                          DropdownMenuItem(
                            value: 'danger',
                            child: Text('Danger'),
                          ),
                          DropdownMenuItem(
                            value: 'attention',
                            child: Text('Attention'),
                          ),
                          DropdownMenuItem(
                            value: 'info',
                            child: Text('Information'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _levelFilter = value),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _levelFilter = null),
                      icon: const Icon(Icons.filter_alt_off_rounded),
                      label: const Text('Reinitialiser'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (alerts.isEmpty)
                const _EmptyState()
              else
                Column(
                  children: [
                    for (final item in alerts) ...[
                      _AlertCard(alert: item as Map<String, dynamic>),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _stats(List<dynamic> alerts) {
    int count(String level) =>
        alerts.where((item) => item['niveau'] == level).length;
    final unread = alerts.where((item) => item['lue'] != true).length;

    return [
      StatCard(
        metric: KpiMetric(
          title: 'Alertes',
          value: '${alerts.length}',
          trend: 'total',
          description: 'signaux academiques',
        ),
        icon: Icons.warning_amber_rounded,
        color: AppColors.primary,
      ),
      StatCard(
        metric: KpiMetric(
          title: 'Danger',
          value: '${count('danger')}',
          trend: 'urgent',
          description: 'niveau critique',
        ),
        icon: Icons.priority_high_rounded,
        color: AppColors.danger,
      ),
      StatCard(
        metric: KpiMetric(
          title: 'Attention',
          value: '${count('attention')}',
          trend: 'a suivre',
          description: 'risque possible',
        ),
        icon: Icons.report_problem_rounded,
        color: AppColors.warning,
      ),
      StatCard(
        metric: KpiMetric(
          title: 'Non lues',
          value: '$unread',
          trend: 'lecture',
          description: 'a consulter',
        ),
        icon: Icons.mark_email_unread_rounded,
        color: AppColors.cyan,
      ),
    ];
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final Map<String, dynamic> alert;

  @override
  Widget build(BuildContext context) {
    final color = _levelColor('${alert['niveau'] ?? 'attention'}');

    return SectionPanel(
      title: '${alert['titre'] ?? '-'}',
      subtitle: '${alert['code_cours'] ?? '-'} ${alert['cours'] ?? ''}',
      trailing: StatusBadge(
        label: _levelLabel('${alert['niveau'] ?? 'attention'}'),
        color: color,
        icon: Icons.warning_amber_rounded,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${alert['message'] ?? '-'}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge(
                label: alert['lue'] == true ? 'Lue' : 'Non lue',
                color: alert['lue'] == true
                    ? AppColors.success
                    : AppColors.warning,
              ),
              StatusBadge(
                label: '${alert['date_creation'] ?? '-'}',
                color: AppColors.textSecondary,
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              const Icon(
                Icons.verified_rounded,
                color: AppColors.success,
                size: 44,
              ),
              const SizedBox(height: 12),
              Text(
                'Aucune alerte active',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                'Vos notes publiees ne generent pas d alerte academique pour le moment.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: 'Donnees indisponibles',
      subtitle: message,
      child: Text(message),
    );
  }
}

Color _levelColor(String level) {
  switch (level) {
    case 'danger':
      return AppColors.danger;
    case 'info':
      return AppColors.primary;
    default:
      return AppColors.warning;
  }
}

String _levelLabel(String level) {
  switch (level) {
    case 'danger':
      return 'Danger';
    case 'info':
      return 'Information';
    default:
      return 'Attention';
  }
}
