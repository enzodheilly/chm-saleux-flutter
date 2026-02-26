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

const Color clubOrange = Color(0xFFF57809);
const Color appBackground = Color(0xFF000000);
const Color navBarColor = Color(0xFF000000);
const Color surfaceColor = Color(0xFF222222);
const Color textPrimary = Color(0xFFFFFFFF);
const Color textSecondary = Color(0xFFA0A5B1);
const Color softBorder = Color(0xFF333333);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  String currentUserName = "ATHLÈTE";
  String? profileImageUrl;

  List<dynamic> allPrograms = [];
  List<dynamic> lastSessions = [];
  List<dynamic> siteNews = [];
  Map<String, dynamic>? profile;

  bool isLoading = true;
  bool isNewsLoading = true;

  final Set<int> _favoriteRoutineIds = <int>{};

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

  // =========================================================
  // ✅ HELPERS URL IMAGES BACKEND (Seulement pour Profil & News)
  // =========================================================

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

  // =========================================================
  // ✅ HELPERS (Images & Textes) POUR LES ROUTINES
  // =========================================================

  String _getCategoryDescription(String title) {
    final t = title.toLowerCase();
    if (t.contains("pec") || t.contains("push")) {
      return "Travaille ta force de poussée et sculpte un torse puissant.";
    }
    if (t.contains("dos") || t.contains("pull")) {
      return "Construis un dos large et épais grâce à ces tirages ciblés.";
    }
    if (t.contains("jambe") || t.contains("bas")) {
      return "Le fondement de ta force. Des quadriceps aux mollets.";
    }
    if (t.contains("bras") || t.contains("biceps") || t.contains("triceps")) {
      return "Isole tes muscles pour des bras massifs et dessinés.";
    }
    if (t.contains("epaule") || t.contains("épaule")) {
      return "Développe des épaules larges et fortes en 3D.";
    }
    if (t.contains("cardio") || t.contains("run")) {
      return "Améliore ton endurance et brûle un maximum de calories.";
    }
    if (t.contains("mobil")) {
      return "Gagne en souplesse, récupère mieux et préviens les blessures.";
    }
    if (t.contains("perte") || t.contains("poids")) {
      return "Des circuits haute intensité pour fondre efficacement.";
    }
    if (t.contains("full") || t.contains("body")) {
      return "Sollicite tout ton corps pour un développement harmonieux.";
    }
    return "Repousse tes limites avec ces entraînements ciblés spécialement pour toi.";
  }

  String _getImageForGroup(String groupName) {
    final name = groupName.toLowerCase().trim();
    if (name.contains("pec") ||
        name.contains("chest") ||
        name.contains("push")) {
      return "assets/images/pecs.jpg";
    }
    if (name.contains("dos") ||
        name.contains("back") ||
        name.contains("pull")) {
      return "assets/images/dos.jpg";
    }
    if (name.contains("jambe") ||
        name.contains("leg") ||
        name.contains("bas")) {
      return "assets/images/jambes.jpg";
    }
    if (name.contains("bras") ||
        name.contains("arm") ||
        name.contains("biceps") ||
        name.contains("triceps")) {
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
    if (name.contains("mobil")) {
      return "assets/images/mobilite.jpg";
    }
    if (name.contains("perte") || name.contains("poids")) {
      return "assets/images/perte_poids.jpg";
    }
    if (name.contains("full") ||
        name.contains("body") ||
        name.contains("haut")) {
      return "assets/images/fullbody.jpg";
    }
    return "assets/images/default.jpg";
  }

  IconData _getIconForCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('pec') || c.contains('push')) return Icons.fitness_center;
    if (c.contains('dos') || c.contains('back') || c.contains('pull')) {
      return Icons.accessibility_new_rounded;
    }
    if (c.contains('jambe') || c.contains('leg')) {
      return Icons.directions_run_rounded;
    }
    if (c.contains('bras') || c.contains('arm')) {
      return Icons.sports_gymnastics_rounded;
    }
    if (c.contains('triceps') || c.contains('avant')) {
      return Icons.sports_gymnastics_rounded;
    }
    if (c.contains('epaule') || c.contains('épaule')) {
      return Icons.accessibility_rounded;
    }
    if (c.contains('abdo')) return Icons.sports_martial_arts_rounded;
    if (c.contains('cardio') || c.contains('run')) {
      return Icons.monitor_heart_rounded;
    }
    if (c.contains('mobil')) return Icons.self_improvement_rounded;
    if (c.contains('perte') || c.contains('poids')) {
      return Icons.monitor_weight_rounded;
    }
    if (c.contains('full') || c.contains('body')) {
      return Icons.accessibility_new_rounded;
    }
    return Icons.fitness_center_rounded;
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

      final routineImageUrl = _getImageForGroup(g);
      final desc = _getCategoryDescription(g);

      return {
        "title": g,
        "subtitle": labelLevel,
        "description": desc,
        "variationsCount": variations.length,
        "averageTime": "$duration min",
        "imgUrl": routineImageUrl,
        "categoryForIcon": g,
        "routineId": rep['id'],
        "routineName": rep['name'] ?? g,
        "variations": variations,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      body: SafeArea(
        bottom: false, // <-- Crucial pour que la barre aille tout en bas
        child: Column(
          children: [
            Container(
              color: navBarColor,
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
                  _fetchCoreData();
                },
                onNotifTap: () {},
              ),
            ),
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
                    left: 0,
                    right: 0,
                    bottom: 0,
                    // ✅ MODIFICATION ICI : On a retiré le SafeArea wrapper
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

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 140),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _WelcomeCard(name: currentUserName),
        ),
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: _FavoritesSummaryCard(),
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
          height: 280,
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
                        padding: const EdgeInsets.only(left: 16, right: 0),
                        physics: const BouncingScrollPhysics(),
                        itemCount: forYou.length,
                        itemBuilder: (context, i) {
                          final item = forYou[i];
                          final routineId = item["routineId"] as int;

                          return _PremiumWorkoutCard(
                            title: item["title"].toString(),
                            description: item["description"].toString(),
                            variationsCount: item["variationsCount"] as int,
                            averageTime: item["averageTime"].toString(),
                            imgUrl: item["imgUrl"].toString(),
                            fallbackIcon: _getIconForCategory(
                              item["categoryForIcon"].toString(),
                            ),
                            isFavorite: _favoriteRoutineIds.contains(routineId),
                            onFavoriteTap: () => _toggleFavorite(routineId),
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
        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _SectionTitle(
            title: "Conseil Nutritionnel",
            actionColor: textSecondary,
            onAction: () {},
          ),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: _NutritionCard(),
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
            onTap: () {},
          ),
        );
      },
    );
  }
}

