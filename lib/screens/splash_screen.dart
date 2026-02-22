import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // ✅ ajoute l'import

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _startApp();
  }

  Future<void> _startApp() async {
    // ✅ Laisse le temps à l'animation de se jouer
    await Future.delayed(const Duration(seconds: 3));

    // ✅ Vérifie la session (token + refresh si besoin)
    final isLoggedIn = await _authService.tryAutoLogin();

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, isLoggedIn ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06060B),
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeOutExpo,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(20 * (1 - value), 0),
                child: child,
              ),
            );
          },
          child: const Text(
            "CHM SALEUX",
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              fontFamily: 'Roboto',
            ),
          ),
        ),
      ),
    );
  }
}
