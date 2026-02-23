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
import 'training_screen.dart';
import 'workout_player_screen.dart';

// ✅ Const global
const Color clubOrange = Color(0xFFF57809);
const Color darkBackground = Color(0xFF0B0B0F);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ✅ NAV
  int _selectedIndex = 0;

  // ✅ PROFIL
  String currentUserName = "ATHLÈTE";
  String? profileImageUrl;

  // ✅ DATA
  List<dynamic> allPrograms = [];
  List<dynamic> lastSessions = [];
  List<dynamic> siteNews = [];
  Map<String, dynamic>? profile;

  bool isLoading = true;
  bool isNewsLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCoreData();
    _fetchNews(); // ✅ non bloquant
  }

  /// ✅ Charge les données essentielles de la Home (rapide)
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
          currentUserName = prof['firstName']?.toUpperCase() ?? "ATHLÈTE";
          profileImageUrl = prof['profileImageUrl'];
        }

        allPrograms = programs;
        lastSessions = sessions;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Erreur chargement principal: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  /// ✅ Charge les news séparément pour ne pas bloquer l’accueil
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

  /// ✅ Programme recommandé simple (1er programme dispo)
  Map<String, dynamic>? _getRecommendedProgram() {
    if (allPrograms.isEmpty) return null;
    final first = allPrograms.first;
    if (first is Map<String, dynamic>) return first;
    return null;
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
        "subtitle":
            "${variations.length} variantes • ~ $duration min • $labelLevel",
        "imgUrl": _getImageForGroup(g),
        "routineId": rep['id'],
        "routineName": rep['name'] ?? g,
      };
    }).toList();
  }

  List<_DayPoint> _buildAttendancePoints({int days = 14}) {
    final now = DateTime.now();
    final Set<String> attended = {};

    for (final s in lastSessions) {
      final iso = (s['performed_at'] ?? "").toString();
      if (iso.isEmpty) continue;
      try {
        final dt = DateTime.parse(iso).toLocal();
        final key =
            "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
        attended.add(key);
      } catch (_) {}
    }

    final List<_DayPoint> pts = [];
    for (int i = days - 1; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key =
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      final isOn = attended.contains(key);
      pts.add(
        _DayPoint(
          dayLabel:
              "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}",
          value: isOn ? 1 : 0,
          isToday: i == 0,
        ),
      );
    }
    return pts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ✅ TOP BAR GLOBALE (Fixe en haut)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: _TopBar(
                title: "chm saleux",
                notifCount: 3,
                userImage: profileImageUrl,
                onProfileTap: () {},
                onNotifTap: () {},
              ),
            ),

            // ✅ CONTENU
            Expanded(
              child: Stack(
                children: [
                  IndexedStack(
                    index: _selectedIndex,
                    children: [
                      _buildHomeContent(),
                      const TrainingScreen(),
                      const ProgressScreen(),
                      const Center(
                        child: Text(
                          "PAGE HALTÉROPHILIE",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          "PAGE ABONNEMENT",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 🔥 BARRE DE REPRISE
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

                  // ✅ BOTTOM NAV BAR FLOTTANTE
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SafeArea(
                      child: _GlassBottomNav(
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

  // ✅ Contenu Accueil (Sans la TopBar)
  Widget _buildHomeContent() {
    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                ),
                child: const TabBar(
                  indicatorColor: clubOrange,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: clubOrange,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                  tabs: [
                    Tab(text: "Toi"),
                    Tab(text: "Actualités"),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
        ],
        body: TabBarView(children: [_buildUserTab(), _buildNewsTab()]),
      ),
    );
  }

  Widget _buildUserTab() {
    final forYou = _buildForYouPrograms();
    final attendance = _buildAttendancePoints(days: 14);
    final attendedCount = attendance.where((e) => e.value > 0).length;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 140),
      children: [
        // ✅ HERO (simplifié : en cours / recommandé / explorer)
        Consumer<WorkoutManager>(
          builder: (context, manager, child) {
            final recommended = _getRecommendedProgram();

            final bool isRunning = manager.isActive;

            final String heroTitle = isRunning
                ? (manager.routineName ?? "SÉANCE EN COURS")
                : (recommended != null
                      ? (recommended['name'] ?? "SÉANCE RECOMMANDÉE").toString()
                      : "AUCUNE SÉANCE DISPONIBLE");

            final String heroMeta = isRunning
                ? "Reprends ta séance là où tu t’es arrêté 💪"
                : (recommended != null
                      ? "${recommended['muscleGroup'] ?? 'Entraînement'} • ${recommended['estimatedDurationMin'] ?? 60} min"
                      : "Découvre les entraînements disponibles dans l’onglet Training.");

            final String buttonText = isRunning
                ? "EN COURS"
                : (recommended != null ? "DÉMARRER" : "EXPLORER");

            final IconData buttonIcon = isRunning
                ? Icons.timelapse_rounded
                : (recommended != null
                      ? Icons.play_arrow_rounded
                      : Icons.fitness_center_rounded);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _HeroBanner(
                name: currentUserName,
                title: heroTitle,
                meta: heroMeta,
                accent: clubOrange,
                buttonText: buttonText,
                buttonIcon: buttonIcon,
                onStart: () {
                  if (isRunning) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkoutPlayerScreen(
                          routineId: manager.routineId!,
                          routineName: manager.routineName!,
                        ),
                      ),
                    );
                    return;
                  }

                  if (recommended != null && recommended['id'] != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkoutPlayerScreen(
                          routineId: recommended['id'],
                          routineName: (recommended['name'] ?? 'Séance')
                              .toString(),
                        ),
                      ),
                    );
                    return;
                  }

                  // Fallback : onglet Training
                  setState(() => _selectedIndex = 1);
                },
              ),
            );
          },
        ),

        const SizedBox(height: 26),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _SectionTitle(
            title: "ENTRAÎNEMENTS POUR TOI",
            actionText: "Voir tout",
            actionColor: clubOrange,
            onAction: () => setState(() => _selectedIndex = 1),
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 190,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: clubOrange),
                )
              : (forYou.isEmpty
                    ? const Center(
                        child: Text(
                          "Aucun programme disponible",
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 16, right: 8),
                        physics: const BouncingScrollPhysics(),
                        itemCount: forYou.length,
                        itemBuilder: (context, i) {
                          final item = forYou[i];
                          return _WorkoutCard(
                            title: item["title"].toString().toUpperCase(),
                            subtitle: item["subtitle"].toString(),
                            imgUrl: item["imgUrl"].toString(),
                            accent: clubOrange,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WorkoutPlayerScreen(
                                    routineId: item["routineId"] as int,
                                    routineName: item["routineName"].toString(),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      )),
        ),

        const SizedBox(height: 26),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _SectionTitle(
            title: "ASSIDUITÉ",
            actionText: "30 jours",
            actionColor: Colors.white.withOpacity(0.4),
            onAction: () {},
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _AttendanceCard(
            accent: clubOrange,
            points: attendance,
            summaryText:
                "$attendedCount jour(s) de présence sur les ${attendance.length} derniers jours",
          ),
        ),

        const SizedBox(height: 18),
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
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: siteNews.length,
      itemBuilder: (context, index) {
        final article = siteNews[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _NewsCard(
            accent: clubOrange,
            title: article['title'] ?? "Titre indisponible",
            subtitle:
                article['subtitle'] ??
                article['excerpt'] ??
                "Cliquez pour lire...",
            icon: Icons.article_rounded,
          ),
        );
      },
    );
  }
}

