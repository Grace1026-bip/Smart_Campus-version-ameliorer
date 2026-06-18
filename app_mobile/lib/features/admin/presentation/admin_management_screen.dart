import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/faculty_models.dart';
import '../../../shared/layouts/responsive_shell.dart';
import '../../../shared/widgets/section_panel.dart';
import '../../../shared/widgets/smart_table.dart';

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
            title: 'Créer ou modifier',
            subtitle: 'Formulaire visuel prêt à brancher sur le futur backend.',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;
                final fields = [
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Libellé principal',
                      prefixIcon: Icon(Icons.edit_rounded),
                    ),
                  ),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Référence',
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
                        value: 'Archivé',
                        child: Text('Archivé'),
                      ),
                    ],
                    onChanged: (_) {},
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
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
                      for (final cell in row)
                        DataCell(Text(cell, overflow: TextOverflow.ellipsis)),
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
          tableSubtitle: 'Aperçu des profils académiques actifs.',
          columns: ['Nom', 'Spécialité', 'Cours', 'Statut'],
          rows: [
            ['Pr. David Mutombo', 'Bases de données', '3', 'Actif'],
            ['Dr. Esther Kalonji', 'Architecture', '2', 'Actif'],
            ['Ir. Michel Lukusa', 'Réseaux', '2', 'Actif'],
          ],
        );
      case 'Promotions':
        return const _ManagementConfig(
          title: 'Promotions',
          subtitle: 'Suivi des cohortes, niveaux et responsables.',
          tableSubtitle: 'Promotions ouvertes pour l’année académique.',
          columns: ['Promotion', 'Étudiants', 'Chef', 'Statut'],
          rows: [
            ['L1 Informatique', '312', 'Mireille Nzuzi', 'Actif'],
            ['L2 Informatique', '276', 'Sarah Mbuyi', 'Actif'],
            ['L3 Génie logiciel', '188', 'Grâce Ilunga', 'Actif'],
          ],
        );
      case 'Cours':
        return const _ManagementConfig(
          title: 'Cours',
          subtitle: 'Catalogue académique et charges d’enseignement.',
          tableSubtitle: 'Unités d’enseignement configurées.',
          columns: ['Cours', 'Crédits', 'Titulaire', 'Promotion'],
          rows: [
            ['Bases de données avancées', '5', 'Pr. David Mutombo', 'L3'],
            ['Algorithmique II', '4', 'Dr. Esther Kalonji', 'L2'],
            ['Réseaux informatiques', '4', 'Ir. Michel Lukusa', 'L3'],
          ],
        );
      case 'Utilisateurs':
        return const _ManagementConfig(
          title: 'Utilisateurs',
          subtitle: 'Comptes, rôles et accès de la plateforme.',
          tableSubtitle: 'Comptes institutionnels de démonstration.',
          columns: ['Utilisateur', 'Email', 'Rôle', 'Statut'],
          rows: [
            [
              'Nadine Kabeya',
              'admin@smartfaculty.cd',
              'Administrateur',
              'Actif',
            ],
            ['Grâce Ilunga', 'student@smartfaculty.cd', 'Étudiant', 'Actif'],
            ['Sarah Mbuyi', 'chief@smartfaculty.cd', 'Chef promotion', 'Actif'],
          ],
        );
      default:
        return const _ManagementConfig(
          title: 'Étudiants',
          subtitle: 'Dossiers étudiants, promotions et situation académique.',
          tableSubtitle: 'Échantillon de profils étudiants.',
          columns: ['Nom', 'Promotion', 'Moyenne', 'Statut'],
          rows: [
            ['Grâce Ilunga', 'L3 Génie logiciel', '13,7', 'Régulier'],
            ['Noah Kanku', 'L2 Informatique', '8,7', 'À risque'],
            ['Aline Mbala', 'L2 Informatique', '12,1', 'Régulier'],
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
