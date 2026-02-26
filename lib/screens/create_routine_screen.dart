import 'package:flutter/material.dart';
import '../services/routine_service.dart';
import 'workout_player_screen.dart';
import 'program_config_screen.dart';

/// ✅ Alias de compatibilité
class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CreateRoutineScreen();
  }
}

class CreateRoutineScreen extends StatefulWidget {
  const CreateRoutineScreen({super.key});

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  // =========================
  // COULEURS DU THÈME
  // =========================
  static const Color clubOrange = Color(0xFFF57809);
  static const Color darkBg = Color(0xFF0B0B0F);
  static const Color purpleButton = Color(0xFF5E35B1);
  static const Color surfaceColor = Color(0xFF222222);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A5B1);

  // =========================
  // NAVIGATION / ONGLETS
  // =========================
  int _currentTabIndex = 0; // 0 = Catalogue, 1 = Mes Routines
  bool _isCreateMode = false;

  // =========================
  // CATALOGUE DATA
  // =========================
  bool _isLoadingCatalog = true;
  List<dynamic> _catalogRoutines = [];
  final Set<int> _favoriteRoutineIds = <int>{};
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
  // LISTE DE TES CATÉGORIES FIXES
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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingRoutines = false);
    }
  }

  List<dynamic> _effectiveRoutines() {
    if (_optimisticCreatedRoutine == null) return _myRoutines;
    final optimisticId = _toInt(_optimisticCreatedRoutine!['id']);
    if (optimisticId == null) {
      return [_optimisticCreatedRoutine!, ..._myRoutines];
    }
    final exists = _myRoutines.any(
      (r) => _toInt(_mapify(r)['id']) == optimisticId,
    );
    if (exists) return _myRoutines;
    return [_optimisticCreatedRoutine!, ..._myRoutines];
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
  // NAVIGATION ACTIONS
  // =========================

  void _enterCreateMode() {
    setState(() {
      _currentTabIndex = 1;
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
    final payload = <Map<String, dynamic>>[];
    for (int i = 0; i < _exercises.length; i++) {
      final e = _exercises[i];
      payload.add({
        "exerciseId": e.exerciseId,
        "order": i + 1,
        "sets": e.sets,
        "reps": e.reps,
        "restSec": e.restSec,
      });
    }
    return payload;
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
        backgroundColor: const Color(0xFF16161D),
        title: const Text("Supprimer ?", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Supprimer",
              style: TextStyle(color: Colors.redAccent),
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
      _currentTabIndex = 1;
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
  // PARSING
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
    if (v < min) return min;
    if (v > max) return max;
    return v;
  }

  String _routineTitle(dynamic routine) =>
      (_mapify(routine)['name'] ?? _mapify(routine)['title'] ?? 'Routine')
          .toString();

  int? _routineId(dynamic routine) => _toInt(_mapify(routine)['id']);

  Future<void> _startRoutine(dynamic routine) async {
    final id = _routineId(routine);
    final name = _routineTitle(routine);
    if (id == null) return;
    if (!mounted) return;
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
                child: _currentTabIndex == 0
                    ? _buildCatalogueTab()
                    : _buildMyRoutinesHub(),
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
          child: Text(
            "ENTRAÎNEMENT",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
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
                title: "Mes Routines",
                isActive: _currentTabIndex == 1,
                onTap: () => setState(() => _currentTabIndex = 1),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: Colors.white.withOpacity(0.08)),
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
          child: ElevatedButton.icon(
            onPressed: _enterCreateMode,
            icon: const Icon(
              Icons.fitness_center_rounded,
              color: Colors.white,
              size: 20,
            ),
            label: const Text(
              "CRÉE TES ENTRAÎNEMENTS",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: purpleButton,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // --- SECTION : GROUPES MUSCULAIRES ---
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Text(
            "PAR GROUPE MUSCULAIRE",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _muscleCategories.length,
            itemBuilder: (context, index) {
              final cat = _muscleCategories[index];
              final title = cat['title'] as String;
              final keys = (cat['keys'] as List).cast<String>();

              final finalImgUrl = _getImageForGroup(title);
              final count = _countRoutinesForCategory(keys);
              final desc = _getCategoryDescription(title);

              return _CategoryHorizontalCard(
                title: title,
                description: desc,
                variationsCount: count,
                averageTime: "45 min",
                imgUrl: finalImgUrl,
                fallbackIcon: _getIconForCategory(title),
                isFavorite: _favoriteCategoryTitles.contains(title),
                onFavoriteTap: () => _toggleCategoryFavorite(title),
                onTap: () => _openCategoryConfig(title, keys),
              );
            },
          ),
        ),

        const SizedBox(height: 32),

        // --- SECTION : AUTRES ---
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Text(
            "AUTRES",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _otherCategories.length,
            itemBuilder: (context, index) {
              final cat = _otherCategories[index];
              final title = cat['title'] as String;
              final keys = (cat['keys'] as List).cast<String>();

              final finalImgUrl = _getImageForGroup(title);
              final count = _countRoutinesForCategory(keys);
              final desc = _getCategoryDescription(title);

              return _CategoryHorizontalCard(
                title: title,
                description: desc,
                variationsCount: count,
                averageTime: "45 min",
                imgUrl: finalImgUrl,
                fallbackIcon: _getIconForCategory(title),
                isFavorite: _favoriteCategoryTitles.contains(title),
                onFavoriteTap: () => _toggleCategoryFavorite(title),
                onTap: () => _openCategoryConfig(title, keys),
              );
            },
          ),
        ),
      ],
    );
  }

  // =========================
  // ONGLET 2 : MES ROUTINES (HUB)
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
      backgroundColor: const Color(0xFF1A1A22),
      onRefresh: _loadMyRoutines,
      child: ListView(
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
              TextButton.icon(
                onPressed: _enterCreateMode,
                icon: const Icon(
                  Icons.add_rounded,
                  color: clubOrange,
                  size: 18,
                ),
                label: const Text(
                  "Nouvelle routine",
                  style: TextStyle(
                    color: clubOrange,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          ...List.generate(routines.length, (index) {
            final routine = routines[index];
            final title = _routineTitle(routine);

            final m = _mapify(routine);
            String categoryString = (m['muscleGroup'] ?? m['category'] ?? '')
                .toString();

            if (categoryString.isEmpty || categoryString == 'null') {
              categoryString = title;
            }

            final categoryForIcon = categoryString;
            final String imgUrl = _getImageForGroup(categoryString);

            // =========================
            // CALCULS (Stats Routine)
            // =========================
            int exCount = _toInt(m['exerciseCount']) ?? 0;
            int tSets = 0;
            int tDurationSec = 0;

            final rawExercises = m['exercises'];
            if (rawExercises is List) {
              if (exCount == 0) exCount = rawExercises.length;

              for (final raw in rawExercises) {
                final exMap = _mapify(raw);
                final sets = _toInt(exMap['sets']) ?? 1;
                // Prends la donnée 'reps' (du draft) ou 'repsMax' (de l'API)
                final reps =
                    _toInt(exMap['reps']) ?? _toInt(exMap['repsMax']) ?? 10;
                // Idem pour le temps de repos
                final rest =
                    _toInt(exMap['restSec']) ??
                    _toInt(exMap['restSeconds']) ??
                    60;

                tSets += sets;
                // Calcul = Temps sous tension (4s par rep) + Temps de repos
                tDurationSec += sets * ((reps * 4) + rest);
              }
            }

            int dMin = tDurationSec > 0 ? (tDurationSec ~/ 60) : 45;
            if (tDurationSec > 0 && dMin == 0)
              dMin = 1; // Minimum 1 min si l'entraînement est très court

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _WorkoutCard(
                title: title,
                exerciseCount: exCount,
                totalSets: tSets,
                durationMin: dMin,
                imgUrl: imgUrl,
                categoryForIcon: categoryForIcon,
                accent: clubOrange,
                isFullWidth: true,
                onTap: () => _startRoutine(routine),
                onEdit: () => _editRoutine(routine),
                onDuplicate: () => _duplicateRoutine(routine),
                onDelete: () => _deleteRoutine(routine),
              ),
            );
          }),
        ],
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
          const Text(
            "EXERCICES AJOUTÉS",
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(_exercises.length, (index) {
            final e = _exercises[index];
            return _ExerciseDraftCard(
              index: index,
              exercise: e,
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
              onRestMinus: () => setState(() {
                if (e.restSec > 0) e.restSec = (e.restSec - 5).clamp(0, 999);
              }),
              onRestPlus: () => setState(() => e.restSec += 5),
            );
          }),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withOpacity(0.15)),
            backgroundColor: Colors.white.withOpacity(0.03),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _openExercisePicker,
          icon: const Icon(Icons.add_circle_outline_rounded, color: clubOrange),
          label: const Text(
            "AJOUTER UN EXERCICE",
            style: TextStyle(fontWeight: FontWeight.w900),
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
    const accent = Color(0xFFF57809);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive ? accent : Colors.white54,
            ),
          ),
          const SizedBox(height: 8),
          if (isActive)
            Container(
              height: 3,
              width: 40,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else
            const SizedBox(height: 3),
        ],
      ),
    );
  }
}

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

