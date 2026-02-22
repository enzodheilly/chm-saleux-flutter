import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/workout_manager.dart';
import 'screens/splash_screen.dart'; // ✅ AJOUT : Importe ton fichier d'animation

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => WorkoutManager())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CHM Saleux',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // J'ai mis le fond noir par défaut pour éviter le flash blanc entre les pages
        scaffoldBackgroundColor: const Color(0xFF06060B),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),

      // ✅ CHANGEMENT : On démarre sur le Splash
      initialRoute: '/splash',

      routes: {
        // ✅ AJOUT : La route de l'animation
        '/splash': (context) => const SplashScreen(),

        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
