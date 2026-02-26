import 'dart:ui';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

// --- COULEURS STYLE iOS DARK MODE ---
const Color appBackground = Color(0xFF000000); // Noir profond
const Color cardColor = Color(0xFF1C1C1E); // Gris très foncé
const Color dividerColor = Color(0xFF2C2C2E);
const Color textSecondary = Color(0xFF8E8E93);
const Color clubOrange = Color(0xFFF57809);

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
  late Animation<int> _xpCount;

  bool _isSavingXp = true;
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
    final base = 50;
    final bonusVol = (totalVolume / 250).floor() * 10;
    final bonusSets = (totalSets / 10).floor() * 10;
    final bonusTime = (durationSec / 900).floor() * 10;
    return base + bonusVol + bonusSets + bonusTime;
  }

  String _getBannerImage(String routineName) {
    final name = routineName.toLowerCase().trim();
    if (name.contains("pec") || name.contains("chest")) {
      return "https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=1200&q=80";
    }
    if (name.contains("dos") || name.contains("back")) {
      return "https://images.unsplash.com/photo-1603287681836-e54f0e4475ac?w=1200&q=80";
    }
    if (name.contains("jambe") || name.contains("leg")) {
      return "https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=1200&q=80";
    }
    if (name.contains("bras") || name.contains("arm")) {
      return "https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=1200&q=80";
    }
    if (name.contains("epaule") || name.contains("shoulder")) {
      return "https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?w=1200&q=80";
    }
    if (name.contains("abdo") || name.contains("abs")) {
      return "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=1200&q=80";
    }
    if (name.contains("cardio") || name.contains("run")) {
      return "https://images.unsplash.com/photo-1538805060504-6335d7aa1b7e?w=1200&q=80";
    }
    if (name.contains("full") || name.contains("body")) {
      return "https://images.unsplash.com/photo-1517963879466-e9b5ce3825bf?w=1200&q=80";
    }
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
    _xpCount = IntTween(begin: 0, end: 0).animate(_xpController);
    _processWorkoutAndXp();
  }

  Future<void> _processWorkoutAndXp() async {
    final totalSeconds = _toInt(widget.stats['duration_seconds']);
    final totalVolume = _toDouble(widget.stats['total_volume']);
    final totalSets = _getTotalSets();

    final gainedXp = _calcXp(totalVolume, totalSets, totalSeconds);
    final result = await AuthService().addXpToUser(gainedXp);

    if (!mounted) return;

    setState(() {
      _isSavingXp = false;
      if (result != null) {
        _hasLeveledUp = result['has_leveled_up'] ?? false;
        _newLevel = result['new_level'] ?? 1;
      }
      _xpCount = IntTween(begin: 0, end: gainedXp).animate(
        CurvedAnimation(parent: _xpController, curve: Curves.easeOutExpo),
      );
    });

    _xpController.forward();

    if (_hasLeveledUp) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) _showLevelUpDialog(_newLevel);
      });
    }
  }

  void _showLevelUpDialog(int level) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Félicitations, tes efforts paient ! Tu as atteint le niveau $level.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Continuer",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
      backgroundColor: appBackground,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ===================
                // HEADER BANNIÈRE
                // ===================
                SliverAppBar(
                  expandedHeight: 260,
                  pinned: true,
                  backgroundColor: appBackground,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(
                      left: 20,
                      bottom: 16,
                      right: 20,
                    ),
                    title: Text(
                      routineName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        letterSpacing: -0.5,
                      ),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          bannerUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              Container(color: cardColor),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                appBackground.withOpacity(0.5),
                                appBackground,
                              ],
                              stops: const [0.5, 0.8, 1.0],
                            ),
                          ),
                        ),
                        // Bouton Fermer (Croix style iOS)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 10,
                          right: 16,
                          child: GestureDetector(
                            onTap: () => Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2C2E).withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ===================
                // CONTENU
                // ===================
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Bloc d'XP (Style Pro)
                      AnimatedBuilder(
                        animation: _xpController,
                        builder: (_, _) {
                          if (_isSavingXp) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: clubOrange,
                              ),
                            );
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.stars_rounded,
                                  color: clubOrange,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "+ ${_xpCount.value} XP GAGNÉS",
                                  style: const TextStyle(
                                    color: clubOrange,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // Section Statistiques
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          "RÉSUMÉ DE LA SÉANCE",
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildStatRow(
                              icon: Icons.timer_outlined,
                              label: "Durée",
                              value: duration,
                            ),
                            const Divider(
                              height: 1,
                              color: dividerColor,
                              indent: 48,
                            ),
                            _buildStatRow(
                              icon: Icons.stacked_bar_chart_rounded,
                              label: "Volume total",
                              value: volumeLabel,
                            ),
                            const Divider(
                              height: 1,
                              color: dividerColor,
                              indent: 48,
                            ),
                            _buildStatRow(
                              icon: Icons.done_all_rounded,
                              label: "Séries complétées",
                              value: "$totalSets",
                            ),
                            const Divider(
                              height: 1,
                              color: dividerColor,
                              indent: 48,
                            ),
                            _buildStatRow(
                              icon: Icons.event_available_rounded,
                              label: "Date",
                              value: dateLabel,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Message info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Retrouve l'historique détaillé de tes performances dans l'onglet Progrès.",
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // ===================
          // BOUTON FIXE EN BAS
          // ===================
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: const BoxDecoration(
              color: appBackground,
              border: Border(top: BorderSide(color: dividerColor)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: clubOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Retour à l'accueil",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- COMPOSANT ROW ---
  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(color: textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
