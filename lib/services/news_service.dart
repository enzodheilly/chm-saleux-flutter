import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class NewsService {
  static const String apiUrl = 'http://10.0.2.2:8000/api/actus';

  Future<List<dynamic>> getSiteNews() async {
    try {
      final token = await AuthService().getToken();

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      debugPrint('NEWS status: ${response.statusCode}');
      debugPrint('NEWS body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) return decoded;
      }

      return [];
    } catch (e) {
      debugPrint("Erreur fetch news: $e");
      return [];
    }
  }
}
