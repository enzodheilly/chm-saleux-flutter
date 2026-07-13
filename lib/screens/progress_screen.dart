import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/routine_service.dart';
import '../theme/app_theme.dart';
import '../widgets/design_system.dart';

// =========================
// PALETTE
// Les noms locaux sont conservés (utilisés dans tout le fichier) mais
// pointent désormais vers la palette partagée AppColors, pour limiter
// la palette réelle à quelques couleurs porteuses de sens.
// =========================
const Color clubOrange = AppColors.accent;
const Color appBackground = AppColors.bg;
const Color surfaceColor = AppColors.surface;
const Color textPrimary = AppColors.textPrimary;
const Color textSecondary = AppColors.textSecondary;
const Color purpleAccent = AppColors.accent;
const Color blueAccent = AppColors.info;
const Color greenAccent = AppColors.success;
const Color purpleLight = AppColors.info;

// =========================
// MODELS
// =========================

class _ProgressData {
  final Map<String, dynamic> stats;
  final List<dynamic> sessions;
  const _ProgressData({required this.stats, required this.sessions});
}

class _BarData {
  final int vol;
  final String lbl;
  const _BarData({required this.vol, required this.lbl});
}

class _PItem {
  final String label, value;
  final double pct;
  final Color color;
  const _PItem(this.label, this.value, this.pct, this.color);
}

class _Muscle {
  final String name;
  final int count, dur, sets;
  final double vol;
  const _Muscle(this.name, this.count, this.vol, this.dur, this.sets);
}

