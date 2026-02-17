import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/workout_manager.dart';
import '../screens/workout_player_screen.dart'; // Vérifie bien ce chemin !

class ActiveWorkoutBar extends StatelessWidget {
  const ActiveWorkoutBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutManager>(
      builder: (context, manager, child) {
        // Si aucune séance n'est active, on n'affiche rien (taille 0)
        if (!manager.isActive) return const SizedBox.shrink();

        return Material(
          color: Colors
              .transparent, // Important pour éviter les fonds rouges par défaut
          child: GestureDetector(
            onTap: () {
              // On ouvre le Player qui se connectera automatiquement au manager
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkoutPlayerScreen(
                    routineId: manager.routineId!,
                    routineName: manager.routineName!,
                  ),
                ),
              );
            },
            child: Container(
              height: 60, // Hauteur fixe pour éviter les problèmes de layout
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF57809), // Club Orange
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.equalizer_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "SÉANCE EN COURS",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          manager.routineName ?? "Entraînement",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "REPRENDRE",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
