import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/faculty_models.dart';
import '../../../data/services/session_service.dart';
import '../../../shared/widgets/app_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  UserRole _selectedRole = UserRole.administrator;
  bool _passwordHidden = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 920;
            return Row(
              children: [
                if (wide) Expanded(child: _InstitutionPanel()),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: _LoginForm(
                          formKey: _formKey,
                          selectedRole: _selectedRole,
                          passwordHidden: _passwordHidden,
                          onRoleChanged: (role) =>
                              setState(() => _selectedRole = role),
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
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    SessionService.connectAs(_selectedRole);
    Navigator.of(
      context,
    ).pushReplacementNamed(AppRoutes.dashboardForRole(_selectedRole));
  }
}

class _InstitutionPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.all(44),
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppLogo(onDark: true),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.account_balance_rounded,
                  color: Colors.white,
                  size: 44,
                ),
                SizedBox(height: 22),
                Text(
                  'Pilotage académique moderne',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Une interface unique pour suivre les réclamations, projets, stages, notes et analytics de la faculté.',
                  style: TextStyle(
                    color: Color(0xFFE6EEF7),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SignalChip(label: 'Mock data'),
              _SignalChip(label: 'Responsive'),
              _SignalChip(label: 'Prêt PHP POO'),
            ],
          ),
        ],
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
    required this.passwordHidden,
    required this.onRoleChanged,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final UserRole selectedRole;
  final bool passwordHidden;
  final ValueChanged<UserRole> onRoleChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLogo(),
          const SizedBox(height: 34),
          Text('Connexion', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text(
            'Accédez à votre espace académique selon votre rôle.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 28),
          DropdownButtonFormField<UserRole>(
            initialValue: selectedRole,
            decoration: const InputDecoration(
              labelText: 'Rôle institutionnel',
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
            initialValue: AppConstants.demoEmail,
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
            initialValue: 'password',
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
              child: const Text('Mot de passe oublié'),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.login_rounded),
              label: const Text('Se connecter'),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            AppConstants.apiFutureNote,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
