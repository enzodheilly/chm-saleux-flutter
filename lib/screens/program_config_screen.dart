import 'package:flutter/material.dart';
import 'dart:ui';
import 'workout_player_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/design_system.dart';

// Alias locaux vers le système de design partagé (AppColors) — conservés
// pour ne pas avoir à renommer tous les usages dans ce fichier.
const Color clubOrange = AppColors.accent;
const Color darkBg = AppColors.bg;
const Color surfaceColor = AppColors.surface;

class ProgramConfigScreen extends StatefulWidget {
  final String muscleGroup;
  final List<dynamic> variations;

  const ProgramConfigScreen({
    super.key,
    required this.muscleGroup,
    required this.variations,
  });

  @override
  State<ProgramConfigScreen> createState() => _ProgramConfigScreenState();
}

class _ProgramConfigScreenState extends State<ProgramConfigScreen> {
  String selectedGoal = "prise_de_masse";
  String selectedLevel = "intermediaire";

  Map<String, dynamic>? getMatchingProgram() {
    try {
      return widget.variations.firstWhere(
        (p) => p['goal'] == selectedGoal && p['level'] == selectedLevel,
      );
    } catch (e) {
      return null;
    }
  }

  // ✅ LOGIQUE D'IMAGE : On utilise tes assets locaux pour une cohérence parfaite
  String _getBackgroundImage() {
    final name = widget.muscleGroup.toLowerCase().trim();
    if (name.contains("pec") ||
        name.contains("chest") ||
        name.contains("push")) {
      return "assets/images/pecs.jpg";
    }
    if (name.contains("dos") ||
        name.contains("back") ||
        name.contains("pull")) {
      return "assets/images/dos.jpg";
    }
    if (name.contains("jambe") ||
        name.contains("leg") ||
        name.contains("bas")) {
      return "assets/images/jambes.jpg";
    }
    if (name.contains("bras") ||
        name.contains("arm") ||
        name.contains("biceps") ||
        name.contains("triceps")) {
      return "assets/images/bras.jpg";
    }
    if (name.contains("epaule") || name.contains("épaule")) {
      return "assets/images/epaules.jpg";
    }
    if (name.contains("abdo") || name.contains("abs")) {
      return "assets/images/abdos.jpg";
    }
    if (name.contains("cardio") || name.contains("run")) {
      return "assets/images/cardio.jpg";
    }
    if (name.contains("mobil")) {
      return "assets/images/mobilite.jpg";
    }
    if (name.contains("perte") || name.contains("poids")) {
      return "assets/images/perte_poids.jpg";
    }
    if (name.contains("full") ||
        name.contains("body") ||
        name.contains("haut")) {
      return "assets/images/fullbody.jpg";
    }
    return "assets/images/default.jpg";
  }

