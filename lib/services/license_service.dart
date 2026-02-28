import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class LicenseService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  // ⚠️ Vérifie que c'est bien la vraie clé de stockage de ton JWT
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

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>?> getMyLicense() async {
    try {
      final uri = Uri.parse('$baseUrl/api/licences/me');

      final response = await _client
          .get(uri, headers: await _headers(withAuth: true))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 || response.body.isEmpty) {
        return null;
      }

      final payload = _decodeObject(response.body);
      final rawLicense = payload['license'];

      if (rawLicense is Map<String, dynamic>) {
        return rawLicense;
      }

      if (rawLicense is Map) {
        return Map<String, dynamic>.from(rawLicense);
      }

      return null;
    } on TimeoutException {
      return null;
    } catch (e) {
      print('DEBUG getMyLicense EXCEPTION: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getLicenseByNumber(String number) async {
    final licenseNumber = number.trim();

    if (licenseNumber.isEmpty) {
      return null;
    }

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

  Future<Map<String, dynamic>> requestLicenseRecovery({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final cleanFirstName = firstName.trim();
    final cleanLastName = lastName.trim();
    final cleanEmail = email.trim();

    if (cleanFirstName.isEmpty || cleanLastName.isEmpty || cleanEmail.isEmpty) {
      return {
        'success': false,
        'message': 'Veuillez renseigner le prénom, le nom et l’email.',
      };
    }

    try {
      final uri = Uri.parse('$baseUrl/api/licences/recovery/request');

      final body = jsonEncode({
        'firstName': cleanFirstName,
        'lastName': cleanLastName,
        'email': cleanEmail,
      });

      final response = await _client
          .post(uri, headers: await _headers(), body: body)
          .timeout(const Duration(seconds: 10));

      final payload = _decodeObject(response.body);

      if (response.statusCode == 200) {
        return {
          'success': payload['success'] == true,
          'token': payload['token'],
          'message':
              payload['message'] ??
              'Une licence a été trouvée. Le code de vérification a été envoyé.',
        };
      }

      if (response.statusCode == 404) {
        return {
          'success': false,
          'message':
              payload['error'] ??
              'Aucune licence trouvée avec ces informations.',
        };
      }

      if (response.statusCode == 400) {
        return {
          'success': false,
          'message': payload['error'] ?? 'Informations invalides.',
        };
      }

      if (response.statusCode == 429) {
        return {
          'success': false,
          'message':
              payload['error'] ??
              'Trop de tentatives. Veuillez réessayer plus tard.',
        };
      }

      return {
        'success': false,
        'message':
            payload['error'] ?? 'Erreur serveur (${response.statusCode}).',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Le serveur met trop de temps à répondre.',
      };
    } catch (e) {
      print('DEBUG recovery/request EXCEPTION: $e');
      return {
        'success': false,
        'message': 'Impossible de contacter le serveur.',
      };
    }
  }

  Future<List<Map<String, dynamic>>> verifyLicenseRecovery({
    required String token,
    required String code,
  }) async {
    final cleanToken = token.trim();
    final cleanCode = code.trim();

    if (cleanToken.isEmpty || cleanCode.isEmpty) {
      return [];
    }

    try {
      final uri = Uri.parse('$baseUrl/api/licences/recovery/verify');

      final body = jsonEncode({'token': cleanToken, 'code': cleanCode});

      final response = await _client
          .post(uri, headers: await _headers(), body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return [];
      }

      final data = _decodeObject(response.body);
      final licenses = data['licenses'];

      if (licenses is! List) {
        return [];
      }

      return licenses.map<Map<String, dynamic>>((e) {
        if (e is Map<String, dynamic>) return e;
        if (e is Map) return Map<String, dynamic>.from(e);
        return <String, dynamic>{};
      }).toList();
    } on TimeoutException {
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> associateRecoveredLicense({
    required String token,
    required String licenseNumber,
  }) async {
    final cleanToken = token.trim();
    final cleanLicenseNumber = licenseNumber.trim();

    if (cleanToken.isEmpty || cleanLicenseNumber.isEmpty) {
      return {
        'success': false,
        'message': 'Token ou numéro de licence manquant.',
      };
    }

    try {
      final uri = Uri.parse('$baseUrl/api/licences/recovery/associate');

      final body = jsonEncode({
        'token': cleanToken,
        'licenseNumber': cleanLicenseNumber,
      });

      final response = await _client
          .post(uri, headers: await _headers(withAuth: true), body: body)
          .timeout(const Duration(seconds: 10));

      final payload = _decodeObject(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': payload['message'] ?? 'Licence associée avec succès.',
          'license': payload['license'],
        };
      }

      if (response.statusCode == 400) {
        return {
          'success': false,
          'message':
              payload['error'] ??
              'Demande invalide ou vérification incomplète.',
        };
      }

      if (response.statusCode == 401) {
        return {
          'success': false,
          'message':
              payload['error'] ??
              'Utilisateur non authentifié. Veuillez vous reconnecter.',
        };
      }

      if (response.statusCode == 403) {
        return {
          'success': false,
          'message':
              payload['error'] ??
              'Cette licence ne peut pas être associée à cette demande.',
        };
      }

      if (response.statusCode == 404) {
        return {
          'success': false,
          'message': payload['error'] ?? 'Licence ou demande introuvable.',
        };
      }

      if (response.statusCode == 409) {
        return {
          'success': false,
          'message':
              payload['error'] ??
              'Cette licence est déjà associée à un autre compte.',
        };
      }

      return {
        'success': false,
        'message':
            payload['error'] ?? 'Erreur serveur (${response.statusCode}).',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Le serveur met trop de temps à répondre.',
      };
    } catch (e) {
      print('DEBUG recovery/associate EXCEPTION: $e');
      return {
        'success': false,
        'message': 'Impossible de contacter le serveur.',
      };
    }
  }

  void dispose() {
    _client.close();
  }
}
