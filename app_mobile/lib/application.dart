import 'package:flutter/material.dart';

import 'coeur/constantes/constantes_application.dart';
import 'coeur/routes/routes_application.dart';
import 'coeur/theme/theme_application.dart';

class SmartFacultyApp extends StatelessWidget {
  const SmartFacultyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
