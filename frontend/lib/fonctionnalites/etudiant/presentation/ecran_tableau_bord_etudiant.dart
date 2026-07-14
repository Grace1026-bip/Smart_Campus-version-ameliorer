import 'package:flutter/material.dart';

import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/tuile_fonctionnalite.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_api.dart';
import '../../../donnees/services/service_etudiant.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.student,
      selectedRoute: AppRoutes.studentDashboard,
      title: 'Espace etudiant',
      subtitle: 'Votre situation academique actuelle, depuis les donnees publiees.',
      body: FutureBuilder<Map<String, dynamic>>(
        future: EtudiantDataSource.service.tableauDeBord(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorPanel(message: _messageErreur(snapshot.error));
          }
          return _DashboardContent(data: snapshot.data ?? const {});
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final profil = _map(data['profil']);
    final annonces = _list(data['dernieres_annonces']);
    final projets = _list(data['projets']);
    final inscription = _map(data['inscription_academique']);
    final sansCours = data['etat'] == 'aucune_inscription_active';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionPanel(
          title: 'Bonjour ${profil['nom_complet'] ?? '-'}',
          subtitle: '${profil['promotion'] ?? '-'} | ${profil['annee_academique'] ?? '-'}',
          trailing: _StatusChip(label: _labelStatut(profil['statut'])),
          child: Wrap(
            spacing: 28,
            runSpacing: 16,
            children: [
              _Info(label: 'Matricule', value: profil['matricule']),
              _Info(label: 'Email', value: profil['email']),
              _Info(label: 'Niveau', value: profil['niveau']),
              _Info(label: 'Inscription', value: _labelStatut(inscription['statut'])),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (sansCours)
          const SectionPanel(
            title: 'Aucune inscription active',
            subtitle: 'Votre compte est actif, mais aucun cours courant ne vous est rattache.',
            child: Text('Les cours, notes et resultats apparaitront apres validation de votre inscription.'),
          ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _CountPanel(title: 'Cours actuels', value: '${data['nombre_cours'] ?? 0}', icon: Icons.menu_book_rounded),
            _CountPanel(title: 'Resultats officiels', value: '${data['nombre_resultats_officiels'] ?? 0}', icon: Icons.verified_rounded, color: AppColors.success),
          ],
        ),
        const SizedBox(height: 22),
        SectionPanel(
          title: 'Acces rapides',
          subtitle: 'Consultez uniquement vos informations academiques.',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth < 700 ? constraints.maxWidth : 220.0;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _Tile(width: width, icon: Icons.menu_book_rounded, title: 'Mes cours', route: AppRoutes.studentCourses),
                  _Tile(width: width, icon: Icons.campaign_rounded, title: 'Valve', route: AppRoutes.studentValve),
                  _Tile(width: width, icon: Icons.fact_check_rounded, title: 'Mes notes', route: AppRoutes.studentNotes),
                  _Tile(width: width, icon: Icons.assessment_rounded, title: 'Mes resultats', route: AppRoutes.studentResults),
                  _Tile(width: width, icon: Icons.history_rounded, title: 'Historique', route: AppRoutes.studentHistory),
                  _Tile(width: width, icon: Icons.assignment_rounded, title: 'Mon enrolement', route: AppRoutes.studentEnrollments),
                  _Tile(width: width, icon: Icons.workspaces_rounded, title: 'Mon projet', route: AppRoutes.studentProjects),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 22),
        _RecentPublications(items: annonces),
        const SizedBox(height: 22),
        _Projects(items: projets),
        const SizedBox(height: 16),
        Text('Les moyennes, presences, paiements et alertes ne sont pas affiches ici lorsqu aucune donnee officielle correspondante n est disponible.', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _RecentPublications extends StatelessWidget {
  const _RecentPublications({required this.items});
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: 'Dernieres publications Valve',
      subtitle: 'Publications publiees de vos cours actuels.',
      child: items.isEmpty
          ? const Text('Aucune publication recente.')
          : Column(
              children: [
                for (final item in items.take(5))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.campaign_rounded, color: AppColors.primary),
                    title: Text('${item['titre'] ?? '-'}'),
                    subtitle: Text('${item['type_publication'] ?? 'Publication'} | ${item['publie_le'] ?? '-'}'),
                  ),
              ],
            ),
    );
  }
}

class _Projects extends StatelessWidget {
  const _Projects({required this.items});
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: 'Projet et encadrement',
      subtitle: 'Projet(s) actuellement rattache(s) a votre dossier.',
      child: items.isEmpty
          ? const Text('Aucun projet academique ne vous est actuellement attribue.')
          : Column(
              children: [
                for (final item in items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.workspaces_rounded, color: AppColors.terracotta),
                    title: Text('${item['titre'] ?? '-'}'),
                    subtitle: Text('${item['type_projet_libelle'] ?? item['type_projet'] ?? '-'} | ${item['statut'] ?? '-'}'),
                    trailing: Text('${item['nombre_encadreurs'] ?? 0} encadreur(s)'),
                  ),
              ],
            ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.width, required this.icon, required this.title, required this.route});
  final double width;
  final IconData icon;
  final String title;
  final String route;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: FeatureTile(
          icon: icon,
          title: title,
          subtitle: 'Ouvrir la consultation',
          onTap: () => Navigator.of(context).pushNamed(route),
        ),
      );
}

class _CountPanel extends StatelessWidget {
  const _CountPanel({required this.title, required this.value, required this.icon, this.color = AppColors.primary});
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 230,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [Icon(icon, color: color), const SizedBox(width: 14), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.bodySmall), Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w900))])]),
      );
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label;
  final dynamic value;
  @override
  Widget build(BuildContext context) => SizedBox(width: 190, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.labelSmall), const SizedBox(height: 4), Text('${value ?? '-'}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))]));
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Chip(label: Text(label), avatar: const Icon(Icons.verified_rounded, size: 18, color: AppColors.success));
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => SectionPanel(title: 'Espace etudiant indisponible', subtitle: message, child: const Text('Verifiez votre session ou reessayez dans quelques instants.'));
}

Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : const {};
List<dynamic> _list(dynamic value) => value is List<dynamic> ? value : const [];
String _labelStatut(dynamic value) {
  switch (value?.toString()) {
    case 'actif':
      return 'Actif';
    case 'valide':
      return 'Valide';
    case 'en_attente':
      return 'En attente';
    case 'non_enregistree':
      return 'Non enregistree';
    default:
      return value?.toString().isNotEmpty == true ? value.toString() : 'Non precise';
  }
}
String _messageErreur(Object? erreur) => erreur is ApiException ? erreur.messagePourUtilisateur : 'Les donnees etudiantes ne peuvent pas etre chargees.';
