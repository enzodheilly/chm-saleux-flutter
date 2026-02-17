import 'dart:ui'; // 👈 Nécessaire pour BackdropFilter
import 'package:flutter/material.dart';
import '../services/routine_service.dart';
import 'program_config_screen.dart';

class TrainingScreen extends StatefulWidget {
  // ✅ NOUVEAU PARAMÈTRE OPTIONNEL
  final DateTime? targetDate;

  const TrainingScreen({super.key, this.targetDate});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  late Future<List<dynamic>> _programsFuture;

  @override
  void initState() {
    super.initState();
    _programsFuture = RoutineService().getAllPrograms();
  }

  String _getImageForGroup(String groupName) {
    final name = groupName.toLowerCase().trim();
    if (name.contains("pec") || name.contains("chest")) {
      return "https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800&q=80";
    }
    if (name.contains("dos") || name.contains("back")) {
      return "https://images.unsplash.com/photo-1603287681836-e54f0e4475ac?w=800&q=80";
    }
    if (name.contains("jambe") || name.contains("leg")) {
      return "https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=800&q=80";
    }
    if (name.contains("bras") || name.contains("arm")) {
      return "https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800&q=80";
    }
    if (name.contains("epaule") || name.contains("shoulder")) {
      return "https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?w=800&q=80";
    }
    if (name.contains("abdo") || name.contains("abs")) {
      return "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800&q=80";
    }
    if (name.contains("cardio") || name.contains("run")) {
      return "https://images.unsplash.com/photo-1538805060504-6335d7aa1b7e?w=800&q=80";
    }
    if (name.contains("full") || name.contains("body")) {
      return "https://images.unsplash.com/photo-1517963879466-e9b5ce3825bf?w=800&q=80";
    }
    return "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80";
  }

  // ✅ FONCTION POUR GÉRER LE CLIC
  void _onCardTap(
    BuildContext context, {
    required dynamic representativeProgram,
    required String groupName,
    required List<dynamic> variations,
  }) {
    // CAS 1 : MODE PLANIFICATION (On vient de l'accueil avec une date)
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
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF57809),
              ),
              onPressed: () async {
                // 1) Appel API
                final success = await RoutineService().scheduleRoutine(
                  representativeProgram['id'],
                  d,
                );

                Navigator.pop(ctx); // Ferme la popup

                // 2) Feedback + retour
                if (!mounted) return;

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Séance ajoutée au planning !"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(
                    context,
                    true,
                  ); // Revient à l'accueil avec "true"
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Erreur lors de l'ajout"),
                      backgroundColor: Colors.red,
                    ),
                  );
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
    }
    // CAS 2 : MODE CATALOGUE NORMAL
    else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProgramConfigScreen(
            muscleGroup: groupName,
            variations: variations,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color clubOrange = Color(0xFFF57809);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),

      // ✅ AppBar uniquement si mode planification
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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ✅ Titre seulement en mode catalogue
            if (widget.targetDate == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Text(
                    "CATALOGUE",
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                      letterSpacing: 1.0,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),

            // ✅ Bouton Mode Libre version Glass (tu le gardes tel quel)
            if (widget.targetDate == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _GlassCreateCard(accent: clubOrange),
                ),
              ),

            if (widget.targetDate == null)
              const SliverToBoxAdapter(child: SizedBox(height: 30)),

            // ✅ Filtres version Glass (tu les gardes tel quel)
            if (widget.targetDate == null)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    children: const [
                      // si tes chips ont besoin d'accent, remets-les comme avant
                    ],
                  ),
                ),
              ),

            if (widget.targetDate == null)
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

            FutureBuilder<List<dynamic>>(
              future: _programsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: clubOrange),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        "Aucun programme disponible",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }

                final allPrograms = snapshot.data!;

                // ✅ Groupement identique à ton code
                Map<String, List<dynamic>> groupedPrograms = {};
                for (var p in allPrograms) {
                  String groupName = p['muscleGroup'] ?? "Autre";
                  groupedPrograms.putIfAbsent(groupName, () => []);
                  groupedPrograms[groupName]!.add(p);
                }
                final uniqueGroups = groupedPrograms.keys.toList();

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final groupName = uniqueGroups[index];
                      final variations = groupedPrograms[groupName]!;
                      final representative = variations.first;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: GestureDetector(
                          onTap: () {
                            _onCardTap(
                              context,
                              representativeProgram: representative,
                              groupName: groupName,
                              variations: variations,
                            );
                          },
                          child: _ProgramCard(
                            title: groupName.toUpperCase(),
                            category: widget.targetDate != null
                                ? "Choisir"
                                : "${variations.length} variantes",
                            level: "Personnalisable",
                            duration:
                                "~ ${representative['estimatedDurationMin'] ?? 60} min",
                            imageUrl: _getImageForGroup(groupName),
                            accent: clubOrange,
                          ),
                        ),
                      );
                    }, childCount: uniqueGroups.length),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

// --- WIDGETS GLASS ---

class _GlassCreateCard extends StatelessWidget {
  final Color accent;
  const _GlassCreateCard({required this.accent});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 25),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_calendar_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "MODE LIBRE",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Crée ta propre séance\nde A à Z.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected; // 👈 Cette variable causait l'erreur
  final Color accent;

  // ✅ CORRECTION : Ajout de "required this.isSelected" dans le constructeur
  const _GlassFilterChip({
    required this.label,
    required this.isSelected,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              // Utilisation de isSelected pour changer la couleur
              color: isSelected
                  ? accent.withOpacity(0.8)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected ? accent : Colors.white.withOpacity(0.1),
              ),
            ),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.6),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final String title;
  final String category;
  final String level;
  final String duration;
  final String imageUrl;
  final Color accent;

  const _ProgramCard({
    required this.title,
    required this.category,
    required this.level,
    required this.duration,
    required this.imageUrl,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A22),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: Colors.grey[900]),
            ),
            // ✅ Overlay Gradient Apple Style
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // ✅ Badge en verre
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        color: accent.withOpacity(0.5),
                        child: Text(
                          category.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: Colors.white.withOpacity(0.7),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        duration,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.signal_cellular_alt,
                        color: Colors.white.withOpacity(0.7),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        level,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ✅ Bouton "+" en verre
            Positioned(
              right: 16,
              bottom: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Icon(Icons.add, color: accent),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
