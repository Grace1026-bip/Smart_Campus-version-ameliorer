import '../../../accueil_principal/presentation/ecrans/dashboard_doyen.dart';
import '../../../accueil_principal/presentation/ecrans/dashboard_chef_promotion.dart';
import '../../../accueil_principal/presentation/ecrans/dashboard_professeur.dart';
import 'package:flutter/material.dart';
import '../../../../../systeme_conception/couleurs.dart';
import '../../../accueil_principal/presentation/ecrans/dashboard_appariteur.dart';
// AJOUT DE L'IMPORT DE LA PAGE SURVEILLANT :
import '../../../accueil_principal/presentation/ecrans/dashboard_surveillant.dart';

class EcranConnexion extends StatefulWidget {
  const EcranConnexion({Key? key}) : super(key: key);

  @override
  State<EcranConnexion> createState() => _EcranConnexionState();
}

class _EcranConnexionState extends State<EcranConnexion> {
  final _formKey = GlobalKey<FormState>();
  String _roleSelectionne = 'Appariteur';
  bool _motDePasseMasque = true;

  final List<String> _roles = [
    'Appariteur',
    'Chef de promotion',
    'Surveillant',
    'Professeur',
    'Doyen'
  ];

  @override
  Widget build(BuildContext context) {
    final tailleEcran = MediaQuery.of(context).size;
    final estModeDesktop = tailleEcran.width > 800;

    return Scaffold(
      backgroundColor: CouleursSmartCampus.fondPrincipal,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: estModeDesktop ? 480 : double.infinity,
            padding: const EdgeInsets.all(40.0),
            decoration: BoxDecoration(
              color: CouleursSmartCampus.fondSurface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: CouleursSmartCampus.principal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                              color: CouleursSmartCampus.principal,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'SMART CAMPUS',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: CouleursSmartCampus.textePrincipal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Connexion à votre espace',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: CouleursSmartCampus.textePrincipal),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Veuillez entrer vos identifiants académiques.',
                    style: TextStyle(fontSize: 14, color: CouleursSmartCampus.texteSecondaire),
                  ),
                  const SizedBox(height: 32),

                  // SÉLECTEUR DE RÔLE
                  const Text(
                    'Votre rôle institutionnel',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CouleursSmartCampus.textePrincipal),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: CouleursSmartCampus.fondPrincipal,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _roleSelectionne,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: CouleursSmartCampus.texteSecondaire),
                        items: _roles.map((String role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(role, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: CouleursSmartCampus.textePrincipal)),
                          );
                        }).toList(),
                        onChanged: (String? valeur) {
                          if (valeur != null) {
                            setState(() {
                              _roleSelectionne = valeur;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // CHAMP IDENTIFIANT
                  const Text(
                    'Identifiant ou Email',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CouleursSmartCampus.textePrincipal),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'ex: matricule@upc.cd',
                      hintStyle: const TextStyle(color: CouleursSmartCampus.texteSecondaire, fontSize: 14),
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: CouleursSmartCampus.texteSecondaire),
                      filled: true,
                      fillColor: CouleursSmartCampus.fondPrincipal,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: CouleursSmartCampus.principal, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // CHAMP MOT DE PASSE
                  const Text(
                    'Mot de passe',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CouleursSmartCampus.textePrincipal),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    obscureText: _motDePasseMasque,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: const TextStyle(color: CouleursSmartCampus.texteSecondaire, fontSize: 14),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: CouleursSmartCampus.texteSecondaire),
                      suffixIcon: IconButton(
                        icon: Icon(_motDePasseMasque ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: CouleursSmartCampus.texteSecondaire),
                        onPressed: () => setState(() => _motDePasseMasque = !_motDePasseMasque),
                      ),
                      filled: true,
                      fillColor: CouleursSmartCampus.fondPrincipal,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: CouleursSmartCampus.principal, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // BOUTON DE CONNEXION INTELLIGENT
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                      // RE-ROUTAGE PAR PROFIL SMART CAMPUS
                        if (_roleSelectionne == 'Surveillant') {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const DashboardSurveillant()),
                          );
                        } else if (_roleSelectionne == 'Professeur') {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const DashboardProfesseur()),
                          );
                        } else if (_roleSelectionne == 'Chef de promotion') {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const DashboardChefPromotion()),
                          );
                        } else if (_roleSelectionne == 'Doyen') {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const DashboardDoyen()),
                          );
                        } else {
                          // Par défaut : l'Appariteur
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const DashboardAppariteur()),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CouleursSmartCampus.principal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Se connecter de façon sécurisée', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}