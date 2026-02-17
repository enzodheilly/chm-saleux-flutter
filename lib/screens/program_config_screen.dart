import 'package:flutter/material.dart';
import 'dart:ui'; // 👈 IMPORTANT POUR L'EFFET VERRE (ImageFilter)

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

  final Color clubOrange = const Color(0xFFF57809);
  final Color darkBg = const Color(0xFF0B0B0F);

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

    return Scaffold(
      backgroundColor: darkBg,
      body: Stack(
        children: [
          // 1. FOND IMMERSIF
          Positioned.fill(
            child: Image.network(_getBackgroundImage(), fit: BoxFit.cover),
          ),
          // Voile noir
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.4), darkBg],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),

          // 2. CONTENU SCROLLABLE
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        widget.muscleGroup.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      Text(
                        "Configure ta séance idéale",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 40),

                      _SectionHeader(
                        title: "TON OBJECTIF",
                        icon: Icons.flag_rounded,
                      ),
                      const SizedBox(height: 15),
                      // ✅ NOUVEAU SÉLECTEUR VERRE
                      _GlassGoalSelector(
                        selected: selectedGoal,
                        onSelect: (val) => setState(() => selectedGoal = val),
                        accent: clubOrange,
                      ),

                      const SizedBox(height: 30),

                      _SectionHeader(
                        title: "DIFFICULTÉ",
                        icon: Icons.speed_rounded,
                      ),
                      const SizedBox(height: 15),
                      // ✅ NOUVEAU SÉLECTEUR VERRE
                      _GlassLevelSelector(
                        selected: selectedLevel,
                        onSelect: (val) => setState(() => selectedLevel = val),
                        accent: clubOrange,
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. BOUTON FLOTTANT EN BAS (Version Verre Orange)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            // On utilise un ClipRRect et BackdropFilter ici aussi pour que le bas de l'écran soit flouté
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  decoration: BoxDecoration(
                    color: darkBg.withOpacity(0.6), // Fond semi-transparent
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                  ),
                  child: matchingProgram != null
                      ? _AppleGlassButton(
                          onTap: () {
                            print("GO -> ID: ${matchingProgram['id']}");
                          },
                          isActive: true, // Toujours actif (orange)
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
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
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
                          accentColor: Colors.red, // Inactif rouge
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
// WIDGETS DE STYLE (MISE À JOUR GLASS)
// ==========================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFF57809), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// 🔥 LE CŒUR DE L'EFFET APPLE GLASS 🔥
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
    // Détermine la couleur de teinte et de bordure selon l'état
    final tintColor = isActive
        ? accentColor.withOpacity(0.35)
        : Colors.white.withOpacity(0.08);
    final borderColor = isActive
        ? accentColor.withOpacity(0.6)
        : Colors.white.withOpacity(0.15);

    // ClipRRect est nécessaire pour que le flou ne dépasse pas des bords arrondis
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        // C'est ça qui fait le flou derrière le bouton !
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: padding,
            decoration: BoxDecoration(
              color: tintColor, // Couleur semi-transparente
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

// Sélecteur d'objectifs utilisant le bouton verre
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
        'label': 'Sèche',
        'icon': Icons.local_fire_department,
      },
      {'key': 'renfo', 'label': 'Force', 'icon': Icons.flash_on},
    ];
    return Column(
      children: options.map((opt) {
        final isSelected = selected == opt['key'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          // Utilisation du widget verre
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

// Sélecteur de niveaux utilisant le bouton verre
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
            // Utilisation du widget verre
            child: _AppleGlassButton(
              onTap: () => onSelect(lvl),
              isActive: isSelected,
              accentColor: accent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  lvl == 'debutant'
                      ? 'Novice'
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
