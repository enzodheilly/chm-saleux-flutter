import 'dart:ui';
import 'package:flutter/material.dart';

import '../services/auth_service.dart'; // ✅ N'oublie pas d'importer ton service

const Color clubOrange = Color(0xFFF57809);
const Color darkBg = Color(0xFF0B0B0F);
const Color cardSurface = Color(0xFF16161C);

class WorkoutSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> stats;

  const WorkoutSummaryScreen({super.key, required this.stats});

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _xpController;
  late final Animation<double> _xpAppear;
  late Animation<int>
  _xpCount; // ✅ Plus en 'final' car on la met à jour dynamiquement

  bool _isSavingXp = true; // ✅ Indique si on est en train de sauvegarder l'XP
  bool _hasLeveledUp = false;
  int _newLevel = 1;

  int _toInt(dynamic v) =>
      v is num ? v.toInt() : int.tryParse("${v ?? 0}") ?? 0;

  double _toDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse("${v ?? 0}") ?? 0.0;

  String _formatDuration(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return "${m}m ${s.toString().padLeft(2, '0')}s";
  }

  String _formatDateLabel(dynamic performedAt) {
    final iso = performedAt?.toString();
    if (iso == null || iso.isEmpty) return "Aujourd’hui";
    try {
      final dt = DateTime.parse(iso).toLocal();
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      return "$d/$m";
    } catch (_) {
      return "Aujourd’hui";
    }
  }

  int _calcXp(double totalVolume, int totalSets, int durationSec) {
    // XP simple mais cohérent : volume + séries + durée
    final base = 50;
    final bonusVol = (totalVolume / 250).floor() * 10;
    final bonusSets = (totalSets / 10).floor() * 10;
    final bonusTime = (durationSec / 900).floor() * 10;
    return base + bonusVol + bonusSets + bonusTime;
  }

  String _getBannerImage(String routineName) {
    final name = routineName.toLowerCase().trim();

    if (name.contains("pec") || name.contains("chest"))
      return "https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=1200&q=80";
    if (name.contains("dos") || name.contains("back"))
      return "https://images.unsplash.com/photo-1603287681836-e54f0e4475ac?w=1200&q=80";
    if (name.contains("jambe") || name.contains("leg"))
      return "https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=1200&q=80";
    if (name.contains("bras") || name.contains("arm"))
      return "https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=1200&q=80";
    if (name.contains("epaule") || name.contains("shoulder"))
      return "https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?w=1200&q=80";
    if (name.contains("abdo") || name.contains("abs"))
      return "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=1200&q=80";
    if (name.contains("cardio") || name.contains("run"))
      return "https://images.unsplash.com/photo-1538805060504-6335d7aa1b7e?w=1200&q=80";
    if (name.contains("full") || name.contains("body"))
      return "https://images.unsplash.com/photo-1517963879466-e9b5ce3825bf?w=1200&q=80";

    return "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=1200&q=80";
  }

  int _getTotalSets() {
    final raw =
        widget.stats['total_sets'] ??
        widget.stats['totalCompletedSets'] ??
        widget.stats['total_completed_sets'] ??
        0;
    return _toInt(raw);
  }

  @override
  void initState() {
    super.initState();

    _xpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _xpAppear = CurvedAnimation(
      parent: _xpController,
      curve: Curves.easeOutBack,
    );

    // Initialisation vide en attendant la réponse du serveur
    _xpCount = IntTween(begin: 0, end: 0).animate(_xpController);

    // ✅ On lance la sauvegarde de l'XP
    _processWorkoutAndXp();
  }

  /// ✅ Méthode pour gérer la sauvegarde et l'animation de l'XP
  Future<void> _processWorkoutAndXp() async {
    final totalSeconds = _toInt(widget.stats['duration_seconds']);
    final totalVolume = _toDouble(widget.stats['total_volume']);
    final totalSets = _getTotalSets();

    // 1. Calcul de l'XP gagné
    final gainedXp = _calcXp(totalVolume, totalSets, totalSeconds);

    // 2. Sauvegarde en BDD
    final result = await AuthService().addXpToUser(gainedXp);

    if (!mounted) return;

    setState(() {
      _isSavingXp = false;
      if (result != null) {
        _hasLeveledUp = result['has_leveled_up'] ?? false;
        _newLevel = result['new_level'] ?? 1;
      }

      // 3. Mise à jour de l'animation avec la vraie valeur
      _xpCount = IntTween(begin: 0, end: gainedXp).animate(
        CurvedAnimation(parent: _xpController, curve: Curves.easeOutExpo),
      );
    });

    _xpController.forward();

    // 4. Si level up, on affiche la modale après l'animation
    if (_hasLeveledUp) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) _showLevelUpDialog(_newLevel);
      });
    }
  }

  /// ✅ Modale stylisée pour célébrer le Level Up
  void _showLevelUpDialog(int level) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: clubOrange.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: clubOrange.withOpacity(0.15),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: clubOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: clubOrange,
                  size: 54,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "NIVEAU SUPÉRIEUR !",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Félicitations, tes efforts paient ! Tu as atteint le niveau $level.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: clubOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "CONTINUER",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _xpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int totalSeconds = _toInt(widget.stats['duration_seconds']);
    final String duration = _formatDuration(totalSeconds);
    final double totalVolume = _toDouble(widget.stats['total_volume']);
    final String volumeLabel = "${totalVolume.toInt()} kg";
    final int totalSets = _getTotalSets();
    final String dateLabel = _formatDateLabel(widget.stats['performed_at']);
    final String routineName = (widget.stats['routine_name'] ?? "Ta séance")
        .toString();
    final String bannerUrl =
        (widget.stats['banner_url']?.toString().isNotEmpty ?? false)
        ? widget.stats['banner_url'].toString()
        : _getBannerImage(routineName);

    return Scaffold(
      backgroundColor: darkBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0F0F13),
                    Colors.black.withOpacity(0.95),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 240,
                  pinned: true,
                  backgroundColor: darkBg,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          bannerUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              Container(color: Colors.grey[900]),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.10),
                                Colors.black.withOpacity(0.45),
                                Colors.black.withOpacity(0.95),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 14,
                          left: 14,
                          child: _GlassIconButton(
                            icon: Icons.close,
                            onTap: () => Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ✅ Animation de l'XP avec statut de chargement
                              AnimatedBuilder(
                                animation: _xpController,
                                builder: (_, _) {
                                  if (_isSavingXp) {
                                    return const Opacity(
                                      opacity: 0.8,
                                      child: _Pill(
                                        icon: Icons.hourglass_empty_rounded,
                                        text: "Calcul de l'XP...",
                                        tint: Colors.white,
                                        subtle: true,
                                      ),
                                    );
                                  }

                                  final scale = 0.92 + (0.08 * _xpAppear.value);
                                  final opacity = (0.2 + 0.8 * _xpAppear.value)
                                      .clamp(0.0, 1.0);

                                  return Opacity(
                                    opacity: opacity,
                                    child: Transform.scale(
                                      scale: scale,
                                      alignment: Alignment.centerLeft,
                                      child: _Pill(
                                        icon: Icons.stars_rounded,
                                        text: "+ ${_xpCount.value} XP",
                                        tint: clubOrange,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "SÉANCE TERMINÉE",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 26,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Bien joué. Tes stats ont été enregistrées.",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.78),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _SummaryCard(
                        title: routineName,
                        chips: [
                          _Pill(
                            icon: Icons.timer_outlined,
                            text: duration,
                            tint: Colors.white,
                            subtle: true,
                          ),
                          _Pill(
                            icon: Icons.fitness_center_rounded,
                            text: volumeLabel,
                            tint: clubOrange,
                          ),
                          _Pill(
                            icon: Icons.done_all_rounded,
                            text: "$totalSets séries",
                            tint: Colors.greenAccent,
                            subtle: true,
                          ),
                          _Pill(
                            icon: Icons.calendar_today_rounded,
                            text: dateLabel,
                            tint: Colors.purpleAccent,
                            subtle: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const _SectionTitle("STATISTIQUES"),
                      const SizedBox(height: 10),
                      _StatsCompactCard(
                        rows: [
                          _StatRowModel(
                            icon: Icons.timer_outlined,
                            label: "Durée",
                            value: duration,
                            accent: clubOrange,
                          ),
                          _StatRowModel(
                            icon: Icons.stacked_bar_chart_rounded,
                            label: "Volume",
                            value: volumeLabel,
                            accent: Colors.blueAccent,
                          ),
                          _StatRowModel(
                            icon: Icons.done_all_rounded,
                            label: "Séries",
                            value: "$totalSets",
                            accent: Colors.greenAccent,
                          ),
                          _StatRowModel(
                            icon: Icons.event_available_rounded,
                            label: "Date",
                            value: dateLabel,
                            accent: Colors.purpleAccent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const _GlassInfo(
                        icon: Icons.insights_rounded,
                        text:
                            "Retrouve tes performances dans l’onglet Progrès.",
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomCtaGlass(
              label: "RETOUR À L'ACCUEIL",
              onTap: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================
// COMPONENTS
// =====================

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.55),
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        fontSize: 11,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final List<Widget> chips;

  const _SummaryCard({required this.title, required this.chips});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              fontStyle: FontStyle.italic,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: chips),
        ],
      ),
    );
  }
}

class _StatRowModel {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  _StatRowModel({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });
}

class _StatsCompactCard extends StatelessWidget {
  final List<_StatRowModel> rows;

  const _StatsCompactCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Column(
            children: List.generate(rows.length, (i) {
              final r = rows[i];
              return Column(
                children: [
                  _StatRow(r: r),
                  if (i != rows.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(height: 1, color: Colors.white10),
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final _StatRowModel r;
  const _StatRow({required this.r});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: r.accent.withOpacity(0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: r.accent.withOpacity(0.24)),
          ),
          child: Icon(r.icon, color: r.accent, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            r.label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              fontSize: 10,
            ),
          ),
        ),
        Text(
          r.value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _GlassInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _GlassInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Row(
            children: [
              Icon(icon, color: clubOrange, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.70),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color tint;
  final bool subtle;

  const _Pill({
    required this.icon,
    required this.text,
    required this.tint,
    this.subtle = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = subtle ? Colors.white.withOpacity(0.06) : tint.withOpacity(0.16);
    final border = subtle
        ? Colors.white.withOpacity(0.10)
        : tint.withOpacity(0.26);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: subtle ? Colors.white70 : tint),
          const SizedBox(width: 7),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(subtle ? 0.82 : 1.0),
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomCtaGlass extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BottomCtaGlass({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
          ),
          child: Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: clubOrange.withOpacity(0.18),
                  border: Border.all(
                    color: clubOrange.withOpacity(0.55),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: clubOrange.withOpacity(0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.home_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.9,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
