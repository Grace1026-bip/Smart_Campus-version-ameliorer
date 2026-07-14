import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../coeur/constantes/constantes_application.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_enseignant.dart';
import '../../../donnees/services/service_etudiant.dart';
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
    final role = SessionService.currentRole;
    if (role == UserRole.student) {
      return const _StudentApiProfileScreen();
    }
    if (role == UserRole.teacher) {
      return const _TeacherApiProfileScreen();
    }

    final user = SessionService.currentUser;

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
                  trend: 'FastAPI',
                  description: 'integration active',
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

class _StudentApiProfileScreen extends StatefulWidget {
  const _StudentApiProfileScreen();

  @override
  State<_StudentApiProfileScreen> createState() =>
      _StudentApiProfileScreenState();
}

class _StudentApiProfileScreenState extends State<_StudentApiProfileScreen> {
  late Future<Map<String, dynamic>> _future =
      EtudiantDataSource.service.profil();

  void _refresh() {
    setState(() => _future = EtudiantDataSource.service.profil());
  }

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.student,
      selectedRoute: AppRoutes.profile,
      title: 'Profil etudiant',
      subtitle: 'Identite, promotion et informations de contact.',
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return SectionPanel(
              title: 'Connexion API impossible',
              subtitle: snapshot.error.toString(),
              child: const Text(ApiConfig.serverUnavailableMessage),
            );
          }

          final profil = snapshot.data ?? {};

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionPanel(
                title: '${profil['nom_complet'] ?? '-'}',
                subtitle:
                    '${profil['promotion'] ?? '-'} - ${profil['annee_academique'] ?? '-'}',
                trailing: StatusBadge(
                  label: '${profil['statut'] ?? '-'}',
                  color: AppColors.primary,
                  icon: Icons.verified_user_rounded,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StudentProfileAvatar(profil: profil),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Wrap(
                        spacing: 18,
                        runSpacing: 14,
                        children: [
                          _Info(
                            label: 'Matricule',
                            value: '${profil['matricule'] ?? '-'}',
                          ),
                          _Info(
                            label: 'Email',
                            value: '${profil['email'] ?? '-'}',
                          ),
                          _Info(
                            label: 'Promotion',
                            value: '${profil['promotion'] ?? '-'}',
                          ),
                          _Info(
                            label: 'Niveau',
                            value: '${profil['niveau'] ?? '-'}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              ResponsiveGrid(
                children: [
                  const StatCard(
                    metric: KpiMetric(
                      title: 'Role',
                      value: 'Etudiant',
                      trend: 'actif',
                      description: 'compte approuve',
                    ),
                    icon: Icons.school_rounded,
                    color: AppColors.primary,
                  ),
                  StatCard(
                    metric: KpiMetric(
                      title: 'Promotion',
                      value: '${profil['promotion'] ?? '-'}',
                      trend: '${profil['niveau'] ?? '-'}',
                      description: 'affectation academique',
                    ),
                    icon: Icons.groups_rounded,
                    color: AppColors.success,
                  ),
                  StatCard(
                    metric: KpiMetric(
                      title: 'Annee',
                      value: '${profil['annee_academique'] ?? '-'}',
                      trend: 'active',
                      description: 'annee academique',
                    ),
                    icon: Icons.calendar_month_rounded,
                    color: AppColors.cyan,
                  ),
                  StatCard(
                    metric: KpiMetric(
                      title: 'Statut',
                      value: '${profil['statut'] ?? '-'}',
                      trend: 'session',
                      description: 'etat du compte',
                    ),
                    icon: Icons.verified_rounded,
                    color: AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              ResponsiveGrid(
                minItemWidth: 360,
                maxColumns: 2,
                children: [
                  _StudentProfileForm(profil: profil, onSaved: _refresh),
                  const _StudentSecurityPanel(),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TeacherApiProfileScreen extends StatefulWidget {
  const _TeacherApiProfileScreen();

  @override
  State<_TeacherApiProfileScreen> createState() =>
      _TeacherApiProfileScreenState();
}

class _TeacherApiProfileScreenState extends State<_TeacherApiProfileScreen> {
  late final Future<Map<String, dynamic>> _future =
      EnseignantDataSource.service.profil();

  @override
  Widget build(BuildContext context) {
    return SmartFacultyShell(
      role: UserRole.teacher,
      selectedRoute: AppRoutes.profile,
      title: 'Profil enseignant',
      subtitle: 'Identite professionnelle et rattachement academique.',
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return SectionPanel(
              title: 'Profil indisponible',
              subtitle: snapshot.error.toString(),
              child: const Text(ApiConfig.serverUnavailableMessage),
            );
          }

          final profil = snapshot.data ?? {};
          final roles =
              (profil['roles'] as List<dynamic>? ?? const []).join(', ');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionPanel(
                title: '${profil['nom_complet'] ?? '-'}',
                subtitle:
                    '${profil['grade'] ?? '-'} - ${profil['departement'] ?? '-'}',
                trailing: StatusBadge(
                  label: '${profil['statut'] ?? '-'}',
                  color: AppColors.primary,
                  icon: Icons.verified_user_rounded,
                ),
                child: Wrap(
                  spacing: 18,
                  runSpacing: 14,
                  children: [
                    _Info(label: 'Email', value: '${profil['email'] ?? '-'}'),
                    _Info(
                      label: 'Matricule agent',
                      value: '${profil['matricule_agent'] ?? '-'}',
                    ),
                    _Info(
                        label: 'Telephone',
                        value: '${profil['telephone'] ?? '-'}'),
                    _Info(label: 'Roles', value: roles.isEmpty ? '-' : roles),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              ResponsiveGrid(
                children: [
                  StatCard(
                    metric: KpiMetric(
                      title: 'Role actif',
                      value: '${profil['role_actif'] ?? '-'}',
                      trend: 'confirme par FastAPI',
                      description: 'autorisation courante',
                    ),
                    icon: Icons.verified_user_rounded,
                    color: AppColors.primary,
                  ),
                  StatCard(
                    metric: KpiMetric(
                      title: 'Grade',
                      value: '${profil['grade'] ?? '-'}',
                      trend: 'profil enseignant',
                      description: 'donnee professionnelle',
                    ),
                    icon: Icons.school_rounded,
                    color: AppColors.success,
                  ),
                  StatCard(
                    metric: KpiMetric(
                      title: 'Departement',
                      value: '${profil['departement'] ?? '-'}',
                      trend: 'rattachement',
                      description: 'faculte ou departement',
                    ),
                    icon: Icons.account_balance_rounded,
                    color: AppColors.cyan,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const SectionPanel(
                title: 'Acces du compte',
                subtitle:
                    'Les cours affiches sont limites aux affectations confirmees par FastAPI.',
                child: _PermissionLine(
                  icon: Icons.lock_rounded,
                  text:
                      'Aucun mot de passe, token ou secret n est retourne dans le profil.',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StudentProfileForm extends StatefulWidget {
  const _StudentProfileForm({
    required this.profil,
    required this.onSaved,
  });

  final Map<String, dynamic> profil;
  final VoidCallback onSaved;

  @override
  State<_StudentProfileForm> createState() => _StudentProfileFormState();
}

class _StudentProfileFormState extends State<_StudentProfileForm> {
  late final TextEditingController _nomController;
  late final TextEditingController _postnomController;
  late final TextEditingController _prenomController;
  late final TextEditingController _emailController;
  late final TextEditingController _photoController;
  late final TextEditingController _phoneController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nomController =
        TextEditingController(text: '${widget.profil['nom'] ?? ''}');
    _postnomController =
        TextEditingController(text: '${widget.profil['postnom'] ?? ''}');
    _prenomController =
        TextEditingController(text: '${widget.profil['prenom'] ?? ''}');
    _emailController =
        TextEditingController(text: '${widget.profil['email'] ?? ''}');
    _photoController =
        TextEditingController(text: '${widget.profil['photo_url'] ?? ''}');
    _phoneController =
        TextEditingController(text: '${widget.profil['telephone'] ?? ''}');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _postnomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _photoController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: 'Informations personnelles',
      subtitle: 'Ces informations sont enregistrees dans MySQL.',
      child: Column(
        children: [
          TextField(
            controller: _nomController,
            decoration: const InputDecoration(
              labelText: 'Nom',
              prefixIcon: Icon(Icons.person_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _postnomController,
            decoration: const InputDecoration(
              labelText: 'Postnom',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _prenomController,
            decoration: const InputDecoration(
              labelText: 'Prenom',
              prefixIcon: Icon(Icons.badge_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telephone',
              prefixIcon: Icon(Icons.phone_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _photoController,
            decoration: const InputDecoration(
              labelText: 'URL photo',
              prefixIcon: Icon(Icons.image_rounded),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Enregistrement...' : 'Enregistrer'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await EtudiantDataSource.service.modifierProfil({
        'nom': _nomController.text.trim(),
        'postnom': _postnomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'email': _emailController.text.trim(),
        'telephone': _phoneController.text.trim(),
        'photo_url': _photoController.text.trim(),
      });
      if (!mounted) return;
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis a jour.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _StudentProfileAvatar extends StatelessWidget {
  const _StudentProfileAvatar({required this.profil});

  final Map<String, dynamic> profil;

  @override
  Widget build(BuildContext context) {
    final photoUrl = '${profil['photo_url'] ?? ''}'.trim();
    final name = '${profil['nom_complet'] ?? ''}'.trim();
    final initials = name.isEmpty
        ? 'ET'
        : name
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

    return CircleAvatar(
      radius: 38,
      backgroundColor: AppColors.primaryDark,
      backgroundImage:
          photoUrl.isEmpty ? null : NetworkImage(_absoluteUrl(photoUrl)),
      child: photoUrl.isEmpty
          ? Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            )
          : null,
    );
  }
}

class _StudentSecurityPanel extends StatelessWidget {
  const _StudentSecurityPanel();

  @override
  Widget build(BuildContext context) {
    return const SectionPanel(
      title: 'Compte academique',
      subtitle: 'Acces limite a vos propres donnees et cours inscrits.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PermissionLine(
            icon: Icons.lock_rounded,
            text: 'Les notes visibles sont uniquement les notes publiees.',
          ),
          _PermissionLine(
            icon: Icons.menu_book_rounded,
            text: 'Les cours viennent de vos inscriptions academiques.',
          ),
          _PermissionLine(
            icon: Icons.campaign_rounded,
            text: 'La valve affiche les publications de vos cours.',
          ),
          _PermissionLine(
            icon: Icons.mark_email_unread_rounded,
            text: 'Les reclamations restent liees a votre compte.',
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
      subtitle:
          'Les espaces academiques consomment maintenant l API REST FastAPI.',
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
            text: 'Session JWT geree cote backend FastAPI.',
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

String _absoluteUrl(String value) {
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }

  final path = value.startsWith('/') ? value : '/$value';
  return '${ApiConfig.baseUrl}$path';
}
