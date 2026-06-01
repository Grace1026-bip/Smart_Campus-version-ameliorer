import 'package:flutter/material.dart';

import 'package:smart_campus_app/theme/theme_clair.dart';
import 'package:smart_campus_app/fonctionnalites/authentification/ecrans/ecran_connexion.dart';

void main() {
  runApp(const SmartCampusApp());
}

class SmartCampusApp extends StatelessWidget {
  const SmartCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeClair.theme,

      home: const EcranConnexion(),
    );
  }
}