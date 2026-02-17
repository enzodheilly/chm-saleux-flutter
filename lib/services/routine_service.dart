import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class RoutineService {
  // ⚠️ Assure-toi que cette URL est bonne (10.0.2.2 pour Émulateur Android)
  final String baseUrl = "http://10.0.2.2:8000/api";

  // --- 1. SÉANCE DU JOUR ---
  Future<Map<String, dynamic>?> getTodayRoutine() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/my-routine/today'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Erreur RoutineService (Today): $e");
    }
    return null;
  }

  // --- 2. TOUS LES PROGRAMMES ---
  Future<List<dynamic>> getAllPrograms() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/programs'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Erreur RoutineService (AllPrograms): $e");
    }
    return [];
  }

  // ✅ 3. DÉTAILS D'UNE ROUTINE (Pour le Player)
  Future<Map<String, dynamic>?> getRoutineDetails(int routineId) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/programs/$routineId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Erreur RoutineService (Details): $e");
    }
    return null;
  }

  // --- 4. PLANIFIER UNE SÉANCE ---
  Future<bool> scheduleRoutine(int routineId, DateTime date) async {
    final token = await AuthService().getToken();
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/schedule/add');
    String dateString = date.toIso8601String().split('T')[0];

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'routine_id': routineId, 'date': dateString}),
      );

      return response.statusCode == 201;
    } catch (e) {
      print("❌ Erreur réseau : $e");
      return false;
    }
  }

  // --- 5. RÉCUPÉRER LE PLANNING DE LA SEMAINE ---
  Future<List<dynamic>> getWeeklySchedule() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/schedule/my-week'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Erreur RoutineService (Weekly): $e");
    }
    return [];
  }

  // ✅ 6. SAUVEGARDER UNE SÉANCE TERMINÉE (VERSION DEBUG)
  // J'ai blindé cette fonction de logs pour voir où ça coince
  Future<bool> saveWorkoutSession(Map<String, dynamic> sessionData) async {
    print("\n🔵 --- DÉBUT DEBUG SAUVEGARDE ---");

    // 1. Vérification de l'URL
    final url = Uri.parse('$baseUrl/workouts/complete');
    print("📍 URL Ciblée : $url");

    // 2. Vérification du Token
    final token = await AuthService().getToken();
    print("🔑 Token récupéré : ${token != null ? 'OUI (ok)' : 'NON (NULL)'}");

    if (token == null) {
      print("❌ ERREUR : Pas de token, l'utilisateur est déconnecté !");
      print("🔵 --- FIN DEBUG SAUVEGARDE ---\n");
      return false;
    }

    // 3. Vérification des données JSON
    final String bodyJson = jsonEncode(sessionData);
    print("📦 Données envoyées (JSON) : $bodyJson");

    try {
      print("🚀 Envoi de la requête en cours...");
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: bodyJson,
      );

      print("📡 RÉPONSE REÇUE !");
      print("H Code Statut : ${response.statusCode}");
      print("H Corps Réponse : ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ SUCCÈS : Sauvegarde réussie !");
        print("🔵 --- FIN DEBUG SAUVEGARDE ---\n");
        return true;
      } else {
        print("⚠️ ÉCHEC : Le serveur a refusé.");
        print("🔵 --- FIN DEBUG SAUVEGARDE ---\n");
        return false;
      }
    } catch (e) {
      print("❌ CRASH RÉSEAU/CODE : $e");
      print(
        "👉 Vérifie : Ton serveur tourne ? L'IP est bonne ? Internet est activé ?",
      );
      print("🔵 --- FIN DEBUG SAUVEGARDE ---\n");
      return false;
    }
  }
}
