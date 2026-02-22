import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class RoutineService {
  // ✅ Android Emulator -> 10.0.2.2
  static const String baseUrl = "http://10.0.2.2:8000/api";

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  // --- 1. SÉANCE DU JOUR ---
  Future<Map<String, dynamic>?> getTodayRoutine() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/my-routine/today'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
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
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) return decoded;
      }
    } catch (e) {
      print("Erreur RoutineService (AllPrograms): $e");
    }
    return [];
  }

  // --- 3. DÉTAILS D'UNE ROUTINE (Player) ---
  Future<Map<String, dynamic>?> getRoutineDetails(int routineId) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/programs/$routineId'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
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
    final dateString = date.toIso8601String().split('T')[0];

    try {
      final response = await http.post(
        url,
        headers: _headers(token),
        body: jsonEncode({'routine_id': routineId, 'date': dateString}),
      );

      return response.statusCode == 201;
    } catch (e) {
      print("❌ Erreur réseau : $e");
      return false;
    }
  }

  // --- 5. PLANNING DE LA SEMAINE ---
  Future<List<dynamic>> getWeeklySchedule() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/schedule/my-week'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) return decoded;
      }
    } catch (e) {
      print("Erreur RoutineService (Weekly): $e");
    }
    return [];
  }

  // --- 6. SAUVEGARDER UNE SÉANCE TERMINÉE (DEBUG) ---
  Future<bool> saveWorkoutSession(Map<String, dynamic> sessionData) async {
    print("\n🔵 --- DÉBUT DEBUG SAUVEGARDE ---");

    final url = Uri.parse('$baseUrl/workouts/complete');
    print("📍 URL Ciblée : $url");

    final token = await AuthService().getToken();
    print("🔑 Token récupéré : ${token != null ? 'OUI (ok)' : 'NON (NULL)'}");

    if (token == null) {
      print("❌ ERREUR : Pas de token, l'utilisateur est déconnecté !");
      print("🔵 --- FIN DEBUG SAUVEGARDE ---\n");
      return false;
    }

    final bodyJson = jsonEncode(sessionData);
    print("📦 Données envoyées (JSON) : $bodyJson");

    try {
      print("🚀 Envoi de la requête en cours...");
      final response = await http.post(
        url,
        headers: _headers(token),
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
      print("👉 Vérifie : serveur ok ? IP ok ? internet ? ");
      print("🔵 --- FIN DEBUG SAUVEGARDE ---\n");
      return false;
    }
  }

  // --- 7. PROGRÈS : STATS KPI ---
  Future<Map<String, dynamic>?> getProgressStats({int rangeDays = 30}) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return null;

      final url = Uri.parse('$baseUrl/workouts/stats?range=$rangeDays');
      final response = await http.get(url, headers: _headers(token));

      print("📍 GET ProgressStats -> $url");
      print("📡 Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (e) {
      print("Erreur RoutineService (ProgressStats): $e");
    }
    return null;
  }

  // --- 8. PROGRÈS : LISTE SÉANCES (HISTORIQUE) ---
  Future<List<dynamic>> getWorkoutSessions({int rangeDays = 30}) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return [];

      final url = Uri.parse('$baseUrl/workouts/sessions?range=$rangeDays');
      final response = await http.get(url, headers: _headers(token));

      print("📍 GET WorkoutSessions -> $url");
      print("📡 Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) return decoded;
      }
    } catch (e) {
      print("Erreur RoutineService (WorkoutSessions): $e");
    }
    return [];
  }
}
