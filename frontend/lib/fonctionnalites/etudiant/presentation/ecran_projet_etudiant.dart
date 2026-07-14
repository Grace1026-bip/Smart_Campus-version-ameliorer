import 'package:flutter/material.dart';

import '../../../commun/composants/badge_statut.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_api.dart';
import '../../../donnees/services/service_etudiant.dart';

class StudentProjectsScreen extends StatefulWidget {
  const StudentProjectsScreen({super.key});

  @override
  State<StudentProjectsScreen> createState() => _StudentProjectsScreenState();
}

class _StudentProjectsScreenState extends State<StudentProjectsScreen> {
  late Future<List<dynamic>> _future =
      EtudiantDataSource.service.projetsAcademiques();

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.student,
      selectedRoute: AppRoutes.studentProjects,
      title: 'Mon projet',
      subtitle: 'Projet academique et enseignants encadreurs actuels.',
      actions: [
        IconButton(
          tooltip: 'Actualiser',
          onPressed: () => setState(
              () => _future = EtudiantDataSource.service.projetsAcademiques()),
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
            return _StatePanel(
                title: 'Projets indisponibles',
                message: _messageErreur(snapshot.error),
                icon: Icons.cloud_off_rounded);
          }
          final projets = snapshot.data ?? const [];
          if (projets.isEmpty) {
            return const _StatePanel(
              title: 'Aucun projet academique',
              message:
                  'Aucun projet academique ne vous est actuellement attribue.',
              icon: Icons.work_outline_rounded,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in projets) ...[
                _ProjectCard(
                    item: _map(item), onDetail: () => _showDetail(_map(item))),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDetail(Map<String, dynamic> item) async {
    final id = _asInt(item['id']);
    if (id == 0) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['titre']?.toString() ?? 'Projet academique'),
        content: FutureBuilder<Map<String, dynamic>>(
          future: EtudiantDataSource.service.detailProjetAcademique(id),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) return Text(_messageErreur(snapshot.error));
            final projet = snapshot.data ?? item;
            final encadreurs =
                projet['encadreurs'] as List<dynamic>? ?? const [];
            return SizedBox(
              width: 620,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line('Type',
                        '${projet['type_projet_libelle'] ?? projet['type_projet'] ?? '-'}'),
                    _line('Statut', '${projet['statut'] ?? '-'}'),
                    _line('Promotion',
                        '${_map(projet['promotion'])['nom'] ?? '-'}'),
                    if ('${projet['description'] ?? ''}'.trim().isNotEmpty)
                      _line('Description', '${projet['description']}'),
                    const SizedBox(height: 12),
                    const Text('Enseignants encadreurs',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    if (encadreurs.isEmpty)
                      const Text(
                          'Aucun enseignant encadreur n est encore attribue a ce projet.')
                    else
                      for (final item in encadreurs)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.school_rounded,
                              color: AppColors.primary),
                          title: Text('${_map(item)['nom'] ?? '-'}'),
                          subtitle: Text('${_map(item)['grade'] ?? ''}'),
                          trailing: StatusBadge(
                            label: '${_map(item)['role_encadrement'] ?? '-'}',
                            color: _map(item)['role_encadrement'] == 'principal'
                                ? AppColors.primary
                                : AppColors.terracotta,
                            icon: Icons.supervisor_account_rounded,
                          ),
                        ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'))
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.item, required this.onDetail});

  final Map<String, dynamic> item;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final encadreurs = item['encadreurs'] as List<dynamic>? ?? const [];
    return SectionPanel(
      title: item['titre']?.toString() ?? 'Projet academique',
      subtitle:
          '${item['type_projet_libelle'] ?? item['type_projet'] ?? '-'} - ${_map(item['promotion'])['nom'] ?? '-'}',
      trailing: StatusBadge(
          label: '${item['statut'] ?? '-'}',
          color: AppColors.primary,
          icon: Icons.workspaces_rounded),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('${encadreurs.length} encadreur(s)'),
          OutlinedButton.icon(
              onPressed: onDetail,
              icon: const Icon(Icons.visibility_rounded),
              label: const Text('Voir le projet')),
        ],
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel(
      {required this.title, required this.message, required this.icon});
  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SectionPanel(
        title: title,
        subtitle: message,
        child:
            Center(child: Icon(icon, size: 56, color: AppColors.textSecondary)),
      );
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map<String, dynamic> ? value : <String, dynamic>{};

int _asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

Widget _line(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('$label : $value'),
    );

String _messageErreur(Object? error) {
  if (error is ApiException) return error.messagePourUtilisateur;
  return 'Une erreur est survenue. Reessayez.';
}
