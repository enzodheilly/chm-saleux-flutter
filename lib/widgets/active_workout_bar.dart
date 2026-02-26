import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/workout_manager.dart';
import '../screens/workout_player_screen.dart';

const Color clubOrange = Color(0xFFF57809);
const Color surfaceColor = Color(0xFF1C1C22);

class ActiveWorkoutBar extends StatelessWidget {
  const ActiveWorkoutBar({super.key});

  String _formatTime(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return "$m:$sec";
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutManager>(
      builder: (context, manager, child) {
        if (!manager.isActive) return const SizedBox.shrink();

        return Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: surfaceColor.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // ✅ Texte (Nom + Chrono avec "En cours")
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (manager.routineName ?? "ENTRAÎNEMENT")
                                  .toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 12,
                                  color: clubOrange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "En cours • ${_formatTime(manager.seconds)}",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    // Empêche les chiffres de "danser" quand les secondes défilent
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // ✅ Bouton reprendre
                      const _ResumePill(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// =====================
/// UI COMPONENTS
/// =====================

class _ResumePill extends StatelessWidget {
  const _ResumePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: clubOrange,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: clubOrange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "REPRENDRE",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(width: 6),
          Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
        ],
      ),
    );
  }
}
