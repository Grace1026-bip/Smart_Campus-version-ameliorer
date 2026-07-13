import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_app/coeur/theme/couleurs_application.dart';
import 'package:smart_campus_app/coeur/theme/theme_application.dart';
import 'package:smart_campus_app/fonctionnalites/authentification/presentation/ecran_connexion.dart';
import 'package:smart_campus_app/fonctionnalites/authentification/presentation/ecran_demande_inscription.dart';

void main() {
  test('AppTheme expose la palette beige et marron officielle', () {
    final theme = AppTheme.light;

    expect(theme.colorScheme.primary, AppColors.brownPrimary);
    expect(theme.colorScheme.secondary, AppColors.terracotta);
    expect(theme.scaffoldBackgroundColor, AppColors.creamBackground);
    expect(theme.cardTheme.color, AppColors.surface);
    expect(theme.inputDecorationTheme.fillColor, AppColors.surface);
    expect(theme.elevatedButtonTheme.style?.backgroundColor?.resolve({}),
        AppColors.brownPrimary);
  });

  testWidgets('la connexion utilise le bouton principal du theme',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const LoginScreen(),
      ),
    );

    final button = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton).last,
    );
    expect(
      Theme.of(tester.element(find.byType(LoginScreen)))
          .elevatedButtonTheme
          .style
          ?.backgroundColor
          ?.resolve({}),
      AppColors.brownPrimary,
    );
    expect(button, isNotNull);
    expect(find.text('Connexion'), findsOneWidget);
  });

  testWidgets('la demande dinscription partage la surface du theme',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const RegistrationRequestScreen(),
      ),
    );

    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.text('Etudiant'), findsOneWidget);
    expect(find.text('Enseignant'), findsOneWidget);
    expect(AppTheme.light.inputDecorationTheme.fillColor, AppColors.surface);
  });
}
