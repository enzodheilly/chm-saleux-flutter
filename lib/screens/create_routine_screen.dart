import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/routine_service.dart';
import '../widgets/glass_surface.dart';
import '../theme/app_theme.dart';
import '../widgets/design_system.dart';
import 'workout_player_screen.dart';
import 'program_config_screen.dart';

// =========================
// COULEURS DU THÈME GLOBALES
// (pointent vers le système de design partagé — noms locaux conservés
// pour ne pas avoir à renommer tous les usages dans ce fichier)
// =========================
const Color clubOrange = AppColors.accent;
const Color darkBg = AppColors.bg;
const Color purpleButton = AppColors.accent;
const Color surfaceColor = AppColors.surface;
const Color textPrimary = AppColors.textPrimary;
const Color textSecondary = AppColors.textSecondary;
const Color softBorder = AppColors.line;

/// Alias de compatibilité
class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) => const CreateRoutineScreen();
}

// =========================
// SCREEN PRINCIPAL
// =========================

class CreateRoutineScreen extends StatefulWidget {
  const CreateRoutineScreen({super.key});

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  // =========================
  // NAVIGATION / ONGLETS
  // =========================
  int _currentTabIndex = 0; // 0 = Catalogue, 1 = Favoris, 2 = Mes Routines
  bool _isCreateMode = false;

  // =========================
  // CATALOGUE DATA
  // =========================
  bool _isLoadingCatalog = true;
  List<dynamic> _catalogRoutines = [];
  final Set<String> _favoriteCategoryTitles = <String>{};

  // =========================
  // MY ROUTINES DATA
  // =========================
  bool _isLoadingRoutines = true;
  List<dynamic> _myRoutines = [];
  Map<String, dynamic>? _optimisticCreatedRoutine;
  int? _lastCreatedRoutineId;

  // =========================
  // DRAFT CREATE/EDIT FORM
  // =========================
  int? _editingRoutineId;
  final TextEditingController _titleCtrl = TextEditingController();
  bool _isSaving = false;
  final List<_DraftRoutineExercise> _exercises = [];

  // =========================
  // CATÉGORIES FIXES
  // =========================
  final List<Map<String, dynamic>> _muscleCategories = [
    {
      "title": "Pectoraux",
      "keys": ["pec", "chest", "push"],
    },
    {
      "title": "Dos",
      "keys": ["dos", "back", "pull"],
    },
    {
      "title": "Jambes",
      "keys": ["jambe", "leg", "quad", "ischio", "mollet", "bas"],
    },
    {
      "title": "Épaules",
      "keys": ["épaule", "epaule", "shoulder", "delto"],
    },
    {
      "title": "Bras",
      "keys": ["bras", "arm", "biceps", "triceps"],
    },
    {
      "title": "Avant-bras",
      "keys": ["avant", "forearm"],
    },
  ];

