import 'package:flutter/material.dart';
import 'systeme_conception/couleurs.dart';
import 'fonctionnalites/authentification/presentations/ecrans/ecran_splash.dart';

void main() {
  runApp(const ApplicationSmartCampus());
}

class ApplicationSmartCampus extends StatelessWidget {
  const ApplicationSmartCampus({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Campus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: CouleursSmartCampus.fondPrincipal,
        primaryColor: CouleursSmartCampus.principal,
        fontFamily: 'Segoe UI', // Rendu net et propre sur Google Chrome
      ),
      home: const EcranSplash(),
    );
  }
}