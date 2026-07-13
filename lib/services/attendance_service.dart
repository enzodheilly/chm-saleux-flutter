import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AttendanceService {
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const String _tokenStorageKey = 'jwt_token';

  final http.Client _client = http.Client();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = await _storage.read(key: _tokenStorageKey);
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }
    return headers;
  }

  /// Nombre d'adhérents actuellement présents dans la salle (temps réel)
  Future<int?> getCurrentCount() async {
    try {
      final uri = Uri.parse('$baseUrl/api/attendance/current');
      final response = await _client
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200 || response.body.isEmpty) return null;

      final decoded = jsonDecode(response.body);
      final count = decoded is Map ? decoded['count'] : null;
      return count is int ? count : (count is num ? count.toInt() : null);
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
