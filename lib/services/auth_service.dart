import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // ✅ Storage sécurisé (plus stable Android)
  final FlutterSecureStorage storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ✅ Google Sign-In v7 singleton
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;

    await _googleSignIn.initialize(
      serverClientId:
          '42146650997-cdmrq0lfuoe7r4dfbq4gmhmpg1uqc8qt.apps.googleusercontent.com',
    );

    _googleInitialized = true;
  }

  // =========================
  // TOKENS
  // =========================
  Future<String?> getToken() async => storage.read(key: 'jwt_token');
  Future<String?> getRefreshToken() async => storage.read(key: 'refresh_token');

  Future<void> _saveTokens(String token, String? refreshToken) async {
    await storage.write(key: 'jwt_token', value: token);

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await storage.write(key: 'refresh_token', value: refreshToken);
    }
  }

  // =========================
  // PROFIL / SESSION
  // =========================
  Future<Map<String, dynamic>?> getUserProfile() async {
    final token = await getToken();
    if (token == null) {
      debugPrint("🔐 getUserProfile: token NULL");
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("📍 GET /me -> ${response.statusCode}");
      debugPrint("📦 /me body -> ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (e) {
      debugPrint("⚠️ Erreur profil: $e");
    }

    return null;
  }

  /// ✅ Vérifie la session au lancement :
  /// 1) teste le token actuel
  /// 2) si expiré -> tente refresh
  /// 3) re-teste /me
  Future<bool> tryAutoLogin() async {
    final token = await getToken();

    if (token == null) {
      debugPrint("🔐 tryAutoLogin: aucun token trouvé");
      return false;
    }

    debugPrint("🔐 tryAutoLogin: token trouvé, test /me...");

    final profile = await getUserProfile();
    if (profile != null) {
      debugPrint("✅ Session valide (token actif)");
      return true;
    }

    debugPrint("⚠️ Token invalide/expiré, tentative refresh...");
    final refreshed = await refreshAccessToken();

    if (!refreshed) {
      debugPrint("❌ Refresh échoué -> session fermée");
      return false;
    }

    final profileAfterRefresh = await getUserProfile();
    if (profileAfterRefresh != null) {
      debugPrint("✅ Session restaurée via refresh");
      return true;
    }

    debugPrint("❌ Refresh OK mais /me KO");
    return false;
  }

  // =========================
  // LOGIN EMAIL/PASSWORD
  // =========================
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login_check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      debugPrint("📍 POST /login_check -> ${response.statusCode}");
      debugPrint("📦 login body -> ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final token = data['token'];
        final refreshToken = data['refresh_token'];

        if (token == null || token.toString().isEmpty) {
          debugPrint("❌ Login: token absent dans la réponse");
          return false;
        }

        await _saveTokens(token, refreshToken);
        debugPrint("✅ Login réussi, tokens sauvegardés");
        return true;
      }
    } catch (e) {
      debugPrint("⚠️ Erreur login: $e");
    }

    return false;
  }

  // =========================
  // GOOGLE SIGN-IN v7
  // =========================
  Future<bool> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();

      if (!_googleSignIn.supportsAuthenticate()) {
        debugPrint("⚠️ GoogleSignIn.authenticate() non supporté");
        return false;
      }

      final GoogleSignInAccount user = await _googleSignIn.authenticate();
      final String? idToken = user.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        debugPrint("⚠️ Google idToken null/empty");
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/login_google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': idToken}),
      );

      debugPrint("📍 POST /login_google -> ${response.statusCode}");
      debugPrint("📦 google body -> ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final token = data['token'];
        final refreshToken = data['refresh_token'];

        if (token == null || token.toString().isEmpty) {
          debugPrint("❌ Google login: token absent");
          return false;
        }

        await _saveTokens(token, refreshToken);
        debugPrint("✅ Google login réussi, tokens sauvegardés");
        return true;
      } else {
        debugPrint(
          "⚠️ login_google status=${response.statusCode}, body=${response.body}",
        );
      }
    } catch (e) {
      debugPrint("⚠️ Erreur Google Auth: $e");
    }

    return false;
  }

  // =========================
  // REFRESH TOKEN
  // =========================
  Future<bool> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      debugPrint("⚠️ refreshAccessToken: aucun refresh_token");
      return false;
    }

    try {
      // ⚠️ Vérifie que cet endpoint correspond bien à ton backend
      // Souvent: /api/token/refresh (LexikJWT + JWTRefreshTokenBundle)
      final response = await http.post(
        Uri.parse('$baseUrl/token/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      debugPrint("📍 POST /token/refresh -> ${response.statusCode}");
      debugPrint("📦 refresh body -> ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Certains backends renvoient "token", d'autres "access_token"
        final String? newAccessToken = (data['token'] ?? data['access_token'])
            ?.toString();

        // Certains backends renvoient un nouveau refresh_token, d'autres non
        final String? newRefreshToken = data['refresh_token']?.toString();

        if (newAccessToken == null || newAccessToken.isEmpty) {
          debugPrint("❌ refreshAccessToken: access token absent");
          return false;
        }

        await _saveTokens(newAccessToken, newRefreshToken);
        debugPrint("✅ Refresh réussi, nouveaux tokens sauvegardés");
        return true;
      }
    } catch (e) {
      debugPrint("⚠️ Erreur refresh token: $e");
    }

    return false;
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logout() async {
    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } catch (_) {
      // ignore erreurs Google SignOut
    }

    await storage.deleteAll();
    debugPrint("👋 Logout: tokens supprimés");
  }
}