// =====================
// ✅ BARRE DE NAVIGATION (Refaite mode App Native)
// =====================
class _GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _GlassBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Permet de s'assurer que les icônes ne sont pas cachées par la petite barre iPhone en bas
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 70 + bottomPadding,
          padding: EdgeInsets.only(bottom: bottomPadding, left: 6, right: 6),
          decoration: BoxDecoration(
            color: navBarColor.withOpacity(0.95),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 18,
                offset: const Offset(0, -4),
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

      // sinon on suppose base64
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
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

class _WelcomeCard extends StatelessWidget {
  final String name;

  const _WelcomeCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF57809),
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "BONJOUR $name",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          const Expanded(
            child: Text(
              "Prêt à repousser tes limites ?\nChaque répétition te rapproche de ton objectif.\nDonne le maximum aujourd'hui !",
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesSummaryCard extends StatelessWidget {
  const _FavoritesSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 20.0),
                child: Text(
                  "MES FAVORIS",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 0),
              child: Transform.translate(
                offset: const Offset(0, 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/image.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
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

class _PremiumWorkoutCard extends StatelessWidget {
  final String title;
  final String description;
  final int variationsCount;
  final String averageTime;
  final String imgUrl;
  final IconData fallbackIcon;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  const _PremiumWorkoutCard({
    required this.title,
    required this.description,
    required this.variationsCount,
    required this.averageTime,
    required this.imgUrl,
    required this.fallbackIcon,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color surfaceColor = Color(0xFF1C1C22);
    const Color textPrimary = Color(0xFFFFFFFF);
    const Color textSecondary = Color(0xFFA0A5B1);
    const Color softBorder = Color(0xFF333333);
    const Color accent = Color(0xFFF57809);

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: SizedBox(
                    height: 125,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        imgUrl.startsWith('http')
                            ? Image.network(
                                imgUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: softBorder,
                                  child: Center(
                                    child: Icon(
                                      fallbackIcon,
                                      size: 32,
                                      color: textSecondary.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              )
                            : Image.asset(
                                imgUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: softBorder,
                                  child: Center(
                                    child: Icon(
                                      fallbackIcon,
                                      size: 32,
                                      color: textSecondary.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        if (onFavoriteTap != null)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: onFavoriteTap,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 18,
                                  color: isFavorite ? accent : Colors.white,
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        const Spacer(),
                        Divider(
                          color: Colors.white.withOpacity(0.05),
                          height: 16,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.layers_rounded,
                                      color: accent,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "$variationsCount variantes",
                                      style: const TextStyle(
                                        color: accent,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.timer_outlined,
                                      color: textSecondary,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "~ $averageTime",
                                      style: const TextStyle(
                                        color: textSecondary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
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

class _NutritionCard extends StatelessWidget {
  const _NutritionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: clubOrange.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: clubOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Protéines & Récupération",
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Vise entre 1.6g et 2g de protéines par kilo de poids de corps chaque jour. Cela maximisera ta reconstruction musculaire après l'effort et optimisera tes résultats.",
                  style: TextStyle(
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    height: 1.4,
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                              color: softBorder,
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
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
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
                                  color: Colors.black,
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
                          color: textSecondary,
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
      color: softBorder,
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
                  color: textSecondary,
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
