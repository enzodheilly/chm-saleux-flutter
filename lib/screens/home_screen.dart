import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/workout_manager.dart';
import '../widgets/active_workout_bar.dart';
import '../widgets/glass_surface.dart';
import 'progress_screen.dart';

import '../services/auth_service.dart';
import '../services/routine_service.dart';
import '../services/news_service.dart';
import '../theme/app_theme.dart';
import '../widgets/design_system.dart';
import '../widgets/live_attendance_banner.dart';
import 'create_routine_screen.dart';
import 'profile_screen.dart';
import 'program_config_screen.dart';
import 'calendar_screen.dart';
import 'license_screen.dart';

// =========================
// COULEURS GLOBALES
// =========================
// Alias locaux vers le système de design partagé (lib/theme/app_theme.dart) —
// conservés pour éviter de renommer tous les usages du fichier.
const Color clubOrange = AppColors.accent;
const Color appBackground = AppColors.bg;
const Color surfaceColor = AppColors.surface;
const Color textPrimary = AppColors.textPrimary;
const Color textSecondary = AppColors.textSecondary;

enum _DayState { completed, missed, today, todayDone, future }

// =========================
// HOME SCREEN
// =========================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _forYouCategory = 0; // 0 = Pour toi, 1 = Conseils, 2 = Nutrition

  String currentUserName = "Chargement...";
  String? profileImageUrl;

  List<dynamic> allPrograms = [];
  List<dynamic> lastSessions = [];
  List<dynamic> siteNews = [];
  Map<String, dynamic>? profile;

  bool isLoading = true;
  bool isNewsLoading = true;

  final Set<int> _favoriteRoutineIds = {};
  List<Map<String, dynamic>> _weekDays = [];

  @override
  void initState() {
    super.initState();
    _fetchCoreData();
    _fetchNews();
  }

  // =========================
  // FETCH API
  // =========================

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
          String capitalize(String s) => s.isEmpty
              ? ""
              : s[0].toUpperCase() + s.substring(1).toLowerCase();

          final firstName = capitalize(
            (prof['firstName'] ?? prof['firstname'] ?? prof['prenom'] ?? '')
                .toString()
                .trim(),
          );
          final lastName = capitalize(
            (prof['lastName'] ??
                    prof['lastname'] ??
                    prof['name'] ??
                    prof['nom'] ??
                    '')
                .toString()
                .trim(),
          );
          final fullName = "$firstName $lastName".trim();
          currentUserName = fullName.isNotEmpty ? fullName : "Athlète";
          profileImageUrl = prof['profileImageUrl'] ?? prof['avatar'];
        }

        allPrograms = programs;
        lastSessions = sessions;
        _buildCalendarData();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Erreur chargement principal: $e");
      if (mounted) setState(() => isLoading = false);
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
      if (mounted) setState(() => isNewsLoading = false);
    }
  }

  // =========================
  // CALENDRIER SEMAINE
  // =========================

  void _buildCalendarData() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    final Set<String> sessionDates = {};
    for (final session in lastSessions) {
      final dateStr =
          session['date'] ??
          session['createdAt'] ??
          session['completedAt'] ??
          session['performed_at'];
      if (dateStr != null) {
        try {
          final dt = DateTime.parse(dateStr.toString()).toLocal();
          sessionDates.add(_dateKey(dt));
        } catch (_) {}
      }
    }

    const dayNames = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"];
    _weekDays = List.generate(7, (i) {
      final dayDate = monday.add(Duration(days: i));
      final key = _dateKey(dayDate);
      final isToday =
          dayDate.year == now.year &&
          dayDate.month == now.month &&
          dayDate.day == now.day;
      final trained = sessionDates.contains(key);

      _DayState state;
      if (isToday) {
        state = trained ? _DayState.todayDone : _DayState.today;
      } else if (dayDate.isAfter(now)) {
        state = _DayState.future;
      } else {
        state = trained ? _DayState.completed : _DayState.missed;
      }

      return {
        "dayName": dayNames[i],
        "dayNumber": "${dayDate.day}",
        "state": state,
      };
    });
  }

  String _dateKey(DateTime dt) =>
      "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

  // =========================
  // HELPERS
  // =========================

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return "Bonjour,";
    if (h < 17) return "Bon après-midi,";
    return "Bonsoir,";
  }

  String _resolveImageUrl(dynamic raw) {
    if (raw == null) return '';
    final v = raw.toString().trim();
    if (v.isEmpty || v == 'null') return '';
    if (v.startsWith('https://')) return v;
    if (v.startsWith('http://127.0.0.1:8000'))
      return v.replaceFirst('http://127.0.0.1:8000', 'http://10.0.2.2:8000');
    if (v.startsWith('http://localhost:8000'))
      return v.replaceFirst('http://localhost:8000', 'http://10.0.2.2:8000');
    if (v.startsWith('http://')) return v;
    if (v.startsWith('/uploads/') || v.startsWith('/'))
      return 'http://10.0.2.2:8000$v';
    if (v.startsWith('uploads/')) return 'http://10.0.2.2:8000/$v';
    return 'http://10.0.2.2:8000/uploads/$v';
  }

  String _getImageForGroup(String g) {
    final n = g.toLowerCase();
    if (n.contains("pec") || n.contains("push"))
      return "assets/images/pecs.jpg";
    if (n.contains("dos") || n.contains("pull")) return "assets/images/dos.jpg";
    if (n.contains("jambe") || n.contains("leg"))
      return "assets/images/jambes.jpg";
    if (n.contains("bras") || n.contains("biceps"))
      return "assets/images/bras.jpg";
    if (n.contains("epaule") || n.contains("épaule"))
      return "assets/images/epaules.jpg";
    if (n.contains("abdo") || n.contains("abs"))
      return "assets/images/abdos.jpg";
    if (n.contains("cardio") || n.contains("run"))
      return "assets/images/cardio.jpg";
    return "assets/images/default.jpg";
  }

  // ✅ FIX — routineId sécurisé avec cast null-safe
  List<Map<String, dynamic>> _buildForYouPrograms() {
    if (allPrograms.isEmpty) return [];
    final Map<String, List<dynamic>> grouped = {};
    for (final p in allPrograms) {
      final g = (p['muscleGroup'] ?? "Autre").toString();
      grouped.putIfAbsent(g, () => []).add(p);
    }
    return grouped.keys.take(5).map((g) {
      final variations = grouped[g]!;
      final rep = variations.first as Map<String, dynamic>;
      final rawId = rep['id'];
      final routineId = rawId is int
          ? rawId
          : int.tryParse(rawId?.toString() ?? '') ?? 0;
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
        "routineId": routineId,
        "variations": variations,
      };
    }).toList();
  }

  void _toggleFavorite(int id) {
    setState(() {
      if (_favoriteRoutineIds.contains(id)) {
        _favoriteRoutineIds.remove(id);
      } else {
        _favoriteRoutineIds.add(id);
      }
    });
  }

  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_selectedIndex == 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 10),
                child: _TopBar(
                  userName: currentUserName,
                  greeting: _getGreeting(),
                  notifCount: 3,
                  userImage: profileImageUrl,
                  onProfileTap: () => setState(() => _selectedIndex = 4),
                  onNotifTap: () {},
                  onCalendarTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CalendarScreen()),
                  ),
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
                      const LicenseScreen(),
                      const ProgressScreen(),
                      const ProfileScreen(embedded: true),
                    ],
                  ),
                  Consumer<WorkoutManager>(
                    builder: (context, manager, _) {
                      if (!manager.isActive) return const SizedBox.shrink();
                      return Positioned(
                        left: 16,
                        right: 16,
                        bottom: 82 + MediaQuery.of(context).padding.bottom,
                        child: const ActiveWorkoutBar(),
                      );
                    },
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SafeArea(
                      top: false,
                      child: _AppBottomNav(
                        currentIndex: _selectedIndex,
                        onTap: (i) => setState(() => _selectedIndex = i),
                      ),
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

  // =========================
  // TABS
  // =========================

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
                  bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
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
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
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
          child: _WeekCalendar(weekDays: _weekDays, isLoading: isLoading),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: LiveAttendanceBanner(),
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
          child: SectionHeader(
            title: "Entraînements pour toi",
            trailing: GestureDetector(
              onTap: () => setState(() => _selectedIndex = 1),
              child: const Text(
                "VOIR TOUT",
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              _CategoryChip(
                label: "Pour toi",
                selected: _forYouCategory == 0,
                onTap: () => setState(() => _forYouCategory = 0),
              ),
              const SizedBox(width: 8),
              _CategoryChip(
                label: "Conseils",
                selected: _forYouCategory == 1,
                onTap: () => setState(() => _forYouCategory = 1),
              ),
              const SizedBox(width: 8),
              _CategoryChip(
                label: "Nutrition",
                selected: _forYouCategory == 2,
                onTap: () => setState(() => _forYouCategory = 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 190,
          child: _forYouCategory == 1
              ? _buildTipsList(_trainingTips)
              : _forYouCategory == 2
              ? _buildTipsList(_nutritionTips)
              : isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: clubOrange),
                )
              : forYou.isEmpty
              ? const Center(
                  child: Text(
                    "Aucun programme",
                    style: TextStyle(color: textSecondary),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: forYou.length,
                  itemBuilder: (context, i) {
                    final item = forYou[i];
                    final routineId = item["routineId"] as int;
                    return _TrainingCardGlass(
                      title: item["title"].toString(),
                      variationsCount: item["variationsCount"] as int,
                      averageTime: item["averageTime"].toString(),
                      level: item["level"].toString(),
                      imgUrl: item["imgUrl"].toString(),
                      routineId: routineId,
                      isFavorite: _favoriteRoutineIds.contains(routineId),
                      onFavoriteTap: () => _toggleFavorite(routineId),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProgramConfigScreen(
                            muscleGroup: item["title"].toString(),
                            variations: item["variations"] as List<dynamic>,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTipsList(List<(IconData, String, String)> tips) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: tips.length,
      itemBuilder: (context, i) {
        final (icon, title, text) = tips[i];
        return _TipCard(icon: icon, title: title, text: text);
      },
    );
  }

  static const List<(IconData, String, String)> _trainingTips = [
    (
      Icons.timer_rounded,
      "Échauffe-toi 10 min",
      "Prépare tes articulations avant chaque séance pour limiter les blessures.",
    ),
    (
      Icons.bedtime_rounded,
      "Respecte le repos",
      "Laisse 48h à un même groupe musculaire pour bien récupérer.",
    ),
    (
      Icons.center_focus_strong_rounded,
      "Priorise la technique",
      "Une charge plus légère bien exécutée vaut mieux qu'une charge lourde mal maîtrisée.",
    ),
    (
      Icons.water_drop_rounded,
      "Hydrate-toi",
      "Bois régulièrement avant, pendant et après l'effort.",
    ),
  ];

  static const List<(IconData, String, String)> _nutritionTips = [
    (
      Icons.egg_alt_rounded,
      "Protéines à chaque repas",
      "Elles aident à la récupération et au maintien musculaire.",
    ),
    (
      Icons.restaurant_rounded,
      "Ne saute pas les repas",
      "Une alimentation régulière soutient l'énergie sur la séance.",
    ),
    (
      Icons.bolt_rounded,
      "Glucides autour de l'effort",
      "Ils apportent l'énergie nécessaire à l'entraînement.",
    ),
    (
      Icons.favorite_rounded,
      "Écoute ta faim",
      "Adapte les quantités à ton niveau d'activité réel.",
    ),
  ];

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
      itemBuilder: (context, i) {
        final article = siteNews[i] as Map<String, dynamic>;
        final imageUrl = _resolveImageUrl(article['photo']);
        final title = (article['title'] ?? "Titre indisponible").toString();
        final excerpt =
            (article['subtitle'] ??
                    article['excerpt'] ??
                    "Découvrez cette actualité.")
                .toString();

        String dateLabel = "Récemment";
        final publishedAt = article['publishedAt']?.toString() ?? "";
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
            imgUrl: imageUrl.isNotEmpty ? imageUrl : null,
            onTap: () {},
          ),
        );
      },
    );
  }
}

// =========================
// TOP BAR
// =========================

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
        _AvatarButton(userImage: userImage, onTap: onProfileTap),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13,
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
                  fontSize: 20,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        _IconBtn(
          icon: Icons.notifications_none_rounded,
          badge: notifCount > 0
              ? "${notifCount > 9 ? '9+' : notifCount}"
              : null,
          onTap: onNotifTap,
        ),
        const SizedBox(width: 10),
        _IconBtn(icon: Icons.calendar_today_rounded, onTap: onCalendarTap),
      ],
    );
  }
}

