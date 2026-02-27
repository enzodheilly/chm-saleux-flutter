import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/workout_manager.dart';
import '../widgets/active_workout_bar.dart';
import 'progress_screen.dart';

import '../services/auth_service.dart';
import '../services/routine_service.dart';
import '../services/news_service.dart';
import 'workout_player_screen.dart';
import 'create_routine_screen.dart';
import 'profile_screen.dart';
import 'program_config_screen.dart';
import 'calendar_screen.dart';

const Color clubOrange = Color(0xFFF57809);
const Color appBackground = Color(0xFF000000);
const Color navBarColor = Color(0xFF000000);
const Color surfaceColor = Color(0xFF1E1E1E);
const Color textPrimary = Color(0xFFFFFFFF);
const Color textSecondary = Color(0xFFA0A5B1);
const Color purpleButton = Color(0xFF5E35B1);

// ✅ Enumération pour l'état des jours du calendrier
enum _DayState { completed, missed, today, future }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  String currentUserName = "Chargement...";
  String? profileImageUrl;

  List<dynamic> allPrograms = [];
  List<dynamic> lastSessions = [];
  List<dynamic> siteNews = [];
  Map<String, dynamic>? profile;

  bool isLoading = true;
  bool isNewsLoading = true;

  final Set<int> _favoriteRoutineIds = <int>{};

  // ✅ Données dynamiques du calendrier
  List<Map<String, dynamic>> _weekDays = [];

  @override
  void initState() {
    super.initState();
    _fetchCoreData();
    _fetchNews();
  }

  Future<void> _fetchCoreData() async {
    try {
      final results = await Future.wait([
        AuthService().getUserProfile(),
        RoutineService().getAllPrograms(),
        RoutineService().getWorkoutSessions(rangeDays: 30),
      ]);

      if (!mounted) return;

      final prof = results[0] as Map<String, dynamic>?;
      final programs = results[1] as List<dynamic>;
      final sessions = results[2] as List<dynamic>;

      setState(() {
        profile = prof;

        if (prof != null) {
          final rawFirstName =
              (prof['firstName'] ?? prof['firstname'] ?? prof['prenom'] ?? "")
                  .toString()
                  .trim();
          final rawLastName =
              (prof['lastName'] ??
                      prof['lastname'] ??
                      prof['name'] ??
                      prof['nom'] ??
                      "")
                  .toString()
                  .trim();

          String capitalize(String s) {
            if (s.isEmpty) return "";
            return s[0].toUpperCase() + s.substring(1).toLowerCase();
          }

          final firstName = capitalize(rawFirstName);
          final lastName = capitalize(rawLastName);

          final fullName = "$firstName $lastName".trim();

          if (fullName.isNotEmpty) {
            currentUserName = fullName;
          } else {
            currentUserName = "Athlète";
          }

          profileImageUrl = prof['profileImageUrl'] ?? prof['avatar'];
        }

        allPrograms = programs;
        lastSessions = sessions;

        // ✅ Mise à jour du calendrier
        _buildCalendarData();

        isLoading = false;
      });
    } catch (e) {
      debugPrint("Erreur chargement principal: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchNews() async {
    try {
      final news = await NewsService().getSiteNews();
      if (!mounted) return;
      setState(() {
        siteNews = news;
        isNewsLoading = false;
      });
    } catch (e) {
      debugPrint("Erreur chargement news: $e");
      if (!mounted) return;
      setState(() => isNewsLoading = false);
    }
  }

  // ✅ LOGIQUE DU CALENDRIER CONNECTÉ
  void _buildCalendarData() {
    final now = DateTime.now();
    final currentWeekday = now.weekday;
    final monday = now.subtract(Duration(days: currentWeekday - 1));

    Set<String> sessionDates = {};
    for (var session in lastSessions) {
      String? dateStr =
          session['date'] ??
          session['createdAt'] ??
          session['completedAt'] ??
          session['performed_at'];
      if (dateStr != null) {
        try {
          final dt = DateTime.parse(dateStr).toLocal();
          sessionDates.add(
            "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}",
          );
        } catch (_) {}
      }
    }

    _weekDays = [];
    List<String> dayNames = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"];

    for (int i = 0; i < 7; i++) {
      final dayDate = monday.add(Duration(days: i));
      final dateKey =
          "${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}";

      _DayState state;
      final isToday =
          (dayDate.year == now.year &&
          dayDate.month == now.month &&
          dayDate.day == now.day);

      if (isToday) {
        state = sessionDates.contains(dateKey)
            ? _DayState.completed
            : _DayState.today;
      } else if (dayDate.isAfter(now)) {
        state = _DayState.future;
      } else {
        state = sessionDates.contains(dateKey)
            ? _DayState.completed
            : _DayState.missed;
      }

      _weekDays.add({
        "dayName": dayNames[i],
        "dayNumber": dayDate.day.toString(),
        "state": state,
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Bonjour,";
    } else if (hour < 17) {
      return "Bon après-midi,";
    } else {
      return "Bonsoir,";
    }
  }

  String? _resolveBackendImageUrl(dynamic rawValue) {
    if (rawValue == null) return null;
    final raw = rawValue.toString().trim();
    if (raw.isEmpty || raw == 'null') return null;
    if (raw.startsWith('https://')) return raw;
    if (raw.startsWith('http://127.0.0.1:8000')) {
      return raw.replaceFirst('http://127.0.0.1:8000', 'http://10.0.2.2:8000');
    }
    if (raw.startsWith('http://localhost:8000')) {
      return raw.replaceFirst('http://localhost:8000', 'http://10.0.2.2:8000');
    }
    if (raw.startsWith('http://')) return raw;
    if (raw.startsWith('/uploads/')) return 'http://10.0.2.2:8000$raw';
    if (raw.startsWith('uploads/')) return 'http://10.0.2.2:8000/$raw';
    if (raw.startsWith('/')) return 'http://10.0.2.2:8000$raw';
    return 'http://10.0.2.2:8000/uploads/$raw';
  }

  String? _buildArticleImageUrl(dynamic photoValue) {
    return _resolveBackendImageUrl(photoValue);
  }

  void _toggleFavorite(int routineId) {
    setState(() {
      if (_favoriteRoutineIds.contains(routineId)) {
        _favoriteRoutineIds.remove(routineId);
      } else {
        _favoriteRoutineIds.add(routineId);
      }
    });
  }

  String _getImageForGroup(String groupName) {
    final name = groupName.toLowerCase().trim();
    if (name.contains("pec") || name.contains("push")) {
      return "assets/images/pecs.jpg";
    }
    if (name.contains("dos") || name.contains("pull")) {
      return "assets/images/dos.jpg";
    }
    if (name.contains("jambe") || name.contains("leg")) {
      return "assets/images/jambes.jpg";
    }
    if (name.contains("bras") || name.contains("biceps")) {
      return "assets/images/bras.jpg";
    }
    if (name.contains("epaule") || name.contains("épaule")) {
      return "assets/images/epaules.jpg";
    }
    if (name.contains("abdo") || name.contains("abs")) {
      return "assets/images/abdos.jpg";
    }
    if (name.contains("cardio") || name.contains("run")) {
      return "assets/images/cardio.jpg";
    }
    return "assets/images/default.jpg";
  }

  List<Map<String, dynamic>> _buildForYouPrograms() {
    if (allPrograms.isEmpty) return [];

    final Map<String, List<dynamic>> grouped = {};
    for (final p in allPrograms) {
      final g = (p['muscleGroup'] ?? "Autre").toString();
      grouped.putIfAbsent(g, () => []);
      grouped[g]!.add(p);
    }

    final groups = grouped.keys.toList();
    final takeGroups = groups.take(5).toList();

    return takeGroups.map((g) {
      final variations = grouped[g]!;
      final rep = variations.first;
      final duration = rep['estimatedDurationMin'] ?? 60;

      final level = (rep['level'] ?? "intermediaire").toString();
      final labelLevel = level == "debutant"
          ? "Débutant"
          : (level == "avance" ? "Avancé" : "Intermédiaire");

      return {
        "title": g,
        "variationsCount": variations.length,
        "averageTime": "$duration min",
        "level": labelLevel,
        "imgUrl": _getImageForGroup(g),
        "routineId": rep['id'],
        "variations": variations,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: _TopBar(
                userName: currentUserName,
                greeting: _getGreeting(),
                notifCount: 3,
                userImage: profileImageUrl,
                onProfileTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                  _fetchCoreData();
                },
                onNotifTap: () {},
                onCalendarTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CalendarScreen()),
                  );
                },
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  IndexedStack(
                    index: _selectedIndex,
                    children: [
                      _buildHomeTabs(),
                      const CreateRoutineScreen(),
                      const ProgressScreen(),
                      const Center(
                        child: Text(
                          "HALTÉROPHILIE",
                          style: TextStyle(color: textPrimary),
                        ),
                      ),
                      const Center(
                        child: Text(
                          "ABONNEMENT",
                          style: TextStyle(color: textPrimary),
                        ),
                      ),
                    ],
                  ),
                  Consumer<WorkoutManager>(
                    builder: (context, manager, child) {
                      if (!manager.isActive) return const SizedBox.shrink();
                      return const Positioned(
                        left: 16,
                        right: 16,
                        bottom: 110,
                        child: ActiveWorkoutBar(),
                      );
                    },
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24 + MediaQuery.of(context).padding.bottom,
                    child: _GlassBottomNav(
                      currentIndex: _selectedIndex,
                      onTap: (i) => setState(() => _selectedIndex = i),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTabs() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: const TabBar(
                indicatorColor: clubOrange,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: textSecondary,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.1,
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.1,
                ),
                tabs: [
                  Tab(text: "Toi"),
                  Tab(text: "Actualités"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(children: [_buildUserTab(), _buildNewsTab()]),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTab() {
    final forYou = _buildForYouPrograms();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 140),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _CircleCalendarTransparent(
            weekDays: _weekDays,
            isLoading: isLoading,
          ),
        ),
        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _RecentStatsCard(
            sessions: lastSessions,
            profile: profile,
            isLoading: isLoading,
          ),
        ),
        const SizedBox(height: 32),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _SectionHeader(
            title: "ENTRAÎNEMENTS POUR TOI",
            actionText: "VOIR TOUT",
            onAction: () => setState(() => _selectedIndex = 1),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 190,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: clubOrange),
                )
              : (forYou.isEmpty
                    ? const Center(
                        child: Text(
                          "Aucun programme",
                          style: TextStyle(color: textSecondary),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 16, right: 0),
                        physics: const BouncingScrollPhysics(),
                        itemCount: forYou.length,
                        itemBuilder: (context, i) {
                          final item = forYou[i];
                          return _TrainingCardGlass(
                            title: item["title"].toString(),
                            variationsCount: item["variationsCount"] as int,
                            averageTime: item["averageTime"].toString(),
                            level: item["level"].toString(),
                            imgUrl: item["imgUrl"].toString(),
                            routineId: item["routineId"] as int,
                            isFavorite: _favoriteRoutineIds.contains(
                              item["routineId"] as int,
                            ),
                            onFavoriteTap: () {
                              _toggleFavorite(item["routineId"] as int);
                            },
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProgramConfigScreen(
                                    muscleGroup: item["title"].toString(),
                                    variations:
                                        item["variations"] as List<dynamic>,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      )),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildNewsTab() {
    if (isNewsLoading) {
      return const Center(child: CircularProgressIndicator(color: clubOrange));
    }
    if (siteNews.isEmpty) {
      return const Center(
        child: Text(
          "Aucune actualité pour le moment.",
          style: TextStyle(color: textSecondary),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
      itemCount: siteNews.length,
      itemBuilder: (context, index) {
        final article = siteNews[index] as Map<String, dynamic>;
        final imageUrl = _buildArticleImageUrl(article['photo']);
        final title = (article['title'] ?? "Titre indisponible").toString();
        final excerpt =
            (article['subtitle'] ??
                    article['excerpt'] ??
                    "Découvrez cette nouvelle actualité...")
                .toString();
        final publishedAt = article['publishedAt']?.toString() ?? "";

        String dateLabel = "Récemment";
        if (publishedAt.isNotEmpty) {
          try {
            final dt = DateTime.parse(publishedAt).toLocal();
            dateLabel =
                "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
          } catch (_) {}
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _NewsHeroCard(
            title: title,
            excerpt: excerpt,
            date: dateLabel,
            imgUrl: imageUrl,
            onTap: () {},
          ),
        );
      },
    );
  }
}

// ==========================================
// 🔥 WIDGETS
// ==========================================

class _TopBar extends StatelessWidget {
  final String userName;
  final String greeting;
  final int notifCount;
  final String? userImage;
  final VoidCallback onProfileTap;
  final VoidCallback onNotifTap;
  final VoidCallback onCalendarTap;

  const _TopBar({
    required this.userName,
    required this.greeting,
    required this.notifCount,
    this.userImage,
    required this.onProfileTap,
    required this.onNotifTap,
    required this.onCalendarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _CircleIcon(
          userImage: userImage,
          icon: Icons.person_outline,
          onTap: onProfileTap,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        _TopBarIconButton(
          icon: Icons.notifications_none_rounded,
          hasBadge: notifCount > 0,
          badgeText: "$notifCount",
          onTap: onNotifTap,
        ),
        const SizedBox(width: 10),
        _TopBarIconButton(
          icon: Icons.calendar_today_rounded,
          hasBadge: false,
          onTap: onCalendarTap,
        ),
      ],
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  final IconData icon;
  final bool hasBadge;
  final String? badgeText;
  final VoidCallback onTap;

  const _TopBarIconButton({
    required this.icon,
    required this.hasBadge,
    this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: surfaceColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          if (hasBadge)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE55B5B),
                  shape: BoxShape.circle,
                  border: Border.all(color: appBackground, width: 2),
                ),
                child: Text(
                  badgeText ?? "",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final String? userImage;
  final VoidCallback onTap;

  const _CircleIcon({required this.icon, this.userImage, required this.onTap});

  ImageProvider? _resolveImageProvider(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim();
    try {
      if (v.startsWith('http://') || v.startsWith('https://')) {
        final fixed = v
            .replaceFirst('http://127.0.0.1:8000', 'http://10.0.2.2:8000')
            .replaceFirst('http://localhost:8000', 'http://10.0.2.2:8000');
        return NetworkImage(fixed);
      }
      if (v.startsWith('/') || v.startsWith('uploads/')) {
        final fixed = v.startsWith('/')
            ? 'http://10.0.2.2:8000$v'
            : 'http://10.0.2.2:8000/$v';
        return NetworkImage(fixed);
      }
      final raw = v.contains(',') ? v.split(',').last : v;
      return MemoryImage(base64Decode(raw));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _resolveImageProvider(userImage);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: surfaceColor,
          shape: BoxShape.circle,
          image: imageProvider != null
              ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
              : null,
        ),
        child: imageProvider == null
            ? Center(child: Icon(icon, size: 20, color: textPrimary))
            : null,
      ),
    );
  }
}

class _CircleCalendarTransparent extends StatelessWidget {
  final List<Map<String, dynamic>> weekDays;
  final bool isLoading;

  const _CircleCalendarTransparent({
    required this.weekDays,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading || weekDays.isEmpty) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(color: clubOrange)),
      );
    }

    return Container(
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: weekDays.map((dayData) {
          return _CircleDayBlock(
            day: dayData["dayName"],
            date: dayData["dayNumber"],
            state: dayData["state"] as _DayState,
          );
        }).toList(),
      ),
    );
  }
}

class _CircleDayBlock extends StatelessWidget {
  final String day;
  final String date;
  final _DayState state;

  const _CircleDayBlock({
    required this.day,
    required this.date,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Border? border;
    Color dayTextColor = textSecondary;

    switch (state) {
      case _DayState.completed:
        bgColor = clubOrange;
        textColor = Colors.white;
        break;
      case _DayState.missed:
      case _DayState.future:
        bgColor = Colors.white.withOpacity(0.08);
        textColor = textSecondary.withOpacity(0.8);
        break;
      case _DayState.today:
        bgColor = Colors.transparent;
        textColor = Colors.white;
        dayTextColor = clubOrange;
        border = Border.all(color: clubOrange, width: 1.5);
        break;
    }

    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            color: dayTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: border,
          ),
          child: Center(
            child: Text(
              date,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentStatsCard extends StatelessWidget {
  final List<dynamic> sessions;
  final Map<String, dynamic>? profile;
  final bool isLoading;

  const _RecentStatsCard({
    required this.sessions,
    required this.profile,
    required this.isLoading,
  });

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    if (v == null) return 0;
    return int.tryParse(v.toString()) ?? 0;
  }

  double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v == null) return 0;
    return double.tryParse(v.toString()) ?? 0;
  }

  DateTime? _extractSessionDate(dynamic rawSession) {
    if (rawSession is! Map<String, dynamic>) return null;

    final rawDate =
        rawSession['performed_at'] ??
        rawSession['date'] ??
        rawSession['createdAt'] ??
        rawSession['completedAt'];

    if (rawDate == null) return null;

    try {
      return DateTime.parse(rawDate.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  int _extractDurationSeconds(dynamic rawSession) {
    if (rawSession is! Map<String, dynamic>) return 0;

    return _toInt(
      rawSession['duration_seconds'] ??
          rawSession['durationSeconds'] ??
          rawSession['duration'] ??
          0,
    );
  }

  int _extractCalories(dynamic rawSession) {
    if (rawSession is! Map<String, dynamic>) return 0;

    return _toInt(
      rawSession['calories_burned'] ??
          rawSession['caloriesBurned'] ??
          rawSession['calories'] ??
          rawSession['kcal'] ??
          0,
    );
  }

  double _extractVolume(dynamic rawSession) {
    if (rawSession is! Map<String, dynamic>) return 0;

    return _toDouble(
      rawSession['total_volume'] ?? rawSession['totalVolume'] ?? 0,
    );
  }

  int _extractTotalSets(dynamic rawSession) {
    if (rawSession is! Map<String, dynamic>) return 0;

    return _toInt(
      rawSession['total_sets'] ??
          rawSession['totalCompletedSets'] ??
          rawSession['total_completed_sets'] ??
          rawSession['completed_sets'] ??
          0,
    );
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return "${hours}h ${minutes.toString().padLeft(2, '0')}m";
    }
    return "${minutes}m";
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [clubOrange, Color(0xFFC45000)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const SizedBox(
          height: 150,
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final nextMonday = monday.add(const Duration(days: 7));

    final weeklySessions = sessions.where((raw) {
      final dt = _extractSessionDate(raw);
      if (dt == null) return false;
      return !dt.isBefore(monday) && dt.isBefore(nextMonday);
    }).toList();

    final List<int> sessionsByDay = List.filled(7, 0);

    for (final raw in weeklySessions) {
      final dt = _extractSessionDate(raw);
      if (dt == null) continue;
      final index = dt.weekday - 1; // lundi=0
      if (index >= 0 && index < 7) {
        sessionsByDay[index]++;
      }
    }

    final int completedSessions = weeklySessions.length;

    final int totalDurationSeconds = weeklySessions.fold<int>(
      0,
      (sum, raw) => sum + _extractDurationSeconds(raw),
    );

    final int totalCalories = weeklySessions.fold<int>(
      0,
      (sum, raw) => sum + _extractCalories(raw),
    );

    final double totalVolume = weeklySessions.fold<double>(
      0,
      (sum, raw) => sum + _extractVolume(raw),
    );

    final int totalSets = weeklySessions.fold<int>(
      0,
      (sum, raw) => sum + _extractTotalSets(raw),
    );

    final int sessionsWithCalories = weeklySessions.where((raw) {
      return _extractCalories(raw) > 0;
    }).length;

    final String timeLabel = _formatDuration(totalDurationSeconds);
    final String sessionsLabel = "$completedSessions";
    final String setsLabel = "$totalSets";

    final bool hasCalories = sessionsWithCalories > 0;
    final String thirdValue = hasCalories
        ? "${(totalCalories / sessionsWithCalories).round()} kcal"
        : "${totalVolume.toInt()} kg";
    final String thirdLabel = hasCalories ? "CALORIES (MOY.)" : "VOLUME TOTAL";

    final int maxDayCount = sessionsByDay.every((e) => e == 0)
        ? 1
        : sessionsByDay.reduce((a, b) => a > b ? a : b);

    double barHeightFor(int count) {
      if (count <= 0) return 20;
      return 20 + ((count / maxDayCount) * 40);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [clubOrange, Color(0xFFC45000)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: clubOrange.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "STATISTIQUES RÉCENTES",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Entraînements de la semaine",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ✅ Version responsive : plus d'overflow
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (index) {
                        return Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: _MiniBar(
                              height: barHeightFor(sessionsByDay[index]),
                              isActive: sessionsByDay[index] > 0,
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 12,
                            color: purpleButton,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              setsLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              "SÉRIES RÉALISÉES",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 120,
                color: Colors.white.withOpacity(0.25),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatCounter(
                      icon: Icons.access_time_filled_rounded,
                      value: timeLabel,
                      label: "TEMPS TOTAL",
                    ),
                    const SizedBox(height: 16),
                    _StatCounter(
                      icon: Icons.check_circle_rounded,
                      value: sessionsLabel,
                      label: "SÉANCES CETTE SEMAINE",
                    ),
                    const SizedBox(height: 16),
                    _StatCounter(
                      icon: hasCalories
                          ? Icons.local_fire_department_rounded
                          : Icons.fitness_center_rounded,
                      value: thirdValue,
                      label: thirdLabel,
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

class _MiniBar extends StatelessWidget {
  final double height;
  final bool isActive;

  const _MiniBar({required this.height, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: height,
      decoration: BoxDecoration(
        color: isActive ? purpleButton : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _StatCounter extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCounter({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: purpleButton, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 10,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.5,
          ),
        ),
        GestureDetector(
          onTap: onAction,
          child: Text(
            actionText,
            style: const TextStyle(
              color: clubOrange,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrainingCardGlass extends StatelessWidget {
  final String title;
  final int variationsCount;
  final String averageTime;
  final String level;
  final String imgUrl;
  final VoidCallback onTap;
  final int routineId;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  const _TrainingCardGlass({
    required this.title,
    required this.variationsCount,
    required this.averageTime,
    required this.level,
    required this.imgUrl,
    required this.onTap,
    required this.routineId,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imgUrl.startsWith('http')
                ? Image.network(imgUrl, fit: BoxFit.cover)
                : Image.asset(imgUrl, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: onFavoriteTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isFavorite
                            ? clubOrange.withOpacity(0.8)
                            : Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isFavorite
                              ? clubOrange
                              : Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Icon(
                        isFavorite
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$variationsCount variantes • $averageTime • $level",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              child: GestureDetector(
                onTap: onTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.play_arrow_rounded,
                            color: purpleButton,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "LANCER",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _NewsHeroCard extends StatelessWidget {
  final String title;
  final String excerpt;
  final String date;
  final String? imgUrl;
  final VoidCallback onTap;

  const _NewsHeroCard({
    required this.title,
    required this.excerpt,
    required this.date,
    this.imgUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: surfaceColor,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imgUrl != null)
                Image.network(
                  imgUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _fallbackImg(),
                )
              else
                _fallbackImg(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.95),
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 0.8],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: clubOrange,
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        date,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
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

  Widget _fallbackImg() {
    return Container(
      color: const Color(0xFF2C2C2E),
      child: const Center(
        child: Icon(Icons.article_rounded, color: textSecondary, size: 40),
      ),
    );
  }
}

class _GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _GlassBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: "Accueil",
                  index: 0,
                  currentIndex: currentIndex,
                  onTap: onTap,
                ),
                _NavItem(
                  icon: Icons.fitness_center_rounded,
                  label: "Training",
                  index: 1,
                  currentIndex: currentIndex,
                  onTap: onTap,
                ),
                _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: "Progrès",
                  index: 2,
                  currentIndex: currentIndex,
                  onTap: onTap,
                ),
                _NavItem(
                  icon: Icons.monitor_weight_rounded,
                  label: "Haltéro",
                  index: 3,
                  currentIndex: currentIndex,
                  onTap: onTap,
                ),
                _NavItem(
                  icon: Icons.card_membership_rounded,
                  label: "Abonnement",
                  index: 4,
                  currentIndex: currentIndex,
                  onTap: onTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = index == currentIndex;
    final Color inactiveColor = const Color(0xFF888888);
    final Color activeColor = isSelected ? clubOrange : inactiveColor;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(12),
          splashColor: clubOrange.withOpacity(0.10),
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: activeColor),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: activeColor,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: isSelected ? 16 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: clubOrange,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
