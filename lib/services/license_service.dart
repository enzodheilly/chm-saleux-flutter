import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Résultat d'une tentative d'association de licence côté backend.
class LicenseLinkResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? license;

  const LicenseLinkResult({required this.success, this.message, this.license});
}

class LicenseService {
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const String _tokenStorageKey = 'jwt_token';

  final http.Client _client = http.Client();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Map<String, String> get _baseHeaders => const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Map<String, String>> _headers({bool withAuth = false}) async {
    final headers = Map<String, String>.from(_baseHeaders);
    if (withAuth) {
      final token = await _storage.read(key: _tokenStorageKey);
      if (token != null && token.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer ${token.trim()}';
      }
    }
    return headers;
  }

  Map<String, dynamic> _decodeObject(String body) {
    if (body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return <String, dynamic>{};
  }

  /// Récupère la licence associée au compte connecté
  Future<Map<String, dynamic>?> getMyLicense() async {
    try {
      final uri = Uri.parse('$baseUrl/api/licences/me');
      final response = await _client
          .get(uri, headers: await _headers(withAuth: true))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 || response.body.isEmpty) return null;

      final payload = _decodeObject(response.body);
      final rawLicense = payload['license'];

      if (rawLicense is Map<String, dynamic>) return rawLicense;
      if (rawLicense is Map) return Map<String, dynamic>.from(rawLicense);
      return null;
    } on TimeoutException {
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Recherche une licence par son numéro (lecture seule, ne l'associe pas)
  Future<Map<String, dynamic>?> getLicenseByNumber(String number) async {
    final licenseNumber = number.trim();
    if (licenseNumber.isEmpty) return null;

    try {
      final uri = Uri.parse(
        '$baseUrl/api/licences/${Uri.encodeComponent(licenseNumber)}',
      );
      final response = await _client
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = _decodeObject(response.body);
        return data.isEmpty ? null : data;
      }
      return null;
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Associe réellement (côté backend) la licence au compte connecté.
  /// Retourne (success, message, licence?).
  Future<LicenseLinkResult> linkLicense(String number) async {
    final licenseNumber = number.trim();
    if (licenseNumber.isEmpty) {
      return const LicenseLinkResult(
        success: false,
        message: 'Veuillez saisir un numéro de licence.',
      );
    }

    try {
      final uri = Uri.parse('$baseUrl/api/licences/link');
      final response = await _client
          .post(
            uri,
            headers: await _headers(withAuth: true),
            body: jsonEncode({'number': licenseNumber}),
          )
          .timeout(const Duration(seconds: 10));

      final payload = _decodeObject(response.body);
      final success = payload['success'] == true;
      final message = payload['message'] is String
          ? payload['message'] as String
          : null;

      if (!success || response.statusCode != 200) {
        return LicenseLinkResult(
          success: false,
          message: message ?? 'Impossible d\'associer cette licence.',
        );
      }

      final license = payload['license'];
      return LicenseLinkResult(
        success: true,
        license: license is Map ? Map<String, dynamic>.from(license) : null,
      );
    } on TimeoutException {
      return const LicenseLinkResult(
        success: false,
        message: 'Délai dépassé, réessayez.',
      );
    } catch (_) {
      return const LicenseLinkResult(
        success: false,
        message: 'Erreur de connexion au serveur.',
      );
    }
  }

  /// Dissocie réellement (côté backend) la licence du compte connecté.
  Future<bool> unlinkLicense() async {
    try {
      final uri = Uri.parse('$baseUrl/api/licences/unlink');
      final response = await _client
          .post(uri, headers: await _headers(withAuth: true))
          .timeout(const Duration(seconds: 10));

      if (response.body.isEmpty) return response.statusCode == 200;
      final payload = _decodeObject(response.body);
      return response.statusCode == 200 && payload['success'] == true;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}
