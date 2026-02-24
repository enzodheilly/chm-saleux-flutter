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

// ✅ Palette light / moderne
const Color clubOrange = Color(0xFFF57809);
const Color appBackground = Color(0xFFF6F7F9);
const Color surfaceColor = Colors.white;
const Color textPrimary = Color(0xFF15171C);
const Color textSecondary = Color(0xFF757C87);
const Color softBorder = Color(0xFFE9EDF2);

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

  // ✅ Favoris (local UI pour le moment)
  final Set<int> _favoriteRoutineIds = <int>{};

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

  /// ✅ Convertit le champ "photo" de l'API en URL exploitable par Flutter
  String? _buildArticleImageUrl(dynamic photoValue) {
    if (photoValue == null) return null;

    final raw = photoValue.toString().trim();
    if (raw.isEmpty) return null;

    // URL complète déjà prête
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    // Chemin absolu depuis Symfony (ex: /uploads/monimage.jpg)
    if (raw.startsWith('/')) {
      return 'http://10.0.2.2:8000$raw';
    }

    // Si la BDD stocke déjà "uploads/monimage.jpg" (sans slash)
    if (raw.startsWith('uploads/')) {
      return 'http://10.0.2.2:8000/$raw';
    }

    // ✅ Cas probable : juste "monimage.jpg" -> public/uploads/
    return 'http://10.0.2.2:8000/uploads/$raw';
  }

  /// ✅ Programme recommandé simple (1er programme dispo)
  Map<String, dynamic>? _getRecommendedProgram() {
    if (allPrograms.isEmpty) return null;
    final first = allPrograms.first;
    if (first is Map<String, dynamic>) return first;
    return null;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
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

  List<Map<String, dynamic>> _buildFavoritePrograms() {
    if (_favoriteRoutineIds.isEmpty) return [];

    final result = <Map<String, dynamic>>[];
    for (final p in allPrograms) {
      if (p is! Map<String, dynamic>) continue;
      final id = _toInt(p['id']);
      if (id != null && _favoriteRoutineIds.contains(id)) {
        result.add(p);
      }
    }
    return result;
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
      backgroundColor: appBackground,
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
                onProfileTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );

                  // ✅ Refresh de la home au retour (si photo / nom modifié)
                  _fetchCoreData();
                },
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
                      const CreateRoutineScreen(),
                      const ProgressScreen(),
                      const Center(
                        child: Text(
                          "PAGE HALTÉROPHILIE",
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          "PAGE ABONNEMENT",
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w800,
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
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: softBorder, width: 1),
                  ),
                ),
                child: const TabBar(
                  indicatorColor: clubOrange,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: textPrimary,
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
    final favoritePrograms = _buildFavoritePrograms();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 140),
      children: [
        // ✅ NOUVEAU BLOC BONJOUR (sans la partie entraînement)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _WelcomeCard(
            name: currentUserName,
            favoritesCount: _favoriteRoutineIds.length,
            attendedCount: attendedCount,
          ),
        ),

        const SizedBox(height: 18),

        // ✅ CASE MES FAVORIS
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _FavoritesSummaryCard(
            count: _favoriteRoutineIds.length,
            favoriteNames: favoritePrograms
                .take(3)
                .map((e) => (e['name'] ?? 'Séance').toString())
                .toList(),
          ),
        ),

        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _SectionTitle(
            title: "Entraînements pour toi",
            actionText: "Voir tout",
            actionColor: clubOrange,
            onAction: () => setState(() => _selectedIndex = 1),
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 230,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: clubOrange),
                )
              : (forYou.isEmpty
                    ? const Center(
                        child: Text(
                          "Aucun programme disponible",
                          style: TextStyle(color: textSecondary),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 16, right: 8),
                        physics: const BouncingScrollPhysics(),
                        itemCount: forYou.length,
                        itemBuilder: (context, i) {
                          final item = forYou[i];
                          final routineId = item["routineId"] as int;

                          return _WorkoutCard(
                            title: item["title"].toString(),
                            subtitle: item["subtitle"].toString(),
                            imgUrl: item["imgUrl"].toString(),
                            accent: clubOrange,
                            isFavorite: _favoriteRoutineIds.contains(routineId),
                            onFavoriteTap: () => _toggleFavorite(routineId),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WorkoutPlayerScreen(
                                    routineId: routineId,
                                    routineName: item["routineName"].toString(),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      )),
        ),

        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _SectionTitle(
            title: "Assiduité",
            actionText: "14 jours",
            actionColor: textSecondary,
            onAction: () {},
          ),
        ),
        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _AttendanceCard(
            accent: clubOrange,
            points: attendance,
            summaryText:
                "$attendedCount jour(s) d'entraînement sur ${attendance.length} jours",
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
          style: TextStyle(color: textSecondary),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: siteNews.length,
      itemBuilder: (context, index) {
        final article = siteNews[index] as Map<String, dynamic>;

        final imageUrl = _buildArticleImageUrl(article['photo']);
        final title = (article['title'] ?? "Titre indisponible").toString();
        final subtitle =
            (article['subtitle'] ??
                    article['excerpt'] ??
                    "Cliquez pour lire...")
                .toString();
        final publishedAt = article['publishedAt']?.toString();

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _NewsCard(
            accent: clubOrange,
            title: title,
            subtitle: subtitle,
            imageUrl: imageUrl,
            publishedAt: publishedAt,
            onTap: () {
              // 🔜 Plus tard : écran détail actu
            },
          ),
        );
      },
    );
  }
}

