import 'package:flutter/material.dart';

import '../../../coeur/constantes/constantes_application.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_session.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/carte_statistique.dart';
import '../../../commun/composants/badge_statut.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SessionService.currentUser;
    final role = SessionService.currentRole;

    return SmartFacultyShell(
      role: role,
      selectedRoute: AppRoutes.profile,
      title: 'Profil utilisateur',
      subtitle: 'Identite, role, coordonnees et preferences du compte.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionPanel(
            title: user.name,
            subtitle: user.department,
            trailing: StatusBadge(
              label: role.label,
              color: AppColors.primary,
              icon: Icons.badge_rounded,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.primaryDark,
                  child: Text(
                    user.avatarText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Wrap(
                    spacing: 18,
                    runSpacing: 14,
                    children: [
                      _Info(label: 'Email', value: user.email),
                      _Info(label: 'Matricule', value: user.matricule),
                      _Info(label: 'Telephone', value: user.phone),
                      _Info(label: 'Localisation', value: user.location),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          ResponsiveGrid(
            children: [
              StatCard(
                metric: KpiMetric(
                  title: 'Role',
                  value: role.label,
                  trend: 'actif',
                  description: role.workspaceLabel,
                ),
                icon: Icons.verified_user_rounded,
                color: AppColors.primary,
              ),
              const StatCard(
                metric: KpiMetric(
                  title: 'Notifications',
                  value: '4',
                  trend: '2 nouvelles',
                  description: 'messages visibles',
                ),
                icon: Icons.notifications_rounded,
                color: AppColors.warning,
              ),
              const StatCard(
                metric: KpiMetric(
                  title: 'Securite',
                  value: 'OK',
                  trend: 'demo',
                  description: 'auth future JWT/session',
                ),
                icon: Icons.lock_rounded,
                color: AppColors.success,
              ),
              const StatCard(
                metric: KpiMetric(
                  title: 'API',
                  value: 'REST',
                  trend: 'PHP POO',
                  description: 'integration future',
                ),
                icon: Icons.api_rounded,
                color: AppColors.cyan,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const ResponsiveGrid(
            minItemWidth: 360,
            maxColumns: 2,
            children: [
              _ProfileForm(),
              _SecurityPanel(),
            ],
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

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
              fontWeight: FontWeight.w800,
              fontSize: 12,
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

class _ProfileForm extends StatelessWidget {
  const _ProfileForm();

  @override
  Widget build(BuildContext context) {
    final user = SessionService.currentUser;

    return SectionPanel(
      title: 'Informations personnelles',
      subtitle: 'Formulaire mocke pour preparer la future API profil.',
      child: Column(
        children: [
          TextField(
            controller: TextEditingController(text: user.name),
            decoration: const InputDecoration(
              labelText: 'Nom complet',
              prefixIcon: Icon(Icons.person_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: TextEditingController(text: user.email),
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: TextEditingController(text: user.phone),
            decoration: const InputDecoration(
              labelText: 'Telephone',
              prefixIcon: Icon(Icons.phone_rounded),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Le profil est pret a etre synchronise.'),
                ),
              ),
              icon: const Icon(Icons.save_rounded),
              label: const Text('Enregistrer'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityPanel extends StatelessWidget {
  const _SecurityPanel();

  @override
  Widget build(BuildContext context) {
    return const SectionPanel(
      title: 'Connexion future API',
      subtitle: AppConstants.apiArchitectureNote,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PermissionLine(
            icon: Icons.http_rounded,
            text: 'Contrats de services separes des widgets.',
          ),
          _PermissionLine(
            icon: Icons.admin_panel_settings_rounded,
            text: 'Roles et permissions centralises par session.',
          ),
          _PermissionLine(
            icon: Icons.storage_rounded,
            text: 'Aucune base de donnees dans le frontend.',
          ),
          _PermissionLine(
            icon: Icons.lock_rounded,
            text: 'Session ou JWT prevu cote backend PHP.',
          ),
        ],
      ),
    );
  }
}

class _PermissionLine extends StatelessWidget {
  const _PermissionLine({required this.icon, required this.text});

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
