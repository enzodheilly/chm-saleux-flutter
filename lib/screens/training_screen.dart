import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/routine_service.dart';
import 'program_config_screen.dart';

class TrainingScreen extends StatefulWidget {
  final DateTime? targetDate;

  const TrainingScreen({super.key, this.targetDate});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  late Future<List<dynamic>> _programsFuture;

  static const Color clubOrange = Color(0xFFF57809);
  static const Color darkBg = Color(0xFF0B0B0F);

  @override
  void initState() {
    super.initState();
    _programsFuture = RoutineService().getAllPrograms();
  }

  String _getImageForGroup(String groupName) {
    final name = groupName.toLowerCase().trim();
    if (name.contains("pec") ||
        name.contains("chest") ||
        name.contains("push")) {
      return "https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800&q=80";
    }
    if (name.contains("dos") ||
        name.contains("back") ||
        name.contains("row") ||
        name.contains("pull")) {
      return "https://images.unsplash.com/photo-1603287681836-e54f0e4475ac?w=800&q=80";
    }
    if (name.contains("jambe") ||
        name.contains("leg") ||
        name.contains("squat")) {
      return "https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=800&q=80";
    }
    if (name.contains("bras") ||
        name.contains("arm") ||
        name.contains("biceps") ||
        name.contains("triceps")) {
      return "https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800&q=80";
    }
    if (name.contains("epaule") || name.contains("shoulder")) {
      return "https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?w=800&q=80";
    }
    if (name.contains("abdo") ||
        name.contains("abs") ||
        name.contains("core")) {
      return "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800&q=80";
    }
    if (name.contains("cardio") ||
        name.contains("run") ||
        name.contains("velo") ||
        name.contains("bike")) {
      return "https://images.unsplash.com/photo-1538805060504-6335d7aa1b7e?w=800&q=80";
    }
    if (name.contains("mobil") ||
        name.contains("stretch") ||
        name.contains("souplesse")) {
      return "https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800&q=80";
    }
    if (name.contains("full") || name.contains("body")) {
      return "https://images.unsplash.com/photo-1517963879466-e9b5ce3825bf?w=800&q=80";
    }
    return "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80";
  }

  /// Classe les groupes dans TES catégories UX (4 catégories fixes)
  String _categoryForGroupName(String rawGroupName) {
    final g = rawGroupName.toLowerCase().trim();

    // 1) HAUT DU CORPS (pecs + épaules + dos si anciennes routines)
    if (g.contains("pec") ||
        g.contains("chest") ||
        g.contains("pector") ||
        g.contains("epaule") ||
        g.contains("épaule") ||
        g.contains("shoulder") ||
        g.contains("delto") ||
        g.contains("dos") ||
        g.contains("back")) {
      return "Haut du corps";
    }

    // 2) BRAS (biceps / triceps / avant-bras)
    if (g.contains("biceps") ||
        g.contains("triceps") ||
        g.contains("avant bras") ||
        g.contains("avant-bras") ||
        g.contains("avantbras") ||
        g.contains("forearm") ||
        g.contains("forearms") ||
        g.contains("bras") ||
        g.contains("arm")) {
      return "Bras";
    }

    // 3) JAMBES
    if (g.contains("jambe") ||
        g.contains("leg") ||
        g.contains("quadr") ||
        g.contains("ischio") ||
        g.contains("glute") ||
        g.contains("fessier") ||
        g.contains("mollet") ||
        g.contains("cuisse")) {
      return "Jambes";
    }

    // 4) AUTRES
    if (g.contains("cardio") ||
        g.contains("run") ||
        g.contains("course") ||
        g.contains("velo") ||
        g.contains("vélo") ||
        g.contains("bike") ||
        g.contains("hiit") ||
        g.contains("endurance") ||
        g.contains("full body") ||
        g.contains("fullbody") ||
        g.contains("full") ||
        g.contains("mobil") ||
        g.contains("mobilité") ||
        g.contains("stretch") ||
        g.contains("souplesse") ||
        g.contains("perte") ||
        g.contains("abdo") ||
        g.contains("abs") ||
        g.contains("core") ||
        g.contains("gainage")) {
      return "Autres";
    }

    return "Autres";
  }

  /// Groupement par muscleGroup puis regroupement en catégories UX
  /// Groupement par muscleGroup puis regroupement en 4 catégories UX
  Map<String, List<_ProgramGroupItem>> _buildSections(
    List<dynamic> allPrograms,
  ) {
    final Map<String, List<dynamic>> groupedPrograms = {};

    for (final p in allPrograms) {
      final groupName = (p['muscleGroup'] ?? "Autre").toString().trim();
      groupedPrograms.putIfAbsent(groupName, () => []);
      groupedPrograms[groupName]!.add(p);
    }

    // ✅ TES 4 catégories (ordre fixe)
    final Map<String, List<_ProgramGroupItem>> sections = {
      "Haut du corps": [],
      "Bras": [],
      "Jambes": [],
      "Autres": [],
    };

    groupedPrograms.forEach((groupName, variations) {
      final rep = variations.first;
      final section = _categoryForGroupName(groupName);

      sections.putIfAbsent(section, () => []);
      sections[section]!.add(
        _ProgramGroupItem(
          groupName: groupName,
          representative: rep,
          variations: variations,
        ),
      );
    });

    // Tri alpha dans chaque section
    for (final entry in sections.entries) {
      entry.value.sort(
        (a, b) =>
            a.groupName.toLowerCase().compareTo(b.groupName.toLowerCase()),
      );
    }

    // Retire les sections vides en conservant l'ordre
    return {
      for (final e in sections.entries)
        if (e.value.isNotEmpty) e.key: e.value,
    };
  }

