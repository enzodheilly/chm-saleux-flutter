import 'package:flutter/material.dart';
import '../services/routine_service.dart';
import 'workout_player_screen.dart';

/// ✅ Alias de compatibilité (si tu as encore des anciens appels TrainingScreen())
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
  static const Color clubOrange = Color(0xFFF57809);
  static const Color darkBg = Color(0xFF0B0B0F);

  // =========================
  // MODE HUB / CREATE
  // =========================
  bool _isCreateMode = false;

  // Hub data
  bool _isLoadingRoutines = true;
  List<dynamic> _myRoutines = [];

  // Pour afficher direct la routine créée/éditée même si la refresh API met un peu de temps
  Map<String, dynamic>? _optimisticCreatedRoutine;
  int? _lastCreatedRoutineId;

  // Draft create/edit form
  int? _editingRoutineId; // null = création, sinon édition
  final TextEditingController _titleCtrl = TextEditingController();
  bool _isSaving = false;
  final List<_DraftRoutineExercise> _exercises = [];

  @override
  void initState() {
    super.initState();
    _loadMyRoutines();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  // =========================
  // HUB
  // =========================

  Future<void> _loadMyRoutines() async {
    if (mounted) {
      setState(() => _isLoadingRoutines = true);
    }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur chargement routines : $e")),
      );
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

  void _enterCreateMode() {
    setState(() {
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

  // =========================
  // CREATE / EDIT FLOW
  // =========================

  Future<void> _openExercisePicker() async {
    final picked = await Navigator.push<_ExerciseLite?>(
      context,
      MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
    );

    if (picked == null) return;

    // éviter les doublons
    final exists = _exercises.any((e) => e.exerciseId == picked.id);
    if (exists) {
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

  void _removeExercise(int index) {
    setState(() => _exercises.removeAt(index));
  }

  void _moveUp(int index) {
    if (index <= 0) return;
    setState(() {
      final item = _exercises.removeAt(index);
      _exercises.insert(index - 1, item);
    });
  }

  void _moveDown(int index) {
    if (index >= _exercises.length - 1) return;
    setState(() {
      final item = _exercises.removeAt(index);
      _exercises.insert(index + 1, item);
    });
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
        final routineName = (result['name'] ?? name).toString();

        _optimisticCreatedRoutine = {
          "id": routineId,
          "name": routineName,
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
        };

        _lastCreatedRoutineId = routineId;

        final successMsg = isEdit ? "Routine modifiée ✅" : "Routine créée ✅";

        setState(() {
          _isCreateMode = false;
        });

        _resetDraft();
        await _loadMyRoutines();

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMsg)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingRoutineId != null
                  ? "Erreur lors de la modification."
                  : "Erreur lors de l'enregistrement.",
            ),
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

  // =========================
  // ROUTINE CARD MENU ACTIONS
  // =========================

  Future<void> _deleteRoutine(dynamic routine) async {
    final id = _routineId(routine);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible de supprimer (id manquant).")),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16161D),
          title: const Text(
            "Supprimer la routine ?",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            "Cette action est irréversible.",
            style: TextStyle(color: Colors.white.withOpacity(0.75)),
          ),
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
        );
      },
    );

    if (confirmed != true) return;

    final ok = await RoutineService().deleteCustomRoutine(id);

    if (!mounted) return;

    if (ok) {
      setState(() {
        _myRoutines.removeWhere((r) => _routineId(r) == id);

        if (_lastCreatedRoutineId == id) {
          _lastCreatedRoutineId = null;
        }

        if (_optimisticCreatedRoutine != null &&
            _routineId(_optimisticCreatedRoutine) == id) {
          _optimisticCreatedRoutine = null;
        }
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Routine supprimée ✅")));

      await _loadMyRoutines();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la suppression.")),
      );
    }
  }

  Future<void> _duplicateRoutine(dynamic routine) async {
    final id = _routineId(routine);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible de dupliquer (id manquant).")),
      );
      return;
    }

    final created = await RoutineService().duplicateCustomRoutine(id);

    if (!mounted) return;

    if (created != null) {
      final newId = _toInt(created['id']);

      _lastCreatedRoutineId = newId;
      _optimisticCreatedRoutine = {
        "id": newId,
        "name": (created['name'] ?? "${_routineTitle(routine)} (copie)")
            .toString(),
        "exerciseCount":
            _toInt(_mapify(routine)['exerciseCount']) ??
            ((_mapify(routine)['exercises'] is List)
                ? (_mapify(routine)['exercises'] as List).length
                : null),
        "exercises": _mapify(routine)['exercises'] ?? [],
      };

      await _loadMyRoutines();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Routine dupliquée ✅")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la duplication.")),
      );
    }
  }

  Future<void> _editRoutine(dynamic routine) async {
    final id = _routineId(routine);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible de modifier (id manquant).")),
      );
      return;
    }

    Map<String, dynamic> routineData = _mapify(routine);

    final hasUsableExercises =
        routineData['exercises'] is List &&
        (routineData['exercises'] as List).isNotEmpty &&
        _extractDraftExercisesFromApi(routineData).isNotEmpty;

    if (!hasUsableExercises) {
      final detailed = await RoutineService().getCustomRoutineDetails(id);
      if (detailed != null) {
        routineData = detailed;
      }
    }

    final draftExercises = _extractDraftExercisesFromApi(routineData);

    if (draftExercises.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible de charger les exercices de la routine."),
        ),
      );
      return;
    }

    setState(() {
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
          _toInt(m['id']); // fallback si backend incomplet

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
  // PARSE ROUTINE
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

  String _routineTitle(dynamic routine) {
    final m = _mapify(routine);
    return (m['name'] ?? m['title'] ?? 'Routine').toString();
  }

  String _routineSubtitle(dynamic routine) {
    final m = _mapify(routine);

    final exercises = m['exercises'];
    if (exercises is List && exercises.isNotEmpty) {
      final names = <String>[];

      for (final ex in exercises) {
        final em = _mapify(ex);

        // Formats possibles:
        // - {name: "..."}
        // - {exercise: {name: "..."}}
        // - {exerciseName: "..."}
        final nested = _mapify(em['exercise']);
        final n =
            (em['name'] ?? em['exerciseName'] ?? nested['name'] ?? em['label'])
                ?.toString();

        if (n != null && n.trim().isNotEmpty) {
          names.add(n.trim());
        }
      }

      if (names.isNotEmpty) {
        return names.take(4).join(', ') + (names.length > 4 ? ', ...' : '');
      }
    }

    final count = _toInt(m['exerciseCount']);
    if (count != null) {
      return "$count exercice${count > 1 ? 's' : ''}";
    }

    final group = m['muscleGroup']?.toString();
    if (group != null && group.isNotEmpty) return group;

    return "Routine personnalisée";
  }

  int? _routineId(dynamic routine) {
    final m = _mapify(routine);
    return _toInt(m['id']);
  }

  Future<void> _startRoutine(dynamic routine) async {
    final id = _routineId(routine);
    final name = _routineTitle(routine);

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible de lancer cette routine (id manquant)."),
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutPlayerScreen(routineId: id, routineName: name),
      ),
    );
  }

  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,

      // ✅ AppBar uniquement en mode création / édition
      appBar: _isCreateMode
          ? AppBar(
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
            )
          : null,

      body: SafeArea(
        top: !_isCreateMode, // si pas d'appBar -> garde safe top
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _isCreateMode ? _buildCreateForm() : _buildHub(),
        ),
      ),
    );
  }

  // =========================
  // HUB SCREEN
  // =========================

  Widget _buildHub() {
    final routines = _effectiveRoutines();

    if (_isLoadingRoutines) {
      return const Center(child: CircularProgressIndicator(color: clubOrange));
    }

    // ✅ Etat initial : page basic avec 1 seul bouton "Créer une routine"
    if (routines.isEmpty) {
      return Padding(
        key: const ValueKey('empty_hub'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ENTRAÎNEMENT",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                fontSize: 24,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 10),
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

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.white54),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Tu pourras ensuite ajouter des exercices, régler les séries / reps / repos puis lancer ta routine.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.62),
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ✅ Hub routines (après création)
    return RefreshIndicator(
      color: clubOrange,
      backgroundColor: const Color(0xFF1A1A22),
      onRefresh: _loadMyRoutines,
      child: ListView(
        key: const ValueKey('routines_hub'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          170 + MediaQuery.of(context).padding.bottom, // 👈 espace bottom nav
        ),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "MES ROUTINES",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontSize: 22,
                  ),
                ),
              ),
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
          const SizedBox(height: 8),

          if (_lastCreatedRoutineId != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: clubOrange.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: clubOrange.withOpacity(0.22)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: clubOrange,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Routine créée avec succès ✅",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.92),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          ...List.generate(routines.length, (index) {
            final routine = routines[index];
            final id = _routineId(routine);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SavedRoutineCard(
                title: _routineTitle(routine),
                subtitle: _routineSubtitle(routine),
                isHighlighted: id != null && id == _lastCreatedRoutineId,
                onStart: () => _startRoutine(routine),
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
  // CREATE / EDIT FORM
  // =========================

  Widget _buildCreateForm() {
    final isEdit = _editingRoutineId != null;

    return ListView(
      key: ValueKey(isEdit ? 'edit_form' : 'create_form'),
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        170 + MediaQuery.of(context).padding.bottom, // 👈 évite la bottom nav
      ),
      children: [
        Text(
          isEdit ? "MODIFICATION DE LA ROUTINE" : "CRÉATION DE VOTRE ROUTINE",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _titleCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: _darkInput(
            hint: "Titre de la routine (ex: Push hypertrophie)",
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
                if (e.restSec > 0) {
                  e.restSec = (e.restSec - 5).clamp(0, 999);
                }
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
          label: Text(
            isEdit ? "AJOUTER UN EXERCICE" : "AJOUTER UN EXERCICE",
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),

        const SizedBox(height: 12),

        if (_exercises.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Text(
              isEdit
                  ? "Ajoute des exercices à cette routine ou modifie les réglages."
                  : "Ajoute des exercices pour commencer ta routine.",
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class ExercisePickerScreen extends StatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  static const Color clubOrange = Color(0xFFF57809);
  static const Color darkBg = Color(0xFF0B0B0F);

  final TextEditingController _searchCtrl = TextEditingController();
  _ExerciseLite? _selected;

  late Future<List<dynamic>> _futureExercises;

  @override
  void initState() {
    super.initState();
    _futureExercises = RoutineService().getAllExercises();
    _searchCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  _ExerciseLite _mapExercise(dynamic e) {
    final map = (e as Map).cast<String, dynamic>();
    return _ExerciseLite(
      id: (map['id'] as num).toInt(),
      name: (map['name'] ?? 'Exercice').toString(),
      muscleGroup: (map['muscleGroup'] ?? map['category'] ?? 'Autre')
          .toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim().toLowerCase();

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annuler", style: TextStyle(color: Colors.white70)),
        ),
        leadingWidth: 80,
        title: const Text(
          "Ajouter un exercice",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: _selected == null
                ? null
                : () => Navigator.pop(context, _selected),
            child: Text(
              "Enregistrer",
              style: TextStyle(
                color: _selected == null ? Colors.white38 : clubOrange,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _darkInput(
                  hint: "Rechercher un exercice...",
                  icon: Icons.search_rounded,
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _futureExercises,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: clubOrange),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: Text(
                        "Impossible de charger les exercices",
                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                      ),
                    );
                  }

                  final all = snapshot.data!.map(_mapExercise).toList();
                  final filtered = all.where((e) {
                    if (query.isEmpty) return true;
                    return e.name.toLowerCase().contains(query) ||
                        e.muscleGroup.toLowerCase().contains(query);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        "Aucun exercice trouvé",
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final e = filtered[index];
                      final isSelected = _selected?.id == e.id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? clubOrange.withOpacity(0.45)
                                : Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: ListTile(
                          onTap: () => setState(() => _selected = e),
                          title: Text(
                            e.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            e.muscleGroup,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                            ),
                          ),
                          trailing: Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isSelected ? clubOrange : Colors.white38,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================
// HUB UI
// =====================

enum _RoutineCardMenuAction { edit, duplicate, delete }

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
  Widget build(BuildContext context) {
    const accent = Color(0xFFF57809);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _SavedRoutineCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onStart;
  final bool isHighlighted;

  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  const _SavedRoutineCard({
    required this.title,
    required this.subtitle,
    required this.onStart,
    this.isHighlighted = false,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF57809);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? accent.withOpacity(0.28)
              : Colors.white.withOpacity(0.06),
          width: isHighlighted ? 1.2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isHighlighted)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "NOUVELLE ROUTINE",
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<_RoutineCardMenuAction>(
                tooltip: "Options",
                onSelected: (action) {
                  switch (action) {
                    case _RoutineCardMenuAction.edit:
                      onEdit?.call();
                      break;
                    case _RoutineCardMenuAction.duplicate:
                      onDuplicate?.call();
                      break;
                    case _RoutineCardMenuAction.delete:
                      onDelete?.call();
                      break;
                  }
                },
                color: const Color(0xFF17171F),
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _RoutineCardMenuAction.edit,
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                        SizedBox(width: 10),
                        Text("Modifier", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _RoutineCardMenuAction.duplicate,
                    child: Row(
                      children: [
                        Icon(
                          Icons.copy_all_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Dupliquer",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _RoutineCardMenuAction.delete,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Supprimer",
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.62),
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "COMMENCER LA ROUTINE",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================
// CREATE UI widgets / models
// =====================

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
  Widget build(BuildContext context) {
    const accent = Color(0xFFF57809);

    return Container(
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
                backgroundColor: accent.withOpacity(0.15),
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
                    const SizedBox(height: 2),
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
                onPressed: onMoveUp,
                icon: const Icon(Icons.arrow_upward_rounded),
                color: Colors.white70,
              ),
              IconButton(
                onPressed: onMoveDown,
                icon: const Icon(Icons.arrow_downward_rounded),
                color: Colors.white70,
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
                child: OutlinedButton.icon(
                  onPressed: onAddSet,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.12)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: accent,
                  ),
                  label: const Text(
                    "Ajouter une série",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onRemoveSet,
                icon: const Icon(Icons.remove_circle_outline_rounded),
                color: Colors.white70,
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
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
}

InputDecoration _darkInput({required String hint, required IconData icon}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
    filled: true,
    fillColor: Colors.white.withOpacity(0.04),
    prefixIcon: Icon(icon, color: Colors.white70),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: Color(0xFFF57809)),
    ),
  );
}

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