/// =======================
/// BOTTOM NAV BAR (theme clair)
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
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 78,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: softBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
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
    final Color activeColor = isSelected ? clubOrange : textSecondary;

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
              Icon(icon, size: 22, color: activeColor),
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

/// =======================
/// TOP BAR
/// =======================
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
            color: textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Badge(
          isLabelVisible: notifCount > 0,
          backgroundColor: clubOrange,
          textColor: Colors.white,
          label: Text("$notifCount"),
          child: _CircleIcon(
            icon: Icons.notifications_none_rounded,
            onTap: onNotifTap,
          ),
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

  ImageProvider? _resolveImageProvider(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim();

    try {
      if (v.startsWith('http://') || v.startsWith('https://')) {
        return NetworkImage(v);
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
          border: Border.all(color: softBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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

/// =======================
/// NOUVEAUX COMPOSANTS HOME
/// =======================
class _WelcomeCard extends StatelessWidget {
  final String name;
  final int favoritesCount;
  final int attendedCount;

  const _WelcomeCard({
    required this.name,
    required this.favoritesCount,
    required this.attendedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: softBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Bonjour $name",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: clubOrange.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.wb_sunny_outlined,
                  color: clubOrange,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Bienvenue 👋 Prêt à t'entraîner aujourd'hui ?",
            style: TextStyle(
              color: textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  icon: Icons.favorite_border_rounded,
                  label: "$favoritesCount favoris",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoChip(
                  icon: Icons.local_fire_department_outlined,
                  label: "$attendedCount jours actifs",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: softBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: clubOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesSummaryCard extends StatelessWidget {
  final int count;
  final List<String> favoriteNames;

  const _FavoritesSummaryCard({
    required this.count,
    required this.favoriteNames,
  });

  @override
  Widget build(BuildContext context) {
    final hasFavorites = count > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: softBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: clubOrange.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.favorite_rounded, color: clubOrange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Mes favoris",
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasFavorites
                      ? "$count entraînement(s) enregistré(s)"
                      : "Ajoute des entraînements en favoris avec le ❤️",
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                if (favoriteNames.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: favoriteNames.map((name) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF6ED),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: clubOrange.withOpacity(0.22),
                          ),
                        ),
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: clubOrange,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
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
              color: textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: -0.1,
            ),
          ),
        ),
        if (actionText != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: actionColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionText!,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: actionColor,
                fontSize: 12.5,
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
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  const _WorkoutCard({
    required this.title,
    required this.subtitle,
    required this.imgUrl,
    required this.accent,
    this.onTap,
    this.isFavorite = false,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: softBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.035),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFF1F3F5),
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.18),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: onFavoriteTap,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white),
                              ),
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 18,
                                color: isFavorite ? clubOrange : textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: clubOrange.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_arrow_rounded,
                                    color: clubOrange,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Lancer",
                                    style: TextStyle(
                                      color: clubOrange,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 13,
                              color: Colors.grey.shade500,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
    final activeCount = points.where((e) => e.value > 0).length;
    final percent = points.isEmpty
        ? 0
        : ((activeCount / points.length) * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: softBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Régularité",
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "$percent%",
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            summaryText,
            style: const TextStyle(
              color: textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 12.5,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 54,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: points.map((p) {
                final on = p.value > 0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      height: on ? (p.isToday ? 52 : 40) : 10,
                      decoration: BoxDecoration(
                        color: on
                            ? accent.withOpacity(p.isToday ? 0.95 : 0.65)
                            : const Color(0xFFEDEFF3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                points.isNotEmpty ? points.first.dayLabel : "--/--",
                style: const TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                points.isNotEmpty ? points.last.dayLabel : "--/--",
                style: const TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final Color accent;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? publishedAt;
  final VoidCallback? onTap;

  const _NewsCard({
    required this.accent,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.publishedAt,
    this.onTap,
  });

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return "Actualité";
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year.toString();
      return "$d/$m/$y";
    } catch (_) {
      return "Actualité";
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatDate(publishedAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: softBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ IMAGE HEADER
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: SizedBox(
                  height: 170,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl != null)
                        Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _NewsImageFallback(accent: accent);
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: const Color(0xFFF6F7F9),
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: clubOrange,
                                ),
                              ),
                            );
                          },
                        )
                      else
                        _NewsImageFallback(accent: accent),

                      // Overlay léger pour lisibilité du badge
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.08),
                              Colors.black.withOpacity(0.05),
                              Colors.black.withOpacity(0.22),
                            ],
                          ),
                        ),
                      ),

                      // Badge date
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 13,
                                color: accent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                dateLabel,
                                style: const TextStyle(
                                  color: textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ✅ TEXTE
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.article_rounded, size: 16, color: accent),
                        const SizedBox(width: 6),
                        const Text(
                          "Lire l’actualité",
                          style: TextStyle(
                            color: clubOrange,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: Colors.grey.shade500,
                        ),
                      ],
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

class _NewsImageFallback extends StatelessWidget {
  final Color accent;

  const _NewsImageFallback({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F6F8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -12,
            top: -8,
            child: Icon(
              Icons.fitness_center_rounded,
              size: 100,
              color: accent.withOpacity(0.08),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.image_not_supported_rounded,
                  color: Colors.grey.shade500,
                  size: 26,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Image indisponible",
                  style: TextStyle(
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
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
