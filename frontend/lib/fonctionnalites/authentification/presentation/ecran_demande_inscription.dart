import 'package:flutter/material.dart';

import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/services/service_inscriptions.dart';

class RegistrationRequestScreen extends StatefulWidget {
  const RegistrationRequestScreen({super.key});

  @override
  State<RegistrationRequestScreen> createState() =>
      _RegistrationRequestScreenState();
}

class _RegistrationRequestScreenState extends State<RegistrationRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nom = TextEditingController();
  final _prenom = TextEditingController();
  final _matricule = TextEditingController();
  final _promotionId = TextEditingController(text: '1');
  final _matriculeAgent = TextEditingController();
  final _departement = TextEditingController(text: 'Informatique');
  TypeDemandeInscription _type = TypeDemandeInscription.etudiant;
  bool _loading = false;
  DemandeInscription? _resultat;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _nom.dispose();
    _prenom.dispose();
    _matricule.dispose();
    _promotionId.dispose();
    _matriculeAgent.dispose();
    _departement.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demande d inscription'),
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brownPrimary.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<TypeDemandeInscription>(
                      segments: TypeDemandeInscription.values
                          .map(
                            (type) => ButtonSegment(
                              value: type,
                              label: Text(type.label),
                              icon: Icon(
                                type == TypeDemandeInscription.etudiant
                                    ? Icons.school_rounded
                                    : Icons.badge_rounded,
                              ),
                            ),
                          )
                          .toList(),
                      selected: {_type},
                      onSelectionChanged: (value) {
                        setState(() => _type = value.single);
                      },
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _nom,
                      decoration: const InputDecoration(labelText: 'Nom'),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _prenom,
                      decoration: const InputDecoration(labelText: 'Prenom'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (!text.contains('@')) return 'Email invalide.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      decoration:
                          const InputDecoration(labelText: 'Mot de passe'),
                      obscureText: true,
                      validator: (value) {
                        if ((value ?? '').length < 8) {
                          return 'Minimum 8 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_type == TypeDemandeInscription.etudiant) ...[
                      TextFormField(
                        controller: _matricule,
                        decoration:
                            const InputDecoration(labelText: 'Matricule'),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _promotionId,
                        decoration:
                            const InputDecoration(labelText: 'ID promotion'),
                        keyboardType: TextInputType.number,
                        validator: _required,
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _matriculeAgent,
                        decoration:
                            const InputDecoration(labelText: 'Matricule agent'),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _departement,
                        decoration:
                            const InputDecoration(labelText: 'Departement'),
                        validator: _required,
                      ),
                    ],
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(_loading ? 'Envoi...' : 'Envoyer'),
                    ),
                    if (_resultat != null) ...[
                      const SizedBox(height: 18),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.08),
                          border: Border.all(color: AppColors.success),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            'Reference ${_resultat!.reference} - ${_resultat!.statut}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Champ requis.';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final demande = await InscriptionDataSource.service.creerDemande(
        DemandeInscriptionPayload(
          type: _type,
          email: _email.text,
          motDePasse: _password.text,
          nom: _nom.text,
          prenom: _prenom.text,
          matricule:
              _type == TypeDemandeInscription.etudiant ? _matricule.text : null,
          promotionId: _type == TypeDemandeInscription.etudiant
              ? int.tryParse(_promotionId.text)
              : null,
          matriculeAgent: _type == TypeDemandeInscription.enseignant
              ? _matriculeAgent.text
              : null,
          departement: _type == TypeDemandeInscription.enseignant
              ? _departement.text
              : null,
        ),
      );
      if (mounted) setState(() => _resultat = demande);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
