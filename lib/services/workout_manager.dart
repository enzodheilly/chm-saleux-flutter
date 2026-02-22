import 'dart:async';
import 'package:flutter/material.dart';
import 'routine_service.dart';
import '../screens/workout_summary_screen.dart'; // ✅ Assure-toi que ce fichier existe

class WorkoutManager extends ChangeNotifier {
  bool _isActive = false;
  int _seconds = 0;
  Timer? _timer;

  int? routineId;
  String? routineName;
  List<dynamic> dynamicExercises = [];
  Map<String, String> workoutData = {};
  Map<String, bool> completedSets = {};

  bool get isActive => _isActive;
  int get seconds => _seconds;
  int get totalCompletedSets => completedSets.values.where((e) => e).length;

  void startOrResumeWorkout(int id, String name, List<dynamic> exercises) {
    if (_isActive && routineId == id) return;
    _isActive = true;
    routineId = id;
    routineName = name;
    if (dynamicExercises.isEmpty) {
      dynamicExercises = List.from(exercises);
    }
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds++;
      notifyListeners();
    });
  }

  Future<void> finishWorkout(BuildContext context) async {
    print("🧠 MANAGER : Déclenchement de la sauvegarde...");

    List<Map<String, dynamic>> exercisesPayload = [];

    for (int i = 0; i < dynamicExercises.length; i++) {
      var ex = dynamicExercises[i];
      List<Map<String, dynamic>> validSets = [];
      int totalSetsCount = ex['sets'] ?? 0;

      for (int j = 0; j < totalSetsCount; j++) {
        String key = "${i}_${j}_done";
        if (completedSets[key] == true) {
          String prefix = "${i}_$j";
          validSets.add({
            "exercise_id": ex['exercise']['id'],
            "weight":
                double.tryParse(workoutData["${prefix}_kg"] ?? "0") ?? 0.0,
            "reps": int.tryParse(workoutData["${prefix}_reps"] ?? "0") ?? 0,
          });
        }
      }

      if (validSets.isNotEmpty) {
        exercisesPayload.add({
          "exercise_id": ex['exercise']['id'],
          "sets": validSets,
        });
      }
    }

    final sessionData = {
      "routine_id": routineId,
      "duration_seconds": _seconds,
      "total_volume": calculateTotalVolume(),
      "total_sets": totalCompletedSets,
      "performed_at": DateTime.now().toIso8601String(),
      "routine_name": routineName,
      "exercises": exercisesPayload,
    };

    print("🚀 MANAGER : Envoi au RoutineService...");
    bool success = await RoutineService().saveWorkoutSession(sessionData);

    if (success) {
      print("✅ MANAGER : Sauvegarde réussie !");

      // ✅ Préparation des données pour le récapitulatif avant le reset
      final summaryStats = Map<String, dynamic>.from(sessionData);

      // Réinitialisation du manager
      stopWorkout();

      if (context.mounted) {
        // ✅ Redirection vers la page récapitulative
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutSummaryScreen(stats: summaryStats),
          ),
        );
      }
    } else {
      print("❌ MANAGER : Erreur lors de la sauvegarde.");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur serveur lors de l'enregistrement 😢"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void updateSetData(String key, String value) {
    workoutData[key] = value;
    notifyListeners();
  }

  void toggleSetDone(String key) {
    completedSets[key] = !(completedSets[key] ?? false);
    notifyListeners();
  }

  void addNewSet(int exIndex) {
    dynamicExercises[exIndex]['sets'] =
        (dynamicExercises[exIndex]['sets'] ?? 0) + 1;
    notifyListeners();
  }

  void removeSet(int exIndex, int setIndex) {
    dynamicExercises[exIndex]['sets']--;
    String prefix = "${exIndex}_$setIndex";
    workoutData.remove("${prefix}_kg");
    workoutData.remove("${prefix}_reps");
    completedSets.remove("${prefix}_done");
    notifyListeners();
  }

  double calculateTotalVolume() {
    double volume = 0;
    completedSets.forEach((key, isDone) {
      if (isDone) {
        String prefix = key.replaceFirst('_done', '');
        double kg = double.tryParse(workoutData['${prefix}_kg'] ?? '0') ?? 0;
        double reps =
            double.tryParse(workoutData['${prefix}_reps'] ?? '0') ?? 0;
        volume += (kg * reps);
      }
    });
    return volume;
  }

  void stopWorkout() {
    _timer?.cancel();
    _isActive = false;
    _seconds = 0;
    routineId = null;
    dynamicExercises = [];
    workoutData = {};
    completedSets = {};
    notifyListeners();
  }
}
