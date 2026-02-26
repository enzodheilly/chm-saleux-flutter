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
const Color appBackground = Color(0xFF000000); // Retour au noir absolu
const Color navBarColor = Color(0xFF000000);
const Color surfaceColor = Color(0xFF1E1E1E); // Couleur des cartes inaltérée
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

  String currentUserName = "Chargement...";
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

  // =========================================================
  // ✅ HELPERS URL IMAGES BACKEND
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
  // ✅ HELPERS ROUTINES
  // =========================================================

  String _getImageForGroup(String groupName) {
    final name = groupName.toLowerCase().trim();
    if (name.contains("pec") || name.contains("push"))
      return "assets/images/pecs.jpg";
    if (name.contains("dos") || name.contains("pull"))
      return "assets/images/dos.jpg";
    if (name.contains("jambe") || name.contains("leg"))
      return "assets/images/jambes.jpg";
    if (name.contains("bras") || name.contains("biceps"))
      return "assets/images/bras.jpg";
    if (name.contains("epaule")) return "assets/images/epaules.jpg";
    if (name.contains("abdo") || name.contains("abs"))
      return "assets/images/abdos.jpg";
    if (name.contains("cardio") || name.contains("run"))
      return "assets/images/cardio.jpg";
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

      return {
        "title": g,
        "variationsCount": variations.length,
        "averageTime": "$duration Min",
        "rating": "4.8", // Fake rating pour matcher le design
        "imgUrl": _getImageForGroup(g),
        "routineId": rep['id'],
        "variations": variations,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground, // ✅ Retour du fond noir complet
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: _NewTopBar(
                userName: currentUserName,
                greeting: _getGreeting(),
                userImage: profileImageUrl,
                onProfileTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                  _fetchCoreData();
                },
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  IndexedStack(
                    index: _selectedIndex,
                    children: [
                      _buildUnifiedHomeFeed(),
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

  // ==========================================
  // 🟢 FLUX UNIQUE COMPLET
  // ==========================================
  Widget _buildUnifiedHomeFeed() {
    final forYou = _buildForYouPrograms();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 140),
      children: [
        // 1. CALENDRIER SEMAINE
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: _WeekCalendar(),
        ),
        const SizedBox(height: 28),

        // 2. ACTIVITÉ DU JOUR (Graphique Compact)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: _SectionHeader(
            title: "Activité du jour",
            actionText: "Voir tout",
            onAction: () {},
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: _ActivityBarChart(),
        ),
        const SizedBox(height: 32),

        // 3. PROGRAMMES POPULAIRES (Horizontal Compact)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: _SectionHeader(
            title: "Programmes Populaires",
            actionText: "Voir tout",
            onAction: () => setState(() => _selectedIndex = 1),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 145, // Hauteur compacte
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
                        padding: const EdgeInsets.only(left: 20, right: 4),
                        physics: const BouncingScrollPhysics(),
                        itemCount: forYou.length,
                        itemBuilder: (context, i) {
                          final item = forYou[i];
                          final routineId = item["routineId"] as int;

                          return _PopularMethodCard(
                            title: item["title"].toString(),
                            variationsCount: item["variationsCount"] as int,
                            rating: item["rating"].toString(),
                            imgUrl: item["imgUrl"].toString(),
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
        const SizedBox(height: 32),

        // 4. ACTUALITÉS (Vertical list style recommandation)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: _SectionHeader(
            title: "Actualités du Club",
            actionText: "Voir tout",
            onAction: () {},
          ),
        ),
        const SizedBox(height: 16),
        _buildNewsVerticalList(),
      ],
    );
  }

  Widget _buildNewsVerticalList() {
    if (isNewsLoading) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator(color: clubOrange)),
      );
    }
    if (siteNews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            "Aucune actualité.",
            style: TextStyle(color: textSecondary),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      itemCount: siteNews.length,
      itemBuilder: (context, index) {
        final article = siteNews[index] as Map<String, dynamic>;
        final imageUrl = _buildArticleImageUrl(article['photo']);
        final title = (article['title'] ?? "Titre indisponible").toString();
        final publishedAt = article['publishedAt']?.toString() ?? "";

        // Formater la date
        String dateLabel = "Récemment";
        if (publishedAt.isNotEmpty) {
          try {
            final dt = DateTime.parse(publishedAt).toLocal();
            dateLabel =
                "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}";
          } catch (_) {}
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _RecommendationCard(
            title: title,
            date: dateLabel,
            imgUrl: imageUrl,
            tag: "News",
            onTap: () {},
          ),
        );
      },
    );
  }
}

// ==========================================
// 🔥 WIDGETS POUR REPRODUIRE LA MAQUETTE
// ==========================================

// 1. TOP BAR
class _NewTopBar extends StatelessWidget {
  final String userName;
  final String greeting;
  final String? userImage;
  final VoidCallback onProfileTap;

  const _NewTopBar({
    required this.userName,
    required this.greeting,
    this.userImage,
    required this.onProfileTap,
  });

