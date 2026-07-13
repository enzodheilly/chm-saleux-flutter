import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Dernier scan connu pour l'adhérent connecté.
class QrScanStatus {
  final String? scannedAt;
  final String? type;
  final String? firstName;

  const QrScanStatus({this.scannedAt, this.type, this.firstName});
}

class QrCodeService {
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const String _tokenStorageKey = 'jwt_token';

  final http.Client _client = http.Client();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Map<String, String> get _baseHeaders => const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Map<String, String>> _headers() async {
    final headers = Map<String, String>.from(_baseHeaders);
    final token = await _storage.read(key: _tokenStorageKey);
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
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

  /// Récupère le QR code (token) de l'adhérent connecté
  Future<String?> getMyQrCode() async {
    try {
      final uri = Uri.parse('$baseUrl/api/qrcode/me');
      final response = await _client
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 || response.body.isEmpty) return null;

      final payload = _decodeObject(response.body);
      final token = payload['token'];
      return token is String && token.isNotEmpty ? token : null;
    } on TimeoutException {
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Dernier scan connu pour l'adhérent connecté (utilisé pour détecter en direct
  /// qu'un scan vient d'avoir lieu pendant l'affichage plein écran du QR).
  Future<QrScanStatus?> getScanStatus() async {
    try {
      final uri = Uri.parse('$baseUrl/api/qrcode/me/status');
      final response = await _client
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200 || response.body.isEmpty) return null;

      final payload = _decodeObject(response.body);
      return QrScanStatus(
        scannedAt: payload['scannedAt'] is String
            ? payload['scannedAt'] as String
            : null,
        type: payload['type'] is String ? payload['type'] as String : null,
        firstName: payload['firstName'] is String
            ? payload['firstName'] as String
            : null,
      );
    } on TimeoutException {
      return null;
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