class _AvatarButton extends StatelessWidget {
  final String? userImage;
  final VoidCallback onTap;

  const _AvatarButton({this.userImage, required this.onTap});

  ImageProvider? _resolveImage(String? value) {
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
        return NetworkImage(
          v.startsWith('/')
              ? 'http://10.0.2.2:8000$v'
              : 'http://10.0.2.2:8000/$v',
        );
      }
      return MemoryImage(base64Decode(v.contains(',') ? v.split(',').last : v));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _resolveImage(userImage);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: surfaceColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          image: imageProvider != null
              ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
              : null,
        ),
        child: imageProvider == null
            ? const Center(
                child: Icon(Icons.person_outline, size: 22, color: textPrimary),
              )
            : null,
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String? badge;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap, this.badge});

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
          if (badge != null)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: appBackground, width: 1.5),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
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

// =========================
// CALENDRIER SEMAINE
// =========================

class _WeekCalendar extends StatelessWidget {
  final List<Map<String, dynamic>> weekDays;
  final bool isLoading;

  const _WeekCalendar({required this.weekDays, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    if (isLoading || weekDays.isEmpty) {
      return const SizedBox(
        height: 70,
        child: Center(
          child: CircularProgressIndicator(color: clubOrange, strokeWidth: 2),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: weekDays
          .map(
            (d) => _DayCell(
              day: d["dayName"] as String,
              date: d["dayNumber"] as String,
              state: d["state"] as _DayState,
            ),
          )
          .toList(),
    );
  }
}

class _DayCell extends StatelessWidget {
  final String day;
  final String date;
  final _DayState state;

  const _DayCell({required this.day, required this.date, required this.state});

  @override
  Widget build(BuildContext context) {
    // ✅ todayDone : aujourd'hui + entraîné → orange avec bordure blanche
    Color bg;
    Color fg;
    Color dayFg = textSecondary;
    Border? border;

    switch (state) {
      case _DayState.completed:
        bg = clubOrange;
        fg = Colors.white;
        break;
      case _DayState.todayDone:
        bg = clubOrange;
        fg = Colors.white;
        dayFg = clubOrange;
        border = Border.all(color: Colors.white, width: 2);
        break;
      case _DayState.today:
        bg = Colors.transparent;
        fg = Colors.white;
        dayFg = clubOrange;
        border = Border.all(color: clubOrange, width: 1.5);
        break;
      case _DayState.missed:
        bg = Colors.white.withOpacity(0.06);
        fg = Colors.white.withOpacity(0.3);
        break;
      case _DayState.future:
        bg = Colors.white.withOpacity(0.04);
        fg = Colors.white.withOpacity(0.2);
        dayFg = Colors.white.withOpacity(0.2);
        break;
    }

    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            color: dayFg,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: border,
          ),
          child: Center(
            child: Text(
              date,
              style: TextStyle(
                color: fg,
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

// =========================
// CARTE STATS RÉCENTES
// =========================

class _RecentStatsCard extends StatelessWidget {
  final List<dynamic> sessions;
  final Map<String, dynamic>? profile;
  final bool isLoading;

  const _RecentStatsCard({
    required this.sessions,
    required this.profile,
    required this.isLoading,
  });

  // Helpers de parsing défensif
  int _int(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  double _dbl(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  DateTime? _sessionDate(dynamic raw) {
    if (raw is! Map) return null;
    final d =
        raw['performed_at'] ??
        raw['date'] ??
        raw['createdAt'] ??
        raw['completedAt'];
    if (d == null) return null;
    try {
      return DateTime.parse(d.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  int _durationSec(dynamic raw) => raw is Map
      ? _int(
          raw['duration_seconds'] ??
              raw['durationSeconds'] ??
              raw['duration'] ??
              0,
        )
      : 0;

  int _calories(dynamic raw) => raw is Map
      ? _int(
          raw['calories_burned'] ??
              raw['caloriesBurned'] ??
              raw['calories'] ??
              raw['kcal'] ??
              0,
        )
      : 0;

  double _volume(dynamic raw) =>
      raw is Map ? _dbl(raw['total_volume'] ?? raw['totalVolume'] ?? 0) : 0.0;

  int _sets(dynamic raw) => raw is Map
      ? _int(
          raw['total_sets'] ??
              raw['totalCompletedSets'] ??
              raw['total_completed_sets'] ??
              raw['completed_sets'] ??
              0,
        )
      : 0;

  String _formatDuration(int totalSec) {
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    return h > 0 ? "${h}h ${m.toString().padLeft(2, '0')}m" : "${m}m";
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 164,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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

    final weeklySessions = sessions.where((r) {
      final dt = _sessionDate(r);
      return dt != null && !dt.isBefore(monday) && dt.isBefore(nextMonday);
    }).toList();

    final List<int> byDay = List.filled(7, 0);
    for (final r in weeklySessions) {
      final dt = _sessionDate(r);
      if (dt != null) {
        final idx = dt.weekday - 1;
        if (idx >= 0 && idx < 7) byDay[idx]++;
      }
    }

    final totalSec = weeklySessions.fold<int>(0, (s, r) => s + _durationSec(r));
    final totalCalories = weeklySessions.fold<int>(
      0,
      (s, r) => s + _calories(r),
    );
    final totalVolume = weeklySessions.fold<double>(
      0,
      (s, r) => s + _volume(r),
    );
    final totalSets = weeklySessions.fold<int>(0, (s, r) => s + _sets(r));
    final sessionsWithCal = weeklySessions
        .where((r) => _calories(r) > 0)
        .length;

    final hasCalories = sessionsWithCal > 0;
    final thirdValue = hasCalories
        ? "${(totalCalories / sessionsWithCal).round()} kcal"
        : "${totalVolume.toInt()} kg";
    final thirdLabel = hasCalories ? "CALORIES (MOY.)" : "VOLUME TOTAL";

    final maxDay = byDay.isEmpty || byDay.every((e) => e == 0)
        ? 1
        : byDay.reduce((a, b) => a > b ? a : b);
    double barH(int c) => c <= 0 ? 16.0 : 16.0 + (c / maxDay) * 34.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "STATISTIQUES RÉCENTES",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barres + séries
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Cette semaine",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(
                        7,
                        (i) => Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: _Bar(
                              height: barH(byDay[i]),
                              isActive: byDay[i] > 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                            size: 11,
                            color: AppColors.bg,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$totalSets",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              "SÉRIES RÉALISÉES",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
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
                height: 104,
                color: Colors.white.withOpacity(0.2),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              // Counters
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatCounter(
                      icon: Icons.access_time_filled_rounded,
                      value: _formatDuration(totalSec),
                      label: "TEMPS TOTAL",
                    ),
                    const SizedBox(height: 10),
                    _StatCounter(
                      icon: Icons.check_circle_rounded,
                      value: "${weeklySessions.length}",
                      label: "SÉANCES CETTE SEMAINE",
                    ),
                    const SizedBox(height: 10),
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

class _Bar extends StatelessWidget {
  final double height;
  final bool isActive;

  const _Bar({required this.height, required this.isActive});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 400),
    curve: Curves.easeOutCubic,
    width: 14,
    height: height,
    decoration: BoxDecoration(
      color: isActive ? Colors.white : Colors.white.withOpacity(0.25),
      borderRadius: BorderRadius.circular(4),
    ),
  );
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
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        padding: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.bg, size: 13),
      ),
      const SizedBox(width: 8),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 9.5,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// =========================
// CHIP DE CATÉGORIE ("Pour toi" / "Conseils" / "Nutrition")
// =========================

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? clubOrange : surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? clubOrange : AppColors.line,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : textSecondary,
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

// =========================
// CARTE CONSEIL / NUTRITION
// =========================

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _TipCard({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent, size: 22),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textSecondary,
                fontSize: 12.5,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================
// CARTE ENTRAÎNEMENT
// =========================

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

  // ✅ FIX — Widget fallback extrait (évite errorBuilder avec params dupliqués)
  Widget _fallback() => Container(
    color: surfaceColor,
    child: const Center(
      child: Icon(Icons.fitness_center_rounded, color: textSecondary, size: 32),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imgUrl.startsWith('http')
                ? Image.network(
                    imgUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, e, st) => _fallback(),
                  )
                : Image.asset(
                    imgUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, e, st) => _fallback(),
                  ),
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
            // Favoris
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
            // Textes
            Positioned(
              left: 14,
              right: 14,
              bottom: 56,
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
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$variationsCount variantes • $averageTime • $level",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Bouton LANCER
            Positioned(
              left: 14,
              bottom: 14,
              child: GlassSurface(
                onTap: onTap,
                borderRadius: BorderRadius.circular(99),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      "LANCER",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================
// CARTE NEWS
// =========================

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

  Widget _fallback() => Container(
    color: const Color(0xFF1C1C1E),
    child: const Center(
      child: Icon(Icons.article_rounded, color: textSecondary, size: 36),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          color: surfaceColor,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ✅ FIX — errorBuilder avec paramètres distincts (ctx, e, st)
              if (imgUrl != null)
                Image.network(
                  imgUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, e, st) => _fallback(),
                )
              else
                _fallback(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.95),
                      Colors.black.withOpacity(0.55),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 0.8],
                  ),
                ),
              ),
              // Badge date
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: clubOrange,
                        size: 11,
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
              // Titre + extrait
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
                        fontSize: 17,
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
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 13,
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
}

// =========================
// BOTTOM NAV
// =========================

class _AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _AppBottomNav({required this.currentIndex, required this.onTap});

  static const _icons = [
    Icons.home_rounded,
    Icons.fitness_center_rounded,
    Icons.qr_code_2_rounded,
    Icons.bar_chart_rounded,
    Icons.person_rounded,
  ];
  static const _labels = ["Accueil", "Training", "Accès", "Progrès", "Profil"];
  static const _highlightIndex = 2;
  static const _highlightColor = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      height: 66,
      child: Row(
        children: List.generate(_icons.length, (i) {
          return _NavItem(
            icon: _icons[i],
            label: _labels[i],
            index: i,
            current: currentIndex,
            onTap: onTap,
            highlightColor: i == _highlightIndex ? _highlightColor : null,
          );
        }),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final Function(int) onTap;
  final Color? highlightColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == current;
    final iconColor = highlightColor != null
        ? Colors.white
        : (isSelected ? clubOrange : const Color(0xFF888888));
    final labelColor = isSelected ? clubOrange : const Color(0xFF888888);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(12),
          splashColor: clubOrange.withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (highlightColor != null)
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: highlightColor, shape: BoxShape.circle),
                  child: Icon(icon, size: 26, color: Colors.white),
                )
              else ...[
                Icon(icon, size: 23, color: iconColor),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: isSelected ? 14 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: clubOrange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
