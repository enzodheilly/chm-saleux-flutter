import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/workout_manager.dart';
import '../screens/workout_player_screen.dart';

const Color clubOrange = Color(0xFFF57809);

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                // ✅ Breakpoint simple : en dessous de ~380px on passe en 2 lignes
                final isCompact = constraints.maxWidth < 380;

                return Container(
                  height: isCompact ? 86 : 64,
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: clubOrange,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: isCompact
                      ? _CompactLayout(
                          routineName: manager.routineName ?? "Entraînement",
                          timeText: _formatTime(manager.seconds),
                          setsText: "${manager.totalCompletedSets}",
                        )
                      : _WideLayout(
                          routineName: manager.routineName ?? "Entraînement",
                          timeText: _formatTime(manager.seconds),
                          setsText: "${manager.totalCompletedSets}",
                        ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// =====================
/// LAYOUTS
/// =====================

class _WideLayout extends StatelessWidget {
  final String routineName;
  final String timeText;
  final String setsText;

  const _WideLayout({
    required this.routineName,
    required this.timeText,
    required this.setsText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ✅ Icône gauche
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.16)),
          ),
          child: const Icon(
            Icons.equalizer_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),

        const SizedBox(width: 12),

        // ✅ Texte
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "SÉANCE EN COURS",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.78),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                routineName.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),

        // ✅ Pills
        _MiniPill(icon: Icons.timer_outlined, text: timeText, emphasize: true),
        const SizedBox(width: 8),
        _MiniPill(
          icon: Icons.done_all_rounded,
          text: setsText,
          suffix: "séries",
          emphasize: false,
        ),
        const SizedBox(width: 10),

        // ✅ Bouton reprendre
        const _ResumePill(),
      ],
    );
  }
}

class _CompactLayout extends StatelessWidget {
  final String routineName;
  final String timeText;
  final String setsText;

  const _CompactLayout({
    required this.routineName,
    required this.timeText,
    required this.setsText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // LIGNE 1 : Icône + Texte + Reprendre
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.16)),
              ),
              child: const Icon(
                Icons.equalizer_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SÉANCE EN COURS",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.78),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    routineName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const _ResumePill(),
          ],
        ),

        const SizedBox(height: 8),

        // LIGNE 2 : Pills
        Row(
          children: [
            Expanded(
              child: _MiniPill(
                icon: Icons.timer_outlined,
                text: timeText,
                emphasize: true,
                expand: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniPill(
                icon: Icons.done_all_rounded,
                text: setsText,
                suffix: "séries",
                emphasize: false,
                expand: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// =====================
/// UI COMPONENTS
/// =====================

class _MiniPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? suffix;
  final bool emphasize;
  final bool expand;

  const _MiniPill({
    required this.icon,
    required this.text,
    this.suffix,
    this.emphasize = false,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(emphasize ? 0.22 : 0.16),
            ),
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: expand
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.9), size: 14),
              const SizedBox(width: 6),
              Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: emphasize ? 12.5 : 12,
                  letterSpacing: emphasize ? 0.6 : 0.2,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    suffix!.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontWeight: FontWeight.w900,
                      fontSize: 9.5,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumePill extends StatelessWidget {
  const _ResumePill();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.16)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_arrow_rounded,
                color: Colors.white.withOpacity(0.92),
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                "REPRENDRE",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
