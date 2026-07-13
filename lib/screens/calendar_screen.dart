import 'package:flutter/material.dart';
import '../services/routine_service.dart';
import '../theme/app_theme.dart';
import '../widgets/design_system.dart';

const Color clubOrange = AppColors.accent;
const Color appBackground = AppColors.bg;
const Color surfaceColor = AppColors.surfaceAlt;
const Color textPrimary = AppColors.textPrimary;
const Color textSecondary = AppColors.textSecondary;

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  // =========================
  // DATA
  // =========================
  bool _isLoading = true;
  List<dynamic> _allSessions = [];
  final Map<String, List<dynamic>> _sessionsByDate = {};

  // =========================
  // VUE
  // =========================
  int _selectedView = 0; // 0 = Mois, 1 = Année, 2 = Plusieurs années

  // ✅ FIX — Initialisées avec des valeurs par défaut, plus de `late`
  List<DateTime> _monthsList = [];
  List<int> _yearsList = [];

  // =========================
  // STATS
  // =========================
  int _currentStreak = 0;
  int _restDaysLast30Days = 0;
  int _totalSessionsLast30Days = 0;

  // =========================
  // ANIMATION
  // =========================
  late final AnimationController _toggleAnimController;

  // =========================
  // LABELS
  // =========================
  static const List<String> _monthNamesFull = [
    "Janvier",
    "Février",
    "Mars",
    "Avril",
    "Mai",
    "Juin",
    "Juillet",
    "Août",
    "Septembre",
    "Octobre",
    "Novembre",
    "Décembre",
  ];
  static const List<String> _monthNamesShort = [
    "janv.",
    "févr.",
    "mars",
    "avr.",
    "mai",
    "juin",
    "juil.",
    "août",
    "sept.",
    "oct.",
    "nov.",
    "déc.",
  ];
  static const List<String> _weekDays = ["L", "M", "M", "J", "V", "S", "D"];

  @override
  void initState() {
    super.initState();
    _toggleAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fetchHistory();
  }

  @override
  void dispose() {
    _toggleAnimController.dispose();
    super.dispose();
  }

  // =========================
  // GÉNÉRATION DES LISTES
  // =========================

  void _generateLists() {
    final now = DateTime.now();

    // Vue Mois : mois courant → janvier (plus récent en premier)
    _monthsList = [
      for (int i = now.month; i >= 1; i--) DateTime(now.year, i, 1),
    ];

    // Vue Année et Plusieurs années
    if (_selectedView == 1) {
      _yearsList = [now.year];
    } else if (_selectedView == 2) {
      _yearsList = [now.year - 1, now.year];
    } else {
      _yearsList = [];
    }
  }

  // =========================
  // FETCH API
  // =========================

  Future<void> _fetchHistory() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final sessions = await RoutineService().getWorkoutSessions(
        rangeDays: 365 * 3,
      );
      if (!mounted) return;
      setState(() {
        _allSessions = sessions;
        _sessionsByDate.clear();
        for (final session in _allSessions) {
          final dateStr =
              session['date'] ??
              session['createdAt'] ??
              session['completedAt'] ??
              session['performed_at'];
          if (dateStr != null) {
            try {
              final dt = DateTime.parse(dateStr.toString()).toLocal();
              final key = _dateKey(dt);
              _sessionsByDate.putIfAbsent(key, () => []).add(session);
            } catch (_) {}
          }
        }
        _calculateStats();
        _generateLists();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erreur chargement calendrier: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _dateKey(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  // =========================
  // CALCUL STATS
  // =========================

  void _calculateStats() {
    final now = DateTime.now();

    int workouts30 = 0;
    for (int i = 0; i < 30; i++) {
      if (_sessionsByDate.containsKey(
        _dateKey(now.subtract(Duration(days: i))),
      )) {
        workouts30++;
      }
    }
    _totalSessionsLast30Days = workouts30;
    _restDaysLast30Days = 30 - workouts30;

    // ✅ Streak en jours consécutifs (tolérance : si pas de séance aujourd'hui, on commence à hier)
    int streak = 0;
    DateTime checkDate = now;
    if (!_sessionsByDate.containsKey(_dateKey(now))) {
      checkDate = now.subtract(const Duration(days: 1));
    }
    while (_sessionsByDate.containsKey(_dateKey(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    _currentStreak = streak;
  }

  // =========================
  // HELPER : Nom court de session
  // =========================

  String _shortSessionName(List<dynamic> sessions) {
    if (sessions.isEmpty) return "";
    final session = sessions.first;
    final name =
        (session['name'] ??
                session['routineName'] ??
                session['routine_name'] ??
                session['muscleGroup'] ??
                "Sport")
            .toString();
    final first = name.split(RegExp(r'\s|-|_')).first;
    return first.length > 7 ? "${first.substring(0, 6)}." : first;
  }

  // ✅ FIX — Année bissextile via DateTime (plus simple et correct)
  bool _isLeapYear(int year) => DateTime(year, 2, 29).month == 2;

  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        centerTitle: true,
        title: const Text(
          "Historique",
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: _fetchHistory,
            tooltip: "Rafraîchir",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: clubOrange))
          : Column(
              children: [
                _buildStatsHeader(),
                _buildViewToggle(),
                Expanded(child: _buildCurrentView()),
              ],
            ),
    );
  }

  // =========================
  // EN-TÊTE STATS
  // =========================

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatChip(
              icon: Icons.local_fire_department_rounded,
              iconColor: AppColors.accent,
              value: "$_currentStreak",
              label: "jours consécutifs",
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.line),
          Expanded(
            child: _StatChip(
              icon: Icons.fitness_center_rounded,
              iconColor: AppColors.textSecondary,
              value: "$_totalSessionsLast30Days",
              label: "séances / 30j",
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.line),
          Expanded(
            child: _StatChip(
              icon: Icons.nightlight_round,
              iconColor: AppColors.textSecondary,
              value: "$_restDaysLast30Days",
              label: "jours de repos",
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // TOGGLE VUE
  // =========================

  Widget _buildViewToggle() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          _buildToggleBtn("Mois", 0),
          _buildToggleBtn("Année", 1),
          _buildToggleBtn("Multi-années", 2),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String label, int index) {
    final isSelected = _selectedView == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedView = index;
            _generateLists();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? clubOrange.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: isSelected
                  ? clubOrange.withOpacity(0.35)
                  : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? clubOrange : textSecondary,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // ROUTEUR VUE
  // =========================

  Widget _buildCurrentView() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      child: KeyedSubtree(
        key: ValueKey(_selectedView),
        child: switch (_selectedView) {
          0 => ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 60, top: 8),
            children: _monthsList.map(_buildLargeMonthBlock).toList(),
          ),
          1 => ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 60),
            itemCount: _yearsList.length,
            itemBuilder: (_, i) => _buildYearGridBlock(_yearsList[i]),
          ),
          _ => ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 60),
            itemCount: _yearsList.length,
            itemBuilder: (_, i) => _buildMultiYearBlock(_yearsList[i]),
          ),
        },
      ),
    );
  }

  // =========================
  // VUE 1 : MOIS (Grands jours)
  // =========================

  Widget _buildLargeMonthBlock(DateTime monthDate) {
    final firstDay = DateTime(monthDate.year, monthDate.month, 1);
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    final firstDayOffset = firstDay.weekday - 1; // 0 = lundi
    final totalCells = daysInMonth + firstDayOffset;
    final rows = (totalCells / 7).ceil();
    final now = DateTime.now();

    // Vérifie si ce mois a des séances
    bool monthHasSession = false;
    for (int d = 1; d <= daysInMonth; d++) {
      if (_sessionsByDate.containsKey(
        _dateKey(DateTime(monthDate.year, monthDate.month, d)),
      )) {
        monthHasSession = true;
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du mois
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _monthNamesFull[monthDate.month - 1].toUpperCase(),
                style: TextStyle(
                  color: monthHasSession
                      ? AppColors.accent
                      : AppColors.textSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "${monthDate.year}",
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Jours de la semaine
          Row(
            children: _weekDays
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.7),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),

          // Grille des jours
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 4,
              childAspectRatio: 0.68,
            ),
            itemCount: rows * 7,
            itemBuilder: (context, index) {
              if (index < firstDayOffset || index >= totalCells)
                return const SizedBox();

              final dayNumber = index - firstDayOffset + 1;
              final cellDate = DateTime(
                monthDate.year,
                monthDate.month,
                dayNumber,
              );
              final dateKey = _dateKey(cellDate);
              final isToday =
                  cellDate.year == now.year &&
                  cellDate.month == now.month &&
                  cellDate.day == now.day;
              final hasTrained = _sessionsByDate.containsKey(dateKey);
              final sessions = _sessionsByDate[dateKey] ?? [];
              final isFuture = cellDate.isAfter(now);

              return GestureDetector(
                onTap: hasTrained
                    ? () => _showDayDetails(cellDate, sessions)
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasTrained
                            ? AppColors.success
                            : isToday
                            ? AppColors.accent.withOpacity(0.1)
                            : Colors.transparent,
                        border: Border.all(
                          color: isToday
                              ? AppColors.accent
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "$dayNumber",
                          style: TextStyle(
                            color: hasTrained
                                ? AppColors.bg
                                : isFuture
                                ? AppColors.textSecondary.withOpacity(0.4)
                                : isToday
                                ? AppColors.accent
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (hasTrained)
                      Text(
                        _shortSessionName(sessions),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================
  // VUE 2 : ANNÉE (Mini mois)
  // =========================

  Widget _buildYearGridBlock(int year) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$year",
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(
            4,
            (rowIndex) => Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(3, (colIndex) {
                  final monthIndex = rowIndex * 3 + colIndex + 1;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: colIndex < 2 ? 14.0 : 0),
                      child: _buildMiniMonth(year, monthIndex),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMonth(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstDayOffset = firstDay.weekday - 1;
    final totalCells = daysInMonth + firstDayOffset;
    final rows = (totalCells / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _monthNamesShort[month - 1],
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: rows * 7,
          itemBuilder: (context, index) {
            if (index < firstDayOffset || index >= totalCells)
              return const SizedBox();
            final dayNumber = index - firstDayOffset + 1;
            final hasTrained = _sessionsByDate.containsKey(
              _dateKey(DateTime(year, month, dayNumber)),
            );
            return Container(
              decoration: BoxDecoration(
                color: hasTrained ? AppColors.success : AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        ),
      ],
    );
  }

  // =========================
  // VUE 3 : MULTI-ANNÉES (Heatmap)
  // =========================

  Widget _buildMultiYearBlock(int year) {
    final firstDay = DateTime(year, 1, 1);
    // ✅ FIX — Calcul bissextile via DateTime
    final daysInYear = _isLeapYear(year) ? 366 : 365;
    final offset = firstDay.weekday - 1;
    final totalCells = offset + daysInYear;
    final totalWeeks = (totalCells / 7).ceil();

    // Position de chaque mois dans la grille (en semaines)
    final monthWeekIndices = List.generate(12, (m) {
      final firstOfMonth = DateTime(year, m + 1, 1);
      final dayOfYear = firstOfMonth.difference(firstDay).inDays;
      return (offset + dayOfYear) ~/ 7;
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$year",
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Labels des mois
                SizedBox(
                  height: 18,
                  width: totalWeeks * 13.0,
                  child: Stack(
                    children: List.generate(
                      12,
                      (m) => Positioned(
                        left: monthWeekIndices[m] * 13.0,
                        child: Text(
                          _monthNamesShort[m],
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Grille heatmap
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(totalWeeks, (weekIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 3.0),
                      child: Column(
                        children: List.generate(7, (dayIndex) {
                          final cellIndex = weekIndex * 7 + dayIndex;
                          if (cellIndex < offset ||
                              cellIndex >= offset + daysInYear) {
                            return const SizedBox(width: 10, height: 12);
                          }
                          final dayOfYear = cellIndex - offset;
                          final cellDate = firstDay.add(
                            Duration(days: dayOfYear),
                          );
                          final sessions = _sessionsByDate[_dateKey(cellDate)];
                          final count = sessions?.length ?? 0;

                          // ✅ Intensité selon le nombre de séances
                          final color = count == 0
                              ? AppColors.line
                              : count == 1
                              ? AppColors.success.withOpacity(0.45)
                              : count == 2
                              ? AppColors.success.withOpacity(0.75)
                              : AppColors.success;

                          return GestureDetector(
                            onTap: count > 0
                                ? () => _showDayDetails(cellDate, sessions!)
                                : null,
                            child: Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(bottom: 3),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                // Légende intensité
                Row(
                  children: [
                    Text(
                      "Moins",
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(width: 4),
                    ...[0.06, 0.45, 0.75, 1.0].map(
                      (opacity) => Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: 3),
                        decoration: BoxDecoration(
                          color: opacity < 0.2
                              ? AppColors.line
                              : AppColors.success.withOpacity(opacity),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Plus",
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // BOTTOM SHEET DÉTAILS JOUR
  // =========================

  void _showDayDetails(DateTime date, List<dynamic> sessions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Handle drag
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre du jour
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${date.day} ${_monthNamesFull[date.month - 1]} ${date.year}"
                              .toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "${sessions.length} séance${sessions.length > 1 ? 's' : ''}",
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...sessions.map((session) {
                      final title =
                          (session['name'] ??
                                  session['routineName'] ??
                                  session['routine_name'] ??
                                  "Entraînement Libre")
                              .toString();
                      final rawDuration =
                          session['durationMin'] ??
                          (session['duration_seconds'] != null
                              ? session['duration_seconds'] ~/ 60
                              : null);
                      final durationLabel = rawDuration != null
                          ? "$rawDuration min"
                          : "--";

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                color: AppColors.accent,
                                size: 22,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title.toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.timer_outlined,
                                          size: 13,
                                          color: textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          durationLabel,
                                          style: const TextStyle(
                                            color: textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =========================
// WIDGET STAT CHIP
// =========================

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, color: iconColor, size: 20),
      const SizedBox(height: 5),
      Text(
        value,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
