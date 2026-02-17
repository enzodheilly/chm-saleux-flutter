import 'package:flutter/material.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  final Map<String, dynamic> stats;

  const WorkoutSummaryScreen({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    // Calcul rapide des minutes/secondes pour l'affichage
    final int totalSeconds = stats['duration_seconds'] ?? 0;
    final String duration =
        "${(totalSeconds ~/ 60)}min ${(totalSeconds % 60)}s";

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 50),
            // ✅ Icône de succès
            const Icon(
              Icons.check_circle_outline,
              color: Color(0xFFF57809),
              size: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              "SÉANCE TERMINÉE !",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 40),

            // ✅ Grille des Stats
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.symmetric(horizontal: 30),
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: [
                  _buildStatCard("DURÉE", duration, Icons.timer),
                  _buildStatCard(
                    "VOLUME",
                    "${stats['total_volume']} kg",
                    Icons.fitness_center,
                  ),
                  _buildStatCard("DATE", "Aujourd'hui", Icons.calendar_today),
                  _buildStatCard("POINTS", "+ 50 XP", Icons.stars),
                ],
              ),
            ),

            // ✅ Bouton Retour au Dashboard
            Padding(
              padding: const EdgeInsets.all(30),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF57809),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text(
                  "RETOUR À L'ACCUEIL",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFF57809), size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
