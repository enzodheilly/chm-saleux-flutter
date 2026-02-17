import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  final storage = const FlutterSecureStorage();

  // ✅ v7: singleton instance (plus de GoogleSignIn(...))
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // ✅ assure initialize() appelé 1 seule fois
  bool _googleInitialized = false;
  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;

    await _googleSignIn.initialize(
      // Si tu envoies l'idToken à ton backend, serverClientId est OK
      serverClientId:
          '42146650997-cdmrq0lfuoe7r4dfbq4gmhmpg1uqc8qt.apps.googleusercontent.com',
    );

    _googleInitialized = true;
  }

  Future<String?> getToken() async => storage.read(key: 'jwt_token');

  Future<Map<String, dynamic>?> getUserProfile() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint("⚠️ Erreur profil: $e");
    }
    return null;
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login_check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveTokens(data['token'], data['refresh_token']);
        return true;
      }
    } catch (e) {
      debugPrint("⚠️ Erreur login: $e");
    }
    return false;
  }

  // ✅ GOOGLE SIGN-IN v7
  Future<bool> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();

      // v7: check plateforme
      if (!_googleSignIn.supportsAuthenticate()) {
        debugPrint(
          "⚠️ GoogleSignIn.authenticate() non supporté sur cette plateforme",
        );
        return false;
      }

      // v7: authenticate() remplace signIn()
      final GoogleSignInAccount user = await _googleSignIn.authenticate();

      // v7: authentication est un getter (PAS de await)
      final String? idToken = user.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        debugPrint("⚠️ idToken null/empty");
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/login_google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveTokens(data['token'], data['refresh_token']);
        return true;
      } else {
        debugPrint(
          "⚠️ login_google status: ${response.statusCode} body=${response.body}",
        );
      }
    } catch (e) {
      debugPrint("⚠️ Erreur Google Auth: $e");
    }
    return false;
  }

  Future<void> logout() async {
    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } catch (_) {}
    await storage.deleteAll();
  }

  Future<void> _saveTokens(String token, String? refreshToken) async {
    await storage.write(key: 'jwt_token', value: token);
    if (refreshToken != null) {
      await storage.write(key: 'refresh_token', value: refreshToken);
    }
  }
}
