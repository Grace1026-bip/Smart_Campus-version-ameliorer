import 'package:flutter/material.dart';

import 'coeur/constantes/constantes_application.dart';
import 'coeur/routes/routes_application.dart';
import 'coeur/theme/theme_application.dart';
import 'coeur/theme/couleurs_application.dart';
import 'donnees/modeles/modeles_faculte.dart';
import 'donnees/services/service_authentification.dart';

class SmartFacultyApp extends StatefulWidget {
  const SmartFacultyApp({super.key});

  @override
  State<SmartFacultyApp> createState() => _SmartFacultyAppState();
}

class _SmartFacultyAppState extends State<SmartFacultyApp> {
  late final Future<FacultyUser?> _sessionFuture =
      AuthDataSource.service.restoreSession();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FacultyUser?>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final ready = snapshot.connectionState == ConnectionState.done;

        if (!ready) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const _StartupScreen(),
          );
        }

        return MaterialApp(
          key: ValueKey(user?.role),
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          initialRoute: user != null
              ? AppRoutes.dashboardForRole(user.role)
              : AppRoutes.login,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
