import 'package:flutter/material.dart';

class AppColors {
  static const Color brownPrimary = Color(0xFF5D4037);
  static const Color brownSecondary = Color(0xFF795548);
  static const Color beigePrimary = Color(0xFFF5EFE6);
  static const Color creamBackground = Color(0xFFFFFDF8);
  static const Color surface = Color(0xFFFAF4EA);
  static const Color terracotta = Color(0xFFC47A5A);
  static const Color textPrimary = Color(0xFF2F2522);
  static const Color textSecondary = Color(0xFF6D625D);
  static const Color border = Color(0xFFD8C8B8);
  static const Color success = Color(0xFF4F7A5A);
  static const Color warning = Color(0xFFC48A2A);
  static const Color danger = Color(0xFFB94A48);
  static const Color disabledBackground = Color(0xFFE7DDD2);
  static const Color disabledText = Color(0xFF9B8E87);

  // Alias conserves pour que les widgets existants utilisent une palette centrale.
  static const Color primaryDark = brownPrimary;
  static const Color primary = brownSecondary;
  static const Color primarySoft = beigePrimary;
  static const Color background = creamBackground;
  static const Color scaffold = creamBackground;
  static const Color surfaceMuted = disabledBackground;
  static const Color info = terracotta;
  static const Color secondary = brownSecondary;

  // Couleurs de categorie attenuees conservees pour les graphiques et comparaisons non semantiques.
  static const Color cyan = Color(0xFF6F8A8A);
  static const Color violet = Color(0xFF8A6F8A);
  static const Color sidebarText = Color(0xFFF9F1E7);
  static const Color sidebarMuted = Color(0xFFD8C8B8);
}