// =====================
// CARTE ROUTINE CLASSIQUE (MES ROUTINES)
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
    if (c.contains('dos') || c.contains('back') || c.contains('pull')) {
      return Icons.accessibility_new_rounded;
    }
    if (c.contains('jambe') || c.contains('leg') || c.contains('bas')) {
      return Icons.directions_run_rounded;
    }
    if (c.contains('bras') || c.contains('arm') || c.contains('biceps')) {
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
    return Icons.fitness_center_rounded;
  }

  @override
  Widget build(BuildContext context) {
    const Color surfaceColor = Color(0xFF222222);
    const Color textPrimary = Color(0xFFFFFFFF);
    const Color textSecondary = Color(0xFFA0A5B1);
    const Color softBorder = Color(0xFF333333);

    final bool hasMenuOptions =
        onEdit != null || onDuplicate != null || onDelete != null;

    return Container(
      width: isFullWidth ? double.infinity : 260,
      margin: EdgeInsets.only(right: isFullWidth ? 0 : 12),
      child: Material(
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
                    height: 120,
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
                                      _getFallbackIcon(),
                                      color: textSecondary,
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
                                      _getFallbackIcon(),
                                      color: textSecondary,
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
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Row(
                            children: [
                              // ❌ ICI ON A ENLEVÉ L'ICONE FAVORIS
                              if (hasMenuOptions) ...[
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: PopupMenuButton<int>(
                                    padding: EdgeInsets.zero,
                                    color: const Color(0xFF17171F),
                                    icon: const Icon(
                                      Icons.more_vert_rounded,
                                      color: Colors.white,
                                      size: 18,
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
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 2,
                                        child: Text(
                                          "Dupliquer",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 3,
                                        child: Text(
                                          "Supprimer",
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
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
                      const SizedBox(height: 8),

                      // ✅ NOUVELLE LIGNE AVEC STATISTIQUES
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.fitness_center_rounded,
                                size: 13,
                                color: textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "$exerciseCount exos",
                                style: const TextStyle(
                                  color: textSecondary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.layers_rounded,
                                size: 13,
                                color: textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "$totalSets séries",
                                style: const TextStyle(
                                  color: textSecondary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                size: 13,
                                color: textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "~ $durationMin min",
                                style: const TextStyle(
                                  color: textSecondary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow_rounded,
                                  color: accent,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Lancer",
                                  style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const Icon(
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
      ),
    );
  }
}

// =====================
// AUTRES COMPOSANTS DRAFT
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
        backgroundColor: const Color(0xFFF57809),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

class _ExerciseDraftCard extends StatelessWidget {
  final int index;
  final _DraftRoutineExercise exercise;
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
      color: Colors.white.withOpacity(0.03),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFF57809).withOpacity(0.15),
              child: Text(
                "${index + 1}",
                style: const TextStyle(
                  color: Colors.white,
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
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline_rounded),
              color: Colors.redAccent,
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
      borderRadius: BorderRadius.circular(10),
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
                color: Color(0xFFF57809),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

InputDecoration _darkInput({required String hint, required IconData icon}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      prefixIcon: Icon(icon, color: Colors.white70),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );

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

class ExercisePickerScreen extends StatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("Exercise Picker - Implémentation masquée ici")),
    );
  }
}
