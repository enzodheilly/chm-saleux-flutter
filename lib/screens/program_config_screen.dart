import 'package:flutter/material.dart';
import 'dart:ui'; // 👈 IMPORTANT POUR L'EFFET VERRE (ImageFilter)

const Color clubOrange = Color(0xFFF57809);
const Color darkBg = Color(0xFF0B0B0F);

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

  String _getBackgroundImage() {
    final name = widget.muscleGroup.toLowerCase();
    if (name.contains("pec")) {
      return "https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800&q=80";
    }
    if (name.contains("dos")) {
      return "https://images.unsplash.com/photo-1603287681836-e54f0e4475ac?w=800&q=80";
    }
    if (name.contains("jambe")) {
      return "https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=800&q=80";
    }
    if (name.contains("bras")) {
      return "https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800&q=80";
    }
    if (name.contains("cardio")) {
      return "https://images.unsplash.com/photo-1538805060504-6335d7aa1b7e?w=800&q=80";
    }
    return "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80";
  }

  Map<String, dynamic>? getMatchingProgram() {
    try {
      return widget.variations.firstWhere(
        (p) => p['goal'] == selectedGoal && p['level'] == selectedLevel,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchingProgram = getMatchingProgram();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: darkBg,
      body: Stack(
        children: [
          // 1. FOND IMMERSIF
          Positioned.fill(
            child: Image.network(_getBackgroundImage(), fit: BoxFit.cover),
          ),

          // Voile noir + gradient (plus clean en haut)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.55),
                    darkBg,
                  ],
                  stops: const [0.0, 0.35, 0.85],
                ),
              ),
            ),
          ),

          // 2. CONTENU
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.10),
                          ),
                        ),
                        child: Text(
                          "PERSONNALISATION",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.80),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 140),
                    children: [
                      const SizedBox(height: 6),
                      // ✅ TITRE style Progrès
                      Text(
                        widget.muscleGroup.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Ajuste ton objectif et ta difficulté.",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.62),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ✅ Header section style Training/Progress (ligne + séparateur)
                      const _PremiumSectionHeader(
                        title: "Objectif",
                        icon: Icons.flag_rounded,
                      ),
                      const SizedBox(height: 14),

                      _GlassGoalSelector(
                        selected: selectedGoal,
                        onSelect: (val) => setState(() => selectedGoal = val),
                        accent: clubOrange,
                      ),

                      const SizedBox(height: 26),

                      const _PremiumSectionHeader(
                        title: "Difficulté",
                        icon: Icons.speed_rounded,
                      ),
                      const SizedBox(height: 14),

                      _GlassLevelSelector(
                        selected: selectedLevel,
                        onSelect: (val) => setState(() => selectedLevel = val),
                        accent: clubOrange,
                      ),

                      const SizedBox(height: 20),

                      // mini info “résumé”
                      if (matchingProgram != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.10),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: clubOrange.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: clubOrange.withOpacity(0.25),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.timer_outlined,
                                      color: clubOrange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Durée estimée",
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.55,
                                            ),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 10,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${matchingProgram['estimatedDurationMin'] ?? 60} min",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. BOUTON FLOTTANT EN BAS
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                  decoration: BoxDecoration(
                    color: darkBg.withOpacity(0.62),
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                  ),
                  child: matchingProgram != null
                      ? _AppleGlassButton(
                          onTap: () {
                            // TODO: brancher navigation / lancer séance
                            // print("GO -> ID: ${matchingProgram['id']}");
                          },
                          isActive: true,
                          accentColor: clubOrange,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "LANCER LA SÉANCE",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                ),
                                child: Text(
                                  "${matchingProgram['estimatedDurationMin']} min",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _AppleGlassButton(
                          onTap: null,
                          isActive: false,
                          accentColor: Colors.red,
                          child: const Center(
                            child: Text(
                              "Aucune séance disponible",
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
}

// ==========================================
// ✅ HEADER PREMIUM (même style que Training/Progress)
// ==========================================
class _PremiumSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PremiumSectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: clubOrange),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(height: 1, color: Colors.white.withOpacity(0.08)),
        ),
      ],
    );
  }
}

// ==========================================
// WIDGETS DE STYLE (INCHANGÉS)
// ==========================================

class _AppleGlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isActive;
  final Color accentColor;
  final EdgeInsetsGeometry padding;

  const _AppleGlassButton({
    required this.child,
    this.onTap,
    this.isActive = false,
    required this.accentColor,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final tintColor = isActive
        ? accentColor.withOpacity(0.35)
        : Colors.white.withOpacity(0.08);
    final borderColor = isActive
        ? accentColor.withOpacity(0.6)
        : Colors.white.withOpacity(0.15);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: padding,
            decoration: BoxDecoration(
              color: tintColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

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
        'label': 'Volume',
        'icon': Icons.fitness_center,
      },
      {
        'key': 'perte_de_poids',
        'label': 'Perte de poids',
        'icon': Icons.local_fire_department,
      },
      {'key': 'renfo', 'label': 'Force', 'icon': Icons.flash_on},
    ];

    return Column(
      children: options.map((opt) {
        final isSelected = selected == opt['key'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _AppleGlassButton(
            onTap: () => onSelect(opt['key'] as String),
            isActive: isSelected,
            accentColor: accent,
            child: Row(
              children: [
                Icon(opt['icon'] as IconData, color: Colors.white, size: 22),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    (opt['label'] as String).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (isSelected) Icon(Icons.check_circle, color: accent),
              ],
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
    final levels = ['debutant', 'intermediaire', 'avance'];

    return Row(
      children: levels.map((lvl) {
        final isSelected = selected == lvl;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: _AppleGlassButton(
              onTap: () => onSelect(lvl),
              isActive: isSelected,
              accentColor: accent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  lvl == 'debutant'
                      ? 'debutant'
                      : (lvl == 'intermediaire' ? 'Inter.' : 'Pro'),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
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