  void _onCardTap(
    BuildContext context, {
    required dynamic representativeProgram,
    required String groupName,
    required List<dynamic> variations,
  }) {
    // ✅ Mode planification (si tu le gardes encore)
    if (widget.targetDate != null) {
      final d = widget.targetDate!;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A22),
          title: Text(
            "Planifier pour le ${d.day}/${d.month} ?",
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            "Veux-tu ajouter '${representativeProgram['name']}' à ton calendrier ?",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                "Annuler",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: clubOrange),
              onPressed: () async {
                final success = await RoutineService().scheduleRoutine(
                  representativeProgram['id'],
                  d,
                );

                if (!ctx.mounted) return;
                Navigator.pop(ctx);

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? "Séance ajoutée au planning !"
                          : "Erreur lors de l'ajout",
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );

                if (success) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text(
                "Valider",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // ✅ Mode catalogue normal
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProgramConfigScreen(muscleGroup: groupName, variations: variations),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: darkBg,
      appBar: widget.targetDate != null
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: const BackButton(color: Colors.white),
              title: const Text(
                "CHOISIS TA SÉANCE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
          future: _programsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: clubOrange),
              );
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  "Aucun programme disponible",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final allPrograms = snapshot.data!;
            final sections = _buildSections(allPrograms);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ✅ Header (catalogue uniquement)
                if (widget.targetDate == null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.06),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "ENTRAÎNEMENT",
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: -0.6,
                                    fontSize: 28,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Choisis une catégorie puis un programme.",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.60),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // ✅ Carte création libre (si catalogue)
                if (widget.targetDate == null)
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),

                if (widget.targetDate == null)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: _SectionHeader(
                        title: "Créer une séance",
                        icon: Icons.edit_calendar_rounded,
                      ),
                    ),
                  ),

                if (widget.targetDate == null)
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                if (widget.targetDate == null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _GlassCreateCard(
                        accent: clubOrange,
                        onTap: () {
                          // TODO: brancher ton mode libre
                        },
                      ),
                    ),
                  ),

                if (widget.targetDate == null)
                  const SliverToBoxAdapter(child: SizedBox(height: 22)),

                // ✅ Catalogue par catégories scrollables
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _SectionHeader(
                      title: widget.targetDate != null
                          ? "Choisir un type de séance"
                          : "Catalogue par catégories",
                      icon: Icons.view_carousel_rounded,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                ...sections.entries.map((entry) {
                  final sectionName = entry.key;
                  final items = entry.value;

                  return SliverToBoxAdapter(
                    child: _ProgramHorizontalSection(
                      title: sectionName,
                      items: items,
                      accent: clubOrange,
                      getImageForGroup: _getImageForGroup,
                      onTap: (item) {
                        _onCardTap(
                          context,
                          representativeProgram: item.representative,
                          groupName: item.groupName,
                          variations: item.variations,
                        );
                      },
                    ),
                  );
                }),

                const SliverToBoxAdapter(child: SizedBox(height: 90)),
              ],
            );
          },
        ),
      ),
    );
  }
}

// =====================
// MODELS
// =====================

class _ProgramGroupItem {
  final String groupName;
  final dynamic representative;
  final List<dynamic> variations;

  _ProgramGroupItem({
    required this.groupName,
    required this.representative,
    required this.variations,
  });
}

// =====================
// WIDGETS
// =====================

class _ProgramHorizontalSection extends StatelessWidget {
  final String title;
  final List<_ProgramGroupItem> items;
  final Color accent;
  final String Function(String groupName) getImageForGroup;
  final void Function(_ProgramGroupItem item) onTap;

  const _ProgramHorizontalSection({
    required this.title,
    required this.items,
    required this.accent,
    required this.getImageForGroup,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 0.8,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "${items.length} groupes",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16, right: 8),
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final rep = item.representative;
                final level = (rep['level'] ?? "Intermédiaire").toString();
                final prettyLevel = level == "debutant"
                    ? "Débutant"
                    : level == "avance"
                    ? "Avancé"
                    : "Intermédiaire";

                return _MiniProgramCard(
                  accent: accent,
                  title: item.groupName.toUpperCase(),
                  subtitle:
                      "${item.variations.length} variantes • ~ ${rep['estimatedDurationMin'] ?? 60} min",
                  level: prettyLevel,
                  imageUrl: getImageForGroup(item.groupName),
                  onTap: () => onTap(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniProgramCard extends StatelessWidget {
  final Color accent;
  final String title;
  final String subtitle;
  final String level;
  final String imageUrl;
  final VoidCallback onTap;

  const _MiniProgramCard({
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.level,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: Colors.grey[900]),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.88),
                      Colors.black.withOpacity(0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // tag niveau
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            level,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.92),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            color: accent,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "CHOISIR",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.94),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 0.8,
                            ),
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
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFF57809)),
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

class _GlassCreateCard extends StatelessWidget {
  final Color accent;
  final VoidCallback? onTap;

  const _GlassCreateCard({required this.accent, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: 112,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.14),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: accent.withOpacity(0.30)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withOpacity(0.18),
                    Colors.white.withOpacity(0.02),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.10)),
                    ),
                    child: const Icon(
                      Icons.edit_calendar_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "MODE LIBRE",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 0.2,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Crée ta séance rapidement.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.10)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "CRÉER",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: accent,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
