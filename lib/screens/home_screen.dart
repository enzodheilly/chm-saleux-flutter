import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';

// ✅ AJOUT DES IMPORTS
import 'package:provider/provider.dart';
import '../services/workout_manager.dart';
import '../widgets/active_workout_bar.dart';

import '../services/auth_service.dart';
import '../services/routine_service.dart';
import 'training_screen.dart';
import 'workout_player_screen.dart';

// ✅ Const global (pour pouvoir l'utiliser dans des widgets const)
const Color clubOrange = Color(0xFFF57809);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ✅ VARIABLES D'ÉTAT
  int _selectedIndex = 0; // Pour la barre du bas
  int _selectedDayIndex = DateTime.now().weekday - 1; // 0=Lundi
  final List<String> _days = ["LUN", "MAR", "MER", "JEU", "VEN", "SAM", "DIM"];

  String currentUserName = "ATHLÈTE";
  String? profileImageUrl;

  List<dynamic> weeklySchedule = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await AuthService().getUserProfile();
      final schedule = await RoutineService().getWeeklySchedule();

      // (Optionnel) debug
      // debugPrint("JSON REÇU : ${jsonEncode(schedule)}");

      if (!mounted) return;

      setState(() {
        if (profile != null) {
          currentUserName = profile['firstName']?.toUpperCase() ?? "ATHLÈTE";
          profileImageUrl = profile['profileImageUrl'];
        }
        weeklySchedule = schedule;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Erreur chargement: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  // ✅ HELPER : Trouve la séance pour le jour sélectionné
  Map<String, dynamic>? _getRoutineForSelectedDay() {
    DateTime now = DateTime.now();
    int diff = _selectedDayIndex - (now.weekday - 1);
    DateTime targetDate = now.add(Duration(days: diff));
    String targetString = targetDate.toIso8601String().split('T')[0];

    try {
      final scheduleEntry = weeklySchedule.firstWhere((entry) {
        final dateValue = entry['scheduledDate'] ?? entry['scheduled_date'];
        return dateValue != null &&
            dateValue.toString().startsWith(targetString);
      }, orElse: () => null);

      if (scheduleEntry != null) {
        return scheduleEntry['routineTemplate'] ??
            scheduleEntry['routine_template'];
      }
    } catch (e) {
      debugPrint("Erreur helper date: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Thème local
    final clubScheme =
        ColorScheme.fromSeed(
          seedColor: clubOrange,
          brightness: Brightness.dark,
        ).copyWith(
          primary: clubOrange,
          secondary: clubOrange,
          tertiary: clubOrange,
          surface: const Color(0xFF0B0B0F),
          surfaceContainerHighest: const Color(0xFF17171F),
          outlineVariant: const Color(0xFF2A2A34),
        );

    final List<Widget> pages = [
      _buildHomeContent(clubScheme),
      const TrainingScreen(),
      const Center(
        child: Text("Page Progrès", style: TextStyle(color: Colors.white)),
      ),
      const Center(
        child: Text("Page Coach", style: TextStyle(color: Colors.white)),
      ),
      const Center(
        child: Text("Page Clubs", style: TextStyle(color: Colors.white)),
      ),
    ];

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: clubScheme,
        scaffoldBackgroundColor: clubScheme.surface,
      ),
      child: Scaffold(
        backgroundColor: clubScheme.surface,

        // ✅ STACK + BARRE ORANGE PERSISTANTE (visible seulement si active)
        body: Stack(
          children: [
            pages[_selectedIndex],

            // 🔥 BARRE DE REPRISE (SEULEMENT SI workout actif)
            Consumer<WorkoutManager>(
              builder: (context, manager, child) {
                if (!manager.isActive) return const SizedBox.shrink();

                return const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0, // ✅ pile au-dessus de la NavigationBar
                  child: ActiveWorkoutBar(),
                );
              },
            ),
          ],
        ),

        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          height: 70,
          backgroundColor: clubScheme.surface,
          indicatorColor: clubOrange.withOpacity(0.18),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: "Accueil",
            ),
            NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center),
              label: "Entraînement",
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: "Progrès",
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: "Coach",
            ),
            NavigationDestination(
              icon: Icon(Icons.location_on_outlined),
              selectedIcon: Icon(Icons.location_on),
              label: "Clubs",
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Contenu de la page Accueil (TabBar + Tabs)
  Widget _buildHomeContent(ColorScheme clubScheme) {
    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // TOP BAR
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _TopBar(
                title: "chm saleux",
                notifCount: 3,
                userImage: profileImageUrl,
                onProfileTap: () {},
                onNotifTap: () {},
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // TABS
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: clubScheme.outlineVariant.withOpacity(0.7),
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
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        bottom: 120, // ✅ pour ne pas cacher le contenu par la barre orange
      ),
      children: [
        // 🔥 1. SÉLECTEUR DE JOURS
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 7,
            itemBuilder: (context, index) {
              bool isSelected = _selectedDayIndex == index;
              bool isToday = (DateTime.now().weekday - 1) == index;

              return GestureDetector(
                onTap: () => setState(() => _selectedDayIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 55,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? clubOrange
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSelected
                          ? clubOrange
                          : Colors.white.withOpacity(0.1),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: clubOrange.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _days[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.black26
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            "${DateTime.now().add(Duration(days: index - (DateTime.now().weekday - 1))).day}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      if (isToday && !isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: clubOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // ✅ ON REMPLACE LE BUILDER PAR UN CONSUMER POUR ÉCOUTER LE MANAGER
        Consumer<WorkoutManager>(
          builder: (context, manager, child) {
            final activeRoutine = _getRoutineForSelectedDay();

            // 🔍 On vérifie si la séance affichée est celle qui tourne actuellement
            bool isRunning =
                activeRoutine != null &&
                manager.isActive &&
                manager.routineId == activeRoutine['id'];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _HeroBanner(
                name: currentUserName,
                title: activeRoutine != null
                    ? activeRoutine['name']
                    : "RIEN DE PRÉVU",
                meta: activeRoutine != null
                    ? "${activeRoutine['muscleGroup'] ?? 'Entraînement'} • ${activeRoutine['estimatedDurationMin'] ?? 60} min"
                    : "Planifie ta séance pour ${_days[_selectedDayIndex]} !",
                accent: clubOrange,

                // ✅ LE TEXTE CHANGE ICI
                buttonText: isRunning
                    ? "EN COURS"
                    : (activeRoutine != null ? "DÉMARRER" : "PLANIFIER"),

                // ✅ L'ICÔNE CHANGE AUSSI
                buttonIcon: isRunning
                    ? Icons.timelapse_rounded
                    : (activeRoutine != null
                          ? Icons.play_arrow_rounded
                          : Icons.calendar_month_rounded),

                onStart: () {
                  if (isRunning) {
                    // 🚀 CAS 1 : REPRENDRE LA SÉANCE EN COURS
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutPlayerScreen(
                          routineId: manager.routineId!,
                          routineName: manager.routineName!,
                        ),
                      ),
                    );
                  } else if (activeRoutine != null) {
                    // 🚀 CAS 2 : DÉMARRER UNE NOUVELLE SÉANCE
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutPlayerScreen(
                          routineId: activeRoutine['id'],
                          routineName: activeRoutine['name'],
                        ),
                      ),
                    );
                  } else {
                    // 📅 CAS 3 : PLANIFIER
                    DateTime now = DateTime.now();
                    int diff = _selectedDayIndex - (now.weekday - 1);
                    DateTime targetDate = now.add(Duration(days: diff));

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TrainingScreen(targetDate: targetDate),
                      ),
                    ).then((value) {
                      if (value == true) {
                        setState(() => isLoading = true);
                        _fetchProfile();
                      }
                    });
                  }
                },
              ),
            );
          },
        ),

        const SizedBox(height: 26),

        // 3. TITRE SECTION
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

        // 4. CARTES SUGGESTIONS
        SizedBox(
          height: 190,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, right: 8),
            physics: const BouncingScrollPhysics(),
            children: const [
              _WorkoutCard(
                title: "Force & Volume",
                subtitle: "4 mins • Intermédiaire",
                imgUrl:
                    "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=900",
                accent: clubOrange,
              ),
              _WorkoutCard(
                title: "Nutrition Post-Effort",
                subtitle: "3 mins • Conseils",
                imgUrl:
                    "https://images.unsplash.com/photo-1546483875-ad9014c88eba?q=80&w=900",
                accent: clubOrange,
              ),
            ],
          ),
        ),

        const SizedBox(height: 26),

        // 5. PROMO CARD
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _PromoCard(
            title: "PARRAINE UN(E) AMI(E) !",
            subtitle: "Et gagne des crédits.",
            icon: Icons.people_alt_rounded,
            accent: clubOrange,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildNewsTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        120, // ✅ espace pour la barre orange
      ),
      children: const [
        _NewsCard(
          accent: clubOrange,
          title: "Nouveau challenge du mois",
          subtitle: "Objectif : 12 séances • Récompenses à la clé",
          icon: Icons.local_fire_department_rounded,
        ),
        SizedBox(height: 12),
        _NewsCard(
          accent: clubOrange,
          title: "Conseil coaching",
          subtitle: "Récup : 7h de sommeil + 2L d’eau / jour",
          icon: Icons.tips_and_updates_rounded,
        ),
        SizedBox(height: 12),
        _NewsCard(
          accent: clubOrange,
          title: "Horaires du club",
          subtitle: "Ouvert jusqu’à 23h cette semaine 💪",
          icon: Icons.access_time_rounded,
        ),
      ],
    );
  }
}