  final List<Map<String, dynamic>> _otherCategories = [
    {
      "title": "Cardio",
      "keys": ["cardio", "run"],
    },
    {
      "title": "Mobilité",
      "keys": ["mobil", "stretch"],
    },
    {
      "title": "Perte de poids",
      "keys": ["perte", "poids", "weight", "mincir"],
    },
    {
      "title": "Full Body",
      "keys": ["full", "body", "complet", "haut"],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCatalogRoutines();
    _loadMyRoutines();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  // =========================
  // API FETCHING & ACTIONS
  // =========================

  Future<void> _loadCatalogRoutines() async {
    if (mounted) setState(() => _isLoadingCatalog = true);
    try {
      final catalog = await RoutineService().getAllPrograms();
      if (!mounted) return;
      setState(() {
        _catalogRoutines = catalog;
        _isLoadingCatalog = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCatalog = false);
      debugPrint("Erreur chargement catalogue : $e");
    }
  }

  Future<void> _loadMyRoutines() async {
    if (mounted) setState(() => _isLoadingRoutines = true);
    try {
      final routines = await RoutineService().getMyCustomRoutines();
      if (!mounted) return;
      setState(() {
        _myRoutines = routines;
        _isLoadingRoutines = false;
        // ✅ FIX BUG 3 — On nettoie l'optimistic si la routine est confirmée côté API
        if (_optimisticCreatedRoutine != null) {
          final optimisticId = _toInt(_optimisticCreatedRoutine!['id']);
          final exists =
              optimisticId != null &&
              _myRoutines.any((r) => _toInt(_mapify(r)['id']) == optimisticId);
          if (exists) _optimisticCreatedRoutine = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingRoutines = false);
    }
  }

  List<dynamic> _effectiveRoutines() {
    if (_optimisticCreatedRoutine == null) return _myRoutines;
    final optimisticId = _toInt(_optimisticCreatedRoutine!['id']);
    if (optimisticId == null)
      return [_optimisticCreatedRoutine!, ..._myRoutines];
    final exists = _myRoutines.any(
      (r) => _toInt(_mapify(r)['id']) == optimisticId,
    );
    if (exists) return _myRoutines;
    return [_optimisticCreatedRoutine!, ..._myRoutines];
  }

  void _toggleCategoryFavorite(String title) {
    setState(() {
      if (_favoriteCategoryTitles.contains(title)) {
        _favoriteCategoryTitles.remove(title);
      } else {
        _favoriteCategoryTitles.add(title);
      }
    });
  }

  // =========================
  // FAVORIS (catégories)
  // =========================

  List<Map<String, dynamic>> get _allCategories => [
    ..._muscleCategories,
    ..._otherCategories,
  ];

  List<Map<String, dynamic>> _favoriteCategories() {
    return _allCategories
        .where(
          (c) =>
              _favoriteCategoryTitles.contains((c['title'] ?? '').toString()),
        )
        .toList();
  }

  // =========================
  // NAVIGATION ACTIONS
  // =========================

  void _enterCreateMode() {
    setState(() {
      _currentTabIndex = 2;
      _isCreateMode = true;
      _resetDraft();
      _editingRoutineId = null;
    });
  }

  void _cancelCreateMode() {
    setState(() {
      _isCreateMode = false;
      _resetDraft();
    });
  }

  void _resetDraft() {
    _titleCtrl.clear();
    _exercises.clear();
    _isSaving = false;
    _editingRoutineId = null;
  }

  void _openCategoryConfig(String title, List<String> keys) {
    final variations = _catalogRoutines.where((r) {
      final group =
          (_mapify(r)['muscleGroup'] ?? _mapify(r)['category'] ?? 'Autre')
              .toString()
              .toLowerCase();
      return keys.any((k) => group.contains(k));
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProgramConfigScreen(muscleGroup: title, variations: variations),
      ),
    );
  }

  // =========================
  // HELPERS (Images & Textes)
  // =========================

  String _getCategoryDescription(String title) {
    final t = title.toLowerCase();
    if (t.contains("pec") || t.contains("push"))
      return "Travaille ta force de poussée et sculpte un torse puissant.";
    if (t.contains("dos") || t.contains("pull"))
      return "Construis un dos large et épais grâce à ces tirages ciblés.";
    if (t.contains("jambe") || t.contains("bas"))
      return "Le fondement de ta force. Des quadriceps aux mollets.";
    if (t.contains("bras") || t.contains("biceps") || t.contains("triceps"))
      return "Isole tes muscles pour des bras massifs et dessinés.";
    if (t.contains("cardio") || t.contains("run"))
      return "Améliore ton endurance et brûle un maximum de calories.";
    if (t.contains("mobil"))
      return "Gagne en souplesse, récupère mieux et préviens les blessures.";
    if (t.contains("perte") || t.contains("poids"))
      return "Des circuits haute intensité pour fondre efficacement.";
    if (t.contains("full") || t.contains("body"))
      return "Sollicite tout ton corps pour un développement harmonieux.";
    return "Repousse tes limites avec ces entraînements ciblés spécialement pour toi.";
  }

  String _getImageForGroup(String groupName) {
    final name = groupName.toLowerCase().trim();
    if (name.contains("pec") || name.contains("chest") || name.contains("push"))
      return "assets/images/pecs.jpg";
    if (name.contains("dos") || name.contains("back") || name.contains("pull"))
      return "assets/images/dos.jpg";
    if (name.contains("jambe") || name.contains("leg") || name.contains("bas"))
      return "assets/images/jambes.jpg";
    if (name.contains("bras") ||
        name.contains("arm") ||
        name.contains("biceps") ||
        name.contains("triceps"))
      return "assets/images/bras.jpg";
    if (name.contains("epaule") || name.contains("épaule"))
      return "assets/images/epaules.jpg";
    if (name.contains("abdo") || name.contains("abs"))
      return "assets/images/abdos.jpg";
    if (name.contains("cardio") || name.contains("run"))
      return "assets/images/cardio.jpg";
    if (name.contains("mobil")) return "assets/images/mobilite.jpg";
    if (name.contains("perte") || name.contains("poids"))
      return "assets/images/perte_poids.jpg";
    if (name.contains("full") || name.contains("body") || name.contains("haut"))
      return "assets/images/fullbody.jpg";
    return "assets/images/default.jpg";
  }

  IconData _getIconForCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('pec') || c.contains('push')) return Icons.fitness_center;
    if (c.contains('dos') || c.contains('back') || c.contains('pull'))
      return Icons.accessibility_new_rounded;
    if (c.contains('jambe') || c.contains('leg'))
      return Icons.directions_run_rounded;
    if (c.contains('bras') || c.contains('arm'))
      return Icons.sports_gymnastics_rounded;
    if (c.contains('triceps') || c.contains('avant'))
      return Icons.sports_gymnastics_rounded;
    if (c.contains('epaule') || c.contains('épaule'))
      return Icons.accessibility_rounded;
    if (c.contains('abdo')) return Icons.sports_martial_arts_rounded;
    if (c.contains('cardio') || c.contains('run'))
      return Icons.monitor_heart_rounded;
    if (c.contains('mobil')) return Icons.self_improvement_rounded;
    if (c.contains('perte') || c.contains('poids'))
      return Icons.monitor_weight_rounded;
    if (c.contains('full') || c.contains('body'))
      return Icons.accessibility_new_rounded;
    return Icons.fitness_center_rounded;
  }

  // =========================
  // CREATE / EDIT FLOW
  // =========================

  Future<void> _openExercisePicker() async {
    final picked = await Navigator.push<_ExerciseLite?>(
      context,
      MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
    );
    if (picked == null) return;
    if (_exercises.any((e) => e.exerciseId == picked.id)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cet exercice est déjà dans la routine.")),
      );
      return;
    }
    setState(() {
      _exercises.add(
        _DraftRoutineExercise(
          exerciseId: picked.id,
          name: picked.name,
          muscleGroup: picked.muscleGroup,
          sets: 1,
          reps: 10,
          restSec: 60,
        ),
      );
    });
  }

  void _removeExercise(int index) => setState(() => _exercises.removeAt(index));

  void _moveUp(int index) {
    if (index > 0) {
      setState(() {
        final item = _exercises.removeAt(index);
        _exercises.insert(index - 1, item);
      });
    }
  }

  void _moveDown(int index) {
    if (index < _exercises.length - 1) {
      setState(() {
        final item = _exercises.removeAt(index);
        _exercises.insert(index + 1, item);
      });
    }
  }

  List<Map<String, dynamic>> _buildExercisePayloadFromDraft() {
    return [
      for (int i = 0; i < _exercises.length; i++)
        {
          "exerciseId": _exercises[i].exerciseId,
          "order": i + 1,
          "sets": _exercises[i].sets,
          "reps": _exercises[i].reps,
          "restSec": _exercises[i].restSec,
        },
    ];
  }

  Future<void> _saveRoutine() async {
    final name = _titleCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ajoute un titre à ta routine.")),
      );
      return;
    }
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ajoute au moins un exercice.")),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payload = _buildExercisePayloadFromDraft();
      final bool isEdit = _editingRoutineId != null;
      final result = isEdit
          ? await RoutineService().updateCustomRoutine(
              routineId: _editingRoutineId!,
              name: name,
              exercises: payload,
            )
          : await RoutineService().createCustomRoutine(
              name: name,
              exercises: payload,
            );

      if (!mounted) return;
      if (result != null) {
        final routineId = _toInt(result['id']) ?? _editingRoutineId;
        _optimisticCreatedRoutine = {
          "id": routineId,
          "name": (result['name'] ?? name).toString(),
          "exercises": _exercises
              .map(
                (e) => {
                  "exerciseId": e.exerciseId,
                  "name": e.name,
                  "muscleGroup": e.muscleGroup,
                  "sets": e.sets,
                  "reps": e.reps,
                  "restSec": e.restSec,
                },
              )
              .toList(),
          "exerciseCount": _exercises.length,
          "muscleGroup": _exercises.isNotEmpty
              ? _exercises.first.muscleGroup
              : null,
        };
        _lastCreatedRoutineId = routineId;
        setState(() => _isCreateMode = false);
        _resetDraft();
        // ✅ _loadMyRoutines nettoie _optimisticCreatedRoutine si la routine est confirmée
        await _loadMyRoutines();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? "Routine modifiée ✅" : "Routine créée ✅"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteRoutine(dynamic routine) async {
    final id = _routineId(routine);
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text("Supprimer ?", style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Supprimer",
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await RoutineService().deleteCustomRoutine(id);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _myRoutines.removeWhere((r) => _routineId(r) == id);
        if (_lastCreatedRoutineId == id) _lastCreatedRoutineId = null;
        if (_optimisticCreatedRoutine != null &&
            _routineId(_optimisticCreatedRoutine) == id) {
          _optimisticCreatedRoutine = null;
        }
      });
      await _loadMyRoutines();
    }
  }

