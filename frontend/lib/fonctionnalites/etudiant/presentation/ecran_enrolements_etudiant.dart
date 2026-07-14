import 'package:flutter/material.dart';

import '../../../commun/composants/badge_statut.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/lien_externe.dart';
import '../../../donnees/services/service_api.dart';
import '../../../donnees/services/service_etudiant.dart';

class StudentEnrollmentsScreen extends StatefulWidget {
  const StudentEnrollmentsScreen({super.key});

  @override
  State<StudentEnrollmentsScreen> createState() =>
      _StudentEnrollmentsScreenState();
}

class _StudentEnrollmentsScreenState extends State<StudentEnrollmentsScreen> {
  late Future<List<dynamic>> _future = EtudiantDataSource.service.enrolements();
  int? _downloadingId;

  void _refresh() {
    setState(() => _future = EtudiantDataSource.service.enrolements());
  }

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.student,
      selectedRoute: AppRoutes.studentEnrollments,
      title: 'Mon enrolement',
      subtitle: 'Fiches academiques et programme de votre inscription.',
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
            return _ErrorPanel(message: _messageErreur(snapshot.error));
          }
          final elements = snapshot.data ?? const [];
          if (elements.isEmpty) {
            return const _StatePanel(
              icon: Icons.assignment_outlined,
              title: 'Aucun enrolement',
              message: 'Aucun enrolement academique ne vous est attribue.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveGrid(children: _stats(elements)),
              const SizedBox(height: 22),
              for (final item in elements) ...[
                _EnrollmentCard(
                  item: _map(item),
                  downloading: _downloadingId == _asInt(_map(item)['id']),
                  onDetail: () => _showDetail(_map(item)),
                  onDownload: () => _download(_map(item)),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }

  List<Widget> _stats(List<dynamic> elements) {
    final valid =
        elements.where((item) => _map(item)['statut'] == 'valide').length;
    final credits = elements.fold<int>(
      0,
      (total, item) => total + _asInt(_map(item)['credits_prevus']),
    );
    return [
      _stat('Enrolements', '${elements.length}', Icons.assignment_rounded,
          AppColors.primary),
      _stat('Valides', '$valid', Icons.verified_rounded, AppColors.success),
      _stat('Credits', '$credits', Icons.workspace_premium_rounded,
          AppColors.warning),
    ];
  }

  Widget _stat(String title, String value, IconData icon, Color color) {
    return SectionPanel(
      title: title,
      subtitle: 'situation academique',
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(value,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Future<void> _showDetail(Map<String, dynamic> item) async {
    final id = _asInt(item['id']);
    if (id == 0) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail de mon enrolement'),
        content: FutureBuilder<Map<String, dynamic>>(
          future: EtudiantDataSource.service.detailEnrolement(id),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) return Text(_messageErreur(snapshot.error));
            final detail = snapshot.data ?? item;
            final programme = detail['programme'] as List<dynamic>? ?? const [];
            return SizedBox(
              width: 620,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line('Reference', '${detail['reference_fiche'] ?? '-'}'),
                    _line('Statut', '${detail['statut'] ?? '-'}'),
                    _line('Promotion',
                        '${(_map(detail['promotion']))['nom'] ?? '-'}'),
                    _line('Annee',
                        '${(_map(detail['annee_academique']))['libelle'] ?? '-'}'),
                    _line('Credits', '${detail['credits_prevus'] ?? 0}'),
                    const SizedBox(height: 12),
                    const Text('Cours du programme',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    for (final course in programme)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.menu_book_rounded,
                            color: AppColors.primary),
                        title: Text(
                            '${_map(course)['code'] ?? '-'} - ${_map(course)['intitule'] ?? '-'}'),
                        trailing: Text('${_map(course)['credits'] ?? 0} cr.'),
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

  Future<void> _download(Map<String, dynamic> item) async {
    if (item['statut'] != 'valide' || _downloadingId != null) return;
    final id = _asInt(item['id']);
    setState(() => _downloadingId = id);
    try {
      final octets =
          await EtudiantDataSource.service.telechargerFicheEnrolement(id);
      final ok = await telechargerOctets(
        octets: octets,
        nomFichier: 'fiche_enrolement_${item['reference_fiche'] ?? id}.pdf',
      );
      if (!mounted) return;
      _snack(ok
          ? 'Fiche telechargee.'
          : 'Le telechargement est disponible dans le navigateur Web.');
    } catch (error) {
      if (mounted) _snack(_messageErreur(error), erreur: true);
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  void _snack(String message, {bool erreur = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          backgroundColor: erreur ? AppColors.danger : AppColors.success,
          content: Text(message)),
    );
  }
}

class _EnrollmentCard extends StatelessWidget {
  const _EnrollmentCard(
      {required this.item,
      required this.downloading,
      required this.onDetail,
      required this.onDownload});

  final Map<String, dynamic> item;
  final bool downloading;
  final VoidCallback onDetail;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final status = item['statut']?.toString() ?? '-';
    return SectionPanel(
      title: item['reference_fiche']?.toString() ?? 'Enrolement',
      subtitle:
          '${_map(item['promotion'])['nom'] ?? '-'} - ${_map(item['annee_academique'])['libelle'] ?? '-'}',
      trailing: StatusBadge(
          label: status,
          color: _statusColor(status),
          icon: Icons.assignment_turned_in_rounded),
      child: Wrap(
        spacing: 18,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('${item['nombre_cours'] ?? 0} cours'),
          Text('${item['credits_prevus'] ?? 0} credits'),
          OutlinedButton.icon(
              onPressed: onDetail,
              icon: const Icon(Icons.visibility_rounded),
              label: const Text('Detail')),
          if (status == 'valide')
            FilledButton.icon(
              onPressed: downloading ? null : onDownload,
              icon: downloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf_rounded),
              label:
                  Text(downloading ? 'Generation...' : 'Telecharger la fiche'),
            ),
        ],
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel(
      {required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => SectionPanel(
        title: title,
        subtitle: message,
        child:
            Center(child: Icon(icon, size: 56, color: AppColors.textSecondary)),
      );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => _StatePanel(
        icon: Icons.cloud_off_rounded,
        title: 'Enrolements indisponibles',
        message: message,
      );
}

Widget _line(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('$label : $value'),
    );

Map<String, dynamic> _map(dynamic value) =>
    value is Map<String, dynamic> ? value : <String, dynamic>{};

int _asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

Color _statusColor(String status) {
  switch (status) {
    case 'valide':
      return AppColors.success;
    case 'annule':
      return AppColors.danger;
    default:
      return AppColors.warning;
  }
}

String _messageErreur(Object? error) {
  if (error is ApiException) return error.messagePourUtilisateur;
  return 'Une erreur est survenue. Reessayez.';
}