/// =======================
/// WIDGETS COMPONENTS
/// =======================

// 🔥 1. WIDGET "BOUTON VERRE"
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
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// 🔥 2. WIDGET "CONTENEUR VERRE"
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
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
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
    final cs = Theme.of(context).colorScheme;
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
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontSize: 14,
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
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(color: cs.outlineVariant.withOpacity(0.85)),
          image: (userImage != null && userImage!.isNotEmpty)
              ? DecorationImage(
                  image: MemoryImage(base64Decode(userImage!.split(',').last)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: (userImage == null || userImage!.isEmpty)
            ? Center(child: Icon(icon, size: 22, color: cs.onSurface))
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
    final cs = Theme.of(context).colorScheme;

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
                  colors: [const Color(0xFF111119), accent.withOpacity(0.18)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "BONJOUR $name",
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Prêt pour ta séance du jour ?\nC'est la clé du succès !",
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(0.78),
                      fontSize: 13,
                      height: 1.25,
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
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
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
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              letterSpacing: 0.6,
            ),
          ),
        ),
        if (actionText != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionText!,
              style: TextStyle(fontWeight: FontWeight.w800, color: actionColor),
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

  const _WorkoutCard({
    required this.title,
    required this.subtitle,
    required this.imgUrl,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.78),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        color: Colors.white.withOpacity(0.15),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_circle_fill_rounded,
                              color: accent,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Lancer",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.92),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
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
    );
  }
}

class _PromoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;

  const _PromoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF14141C), Color(0xFFF57809)],
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.20),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _GlassButton(
                    onTap: onTap,
                    accent: accent,
                    child: const Text(
                      "EN SAVOIR PLUS",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 84, color: Colors.white.withOpacity(0.22)),
          ],
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.7)),
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
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.75),
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