  Future<void> _duplicateRoutine(dynamic routine) async {
    final id = _routineId(routine);
    if (id == null) return;
    final created = await RoutineService().duplicateCustomRoutine(id);
    if (!mounted) return;
    if (created != null) {
      _lastCreatedRoutineId = _toInt(created['id']);
      await _loadMyRoutines();
    }
  }

  Future<void> _editRoutine(dynamic routine) async {
    final id = _routineId(routine);
    if (id == null) return;
    Map<String, dynamic> routineData = _mapify(routine);
    final hasUsableExercises =
        routineData['exercises'] is List &&
        (routineData['exercises'] as List).isNotEmpty;
    if (!hasUsableExercises) {
      final detailed = await RoutineService().getCustomRoutineDetails(id);
      if (detailed != null) routineData = detailed;
    }
    final draftExercises = _extractDraftExercisesFromApi(routineData);
    setState(() {
      _currentTabIndex = 2;
      _isCreateMode = true;
      _editingRoutineId = id;
      _titleCtrl.text = _routineTitle(routineData);
      _exercises
        ..clear()
        ..addAll(draftExercises);
    });
  }

  List<_DraftRoutineExercise> _extractDraftExercisesFromApi(
    Map<String, dynamic> routineData,
  ) {
    final rawExercises = routineData['exercises'];
    if (rawExercises is! List) return [];
    final list = <_DraftRoutineExercise>[];
    for (final raw in rawExercises) {
      final m = _mapify(raw);
      final nestedExercise = _mapify(m['exercise']);
      final exerciseId =
          _toInt(m['exerciseId']) ??
          _toInt(nestedExercise['id']) ??
          _toInt(m['id']);
      final name =
          (m['name'] ??
                  m['exerciseName'] ??
                  nestedExercise['name'] ??
                  'Exercice')
              .toString();
      final muscleGroup =
          (m['muscleGroup'] ??
                  nestedExercise['muscleGroup'] ??
                  m['category'] ??
                  'Autre')
              .toString();
      if (exerciseId == null) continue;
      list.add(
        _DraftRoutineExercise(
          exerciseId: exerciseId,
          name: name,
          muscleGroup: muscleGroup,
          sets: _intInRange(_toInt(m['sets']), min: 1, max: 999, fallback: 1),
          reps: _intInRange(_toInt(m['reps']), min: 1, max: 999, fallback: 10),
          restSec: _intInRange(
            _toInt(m['restSec']),
            min: 0,
            max: 9999,
            fallback: 60,
          ),
        ),
      );
    }
    return list;
  }

