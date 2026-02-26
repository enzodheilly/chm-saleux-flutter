import 'package:flutter/material.dart';
import 'dart:ui';
import 'workout_player_screen.dart';

const Color clubOrange = Color(0xFFF57809);
const Color darkBg = Color(0xFF0B0B0F);
const Color surfaceColor = Color(
  0xFF1C1C22,
); // Gris très sombre pour les cartes

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
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.10),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "PERSONNALISATION",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 0.8,
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
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
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
                      const _PremiumSectionHeader(
                        title: "Objectif principal",
                        icon: Icons.flag_rounded,
                      ),
                      const SizedBox(height: 16),
                      _GlassGoalSelector(
                        selected: selectedGoal,
                        onSelect: (val) => setState(() => selectedGoal = val),
                        accent: clubOrange,
                      ),

                      const SizedBox(height: 32),

                      // ✅ SECTION NIVEAU
                      const _PremiumSectionHeader(
                        title: "Niveau de difficulté",
                        icon: Icons.local_fire_department_rounded,
                      ),
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
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: clubOrange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.timer_outlined,
                                  color: clubOrange,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Durée estimée de la séance",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${matchingProgram['estimatedDurationMin'] ?? 60} minutes",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.greenAccent.shade400,
                                size: 28,
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
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 8,
                            shadowColor: clubOrange.withOpacity(0.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "DÉMARRER LA SÉANCE",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "${matchingProgram['estimatedDurationMin']} min",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
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
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.redAccent.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: Colors.redAccent.shade200,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Aucune séance pour ces critères",
                                style: TextStyle(
                                  color: Colors.redAccent.shade100,
                                  fontWeight: FontWeight.bold,
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
      color: const Color(0xFF1C1C1E),
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
class _PremiumSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PremiumSectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: clubOrange.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: clubOrange),
        ),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
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
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? accent.withOpacity(0.15) : surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? accent : Colors.white.withOpacity(0.05),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accent.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent
                          : Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      opt['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.white54,
                      size: 20,
                    ),
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
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
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
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: clubOrange,
                        size: 24,
                      ),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
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
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? accent : surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? accent : Colors.white.withOpacity(0.05),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: accent.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    lvl['label']!,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                      fontWeight: isSelected
                          ? FontWeight.w900
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
