import 'package:flutter/material.dart';

import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/tableau_intelligent.dart';
import '../../../commun/composants/badge_statut.dart';

class AdminManagementArgs {
  const AdminManagementArgs(this.category);

  final String category;
}

class AdminManagementScreen extends StatelessWidget {
  const AdminManagementScreen({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final config = _configFor(category);

    return SmartFacultyShell(
      role: UserRole.administrator,
      selectedRoute: AppRoutes.adminDashboard,
      title: 'Gestion ${config.title.toLowerCase()}',
      subtitle: config.subtitle,
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
            title: 'Creer ou modifier',
            subtitle: 'Gestion disponible lorsque la route API correspondante est exposee.',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                final fields = [
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Libelle principal',
                      prefixIcon: Icon(Icons.edit_rounded),
                    ),
                  ),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Reference',
                      prefixIcon: Icon(Icons.tag_rounded),
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: 'Actif',
                    decoration: const InputDecoration(
                      labelText: 'Statut',
                      prefixIcon: Icon(Icons.verified_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Actif', child: Text('Actif')),
                      DropdownMenuItem(
                        value: 'Brouillon',
                        child: Text('Brouillon'),
                      ),
                      DropdownMenuItem(
                          value: 'Archive', child: Text('Archive')),
                    ],
                    onChanged: (_) {},
                  ),
                  ElevatedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Les modifications sont pretes a etre envoyees.',
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Enregistrer'),
                  ),
                ];

                if (compact) {
                  return Column(
                    children: [
                      for (final field in fields) ...[
                        field,
                        const SizedBox(height: 12),
                      ],
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final field in fields) ...[
                      Expanded(child: field),
                      const SizedBox(width: 12),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          SmartTable(
            title: config.title,
            subtitle: config.tableSubtitle,
            columns: config.columns
                .map((label) => DataColumn(label: Text(label)))
                .toList(),
            rows: config.rows
                .map(
                  (row) => DataRow(
                    cells: [
                      for (var i = 0; i < row.length; i++)
                        i == row.length - 1
                            ? DataCell(
                                StatusBadge(
                                  label: row[i],
                                  color: row[i] == 'A risque'
                                      ? AppColors.warning
                                      : AppColors.success,
                                ),
                              )
                            : DataCell(
                                Text(row[i], overflow: TextOverflow.ellipsis),
                              ),
                    ],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  _ManagementConfig _configFor(String category) {
    switch (category) {
      case 'Enseignants':
        return const _ManagementConfig(
          title: 'Enseignants',
          subtitle: 'Administration des enseignants et affectations.',
          tableSubtitle: 'Apercu des profils academiques actifs.',
          columns: ['Nom', 'Specialite', 'Cours', 'Statut'],
          rows: [
            ['Pr. David Mutombo', 'Bases de donnees', '3', 'Actif'],
            ['Dr. Esther Kalonji', 'Architecture', '2', 'Actif'],
            ['Ir. Michel Lukusa', 'Reseaux', '2', 'Actif'],
          ],
        );
      case 'Promotions':
        return const _ManagementConfig(
          title: 'Promotions',
          subtitle: 'Suivi des cohortes, niveaux et responsables.',
          tableSubtitle: 'Promotions ouvertes pour l annee academique.',
          columns: ['Promotion', 'Etudiants', 'Chef', 'Statut'],
          rows: [
            ['L1 Informatique', '312', 'Mireille Nzuzi', 'Actif'],
            ['L2 Informatique', '276', 'Sarah Mbuyi', 'Actif'],
            ['L3 Genie logiciel', '188', 'Grace Ilunga', 'Actif'],
          ],
        );
      case 'Cours':
        return const _ManagementConfig(
          title: 'Cours',
          subtitle: 'Catalogue academique et charges d enseignement.',
          tableSubtitle: 'Unites d enseignement configurees.',
          columns: ['Cours', 'Credits', 'Titulaire', 'Promotion'],
          rows: [
            ['Bases de donnees avancees', '5', 'Pr. David Mutombo', 'L3'],
            ['Algorithmique II', '4', 'Dr. Esther Kalonji', 'L2'],
            ['Reseaux informatiques', '4', 'Ir. Michel Lukusa', 'L3'],
          ],
        );
      case 'Utilisateurs':
        return const _ManagementConfig(
          title: 'Utilisateurs',
          subtitle: 'Comptes, roles et acces de la plateforme.',
          tableSubtitle: 'Comptes institutionnels retournes par FastAPI.',
          columns: ['Utilisateur', 'Email', 'Role', 'Statut'],
          rows: [
            [
              'Nadine Kabeya',
              'admin@smartfaculty.cd',
              'Administrateur',
              'Actif',
            ],
            ['Grace Ilunga', 'student@smartfaculty.cd', 'Etudiant', 'Actif'],
            ['Sarah Mbuyi', 'chief@smartfaculty.cd', 'Chef promotion', 'Actif'],
          ],
        );
      default:
        return const _ManagementConfig(
          title: 'Etudiants',
          subtitle: 'Dossiers etudiants, promotions et situation academique.',
          tableSubtitle: 'Echantillon de profils etudiants.',
          columns: ['Nom', 'Promotion', 'Moyenne', 'Statut'],
          rows: [
            ['Grace Ilunga', 'L3 Genie logiciel', '13,7', 'Actif'],
            ['Noah Kanku', 'L2 Informatique', '8,7', 'A risque'],
            ['Aline Mbala', 'L2 Informatique', '12,1', 'Actif'],
          ],
        );
    }
  }
}

class _ManagementConfig {
  const _ManagementConfig({
    required this.title,
    required this.subtitle,
    required this.tableSubtitle,
    required this.columns,
    required this.rows,
  });

  final String title;
  final String subtitle;
  final String tableSubtitle;
  final List<String> columns;
  final List<List<String>> rows;
}
