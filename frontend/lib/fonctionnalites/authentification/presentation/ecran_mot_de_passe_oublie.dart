import 'package:flutter/material.dart';

import '../../../coeur/theme/couleurs_application.dart';
import '../../../commun/composants/logo_application.dart';
import '../../../donnees/services/service_api.dart';
import '../../../donnees/services/service_reinitialisations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _reference = TextEditingController();
  final _jeton = TextEditingController();
  final _nouveauMotDePasse = TextEditingController();
  bool _envoi = false;
  String? _message;
  String? _erreur;

  @override
  void dispose() {
    _email.dispose();
    _reference.dispose();
    _jeton.dispose();
    _nouveauMotDePasse.dispose();
    super.dispose();
  }

  Future<void> _demander() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _erreur = 'Saisissez une adresse email valide.');
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
      _message = null;
    });
    try {
      await ReinitialisationsDataSource.service.demander(email);
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _message =
            'Votre demande a ete enregistree. Une autorite academique doit la traiter.';
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _erreur = error.messagePourUtilisateur;
      });
    }
  }

  Future<void> _reinitialiser() async {
    if (_reference.text.trim().isEmpty ||
        _jeton.text.trim().isEmpty ||
        _nouveauMotDePasse.text.length < 8) {
      setState(() => _erreur = 'Reference, jeton et mot de passe valide sont requis.');
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
      _message = null;
    });
    try {
      await ReinitialisationsDataSource.service.reinitialiser(
        reference: _reference.text,
        jeton: _jeton.text,
        nouveauMotDePasse: _nouveauMotDePasse.text,
      );
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _message = 'Mot de passe reinitialise. Vous pouvez vous connecter.';
        _jeton.clear();
        _nouveauMotDePasse.clear();
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _erreur = error.messagePourUtilisateur;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 470),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(),
                const SizedBox(height: 32),
                Text(
                  'Recuperation du compte',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Saisissez votre email institutionnel pour recevoir les instructions de reinitialisation.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email institutionnel',
                    prefixIcon: Icon(Icons.mail_rounded),
                  ),
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 12),
                  Text(_erreur!, style: const TextStyle(color: AppColors.danger)),
                ],
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(_message!, style: const TextStyle(color: AppColors.success)),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _envoi ? null : _demander,
                    icon: const Icon(Icons.send_rounded),
                    label: Text(_envoi ? 'Envoi...' : 'Envoyer la demande'),
                  ),
                ),
                const SizedBox(height: 26),
                const Divider(),
                const SizedBox(height: 18),
                Text('J ai recu un jeton', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                TextField(
                  controller: _reference,
                  decoration: const InputDecoration(labelText: 'Reference de la demande'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _jeton,
                  decoration: const InputDecoration(labelText: 'Jeton temporaire'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nouveauMotDePasse,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Nouveau mot de passe'),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _envoi ? null : _reinitialiser,
                    icon: const Icon(Icons.lock_reset_rounded),
                    label: const Text('Definir le nouveau mot de passe'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