/// =======================
/// NOUVELLE BOTTOM NAV BAR
/// =======================
class _GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _GlassBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 82,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1.5,
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
    final Color activeColor = isSelected
        ? clubOrange
        : Colors.white.withOpacity(0.4);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(16),
          splashColor: clubOrange.withOpacity(0.1),
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
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutExpo,
                width: isSelected ? 6 : 0,
                height: 4,
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

/// =======================
/// COMPONENTS RESTANTS
/// =======================

class _GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final Color accent;

  const _GlassButton({
    required this.onTap,
    required this.child,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;

  const _GlassContainer({required this.child, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final int notifCount;
  final String? userImage;
  final VoidCallback onProfileTap;
  final VoidCallback onNotifTap;

  const _TopBar({
    required this.title,
    required this.notifCount,
    this.userImage,
    required this.onProfileTap,
    required this.onNotifTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIcon(
          userImage: userImage,
          icon: Icons.person_outline,
          onTap: onProfileTap,
        ),
        const Spacer(),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
        const Spacer(),
        Badge(
          isLabelVisible: notifCount > 0,
          label: Text("$notifCount"),
          child: _CircleIcon(icon: Icons.notifications_none, onTap: onNotifTap),
        ),
      ],
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final String? userImage;
  final VoidCallback onTap;

  const _CircleIcon({required this.icon, this.userImage, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          image: (userImage != null && userImage!.isNotEmpty)
              ? DecorationImage(
                  image: MemoryImage(base64Decode(userImage!.split(',').last)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: (userImage == null || userImage!.isEmpty)
            ? Center(child: Icon(icon, size: 22, color: Colors.white))
            : null,
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final String name;
  final String title;
  final String meta;
  final Color accent;
  final VoidCallback onStart;
  final String buttonText;
  final IconData buttonIcon;

  const _HeroBanner({
    required this.name,
    required this.title,
    required this.meta,
    required this.accent,
    required this.onStart,
    this.buttonText = "DÉMARRER",
    this.buttonIcon = Icons.play_arrow_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF111119), accent.withOpacity(0.16)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "BONJOUR $name",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 0.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Prêt pour ta séance du jour ?\nC’est la régularité qui paye.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.78),
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF57809), Color(0xFF1A1A22)],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: -0.2,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.88),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _GlassButton(
                          onTap: onStart,
                          accent: accent,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(buttonIcon, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                buttonText,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const _GlassContainer(
                    width: 66,
                    height: 66,
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: Colors.white,
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
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  final Color actionColor;

  const _SectionTitle({
    required this.title,
    this.actionText,
    this.onAction,
    required this.actionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              letterSpacing: 1.0,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        if (actionText != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionText!.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: actionColor,
                letterSpacing: 1.0,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imgUrl;
  final Color accent;
  final VoidCallback? onTap;

  const _WorkoutCard({
    required this.title,
    required this.subtitle,
    required this.imgUrl,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(imgUrl, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.black.withOpacity(0.25),
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
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.16),
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
                                "LANCER",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.92),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
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

class _AttendanceCard extends StatelessWidget {
  final Color accent;
  final List<_DayPoint> points;
  final String summaryText;

  const _AttendanceCard({
    required this.accent,
    required this.points,
    required this.summaryText,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withOpacity(0.30)),
                    ),
                    child: Icon(
                      Icons.auto_graph_rounded,
                      color: accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      "JOURS D’ENTRAÎNEMENT",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.90),
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.5,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                summaryText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 80,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: points.map((p) {
                    final on = p.value > 0;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutExpo,
                          height: on ? (p.isToday ? 74 : 54) : 16,
                          decoration: BoxDecoration(
                            color: on
                                ? accent.withOpacity(p.isToday ? 1.0 : 0.70)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    points.isNotEmpty ? points.first.dayLabel : "--/--",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.40),
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "AUJ.",
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
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

class _NewsCard extends StatelessWidget {
  final Color accent;
  final String title;
  final String subtitle;
  final IconData icon;

  const _NewsCard({
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withOpacity(0.35)),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// MODELS
/// =======================
class _DayPoint {
  final String dayLabel;
  final int value;
  final bool isToday;

  _DayPoint({
    required this.dayLabel,
    required this.value,
    this.isToday = false,
  });
}