  ImageProvider? _resolveImage(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http'))
      return NetworkImage(
        url
            .replaceFirst('127.0.0.1', '10.0.2.2')
            .replaceFirst('localhost', '10.0.2.2'),
      );
    if (url.contains(','))
      return MemoryImage(base64Decode(url.split(',').last));
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final image = _resolveImage(userImage);
    return Row(
      children: [
        GestureDetector(
          onTap: onProfileTap,
          child: CircleAvatar(
            radius: 22,
            backgroundColor: surfaceColor,
            backgroundImage: image,
            child: image == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        _TopBarIconButton(
          icon: Icons.notifications_none_rounded,
          hasBadge: true,
          onTap: () {},
        ),
        const SizedBox(width: 10),
        _TopBarIconButton(
          icon: Icons.calendar_today_rounded,
          hasBadge: false,
          onTap: () {},
        ),
      ],
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  final IconData icon;
  final bool hasBadge;
  final VoidCallback onTap;

  const _TopBarIconButton({
    required this.icon,
    required this.hasBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
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
              top: 0,
              right: 2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4B4B),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: appBackground,
                    width: 2,
                  ), // Bordure raccord avec le fond noir
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// 2. EN-TÊTE DE SECTION
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
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        GestureDetector(
          onTap: onAction,
          child: Text(
            actionText,
            style: const TextStyle(
              color: textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// 3. CALENDRIER DE LA SEMAINE
class _WeekCalendar extends StatelessWidget {
  const _WeekCalendar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          _DayIcon(day: "Lun", date: "12", isCompleted: true),
          _DayIcon(day: "Mar", date: "13", isCompleted: false),
          _DayIcon(day: "Mer", date: "14", isCompleted: true),
          _DayIcon(day: "Jeu", date: "15", isCompleted: true),
          _DayIcon(day: "Ven", date: "16", isToday: true),
          _DayIcon(day: "Sam", date: "17", isCompleted: false),
          _DayIcon(day: "Dim", date: "18", isCompleted: false),
        ],
      ),
    );
  }
}

class _DayIcon extends StatelessWidget {
  final String day;
  final String date;
  final bool isCompleted;
  final bool isToday;

  const _DayIcon({
    required this.day,
    required this.date,
    this.isCompleted = false,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            color: isToday ? clubOrange : textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 36, // Compact
          height: 36, // Compact
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isToday
                ? clubOrange.withOpacity(0.15)
                : (isCompleted ? Colors.transparent : const Color(0xFF2C2C2E)),
            border: Border.all(
              color: isToday || isCompleted ? clubOrange : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              date,
              style: TextStyle(
                color: isToday ? clubOrange : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// 4. GRAPHIQUE ACTIVITÉ (Compact)
class _ActivityBarChart extends StatelessWidget {
  const _ActivityBarChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: const [
          _Bar(label: "Biceps", height: 35, val: "8"),
          _Bar(label: "Pecs", height: 65, val: "16", isActive: true),
          _Bar(label: "Dos", height: 60, val: "14", isActive: true),
          _Bar(label: "Jambes", height: 80, val: "20"),
          _Bar(label: "Epaules", height: 95, val: "24", isActive: true),
          _Bar(label: "Bras", height: 50, val: "12"),
          _Bar(label: "Cardio", height: 40, val: "10"),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final double height;
  final String val;
  final bool isActive;

  const _Bar({
    required this.label,
    required this.height,
    required this.val,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isActive) ...[
          Text(
            "↑ $val",
            style: const TextStyle(
              color: clubOrange,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
        ] else ...[
          Text(
            val,
            style: const TextStyle(
              color: textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Container(
          width: 32,
          height: height,
          decoration: BoxDecoration(
            color: isActive ? clubOrange : const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(
                "kg",
                style: TextStyle(
                  color: isActive
                      ? Colors.white.withOpacity(0.7)
                      : textSecondary.withOpacity(0.5),
                  fontSize: 9,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// 5. CARTE PROGRAMMES POPULAIRES (Compacte)
class _PopularMethodCard extends StatelessWidget {
  final String title;
  final int variationsCount;
  final String rating;
  final String imgUrl;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  const _PopularMethodCard({
    required this.title,
    required this.variationsCount,
    required this.rating,
    required this.imgUrl,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: surfaceColor,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              imgUrl.startsWith('http')
                  ? Image.network(imgUrl, fit: BoxFit.cover)
                  : Image.asset(imgUrl, fit: BoxFit.cover),
              // Dark Gradient plus fort pour que le texte ressorte
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.95),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
              // Bookmark
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: onFavoriteTap,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isFavorite ? Icons.bookmark : Icons.bookmark_border,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
              // Texts (Marges réduites)
              Positioned(
                bottom: 12,
                left: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.fitness_center_rounded,
                          color: textSecondary,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "$variationsCount Variantes",
                          style: const TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.star, color: textSecondary, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          rating,
                          style: const TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }
}

// 6. CARTE RECOMMANDATION (Utilisée pour les Actualités)
class _RecommendationCard extends StatelessWidget {
  final String title;
  final String date;
  final String? imgUrl;
  final String tag;
  final VoidCallback onTap;

  const _RecommendationCard({
    required this.title,
    required this.date,
    this.imgUrl,
    required this.tag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 70,
                height: 70,
                child: imgUrl != null
                    ? Image.network(
                        imgUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallbackImg(),
                      )
                    : _fallbackImg(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: textSecondary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackImg() {
    return Container(
      color: const Color(0xFF2C2C2E),
      child: const Center(
        child: Icon(Icons.article_rounded, color: textSecondary, size: 24),
      ),
    );
  }
}

// ==========================================
// ✅ BARRE DE NAVIGATION (FROSTED GLASS INTACTE)
// ==========================================
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
