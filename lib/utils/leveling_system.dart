import 'dart:math' as math; // ✅ L'import doit toujours être en haut du fichier

class LevelingSystem {
  // Constante de base. Plus elle est élevée, plus il est dur de monter de niveau.
  static const double _xpMultiplier = 150.0;

  /// Calcule le niveau actuel basé sur l'XP total
  static int getLevel(int totalXp) {
    // Formule inverse (Ex: Niveau = racine carrée de (XP / Multiplier))
    // Avec multiplier = 150:
    // 0 XP -> Lvl 1
    // 150 XP -> Lvl 2
    // 600 XP -> Lvl 3
    // 1350 XP -> Lvl 4
    if (totalXp < 0) return 1;
    double rawLevel = (totalXp / _xpMultiplier);
    return rawLevel.isNaN ? 1 : rawLevel.abs().sqrt().floor() + 1;
  }

  /// Calcule l'XP total requis pour atteindre un niveau spécifique
  static int getXpRequiredForLevel(int level) {
    if (level <= 1) return 0;
    return ((level - 1) * (level - 1) * _xpMultiplier).round();
  }

  /// Calcule l'XP nécessaire pour passer du niveau actuel au niveau suivant
  static int getXpToNextLevel(int totalXp) {
    int currentLevel = getLevel(totalXp);
    int nextLevelXp = getXpRequiredForLevel(currentLevel + 1);
    return nextLevelXp - totalXp;
  }

  /// Calcule le pourcentage de progression vers le prochain niveau (de 0.0 à 1.0)
  static double getProgressToNextLevel(int totalXp) {
    int currentLevel = getLevel(totalXp);
    int currentLevelBaseXp = getXpRequiredForLevel(currentLevel);
    int nextLevelXp = getXpRequiredForLevel(currentLevel + 1);

    int xpEarnedInCurrentLevel = totalXp - currentLevelBaseXp;
    int xpNeededForNextLevel = nextLevelXp - currentLevelBaseXp;

    if (xpNeededForNextLevel == 0) return 0.0;
    return xpEarnedInCurrentLevel / xpNeededForNextLevel;
  }
}

// Extension pour la racine carrée
extension on double {
  double sqrt() => math.sqrt(this);
}
