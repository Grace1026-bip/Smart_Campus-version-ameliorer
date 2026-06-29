import 'package:flutter/material.dart';

import '../../../coeur/constantes/constantes_application.dart';
import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_authentification.dart';
import '../../../commun/composants/logo_application.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(
    text: 'admin@smartfaculty.test',
  );
  final _passwordController = TextEditingController(text: 'Admin@123456');
  UserRole _selectedRole = UserRole.administrator;
  bool _passwordHidden = true;
  bool _loading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primarySoft, AppColors.background],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 940;
              return Row(
                children: [
                  if (wide)
                    const Expanded(
                      flex: 11,
                      child: _InstitutionPanel(),
                    ),
                  Expanded(
                    flex: 9,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(wide ? 42 : 20),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 470),
                          child: _LoginForm(
                            formKey: _formKey,
                            selectedRole: _selectedRole,
                            identifierController: _identifierController,
                            passwordController: _passwordController,
                            passwordHidden: _passwordHidden,
                            loading: _loading,
                            onRoleChanged: _changeRole,
                            onTogglePassword: () => setState(
                              () => _passwordHidden = !_passwordHidden,
                            ),
                            onSubmit: _submit,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final user = await AuthDataSource.service.login(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
      );
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacementNamed(AppRoutes.dashboardForRole(user.role));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeRole(UserRole role) {
    setState(() => _selectedRole = role);
    final defaults = _defaultCredentials(role);
    _identifierController.text = defaults[0];
    _passwordController.text = defaults[1];
  }

  List<String> _defaultCredentials(UserRole role) {
    switch (role) {
      case UserRole.student:
        return ['etudiant@smartfaculty.test', 'Etudiant@123456'];
      case UserRole.teacher:
        return ['enseignant@smartfaculty.test', 'password123'];
      case UserRole.administrator:
        return ['admin@smartfaculty.test', 'Admin@123456'];
      case UserRole.apparitor:
        return ['paritaire@smartfaculty.test', 'Paritaire@123456'];
      case UserRole.promotionChief:
        return ['icp@smartfaculty.test', 'Icp@123456'];
      case UserRole.dean:
        return ['doyen@smartfaculty.test', 'Doyen@123456'];
    }
  }
}

class _InstitutionPanel extends StatelessWidget {
  const _InstitutionPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.all(44),
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppLogo(onDark: true),
          Spacer(),
          _AcademicVisual(),
          SizedBox(height: 34),
          Text(
            'Portail academique moderne',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              height: 1.08,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Un espace unique pour suivre notes, reclamations, stages, projets, profils et indicateurs de la faculte.',
            style: TextStyle(
              color: AppColors.sidebarText,
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          Spacer(),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SignalChip(label: 'Mode demo'),
              _SignalChip(label: 'Responsive web/mobile'),
              _SignalChip(label: 'Pret API REST PHP'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AcademicVisual extends StatelessWidget {
  const _AcademicVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              _VisualTile(
                icon: Icons.account_balance_rounded,
                label: 'Faculte',
                value: 'FASI',
                color: Colors.white,
              ),
              SizedBox(width: 12),
              _VisualTile(
                icon: Icons.groups_rounded,
                label: 'Etudiants',
                value: '1 284',
                color: AppColors.success,
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _VisualTile(
                icon: Icons.insights_rounded,
                label: 'Reussite',
                value: '78,6%',
                color: AppColors.warning,
              ),
              SizedBox(width: 12),
              _VisualTile(
                icon: Icons.mark_email_unread_rounded,
                label: 'Reclam.',
                value: '142',
                color: AppColors.primarySoft,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VisualTile extends StatelessWidget {
  const _VisualTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 18),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.sidebarMuted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalChip extends StatelessWidget {
  const _SignalChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.selectedRole,
    required this.identifierController,
    required this.passwordController,
    required this.passwordHidden,
    required this.loading,
    required this.onRoleChanged,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final UserRole selectedRole;
  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final bool passwordHidden;
  final bool loading;
  final ValueChanged<UserRole> onRoleChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(),
            const SizedBox(height: 30),
            Text('Connexion',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(
              'Accedez a votre espace selon votre role institutionnel.',
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 26),
            DropdownButtonFormField<UserRole>(
              initialValue: selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role institutionnel',
                prefixIcon: Icon(Icons.badge_rounded),
              ),
              items: UserRole.values
                  .map(
                    (role) => DropdownMenuItem<UserRole>(
                      value: role,
                      child: Text(role.label),
                    ),
                  )
                  .toList(),
              onChanged: (role) {
                if (role != null) onRoleChanged(role);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: identifierController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email ou matricule',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez saisir un identifiant.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              obscureText: passwordHidden,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  tooltip: passwordHidden
                      ? 'Afficher le mot de passe'
                      : 'Masquer le mot de passe',
                  onPressed: onTogglePassword,
                  icon: Icon(
                    passwordHidden
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.length < 4) {
                  return 'Mot de passe trop court.';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.forgotPassword),
                child: const Text('Mot de passe oublie'),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: loading ? null : onSubmit,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login_rounded),
                label: Text(loading ? 'Connexion...' : 'Se connecter'),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              AppConstants.apiFutureNote,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