  @override
  Widget build(BuildContext context) {
    final matchingProgram = getMatchingProgram();
    final imageUrl = _getBackgroundImage();

    return Scaffold(
      backgroundColor: darkBg,
      body: Stack(
        children: [
          // 1. FOND IMMERSIF LOCAL
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height:
                MediaQuery.of(context).size.height *
                0.55, // Prend 55% de l'écran
            child: imageUrl.startsWith('http')
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _fallbackImage(),
                  )
                : Image.asset(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _fallbackImage(),
                  ),
          ),

          // 2. DÉGRADÉ PREMIUM (Sombre en bas, transparent en haut)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    darkBg.withOpacity(0.4),
                    darkBg.withOpacity(0.95),
                    darkBg,
                  ],
                  stops: const [0.0, 0.25, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 3. CONTENU DÉROULANT
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.10),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(width: 3, height: 11, color: clubOrange),
                            const SizedBox(width: 8),
                            Text(
                              "PERSONNALISATION",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
                    children: [
                      // Espace pour laisser voir l'image
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.12,
                      ),

                      // ✅ TITRE
                      Text(
                        widget.muscleGroup.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Configure ton entraînement sur-mesure en fonction de tes objectifs du jour.",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ✅ SECTION OBJECTIF
                      const _PremiumSectionHeader(title: "Objectif principal"),
                      const SizedBox(height: 16),
                      _GlassGoalSelector(
                        selected: selectedGoal,
                        onSelect: (val) => setState(() => selectedGoal = val),
                        accent: clubOrange,
                      ),

                      const SizedBox(height: 32),

                      // ✅ SECTION NIVEAU
                      const _PremiumSectionHeader(title: "Niveau de difficulté"),
                      const SizedBox(height: 16),
                      _GlassLevelSelector(
                        selected: selectedLevel,
                        onSelect: (val) => setState(() => selectedLevel = val),
                        accent: clubOrange,
                      ),

                      const SizedBox(height: 32),

                      // ✅ RÉSUMÉ INFO
                      if (matchingProgram != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                color: AppColors.accent,
                                size: 22,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Durée estimée de la séance",
                                      style: AppText.label,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${matchingProgram['estimatedDurationMin'] ?? 60} minutes",
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const StatusDot(
                                color: AppColors.success,
                                label: "Prêt",
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. BOUTON FLOTTANT EN BAS (Super Premium)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    MediaQuery.of(context).padding.bottom + 20,
                  ),
                  decoration: BoxDecoration(
                    color: darkBg.withOpacity(0.85),
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                  ),
                  child: matchingProgram != null
                      ? ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WorkoutPlayerScreen(
                                  routineId: matchingProgram['id'],
                                  routineName:
                                      matchingProgram['name'] ??
                                      widget.muscleGroup,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: clubOrange,
                            foregroundColor: AppColors.bg,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "DÉMARRER LA SÉANCE",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.bg.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(AppRadius.sm / 2),
                                ),
                                child: Text(
                                  "${matchingProgram['estimatedDurationMin']} min",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.play_arrow_rounded, size: 20),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: AppColors.danger.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.danger,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Aucune séance pour ces critères",
                                style: TextStyle(
                                  color: AppColors.danger.withOpacity(0.9),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Icon(
          Icons.fitness_center_rounded,
          size: 80,
          color: Colors.white.withOpacity(0.05),
        ),
      ),
    );
  }
}

// ==========================================
// HEADER DE SECTION
// ==========================================
// Trait d'accent + libellé tracké — remplace l'icône répétée dans une
// pastille colorée par le composant partagé [SectionHeader].
class _PremiumSectionHeader extends StatelessWidget {
  final String title;

  const _PremiumSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => SectionHeader(title: title);
}

// ==========================================
// SELECTEURS (Glassmorphism & Animés)
// ==========================================

class _GlassGoalSelector extends StatelessWidget {
  final String selected;
  final Function(String) onSelect;
  final Color accent;

  const _GlassGoalSelector({
    required this.selected,
    required this.onSelect,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      {
        'key': 'prise_de_masse',
        'label': 'Volume Musculaire',
        'icon': Icons.fitness_center_rounded,
        'desc': 'Pour construire du muscle et de la masse',
      },
      {
        'key': 'perte_de_poids',
        'label': 'Perte de poids',
        'icon': Icons.local_fire_department_rounded,
        'desc': 'Intensité élevée pour brûler des calories',
      },
      {
        'key': 'renfo',
        'label': 'Force Pure',
        'icon': Icons.flash_on_rounded,
        'desc': 'Charges lourdes et temps de repos longs',
      },
    ];

    return Column(
      children: options.map((opt) {
        final isSelected = selected == opt['key'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => onSelect(opt['key'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? accent.withOpacity(0.08) : surfaceColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isSelected ? accent : AppColors.line,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    opt['icon'] as IconData,
                    color: isSelected ? accent : Colors.white54,
                    size: 20,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (opt['label'] as String).toUpperCase(),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          opt['desc'] as String,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: accent,
                        size: 22,
                      ),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.line,
                          width: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _GlassLevelSelector extends StatelessWidget {
  final String selected;
  final Function(String) onSelect;
  final Color accent;

  const _GlassLevelSelector({
    required this.selected,
    required this.onSelect,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final levels = [
      {'key': 'debutant', 'label': 'Débutant'},
      {'key': 'intermediaire', 'label': 'Intermédiaire'},
      {'key': 'avance', 'label': 'Avancé'},
    ];

    return Row(
      children: levels.map((lvl) {
        final isSelected = selected == lvl['key'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onSelect(lvl['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? accent : surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: isSelected ? accent : AppColors.line,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    lvl['label']!,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.bg
                          : Colors.white.withOpacity(0.6),
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
