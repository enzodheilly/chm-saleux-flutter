import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/routine_service.dart';

const Color clubOrange = Color(0xFFF57809);
const Color darkBackground = Color(0xFF0B0B0F);

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  final RoutineService _service = RoutineService();

  int rangeDays = 30;
  Future<_ProgressData>? _future;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<_ProgressData> _load() async {
    final stats = await _service.getProgressStats(rangeDays: rangeDays);
    final sessions = await _service.getWorkoutSessions(rangeDays: rangeDays);
    return _ProgressData(stats: stats, sessions: sessions);
  }

  void _reload() => setState(() => _future = _load());

  // ---------- Helpers parsing ----------
  int _asInt(dynamic v, [int def = 0]) {
    if (v == null) return def;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? def;
  }

  double _asDouble(dynamic v, [double def = 0.0]) {
    if (v == null) return def;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? def;
  }

  // ---------- Helpers Format ----------
  String _formatDuration(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    if (h <= 0) return "${m}m";
    return "${h}h ${m.toString().padLeft(2, '0')}";
  }

  String _formatDateShort(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}";
    } catch (_) {
      return "--/--";
    }
  }

  String _rangeLabel() {
    if (rangeDays == 7) return "7 jours";
    if (rangeDays == 30) return "30 jours";
    if (rangeDays == 90) return "3 mois";
    return "Tout";
  }

  List<int> _buildBarsFromSessions(List<dynamic> sessions) {
    final recent = sessions.take(8).toList().reversed.toList();
    final bars = recent.map((s) => _asInt(s['total_volume'])).toList();
    while (bars.length < 8) {
      bars.insert(0, 0);
    }
    return bars;
  }

  void _cycleRange() {
    setState(() {
      if (rangeDays == 7) {
        rangeDays = 30;
      } else if (rangeDays == 30) {
        rangeDays = 90;
      } else if (rangeDays == 90) {
        rangeDays = 0;
      } else {
        rangeDays = 7;
      }
    });
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (_, _) => [
            SliverAppBar(
              backgroundColor: darkBackground,
              elevation: 0,
              centerTitle: false,
              pinned: true,
              expandedHeight: 100,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                title: const Text(
                  "MES PROGRÈS",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              actions: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _CompactRangeSelector(
                      label: _rangeLabel(),
                      onTap: _cycleRange,
                    ),
                  ),
                ),
              ],
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: clubOrange,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.3),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w900),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: "DASHBOARD"),
                    Tab(text: "HISTORIQUE"),
                    Tab(text: "ANALYSE"),
                  ],
                ),
              ),
              pinned: true,
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildDashboardTab(),
              _buildHistoryTab(),
              _buildVisitesTab(),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // TAB 1 : DASHBOARD
  // =========================
  Widget _buildDashboardTab() {
    return FutureBuilder<_ProgressData>(
      future: _future ??= _load(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: clubOrange),
          );
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              "Erreur: ${snap.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final data = snap.data!;
        final stats = data.stats ?? {};

        final sessionsCount = _asInt(stats['sessions']);
        final totalVolume = _asDouble(stats['total_volume']);
        final totalDuration = _asInt(stats['total_duration_seconds']);

        final sessions = data.sessions;
        final bars = _buildBarsFromSessions(sessions);

        final durationLabel = _formatDuration(totalDuration);
        final durationValue = durationLabel.contains('h')
            ? durationLabel.split(' ')[0]
            : durationLabel.replaceAll('m', '');
        final durationUnit = durationLabel.contains('h') ? "Heures" : "Min";

        return RefreshIndicator(
          color: clubOrange,
          backgroundColor: darkBackground,
          onRefresh: () async => _reload(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            children: [
              const _SectionHeader(
                title: "VOLUME HEBDOMADAIRE",
                icon: Icons.bar_chart,
              ),
              const SizedBox(height: 12),
              _AnimatedChartCard(bars: bars),

              const SizedBox(height: 32),

              const _SectionHeader(
                title: "STATISTIQUES CLÉS",
                icon: Icons.analytics_outlined,
              ),
              const SizedBox(height: 12),

              _StatRowTile(
                title: "Volume soulevé",
                value: (totalVolume / 1000).toStringAsFixed(1),
                unit: "Tonnes",
                miniChart: const [0.4, 0.6, 0.3, 0.8, 0.5, 0.9, 0.7],
                accent: clubOrange,
              ),
              _StatRowTile(
                title: "Séances complétées",
                value: "$sessionsCount",
                unit: "Workouts",
                miniChart: const [0.2, 0.8, 0.0, 0.5, 1.0, 0.2, 0.6],
                accent: Colors.blueAccent,
              ),
              _StatRowTile(
                title: "Temps d'effort",
                value: durationValue,
                unit: durationUnit,
                miniChart: const [0.5, 0.5, 0.7, 0.9, 0.6, 0.8, 1.0],
                accent: Colors.greenAccent,
              ),

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  // =========================
  // TAB 2 : HISTORIQUE
  // =========================
  Widget _buildHistoryTab() {
    return FutureBuilder<_ProgressData>(
      future: _future ??= _load(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: clubOrange),
          );
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              "Erreur: ${snap.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final sessions = snap.data!.sessions;

        if (sessions.isEmpty) {
          return Center(
            child: Text(
              "Aucune séance enregistrée",
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: clubOrange,
          backgroundColor: darkBackground,
          onRefresh: () async => _reload(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: sessions.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: _SectionHeader(
                    title: "LISTE DES SÉANCES",
                    icon: Icons.history,
                  ),
                );
              }

              final s = sessions[index - 1];
              final date = _formatDateShort(
                (s['performed_at'] ?? "").toString(),
              );
              final title = (s['routine_name'] ?? "Séance")
                  .toString()
                  .toUpperCase();
              final vol = _asInt(s['total_volume']);
              final dur = _asInt(s['duration_seconds']);
              final fromPlanning = s['is_from_planning'] == true;

              return _ModernSessionTile(
                date: date,
                title: title,
                subtitle:
                    "$vol kg soulevés${fromPlanning ? " • Planning" : ""}",
                duration: _formatDuration(dur),
              );
            },
          ),
        );
      },
    );
  }

  // =========================
  // TAB 3 : ANALYSE (placeholder)
  // =========================
  Widget _buildVisitesTab() {
    return Center(
      child: Text(
        "Bientôt disponible",
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// =====================
// MODERN COMPONENTS
// =====================

class _CompactRangeSelector extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _CompactRangeSelector({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: clubOrange,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedChartCard extends StatelessWidget {
  final List<int> bars;
  const _AnimatedChartCard({required this.bars});

  @override
  Widget build(BuildContext context) {
    final maxVal = bars.isEmpty ? 1 : bars.reduce((a, b) => a > b ? a : b);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 180,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: bars.map((val) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: (maxVal == 0 ? 0.0 : (val / maxVal)),
                      ),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutExpo,
                      builder: (context, percent, _) {
                        return FractionallySizedBox(
                          heightFactor: percent == 0 ? 0.01 : percent,
                          child: Container(
                            width: 20,
                            decoration: BoxDecoration(
                              color: percent > 0.8
                                  ? clubOrange
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              Container(height: 1, color: Colors.white.withOpacity(0.08)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRowTile extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final List<double> miniChart;
  final Color accent;

  const _StatRowTile({
    required this.title,
    required this.value,
    required this.unit,
    required this.miniChart,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -1.0,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          unit,
                          style: TextStyle(
                            color: accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 32,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: miniChart.map((val) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 6,
                            height: 32 * val,
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white.withOpacity(0.3),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernSessionTile extends StatelessWidget {
  final String date;
  final String title;
  final String subtitle;
  final String duration;

  const _ModernSessionTile({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final parts = date.split('/');
    final day = parts.isNotEmpty ? parts[0] : "--";
    final month = parts.length > 1 ? parts[1] : "--";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        day,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        _getMonthName(month),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: clubOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  duration,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMonthName(String m) {
    const months = [
      "JAN",
      "FÉV",
      "MAR",
      "AVR",
      "MAI",
      "JUI",
      "JUL",
      "AOÛ",
      "SEP",
      "OCT",
      "NOV",
      "DÉC",
    ];
    final index = int.tryParse(m) ?? 1;
    return months[(index - 1) % 12];
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: darkBackground.withOpacity(0.95), child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

// =====================
// DATA MODELS
// =====================

class _ProgressData {
  final Map<String, dynamic>? stats;
  final List<dynamic> sessions;
  _ProgressData({required this.stats, required this.sessions});
}
