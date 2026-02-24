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

  // --- 2.bis MES ROUTINES PERSO ---
  Future<List<dynamic>> getMyCustomRoutines() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/custom-routines/me'),
        headers: _headers(token),
      );

      print("📍 GET MyCustomRoutines -> ${response.request?.url}");
      print("📡 Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Cas 1: API renvoie directement une liste
        if (decoded is List) return decoded;

        // Cas 2: API renvoie un objet avec une clé data/items/routines
        if (decoded is Map<String, dynamic>) {
          if (decoded['routines'] is List) return decoded['routines'] as List;
          if (decoded['items'] is List) return decoded['items'] as List;
          if (decoded['data'] is List) return decoded['data'] as List;

          // Compat API Platform / Hydra
          if (decoded['hydra:member'] is List) {
            return decoded['hydra:member'] as List;
          }
        }
      } else {
        print("⚠️ GET MyCustomRoutines refusé: ${response.body}");
      }
    } catch (e) {
      print("Erreur RoutineService (MyCustomRoutines): $e");
    }
    return [];
  }

  // --- 2.ter TOUS LES EXERCICES (pour le créateur de routine) ---
  Future<List<dynamic>> getAllExercises() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/exercises'),
        headers: _headers(token),
      );

      print("📍 GET AllExercises -> ${response.request?.url}");
      print("📡 Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Cas 1: liste directe
        if (decoded is List) return decoded;

        // Cas 2: wrapper
        if (decoded is Map<String, dynamic>) {
          if (decoded['exercises'] is List) return decoded['exercises'] as List;
          if (decoded['items'] is List) return decoded['items'] as List;
          if (decoded['data'] is List) return decoded['data'] as List;

          // Compat API Platform / Hydra
          if (decoded['hydra:member'] is List) {
            return decoded['hydra:member'] as List;
          }
        }
      } else {
        print("⚠️ GET AllExercises refusé: ${response.body}");
      }
    } catch (e) {
      print("Erreur RoutineService (AllExercises): $e");
    }
    return [];
  }

  // --- 2.quater CRÉER UNE ROUTINE PERSO ---
  // ✅ Retourne un Map (id, name, raw) si succès, sinon null
  Future<Map<String, dynamic>?> createCustomRoutine({
    required String name,
    required List<Map<String, dynamic>> exercises,
  }) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return null;

      final url = Uri.parse('$baseUrl/custom-routines');
      final payload = {"name": name, "exercises": exercises};

      print("📍 POST CreateCustomRoutine -> $url");
      print("📦 Payload: ${jsonEncode(payload)}");

      final response = await http.post(
        url,
        headers: _headers(token),
        body: jsonEncode(payload),
      );

      print("📡 Status: ${response.statusCode}");
      print("📨 Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.trim().isNotEmpty) {
          final decoded = json.decode(response.body);

          if (decoded is Map<String, dynamic>) {
            return {
              "id": (decoded['id'] as num?)?.toInt(),
              "name": (decoded['name'] ?? name).toString(),
              "raw": decoded,
            };
          }

          return {"id": null, "name": name, "raw": decoded};
        }

        return {"id": null, "name": name};
      }

      return null;
    } catch (e) {
      print("Erreur RoutineService (CreateCustomRoutine): $e");
      return null;
    }
  }

  // --- 2.quinquies DÉTAIL D'UNE ROUTINE PERSO ---
  Future<Map<String, dynamic>?> getCustomRoutineDetails(int routineId) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/custom-routines/$routineId'),
        headers: _headers(token),
      );

      print("📍 GET CustomRoutineDetails -> ${response.request?.url}");
      print("📡 Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
      } else {
        print("⚠️ GET CustomRoutineDetails refusé: ${response.body}");
      }
    } catch (e) {
      print("Erreur RoutineService (CustomRoutineDetails): $e");
    }
    return null;
  }

  // --- 2.six UPDATE ROUTINE PERSO ---
  Future<Map<String, dynamic>?> updateCustomRoutine({
    required int routineId,
    required String name,
    required List<Map<String, dynamic>> exercises,
  }) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return null;

      final url = Uri.parse('$baseUrl/custom-routines/$routineId');
      final payload = {"name": name, "exercises": exercises};

      print("📍 PUT UpdateCustomRoutine -> $url");
      print("📦 Payload: ${jsonEncode(payload)}");

      final response = await http.put(
        url,
        headers: _headers(token),
        body: jsonEncode(payload),
      );

      print("📡 Status: ${response.statusCode}");
      print("📨 Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.trim().isNotEmpty) {
          final decoded = json.decode(response.body);

          if (decoded is Map<String, dynamic>) {
            return {
              "id": (decoded['id'] as num?)?.toInt() ?? routineId,
              "name": (decoded['name'] ?? name).toString(),
              "raw": decoded,
            };
          }

          return {"id": routineId, "name": name, "raw": decoded};
        }

        return {"id": routineId, "name": name};
      }

      return null;
    } catch (e) {
      print("Erreur RoutineService (UpdateCustomRoutine): $e");
      return null;
    }
  }

  // --- 2.sept DELETE ROUTINE PERSO ---
  Future<bool> deleteCustomRoutine(int routineId) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/custom-routines/$routineId'),
        headers: _headers(token),
      );

      print("📍 DELETE CustomRoutine -> ${response.request?.url}");
      print("📡 Status: ${response.statusCode}");
      print("📨 Body: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Erreur RoutineService (DeleteCustomRoutine): $e");
      return false;
    }
  }

  // --- 2.huit DUPLICATE ROUTINE PERSO ---
  Future<Map<String, dynamic>?> duplicateCustomRoutine(int routineId) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return null;

      final url = Uri.parse('$baseUrl/custom-routines/$routineId/duplicate');

      final response = await http.post(url, headers: _headers(token));

      print("📍 POST DuplicateCustomRoutine -> $url");
      print("📡 Status: ${response.statusCode}");
      print("📨 Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.trim().isNotEmpty) {
          final decoded = json.decode(response.body);

          if (decoded is Map<String, dynamic>) {
            return {
              "id": (decoded['id'] as num?)?.toInt(),
              "name": (decoded['name'] ?? 'Routine dupliquée').toString(),
              "raw": decoded,
            };
          }

          return {"id": null, "name": "Routine dupliquée", "raw": decoded};
        }

        return {"id": null, "name": "Routine dupliquée"};
      }

      return null;
    } catch (e) {
      print("Erreur RoutineService (DuplicateCustomRoutine): $e");
      return null;
    }
  }

  // --- 3. DÉTAILS D'UNE ROUTINE (Player) ---
  // ✅ Essaye /programs/{id} puis fallback /custom-routines/{id}
  Future<Map<String, dynamic>?> getRoutineDetails(int routineId) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return null;

      final headers = _headers(token);

      // 1) Routine programme
      final responseProgram = await http.get(
        Uri.parse('$baseUrl/programs/$routineId'),
        headers: headers,
      );

      print(
        "📍 GET RoutineDetails(program) -> ${responseProgram.request?.url}",
      );
      print("📡 Status(program): ${responseProgram.statusCode}");

      if (responseProgram.statusCode == 200) {
        final decoded = json.decode(responseProgram.body);
        if (decoded is Map<String, dynamic>) return decoded;
      }

      // 2) Fallback routine perso
      final responseCustom = await http.get(
        Uri.parse('$baseUrl/custom-routines/$routineId'),
        headers: headers,
      );

      print("📍 GET RoutineDetails(custom) -> ${responseCustom.request?.url}");
      print("📡 Status(custom): ${responseCustom.statusCode}");

      if (responseCustom.statusCode == 200) {
        final decoded = json.decode(responseCustom.body);
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
