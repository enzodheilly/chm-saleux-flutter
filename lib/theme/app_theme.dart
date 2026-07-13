import 'package:flutter/material.dart';

/// Système de design partagé par toute l'application — palette, typographie,
/// rayons et espacements. Toute nouvelle UI doit passer par ces constantes
/// plutôt que de redéfinir ses propres couleurs par écran.
class AppColors {
  AppColors._();

  static const Color bg = Color(0xFF000000);
  static const Color surface = Color(0xFF111113);
  static const Color surfaceAlt = Color(0xFF17171A);
  static const Color line = Color(0x14FFFFFF);

  /// Couleur d'accent unique de l'app — à utiliser avec parcimonie
  /// (CTA principal, indicateurs actifs), jamais en fond décoratif systématique.
  static const Color accent = Color(0xFFF57706);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF83878F);

  static const Color success = Color(0xFF34D399);
  static const Color danger = Color(0xFFFF4757);
  static const Color warning = Color(0xFFF1C40F);
  static const Color info = Color(0xFF3B82F6);
}

class AppRadius {
  AppRadius._();
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double pill = 999;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppText {
  AppText._();

  /// Grand titre de page.
  static const TextStyle display = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.05,
  );

  /// Titre de carte / section importante.
  static const TextStyle title = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
  );

  static const TextStyle subtitle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  /// Libellé de section tracké (utilisé avec [SectionHeader]).
  static const TextStyle eyebrow = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.6,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static const TextStyle bodyMuted = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle label = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static const TextStyle value = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  /// Texte de bouton principal (sur fond accent, donc en `AppColors.bg`).
  static const TextStyle button = TextStyle(
    color: AppColors.bg,
    fontSize: 13,
    fontWeight: FontWeight.w800,
    letterSpacing: 1,
  );
}