// =========================
// SCREEN
// =========================

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  final RoutineService _service = RoutineService();

  // ✅ rangeDays == 365*3 pour "TOUT" au lieu de 0 (évite l'ambiguïté côté API)
  int _rangeDays = 30;
  late final TabController _tab;
  Future<_ProgressData>? _future;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _future = _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // =========================
  // CHARGEMENT
  // =========================

  Future<_ProgressData> _load() async {
    final rangeDaysToFetch = _rangeDays == 0 ? 365 * 3 : _rangeDays;
    final results = await Future.wait([
      _service.getProgressStats(rangeDays: rangeDaysToFetch),
      _service.getWorkoutSessions(rangeDays: rangeDaysToFetch),
    ]);
    final stats = (results[0] as Map<String, dynamic>?) ?? {};
    final sessions = (results[1] as List<dynamic>?) ?? [];
    return _ProgressData(stats: stats, sessions: sessions);
  }

  void _reload() => setState(() => _future = _load());

  // =========================
  // HELPERS PARSING
  // =========================

  int _i(dynamic v, [int d = 0]) {
    if (v == null) return d;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? d;
  }

  double _d(dynamic v, [double d = 0.0]) {
    if (v == null) return d;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? d;
  }

  /// Extrait la date d'une session — même logique que les autres screens
  String _sessionDateStr(dynamic s) =>
      (s['performed_at'] ??
              s['date'] ??
              s['createdAt'] ??
              s['completedAt'] ??
              '')
          .toString();

  String _dur(int totalSec) {
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    return h > 0 ? '${h}h${m.toString().padLeft(2, '0')}' : '${m}m';
  }

  String _dateFull(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      const mo = [
        'Jan',
        'Fév',
        'Mar',
        'Avr',
        'Mai',
        'Jui',
        'Jul',
        'Aoû',
        'Sep',
        'Oct',
        'Nov',
        'Déc',
      ];
      return '${d.day} ${mo[d.month - 1]}';
    } catch (_) {
      return '--';
    }
  }

  String _dateShort(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return '--';
    }
  }

  String _rangeLabel() => _rangeDays == 7
      ? '7 JOURS'
      : _rangeDays == 30
      ? '30 JOURS'
      : _rangeDays == 90
      ? '3 MOIS'
      : 'TOUT';

  void _cycleRange() {
    setState(() {
      _rangeDays = _rangeDays == 7
          ? 30
          : _rangeDays == 30
          ? 90
          : _rangeDays == 90
          ? 0
          : 7;
      _future = _load();
    });
  }

  // =========================
  // CALCULS
  // =========================

  /// ✅ FIX — utilise tous les champs de date possibles, cohérent avec les autres screens
  Set<int> _activeDays(List<dynamic> sessions) {
    final now = DateTime.now();
    final mon = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final out = <int>{};
    for (final e in sessions) {
      try {
        final d = DateTime.parse(_sessionDateStr(e)).toLocal();
        final diff = d.difference(mon).inDays;
        if (diff >= 0 && diff < 7) out.add(diff);
      } catch (_) {}
    }
    return out;
  }

  /// ✅ FIX — padding null évité, typage explicite
  List<_BarData> _bars(List<dynamic> sessions) {
    final recent = sessions.take(8).toList().reversed.toList();
    final result = <_BarData>[];
    // Padding à gauche avec des barres vides
    for (int i = 0; i < 8 - recent.length; i++) {
      result.add(const _BarData(vol: 0, lbl: ''));
    }
    for (final e in recent) {
      result.add(
        _BarData(
          vol: _i(e['total_volume']),
          lbl: _dateShort(_sessionDateStr(e)),
        ),
      );
    }
    return result;
  }

  Map<String, _Muscle> _muscleMap(List<dynamic> sessions) {
    final m = <String, _Muscle>{};
    for (final e in sessions) {
      final n = (e['routine_name'] ?? 'Autre').toString();
      m.update(
        n,
        (x) => _Muscle(
          n,
          x.count + 1,
          x.vol + _d(e['total_volume']),
          x.dur + _i(e['duration_seconds']),
          x.sets + _i(e['total_completed_sets'] ?? e['total_sets']),
        ),
        ifAbsent: () => _Muscle(
          n,
          1,
          _d(e['total_volume']),
          _i(e['duration_seconds']),
          _i(e['total_completed_sets'] ?? e['total_sets']),
        ),
      );
    }
    final sorted = m.values.toList()..sort((a, b) => b.vol.compareTo(a.vol));
    return {for (final e in sorted) e.name: e};
  }

  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: PageHeader(
                      title: 'Mes performances',
                      subtitle: 'Suivi de ton activité sportive',
                    ),
                  ),
                  // Range pill
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: GestureDetector(
                      onTap: _cycleRange,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _rangeLabel(),
                              style: const TextStyle(
                                color: clubOrange,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textSecondary,
                              size: 15,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.line),
                ),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    color: clubOrange,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(3),
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.bg,
                  unselectedLabelColor: textSecondary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Dashboard'),
                    Tab(text: 'Historique'),
                    Tab(text: 'Analyse'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [_dashboard(), _history(), _analyse()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // VUE COMMUNE FUTUREBUILDER
  // =========================

  Widget _withData(Widget Function(_ProgressData data) builder) {
    return FutureBuilder<_ProgressData>(
      future: _future ??= _load(),
      builder: (_, snap) {
        // ✅ FIX — état d'erreur géré
        if (snap.hasError) {
          return _errorState(snap.error.toString());
        }
        if (!snap.hasData && snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: clubOrange, strokeWidth: 2),
          );
        }
        final data = snap.data ?? _ProgressData(stats: {}, sessions: []);
        return builder(data);
      },
    );
  }

  Widget _errorState(String msg) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surfaceColor,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.danger.withOpacity(0.2)),
          ),
          child: const Icon(
            Icons.wifi_off_rounded,
            color: AppColors.danger,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Impossible de charger les données",
          style: TextStyle(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _reload,
          icon: const Icon(Icons.refresh_rounded, size: 16, color: clubOrange),
          label: const Text(
            "Réessayer",
            style: TextStyle(color: clubOrange, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  // =========================
  // ONGLET : DASHBOARD
  // =========================

  Widget _dashboard() => _withData((data) {
    final stats = data.stats;
    final sessions = data.sessions;
    final vol = _d(stats['total_volume']);
    final secs = _i(stats['total_duration_seconds']);
    final sets = _i(stats['total_sets'] ?? stats['total_completed_sets']);
    final count = _i(stats['sessions']);
    final active = _activeDays(sessions);
    final bars = _bars(sessions);
    final volPct = (vol / 5000).clamp(0.0, 1.0);
    final timePct = (secs / 72000).clamp(0.0, 1.0);
    final setPct = (sets / 200).clamp(0.0, 1.0);

    return RefreshIndicator(
      color: clubOrange,
      backgroundColor: appBackground,
      onRefresh: () async => _reload(),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
        children: [
          _HeroStatsCard(
            vol: vol,
            secs: secs,
            sets: sets,
            count: count,
            active: active,
            volPct: volPct,
            timePct: timePct,
            setPct: setPct,
            dur: _dur(secs),
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Cette période'),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _ModernStatCard(
                icon: Icons.fitness_center_rounded,
                label: 'Séances',
                value: '$count',
                accent: clubOrange,
              ),
              _ModernStatCard(
                icon: Icons.bar_chart_rounded,
                label: 'Volume',
                value: '${(vol / 1000).toStringAsFixed(1)}t',
                accent: blueAccent,
              ),
              _ModernStatCard(
                icon: Icons.timer_outlined,
                label: 'Temps total',
                value: _dur(secs),
                accent: purpleLight,
              ),
              _ModernStatCard(
                icon: Icons.repeat_rounded,
                label: 'Séries',
                value: '$sets',
                accent: greenAccent,
              ),
            ],
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Semaine en cours'),
          const SizedBox(height: 14),
          _ModernWeekCard(activeDays: active),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Volume · 8 dernières séances'),
          const SizedBox(height: 14),
          _ModernVolChart(bars: bars),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Objectifs de la période'),
          const SizedBox(height: 14),
          _ModernProgressCard(
            items: [
              _PItem(
                'Volume',
                '${(vol / 1000).toStringAsFixed(1)}t',
                volPct,
                clubOrange,
              ),
              _PItem('Temps', _dur(secs), timePct, blueAccent),
              _PItem(
                'Séances',
                '$count',
                (count / 30).clamp(0.0, 1.0),
                purpleLight,
              ),
              _PItem('Séries', '$sets', setPct, greenAccent),
            ],
          ),
        ],
      ),
    );
  });

  // =========================
  // ONGLET : HISTORIQUE
  // =========================

  Widget _history() => _withData((data) {
    final sessions = data.sessions;
    if (sessions.isEmpty) {
      return _empty(Icons.fitness_center_outlined, 'Aucune séance enregistrée');
    }
    return RefreshIndicator(
      color: clubOrange,
      backgroundColor: appBackground,
      onRefresh: () async => _reload(),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
        itemCount: sessions.length,
        itemBuilder: (_, i) {
          final s = sessions[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ModernSessionCard(
              title: (s['routine_name'] ?? 'Séance').toString(),
              date: _dateFull(_sessionDateStr(s)),
              vol: _i(s['total_volume']),
              dur: _dur(_i(s['duration_seconds'])),
              sets: _i(s['total_completed_sets'] ?? s['total_sets']),
              plan: s['is_from_planning'] == true,
              index: i,
            ),
          );
        },
      ),
    );
  });

  // =========================
  // ONGLET : ANALYSE
  // =========================

  Widget _analyse() => _withData((data) {
    final sessions = data.sessions;
    if (sessions.isEmpty) {
      return _empty(Icons.bar_chart_outlined, 'Pas encore de données');
    }
    final mm = _muscleMap(sessions);
    final tv = mm.values.fold(0.0, (s, e) => s + e.vol);
    final top = List<dynamic>.from(sessions)
      ..sort((a, b) => _i(b['total_volume']).compareTo(_i(a['total_volume'])));

    return RefreshIndicator(
      color: clubOrange,
      backgroundColor: appBackground,
      onRefresh: () async => _reload(),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
        children: [
          const SectionHeader(title: 'Répartition par exercice'),
          const SizedBox(height: 14),
          ...mm.values.toList().asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ModernAnalyseCard(
                m: e.value,
                pct: tv > 0 ? e.value.vol / tv : 0,
                index: e.key,
              ),
            ),
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Meilleures séances'),
          const SizedBox(height: 14),
          ...top
              .take(5)
              .toList()
              .asMap()
              .entries
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ModernSessionCard(
                    title: (e.value['routine_name'] ?? 'Séance').toString(),
                    date: _dateFull(_sessionDateStr(e.value)),
                    vol: _i(e.value['total_volume']),
                    dur: _dur(_i(e.value['duration_seconds'])),
                    sets: _i(
                      e.value['total_completed_sets'] ?? e.value['total_sets'],
                    ),
                    plan: false,
                    index: e.key,
                    showRank: true,
                  ),
                ),
              ),
        ],
      ),
    );
  });

  Widget _empty(IconData ic, String msg) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surfaceColor,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.line),
          ),
          child: Icon(ic, color: textSecondary.withOpacity(0.4), size: 40),
        ),
        const SizedBox(height: 16),
        Text(
          msg,
          style: TextStyle(
            color: textSecondary.withOpacity(0.6),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _reload,
          icon: const Icon(Icons.refresh_rounded, size: 16, color: clubOrange),
          label: const Text(
            "Rafraîchir",
            style: TextStyle(color: clubOrange, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

// =========================
// HERO CARD
// =========================

class _HeroStatsCard extends StatelessWidget {
  final double vol;
  final int secs, sets, count;
  final Set<int> active;
  final double volPct, timePct, setPct;
  final String dur;

  const _HeroStatsCard({
    required this.vol,
    required this.secs,
    required this.sets,
    required this.count,
    required this.active,
    required this.volPct,
    required this.timePct,
    required this.setPct,
    required this.dur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: clubOrange,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACTIVITÉ GLOBALE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1400),
                  curve: Curves.easeOutCubic,
                  builder: (_, t, __) => CustomPaint(
                    painter: _RingsPainter(
                      volPct: volPct * t,
                      timePct: timePct * t,
                      setPct: setPct * t,
                      center: '${active.length}/7',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _HeroStatRow(
                      icon: Icons.fitness_center_rounded,
                      label: 'Volume',
                      value: '${(vol / 1000).toStringAsFixed(1)}t',
                    ),
                    const SizedBox(height: 12),
                    _HeroStatRow(
                      icon: Icons.access_time_filled_rounded,
                      label: 'Temps',
                      value: dur,
                    ),
                    const SizedBox(height: 12),
                    _HeroStatRow(
                      icon: Icons.repeat_rounded,
                      label: 'Séries',
                      value: '$sets',
                    ),
                    const SizedBox(height: 12),
                    _HeroStatRow(
                      icon: Icons.check_circle_rounded,
                      label: 'Séances',
                      value: '$count',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatRow extends StatelessWidget {
  final IconData icon;
  final String label, value;

  const _HeroStatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 12, color: purpleAccent),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

// =========================
// RINGS PAINTER
// =========================

class _RingsPainter extends CustomPainter {
  final double volPct, timePct, setPct;
  final String center;

  const _RingsPainter({
    required this.volPct,
    required this.timePct,
    required this.setPct,
    required this.center,
  });

  void _ring(Canvas c, Offset o, double r, double pct, Color col, double w) {
    c.drawArc(
      Rect.fromCircle(center: o, radius: r),
      -math.pi / 2,
      math.pi * 2,
      false,
      Paint()
        ..color = col.withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round,
    );
    if (pct > 0) {
      c.drawArc(
        Rect.fromCircle(center: o, radius: r),
        -math.pi / 2,
        math.pi * 2 * pct.clamp(0, 1),
        false,
        Paint()
          ..color = col
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  void paint(Canvas c, Size s) {
    final o = Offset(s.width / 2, s.height / 2);
    _ring(c, o, 52, volPct, Colors.white, 10);
    _ring(c, o, 37, timePct, Colors.white.withOpacity(0.72), 10);
    _ring(c, o, 22, setPct, Colors.white.withOpacity(0.48), 10);
    final tp = TextPainter(
      text: TextSpan(
        text: center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(o.dx - tp.width / 2, o.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_RingsPainter o) =>
      o.volPct != volPct || o.timePct != timePct || o.setPct != setPct;
}

// =========================
// SECTION HEADER
// =========================
// STAT CARD
// =========================

class _ModernStatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color accent;

  const _ModernStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(icon, color: accent, size: 18),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: accent,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: textSecondary.withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// =========================
// WEEK CARD
// =========================

class _ModernWeekCard extends StatelessWidget {
  final Set<int> activeDays;

  const _ModernWeekCard({required this.activeDays});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final mon = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    const lbl = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isActive = activeDays.contains(i);
              final isToday = i == now.weekday - 1;
              final day = mon.add(Duration(days: i));
              return Column(
                children: [
                  Text(
                    lbl[i],
                    style: TextStyle(
                      color: isToday ? clubOrange : textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isActive
                          ? clubOrange
                          : (isToday
                                ? Colors.transparent
                                : Colors.white.withOpacity(0.07)),
                      shape: BoxShape.circle,
                      border: isToday && !isActive
                          ? Border.all(color: clubOrange, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: isActive
                              ? Colors.white
                              : (isToday ? clubOrange : textSecondary),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: Colors.white.withOpacity(0.06)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: clubOrange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
              const SizedBox(width: 10),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${activeDays.length}',
                      style: const TextStyle(
                        color: clubOrange,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: ' / 7 jours actifs cette semaine',
                      style: TextStyle(
                        color: textSecondary.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================
// VOLUME CHART
// =========================

class _ModernVolChart extends StatelessWidget {
  final List<_BarData> bars;

  const _ModernVolChart({required this.bars});

  @override
  Widget build(BuildContext context) {
    // ✅ FIX — protection division par zéro si tous les volumes sont 0
    final maxVol = bars.isEmpty
        ? 0
        : bars.map((b) => b.vol).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: SizedBox(
        height: 100,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: bars.map((b) {
            final pct = (maxVol == 0 || b.vol == 0) ? 0.0 : b.vol / maxVol;
            final isTop = pct > 0.85;
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0,
                    end: pct == 0 ? 4.0 : 12.0 + 72.0 * pct,
                  ),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, h, __) => Container(
                    width: 24,
                    height: h,
                    decoration: BoxDecoration(
                      color: isTop
                          ? clubOrange
                          : (pct > 0
                                ? textSecondary.withOpacity(0.2 + pct * 0.25)
                                : textSecondary.withOpacity(0.12)),
                      borderRadius: BorderRadius.circular(AppRadius.sm - 3),
                    ),
                  ),
                ),
                if (b.lbl.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    b.lbl.split('/').first,
                    style: TextStyle(
                      color: textSecondary.withOpacity(0.4),
                      fontSize: 9,
                    ),
                  ),
                ] else
                  const SizedBox(height: 16),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// =========================
// PROGRESS CARD
// =========================

class _ModernProgressCard extends StatelessWidget {
  final List<_PItem> items;

  const _ModernProgressCard({required this.items});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      children: items
          .asMap()
          .entries
          .map(
            (e) => Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: e.value.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          e.value.label,
                          style: TextStyle(
                            color: textSecondary.withOpacity(0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      e.value.value,
                      style: TextStyle(
                        color: e.value.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: e.value.pct.clamp(0.0, 1.0)),
                  duration: Duration(milliseconds: 900 + e.key * 100),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: v,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: e.value.color,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (e.key < items.length - 1) const SizedBox(height: 18),
              ],
            ),
          )
          .toList(),
    ),
  );
}

// =========================
// SESSION CARD
// =========================

class _ModernSessionCard extends StatelessWidget {
  final String title, date, dur;
  final int vol, sets, index;
  final bool plan, showRank;

  const _ModernSessionCard({
    required this.title,
    required this.date,
    required this.vol,
    required this.dur,
    required this.sets,
    required this.index,
    this.plan = false,
    this.showRank = false,
  });

  @override
  Widget build(BuildContext context) {
    const rankColors = [clubOrange, textSecondary, AppColors.warning];
    const rankIcons = ['🥇', '🥈', '🥉'];
    final isRanked = showRank && index < 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isRanked ? rankColors[index].withOpacity(0.3) : AppColors.line,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isRanked
                  ? rankColors[index].withOpacity(0.15)
                  : clubOrange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: isRanked
                ? Center(
                    child: Text(
                      rankIcons[index],
                      style: const TextStyle(fontSize: 20),
                    ),
                  )
                : const Icon(
                    Icons.fitness_center_rounded,
                    color: clubOrange,
                    size: 20,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (plan) ...[
                      const SizedBox(width: 8),
                      const StatusDot(color: clubOrange, label: 'Planning'),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: TextStyle(
                        color: textSecondary.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '  ·  ',
                      style: TextStyle(color: textSecondary.withOpacity(0.3)),
                    ),
                    Icon(
                      Icons.timer_outlined,
                      size: 11,
                      color: textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dur,
                      style: TextStyle(
                        color: textSecondary.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$vol kg',
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$sets séries',
                style: TextStyle(
                  color: textSecondary.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================
// ANALYSE CARD
// =========================

class _ModernAnalyseCard extends StatelessWidget {
  final _Muscle m;
  final double pct;
  final int index;

  const _ModernAnalyseCard({
    required this.m,
    required this.pct,
    required this.index,
  });

  /// Palette limitée à 3 couleurs du thème, cyclées avec sens plutôt
  /// qu'une couleur ad hoc différente par exercice.
  Color get _accent {
    const colors = [AppColors.accent, AppColors.info, AppColors.success];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      m.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${(pct * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: _accent,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: pct.clamp(0, 1)),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => Stack(
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              FractionallySizedBox(
                widthFactor: v,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${m.count} séances  ·  ${m.vol.toInt()} kg  ·  ${m.sets} séries',
          style: TextStyle(
            color: textSecondary.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