  // =========================
  // PARSING HELPERS
  // =========================

  Map<String, dynamic> _mapify(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  int _intInRange(
    int? value, {
    required int min,
    required int max,
    required int fallback,
  }) {
    final v = value ?? fallback;
    return v.clamp(min, max);
  }

  String _routineTitle(dynamic routine) =>
      (_mapify(routine)['name'] ?? _mapify(routine)['title'] ?? 'Routine')
          .toString();

  int? _routineId(dynamic routine) => _toInt(_mapify(routine)['id']);

  Future<void> _startRoutine(dynamic routine) async {
    final id = _routineId(routine);
    final name = _routineTitle(routine);
    if (id == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutPlayerScreen(routineId: id, routineName: name),
      ),
    );
  }

  // =========================
  // BUILD PRINCIPAL
  // =========================

  Widget _buildTabBody() {
    if (_currentTabIndex == 0) return _buildCatalogueTab();
    if (_currentTabIndex == 1) return _buildFavoritesTab();
    return _buildMyRoutinesHub();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCreateMode) {
      return Scaffold(
        backgroundColor: darkBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: TextButton(
            onPressed: _isSaving ? null : _cancelCreateMode,
            child: const Text(
              "Annuler",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          leadingWidth: 80,
          title: Text(
            _editingRoutineId == null
                ? "Création de votre routine"
                : "Modifier la routine",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          centerTitle: false,
          actions: [
            TextButton(
              onPressed: _isSaving ? null : _saveRoutine,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Enregistrer",
                      style: TextStyle(
                        color: clubOrange,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(child: _buildCreateForm()),
      );
    }

    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleAndTabs(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _buildTabBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleAndTabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: PageHeader(title: "Entraînement"),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _CustomTab(
                title: "Catalogue",
                isActive: _currentTabIndex == 0,
                onTap: () => setState(() => _currentTabIndex = 0),
              ),
              const SizedBox(width: 24),
              _CustomTab(
                title: "Favoris",
                isActive: _currentTabIndex == 1,
                onTap: () => setState(() => _currentTabIndex = 1),
              ),
              const SizedBox(width: 24),
              _CustomTab(
                title: "Mes Routines",
                isActive: _currentTabIndex == 2,
                onTap: () => setState(() => _currentTabIndex = 2),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.line),
      ],
    );
  }

  // =========================
  // ONGLET 1 : CATALOGUE
  // =========================

  int _countRoutinesForCategory(List<String> keys) {
    return _catalogRoutines.where((r) {
      final group =
          (_mapify(r)['muscleGroup'] ?? _mapify(r)['category'] ?? 'Autre')
              .toString()
              .toLowerCase();
      return keys.any((k) => group.contains(k));
    }).length;
  }

  Widget _buildCatalogueTab() {
    if (_isLoadingCatalog) {
      return const Center(
        child: CircularProgressIndicator(color: purpleButton),
      );
    }

    return ListView(
      key: const ValueKey('catalogue_tab'),
      padding: EdgeInsets.fromLTRB(
        16,
        24,
        0,
        170 + MediaQuery.of(context).padding.bottom,
      ),
      physics: const BouncingScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: PrimaryButton(
            label: "Crée tes entraînements",
            icon: Icons.fitness_center_rounded,
            onPressed: _enterCreateMode,
          ),
        ),
        const SizedBox(height: 32),
        _buildSectionTitle("PAR GROUPE MUSCULAIRE"),
        const SizedBox(height: 16),
        _buildCategoryRow(_muscleCategories),
        const SizedBox(height: 32),
        _buildSectionTitle("AUTRES"),
        const SizedBox(height: 16),
        _buildCategoryRow(_otherCategories),
      ],
    );
  }

  Widget _buildSectionTitle(String label) => Padding(
    padding: const EdgeInsets.only(right: 16.0),
    child: SectionHeader(title: label),
  );

  Widget _buildCategoryRow(List<Map<String, dynamic>> categories) {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final title = cat['title'] as String;
          final keys = (cat['keys'] as List).cast<String>();
          return _CategoryHorizontalCard(
            title: title,
            description: _getCategoryDescription(title),
            variationsCount: _countRoutinesForCategory(keys),
            averageTime: "45 min",
            imgUrl: _getImageForGroup(title),
            fallbackIcon: _getIconForCategory(title),
            isFavorite: _favoriteCategoryTitles.contains(title),
            onFavoriteTap: () => _toggleCategoryFavorite(title),
            onTap: () => _openCategoryConfig(title, keys),
          );
        },
      ),
    );
  }

  // =========================
  // ONGLET 2 : FAVORIS
  // =========================

  Widget _buildFavoritesTab() {
    final favCats = _favoriteCategories();
    return RefreshIndicator(
      color: clubOrange,
      backgroundColor: AppColors.surfaceAlt,
      onRefresh: _loadCatalogRoutines,
      child: ListView(
        key: const ValueKey('favorites_tab'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          170 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          const SectionHeader(title: "Favoris"),
          const SizedBox(height: 16),
          if (_isLoadingCatalog)
            const Center(child: CircularProgressIndicator(color: clubOrange))
          else if (favCats.isEmpty)
            Text(
              "Aucune catégorie en favoris pour l'instant.",
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: favCats.length,
                itemBuilder: (context, index) {
                  final cat = favCats[index];
                  final title = cat['title'] as String;
                  final keys = (cat['keys'] as List).cast<String>();
                  return _CategoryHorizontalCard(
                    title: title,
                    description: _getCategoryDescription(title),
                    variationsCount: _countRoutinesForCategory(keys),
                    averageTime: "45 min",
                    imgUrl: _getImageForGroup(title),
                    fallbackIcon: _getIconForCategory(title),
                    isFavorite: true,
                    onFavoriteTap: () => _toggleCategoryFavorite(title),
                    onTap: () => _openCategoryConfig(title, keys),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // =========================
  // ONGLET 3 : MES ROUTINES
  // =========================

  Widget _buildMyRoutinesHub() {
    final routines = _effectiveRoutines();
    if (_isLoadingRoutines) {
      return const Center(child: CircularProgressIndicator(color: clubOrange));
    }

    if (routines.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Crée ta première routine personnalisée pour commencer.",
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 24),
            _PrimaryActionButton(
              label: "CRÉER UNE ROUTINE",
              icon: Icons.add_rounded,
              onTap: _enterCreateMode,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: clubOrange,
      backgroundColor: AppColors.surfaceAlt,
      onRefresh: _loadMyRoutines,
      child: ListView(
        key: const ValueKey('my_routines_tab'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          170 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GhostButton(
                label: "Nouvelle routine",
                icon: Icons.add_rounded,
                onPressed: _enterCreateMode,
                color: AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...routines.map((r) => _buildRoutineCardItem(r)),
        ],
      ),
    );
  }

  Widget _buildRoutineCardItem(dynamic routine) {
    final title = _routineTitle(routine);
    final m = _mapify(routine);
    String categoryString = (m['muscleGroup'] ?? m['category'] ?? '')
        .toString();
    if (categoryString.isEmpty || categoryString == 'null')
      categoryString = title;

    int exCount = _toInt(m['exerciseCount']) ?? 0;
    int tSets = 0;
    int tDurationSec = 0;

    final rawExercises = m['exercises'];
    if (rawExercises is List) {
      if (exCount == 0) exCount = rawExercises.length;
      for (final raw in rawExercises) {
        final exMap = _mapify(raw);
        final sets = _toInt(exMap['sets']) ?? 1;
        final reps = _toInt(exMap['reps']) ?? _toInt(exMap['repsMax']) ?? 10;
        final rest =
            _toInt(exMap['restSec']) ?? _toInt(exMap['restSeconds']) ?? 60;
        tSets += sets;
        tDurationSec += sets * ((reps * 4) + rest);
      }
    }

    int dMin = tDurationSec > 0 ? (tDurationSec ~/ 60) : 45;
    if (tDurationSec > 0 && dMin == 0) dMin = 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _WorkoutCard(
        title: title,
        exerciseCount: exCount,
        totalSets: tSets,
        durationMin: dMin,
        imgUrl: _getImageForGroup(categoryString),
        categoryForIcon: categoryString,
        accent: clubOrange,
        isFullWidth: true,
        onTap: () => _startRoutine(routine),
        onEdit: () => _editRoutine(routine),
        onDuplicate: () => _duplicateRoutine(routine),
        onDelete: () => _deleteRoutine(routine),
      ),
    );
  }

  // =========================
  // FORMULAIRE DE CRÉATION
  // =========================

  Widget _buildCreateForm() {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        170 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        TextField(
          controller: _titleCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: _darkInput(
            hint: "Titre de la routine (ex: Push)",
            icon: Icons.title_rounded,
          ),
        ),
        const SizedBox(height: 16),
        if (_exercises.isNotEmpty) ...[
          const SectionHeader(title: "Exercices ajoutés"),
          const SizedBox(height: 14),
          ...List.generate(_exercises.length, (index) {
            final e = _exercises[index];
            return _ExerciseDraftCard(
              index: index,
              exercise: e,
              isFirst: index == 0,
              isLast: index == _exercises.length - 1,
              onRemove: () => _removeExercise(index),
              onMoveUp: () => _moveUp(index),
              onMoveDown: () => _moveDown(index),
              onAddSet: () => setState(() => e.sets += 1),
              onRemoveSet: () => setState(() {
                if (e.sets > 1) e.sets -= 1;
              }),
              onRepsMinus: () => setState(() {
                if (e.reps > 1) e.reps -= 1;
              }),
              onRepsPlus: () => setState(() => e.reps += 1),
              onRestMinus: () =>
                  setState(() => e.restSec = (e.restSec - 5).clamp(0, 999)),
              onRestPlus: () => setState(() => e.restSec += 5),
            );
          }),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.line),
            backgroundColor: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          onPressed: _openExercisePicker,
          icon: const Icon(Icons.add_circle_outline_rounded, color: clubOrange),
          label: const Text(
            "Ajouter un exercice",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

// =====================
// COMPOSANTS UI
// =====================

class _CustomTab extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _CustomTab({
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive ? clubOrange : Colors.white54,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: isActive ? 40 : 0,
            decoration: BoxDecoration(
              color: clubOrange,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================
// CARTE CATALOGUE (GLASSMORPHISM)
// =====================

class _CategoryHorizontalCard extends StatelessWidget {
  final String title;
  final String description;
  final int variationsCount;
  final String averageTime;
  final String imgUrl;
  final IconData fallbackIcon;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  const _CategoryHorizontalCard({
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

  // ✅ FIX BUG 1 — Widget fallback extrait pour éviter les paramètres dupliqués
  Widget _fallback() => Container(
    color: softBorder,
    child: Icon(fallbackIcon, size: 40, color: textSecondary.withOpacity(0.5)),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Image de fond
              imgUrl.startsWith('http')
                  ? Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => _fallback(),
                    )
                  : Image.asset(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => _fallback(),
                    ),

              // 2. Dégradé sombre
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

              // 3. Bouton Favori (Glassmorphism)
              if (onFavoriteTap != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: onFavoriteTap,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isFavorite
                                ? clubOrange.withOpacity(0.8)
                                : Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
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

              // 4. Textes en bas
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
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
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.layers_rounded,
                          color: clubOrange,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "$variationsCount variantes",
                          style: const TextStyle(
                            color: clubOrange,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.timer_outlined,
                          color: textSecondary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "~ 45 min",
                          style: TextStyle(
                            color: textSecondary,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }
}

// =====================
// CARTE ROUTINE (MES ROUTINES - GLASSMORPHISM)
// =====================

class _WorkoutCard extends StatelessWidget {
  final String title;
  final int exerciseCount;
  final int totalSets;
  final int durationMin;
  final String imgUrl;
  final String categoryForIcon;
  final Color accent;
  final VoidCallback? onTap;
  final bool isFullWidth;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  const _WorkoutCard({
    required this.title,
    required this.exerciseCount,
    required this.totalSets,
    required this.durationMin,
    required this.imgUrl,
    required this.categoryForIcon,
    required this.accent,
    this.onTap,
    this.isFullWidth = false,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
  });

  IconData _getFallbackIcon() {
    final c = categoryForIcon.toLowerCase();
    if (c.contains('pec') || c.contains('push')) return Icons.fitness_center;
    if (c.contains('dos') || c.contains('back') || c.contains('pull'))
      return Icons.accessibility_new_rounded;
    if (c.contains('jambe') || c.contains('leg') || c.contains('bas'))
      return Icons.directions_run_rounded;
    if (c.contains('bras') || c.contains('arm') || c.contains('biceps'))
      return Icons.sports_gymnastics_rounded;
    if (c.contains('triceps') || c.contains('avant'))
      return Icons.sports_gymnastics_rounded;
    if (c.contains('epaule') || c.contains('épaule'))
      return Icons.accessibility_rounded;
    if (c.contains('abdo')) return Icons.sports_martial_arts_rounded;
    if (c.contains('cardio') || c.contains('run'))
      return Icons.monitor_heart_rounded;
    if (c.contains('mobil')) return Icons.self_improvement_rounded;
    if (c.contains('perte') || c.contains('poids'))
      return Icons.monitor_weight_rounded;
    return Icons.fitness_center_rounded;
  }

  // ✅ FIX BUG 1 — Widget fallback extrait pour éviter les paramètres dupliqués
  Widget _fallback() => Container(
    color: softBorder,
    child: Icon(_getFallbackIcon(), color: textSecondary, size: 40),
  );

  @override
  Widget build(BuildContext context) {
    final bool hasMenuOptions =
        onEdit != null || onDuplicate != null || onDelete != null;

    return Container(
      height: 190,
      width: isFullWidth ? double.infinity : 260,
      margin: EdgeInsets.only(right: isFullWidth ? 0 : 12),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Image
              imgUrl.startsWith('http')
                  ? Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => _fallback(),
                    )
                  : Image.asset(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => _fallback(),
                    ),

              // 2. Dégradé
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

              // 3. Menu contextuel (Glass)
              if (hasMenuOptions)
                Positioned(
                  top: 12,
                  right: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: PopupMenuButton<int>(
                          padding: EdgeInsets.zero,
                          color: AppColors.surfaceAlt,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            side: const BorderSide(color: AppColors.line),
                          ),
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onSelected: (v) {
                            if (v == 1) onEdit?.call();
                            if (v == 2) onDuplicate?.call();
                            if (v == 3) onDelete?.call();
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 1,
                              child: Text(
                                "Modifier",
                                style: TextStyle(color: AppColors.textPrimary),
                              ),
                            ),
                            PopupMenuItem(
                              value: 2,
                              child: Text(
                                "Dupliquer",
                                style: TextStyle(color: AppColors.textPrimary),
                              ),
                            ),
                            PopupMenuItem(
                              value: 3,
                              child: Text(
                                "Supprimer",
                                style: TextStyle(color: AppColors.danger),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // 4. Contenu Textuel
              Positioned(
                left: 16,
                right: 16,
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
                    const SizedBox(height: 6),
                    Text(
                      "$exerciseCount exos • $totalSets séries • ~$durationMin min",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // 5. Bouton "LANCER" (Glass)
              Positioned(
                left: 16,
                bottom: 12,
                child: GlassSurface(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: accent, size: 16),
                      const SizedBox(width: 4),
                      const Text(
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
      ),
    );
  }
}

// =====================
// BOUTON PRINCIPAL
// =====================

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: clubOrange,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    ),
  );
}

// =====================
// CARTE EXERCICE DRAFT
// =====================

class _ExerciseDraftCard extends StatelessWidget {
  final int index;
  final _DraftRoutineExercise exercise;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onRemove;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onAddSet;
  final VoidCallback onRemoveSet;
  final VoidCallback onRepsMinus;
  final VoidCallback onRepsPlus;
  final VoidCallback onRestMinus;
  final VoidCallback onRestPlus;

  const _ExerciseDraftCard({
    required this.index,
    required this.exercise,
    required this.isFirst,
    required this.isLast,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onRepsMinus,
    required this.onRepsPlus,
    required this.onRestMinus,
    required this.onRestPlus,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                "${index + 1}",
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    exercise.muscleGroup,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // ✅ FIX BUG 2 — Boutons de réordonnancement ajoutés
            if (!isFirst)
              IconButton(
                onPressed: onMoveUp,
                icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
                color: Colors.white54,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            if (!isLast)
              IconButton(
                onPressed: onMoveDown,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                color: Colors.white54,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.danger,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MiniCounter(
                label: "Séries",
                value: exercise.sets,
                onMinus: onRemoveSet,
                onPlus: onAddSet,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniCounter(
                label: "Reps",
                value: exercise.reps,
                onMinus: onRepsMinus,
                onPlus: onRepsPlus,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniCounter(
                label: "Repos(s)",
                value: exercise.restSec,
                onMinus: onRestMinus,
                onPlus: onRestPlus,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// =====================
// MINI COUNTER
// =====================

class _MiniCounter extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _MiniCounter({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.20),
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.62),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: onMinus,
              child: const Icon(
                Icons.remove_circle_outline,
                size: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "$value",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onPlus,
              child: const Icon(
                Icons.add_circle_outline,
                size: 18,
                color: clubOrange,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// =====================
// INPUT DECORATION
// =====================

InputDecoration _darkInput({required String hint, required IconData icon}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.7)),
      filled: true,
      fillColor: AppColors.surface,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
    );

// =====================
// MODÈLES LÉGERS
// =====================

class _ExerciseLite {
  final int id;
  final String name;
  final String muscleGroup;

  const _ExerciseLite({
    required this.id,
    required this.name,
    required this.muscleGroup,
  });
}

class _DraftRoutineExercise {
  final int exerciseId;
  final String name;
  final String muscleGroup;
  int sets;
  int reps;
  int restSec;

  _DraftRoutineExercise({
    required this.exerciseId,
    required this.name,
    required this.muscleGroup,
    required this.sets,
    required this.reps,
    required this.restSec,
  });
}

// =====================
// ÉCRAN SÉLECTION EXERCICE
// =====================

class ExercisePickerScreen extends StatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  String _searchQuery = "";
  String _selectedCategory = "Tout";
  bool _isLoading = true;
  List<_ExerciseLite> _allExercises = [];

  @override
  void initState() {
    super.initState();
    _fetchExercises();
  }

  Future<void> _fetchExercises() async {
    try {
      final data = await RoutineService().getAllExercises();
      if (!mounted) return;
      final List<_ExerciseLite> loaded = [];
      for (final item in data) {
        if (item is Map) {
          final id = _toInt(item['id']) ?? 0;
          final name = (item['name'] ?? 'Exercice sans nom').toString();
          final muscleGroup =
              (item['muscleGroup'] ?? item['category'] ?? 'Autre').toString();
          loaded.add(
            _ExerciseLite(id: id, name: name, muscleGroup: muscleGroup),
          );
        }
      }
      setState(() {
        _allExercises = loaded;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erreur chargement exercices : $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur de chargement des exercices.")),
        );
      }
    }
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  List<String> get _categories {
    final set = <String>{"Tout"};
    for (final e in _allExercises) {
      if (e.muscleGroup.isNotEmpty) set.add(e.muscleGroup);
    }
    return set.toList();
  }

  List<_ExerciseLite> get _filteredExercises => _allExercises.where((e) {
    final matchesSearch = e.name.toLowerCase().contains(
      _searchQuery.toLowerCase(),
    );
    final matchesCat =
        _selectedCategory == "Tout" || e.muscleGroup == _selectedCategory;
    return matchesSearch && matchesCat;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredExercises;
    final categories = _categories;

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Ajouter un exercice",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: clubOrange))
          : Column(
              children: [
                // Barre de recherche
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: "Rechercher un exercice...",
                      hintStyle: TextStyle(
                        color: textSecondary.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: surfaceColor,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),

                // Filtres catégories
                if (categories.length > 1)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: categories.map((cat) {
                        final isSelected = cat == _selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? clubOrange : surfaceColor,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(
                                  color: isSelected
                                      ? clubOrange
                                      : AppColors.line,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 16),

                // Liste des exercices
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            "Aucun exercice trouvé.",
                            style: TextStyle(
                              color: textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            MediaQuery.of(context).padding.bottom + 16,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final exercise = filtered[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                onTap: () => Navigator.pop(context, exercise),
                                leading: const Icon(
                                  Icons.fitness_center_rounded,
                                  color: clubOrange,
                                  size: 22,
                                ),
                                title: Text(
                                  exercise.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  exercise.muscleGroup,
                                  style: const TextStyle(
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
