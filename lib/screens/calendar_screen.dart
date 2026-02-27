import 'package:flutter/material.dart';
import '../services/routine_service.dart';

const Color clubOrange = Color(0xFFF57809);
const Color appBackground = Color(0xFF000000);
const Color surfaceColor = Color(0xFF1E1E1E);
const Color textPrimary = Color(0xFFFFFFFF);
const Color textSecondary = Color(0xFFA0A5B1);

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _isLoading = true;
  List<dynamic> _allSessions = [];

  final Map<String, List<dynamic>> _sessionsByDate = {};

  final List<String> _monthNamesFull = [
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

  final List<String> _monthNamesShort = [
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

  final List<String> _weekDays = [
    "Lun",
    "Mar",
    "Mer",
    "Jeu",
    "Ven",
    "Sam",
    "Dim",
  ];

  // 0 = Mois, 1 = Année, 2 = Plusieurs années
  int _selectedView = 0;

  late List<DateTime> _monthsList;
  late List<int> _yearsList;

  // Statistiques calculées
  int _currentStreak = 0; // ✅ Remplacé _weeklyStreak par _currentStreak
  int _restDaysLast30Days = 0;

  final ScrollController _monthScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  @override
  void dispose() {
    _monthScrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentMonth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_monthScrollController.hasClients) {
        _monthScrollController.jumpTo(
          _monthScrollController.position.maxScrollExtent,
        );
      }
    });
  }

  void _generateLists() {
    DateTime now = DateTime.now();

    // Vue "Mois" : de Janvier au mois en cours
    _monthsList = [];
    for (int i = 1; i <= now.month; i++) {
      _monthsList.add(DateTime(now.year, i, 1));
    }

    // Vue "Année" et "Plusieurs années"
    _yearsList = [];
    if (_selectedView == 1) {
      _yearsList.add(now.year);
    } else if (_selectedView == 2) {
      _yearsList.addAll([now.year - 1, now.year]);
    }
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await RoutineService().getWorkoutSessions(
        rangeDays: 365 * 3,
      );

      if (!mounted) return;

      setState(() {
        _allSessions = sessions;
        _sessionsByDate.clear();

        for (var session in _allSessions) {
          String? dateStr =
              session['date'] ??
              session['createdAt'] ??
              session['completedAt'] ??
              session['performed_at'];

          if (dateStr != null) {
            try {
              final dt = DateTime.parse(dateStr).toLocal();
              final dateKey = _formatDateKey(dt);

              if (!_sessionsByDate.containsKey(dateKey)) {
                _sessionsByDate[dateKey] = [];
              }
              _sessionsByDate[dateKey]!.add(session);
            } catch (_) {}
          }
        }

        _calculateStats();
        _generateLists();
        _isLoading = false;
      });

      if (_selectedView == 0) {
        _scrollToCurrentMonth();
      }
    } catch (e) {
      debugPrint("Erreur chargement calendrier: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // ==========================================
  // 🔥 LOGIQUE DES STATISTIQUES (Série en jours)
  // ==========================================
  void _calculateStats() {
    final now = DateTime.now();

    int workouts30 = 0;
    for (int i = 0; i < 30; i++) {
      final dateToCheck = now.subtract(Duration(days: i));
      if (_sessionsByDate.containsKey(_formatDateKey(dateToCheck))) {
        workouts30++;
      }
    }
    _restDaysLast30Days = 30 - workouts30;

    // ✅ Calcul de la série actuelle (Streak) en JOURS
    int streak = 0;
    DateTime checkDate = now;

    // Tolérance : Si pas de séance aujourd'hui, on commence à compter à partir d'hier
    final todayKey = _formatDateKey(now);
    if (!_sessionsByDate.containsKey(todayKey)) {
      checkDate = now.subtract(const Duration(days: 1));
    }

    while (true) {
      final key = _formatDateKey(checkDate);
      if (_sessionsByDate.containsKey(key)) {
        streak++;
        checkDate = checkDate.subtract(
          const Duration(days: 1),
        ); // On recule d'un jour
      } else {
        break; // La chaîne est brisée
      }
    }
    _currentStreak = streak;
  }

  String _getShortSessionName(List<dynamic> sessions) {
    if (sessions.isEmpty) return "";
    final session = sessions.first;

    String name =
        (session['name'] ??
                session['routineName'] ??
                session['routine_name'] ??
                session['muscleGroup'] ??
                "Sport")
            .toString();

    final parts = name.split(RegExp(r'\s|-|_'));
    if (parts.isNotEmpty) {
      String shortName = parts.first;
      if (shortName.length > 7) {
        return "${shortName.substring(0, 6)}.";
      }
      return shortName;
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "Historique",
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: clubOrange))
          : Column(
              children: [
                _buildViewToggle(),
                _buildMinimalistStatsHeader(),

                Expanded(child: _buildCurrentView()),
              ],
            ),
    );
  }

  // ==========================================
  // 🔥 WIDGET: SÉLECTEUR DE VUE (Pilules)
  // ==========================================
  Widget _buildViewToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          _buildToggleBtn("Mois", 0),
          _buildToggleBtn("Année", 1),
          _buildToggleBtn("Plusieurs années", 2),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String label, int index) {
    bool isSelected = _selectedView == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedView = index;
            _generateLists();
          });
          if (index == 0) {
            _scrollToCurrentMonth();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : textSecondary,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    if (_selectedView == 0) {
      return ListView(
        controller: _monthScrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        children: _monthsList
            .map((month) => _buildLargeMonthBlock(month))
            .toList(),
      );
    } else if (_selectedView == 1) {
      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        itemCount: _yearsList.length,
        itemBuilder: (context, index) => _buildYearGridBlock(_yearsList[index]),
      );
    } else {
      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        itemCount: _yearsList.length,
        itemBuilder: (context, index) =>
            _buildMultiYearBlock(_yearsList[index]),
      );
    }
  }

  // ==========================================
  // 🔥 WIDGET: EN-TÊTE STATS MINIMALISTE
  // ==========================================
  Widget _buildMinimalistStatsHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 0, bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFFE55B40),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                "Série de $_currentStreak jour(s)", // ✅ Affichage en jours
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withOpacity(0.15),
          ),
          Row(
            children: [
              const Icon(
                Icons.nightlight_round,
                color: Color(0xFF4A90E2),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "$_restDaysLast30Days jours de repos",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🟢 VUE 1 : MOIS (Grands jours avec noms)
  // ==========================================
  Widget _buildLargeMonthBlock(DateTime monthDate) {
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    final firstDayOffset = firstDayOfMonth.weekday - 1;
    final totalCells = daysInMonth + firstDayOffset;
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${_monthNamesFull[monthDate.month - 1]} ${monthDate.year}",
            style: const TextStyle(
              color: clubOrange,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weekDays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      color: textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 10,
              crossAxisSpacing: 4,
              childAspectRatio: 0.65,
            ),
            itemCount: rows * 7,
            itemBuilder: (context, index) {
              if (index < firstDayOffset || index >= totalCells) {
                return const SizedBox();
              }

              final dayNumber = index - firstDayOffset + 1;
              final cellDate = DateTime(
                monthDate.year,
                monthDate.month,
                dayNumber,
              );
              final dateKey = _formatDateKey(cellDate);

              final isToday =
                  cellDate.year == DateTime.now().year &&
                  cellDate.month == DateTime.now().month &&
                  cellDate.day == DateTime.now().day;

              final hasTrained = _sessionsByDate.containsKey(dateKey);
              final sessionsForDay = _sessionsByDate[dateKey] ?? [];

              return GestureDetector(
                onTap: () {
                  if (hasTrained) _showDayDetails(cellDate, sessionsForDay);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: hasTrained ? clubOrange : surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isToday
                              ? Colors.white.withOpacity(0.8)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          dayNumber.toString(),
                          style: TextStyle(
                            color: hasTrained || isToday
                                ? Colors.white
                                : textSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasTrained)
                      Text(
                        _getShortSessionName(sessionsForDay),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: clubOrange,
                          fontSize: 9,
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

  // ==========================================
  // 🔵 VUE 2 : ANNÉE (Grille de petits mois)
  // ==========================================
  Widget _buildYearGridBlock(int year) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$year",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: List.generate(4, (rowIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(3, (colIndex) {
                    int monthIndex = (rowIndex * 3) + colIndex + 1;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: colIndex < 2 ? 16.0 : 0,
                        ),
                        child: _buildMiniMonth(year, monthIndex),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMonth(int year, int month) {
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstDayOffset = firstDayOfMonth.weekday - 1;
    final totalCells = daysInMonth + firstDayOffset;
    final rows = (totalCells / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _monthNamesShort[month - 1],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 3,
            mainAxisSpacing: 3,
          ),
          itemCount: rows * 7,
          itemBuilder: (context, index) {
            if (index < firstDayOffset || index >= totalCells) {
              return const SizedBox();
            }

            final dayNumber = index - firstDayOffset + 1;
            final cellDate = DateTime(year, month, dayNumber);
            final dateKey = _formatDateKey(cellDate);

            final hasTrained = _sessionsByDate.containsKey(dateKey);

            return Container(
              decoration: BoxDecoration(
                color: hasTrained ? clubOrange : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        ),
      ],
    );
  }

  // ==========================================
  // 🟣 VUE 3 : PLUSIEURS ANNÉES (Heatmap GitHub)
  // ==========================================
  Widget _buildMultiYearBlock(int year) {
    DateTime firstDay = DateTime(year, 1, 1);
    int daysInYear = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
        ? 366
        : 365;

    int offset = firstDay.weekday - 1;
    int totalCells = offset + daysInYear;
    int totalWeeks = (totalCells / 7).ceil();

    List<int> monthWeekIndices = [];
    for (int m = 1; m <= 12; m++) {
      DateTime firstOfMonth = DateTime(year, m, 1);
      int dayOfYear = firstOfMonth.difference(firstDay).inDays;
      monthWeekIndices.add((offset + dayOfYear) ~/ 7);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$year",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 20,
                  width: totalWeeks * 12.0,
                  child: Stack(
                    children: List.generate(12, (m) {
                      int weekIndex = monthWeekIndices[m];
                      return Positioned(
                        left: weekIndex * 12.0,
                        child: Text(
                          _monthNamesShort[m],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(totalWeeks, (weekIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 2.0),
                      child: Column(
                        children: List.generate(7, (dayIndex) {
                          int cellIndex = (weekIndex * 7) + dayIndex;

                          if (cellIndex < offset ||
                              cellIndex >= offset + daysInYear) {
                            return Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(bottom: 2),
                              color: Colors.transparent,
                            );
                          }

                          int dayOfYear = cellIndex - offset;
                          DateTime cellDate = firstDay.add(
                            Duration(days: dayOfYear),
                          );
                          bool hasTrained = _sessionsByDate.containsKey(
                            _formatDateKey(cellDate),
                          );

                          return Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              color: hasTrained
                                  ? clubOrange
                                  : Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DÉTAILS DE LA SÉANCE
  // ==========================================
  void _showDayDetails(DateTime date, List<dynamic> sessions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Séance(s) du ${date.day} ${_monthNamesFull[date.month - 1]}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
              ...sessions.map((session) {
                final title =
                    session['name'] ??
                    session['routineName'] ??
                    session['routine_name'] ??
                    "Entraînement Libre";
                final duration =
                    session['durationMin'] ??
                    (session['duration_seconds'] != null
                        ? (session['duration_seconds'] ~/ 60)
                        : "--");

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: appBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: clubOrange.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: clubOrange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.toString().toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Durée : $duration min",
                              style: const TextStyle(
                                color: textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
