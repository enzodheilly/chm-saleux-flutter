import 'dart:async';
import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import '../theme/app_theme.dart';

/// Bandeau "en direct" affichant le nombre d'adhérents actuellement présents
/// dans la salle (basé sur les derniers scans QR d'entrée/sortie). Se
/// rafraîchit automatiquement pendant que le widget est affiché.
class LiveAttendanceBanner extends StatefulWidget {
  const LiveAttendanceBanner({super.key});

  @override
  State<LiveAttendanceBanner> createState() => _LiveAttendanceBannerState();
}

class _LiveAttendanceBannerState extends State<LiveAttendanceBanner>
    with SingleTickerProviderStateMixin {
  final AttendanceService _service = AttendanceService();
  Timer? _timer;

  late final AnimationController _pulseController;

  bool _loading = true;
  int? _count;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _load();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final count = await _service.getCurrentCount();
    if (!mounted) return;
    setState(() {
      _count = count;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Erreur réseau silencieuse : pas de bandeau cassé, on affiche juste rien.
    if (!_loading && _count == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          FadeTransition(
            opacity: Tween<double>(
              begin: 0.35,
              end: 1.0,
            ).animate(_pulseController),
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _loading
                ? Text(
                    'Chargement…',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: '$_count ',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        TextSpan(
                          text: (_count ?? 0) <= 1
                              ? 'adhérent en salle'
                              : 'adhérents en salle',
                        ),
                      ],
                    ),
                  ),
          ),
          const Text(
            'EN DIRECT',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
