import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:heart_thrive/core/api_endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/secure_storage_utils.dart';

class PatientProfileService {
  // Resolve base URL per platform (same as AuthService)
  static const String _envHost = String.fromEnvironment('API_HOST', defaultValue: 'localhost');
  static const int _envPort = int.fromEnvironment('API_PORT', defaultValue: 8080);

  // static String get _baseUrl {
  //   if (!kIsWeb) {
  //     try {
  //       if (Platform.isAndroid) {
  //         return 'http://10.0.2.2:$_envPort';
  //       }
  //     } catch (_) {}
  //   }
  //   return 'http://$_envHost:$_envPort';
  // }

  // static String get baseUrl {
  //   // Android emulator cannot reach host via localhost; use 10.0.2.2
  //   if (!kIsWeb) {
  //     try {
  //       if (Platform.isAndroid) {
  //         return 'http://10.0.2.2:$_envPort';
  //       }
  //     } catch (_) {}
  //   }
  //   return 'http://$_envHost:$_envPort';
  // }


  // static String baseUrl = "https://qaheartthrive.schoolyug.com";
  // Get authentication token from SharedPreferences
  static Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      // Secure Storage
      final secureStorage = SecureStorageUtils();

      String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
      token = secureStorageToken;
      return token;
    } catch (e) {
      debugPrint('Error getting auth token: $e');
      return null;
    }
  }

  // Fetch patient profile data
  static Future<Map<String, dynamic>?> fetchPatientProfile() async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception('No authentication token found. Please sign in again.');
    }

    final uri = Uri.parse(ApiEndpoints.patientProfilesURL);
    
    debugPrint('DEBUG: Fetch Profile URL = $uri');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(timeoutDuration);

    debugPrint('DEBUG: Fetch Profile Response status = ${response.statusCode}');
    debugPrint('DEBUG: Fetch Profile Response body = ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } catch (e) {
        debugPrint('Error parsing profile data: $e');
        return null;
      }
    }

    String message = 'Failed to fetch profile (${response.statusCode})';
    if (response.statusCode == 401) {
      message = 'Unauthorized. Please sign in again.';
    }
    try {
      final Map<String, dynamic> body = jsonDecode(response.body);
      if (body['message'] is String) {
        message = body['message'];
      } else if (body['error'] is String) {
        message = body['error'];
      }
    } catch (_) {}
    throw Exception(message);
  }

  // Update patient profile data
  static Future<void> updatePatientProfile(Map<String, dynamic> profileData) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception('No authentication token found. Please sign in again.');
    }

    final uri = Uri.parse(ApiEndpoints.patientProfilesURL);
    
    // Load stored raw user JSON to seed the payload
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> storedUser = {};
    try {
      final raw = prefs.getString('user_raw_json');
      if (raw != null && raw.isNotEmpty) {
        storedUser = jsonDecode(raw) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('DEBUG: Could not parse stored user json: $e');
    }

    // Build payload according to backend raw schema
    final String nowIso = DateTime.now().toUtc().toIso8601String();

    // Extract simple fields (with sensible defaults)
    final double weight = _toDouble(profileData['weight']) ?? _toDouble(storedUser['weight']) ?? 0.0;
    final String weightUnitType = (profileData['weightUnitType'] ?? storedUser['weightUnitType'] ?? 'KG').toString();
    final double height = _toDouble(profileData['height']) ?? _toDouble(storedUser['height']) ?? 0.0;
    final String heightUnitType = (profileData['heightUnitType'] ?? storedUser['heightUnitType'] ?? 'CM').toString();
    final bool active = profileData['active'] is bool ? profileData['active'] : (storedUser['active'] is bool ? storedUser['active'] : true);

    // Merge user fields: prefer edits > stored > defaults
    String? dobRaw = profileData['dateOfBirth']?.toString() ?? storedUser['dateOfBirth']?.toString();
    final String dobIso = _normalizeDateIso(dobRaw) ?? nowIso;

    // Gender mapping: accept provided id/name or fall back to stored structure
    dynamic providedGender = profileData['gender'] ?? storedUser['gender'];
    if (profileData['genderId'] != null) {
      providedGender = {'id': profileData['genderId']};
    } else if (providedGender is String) {
      final mappedId = _mapGenderStringToId(providedGender);
      providedGender = mappedId != null ? {'id': mappedId} : {'name': providedGender};
    } else if (providedGender is Map && providedGender['name'] is String && providedGender['id'] == null) {
      final mappedId = _mapGenderStringToId(providedGender['name']);
      if (mappedId != null) providedGender = {'id': mappedId};
    }

    Map<String, dynamic> user = {
      'id': profileData['userId'] ?? storedUser['id'] ?? 0,
      'uuid': profileData['userUuid'] ?? storedUser['uuid'] ?? '',
      'login': profileData['login'] ?? storedUser['login'] ?? storedUser['email'] ?? '',
      'passwordHash': profileData['passwordHash'] ?? storedUser['passwordHash'] ?? '',
      'firstName': profileData['firstName'] ?? storedUser['firstName'] ?? '',
      'lastName': profileData['lastName'] ?? storedUser['lastName'] ?? '',
      'email': profileData['email'] ?? storedUser['email'] ?? '',
      'active': profileData['userActive'] ?? storedUser['active'] ?? true,
      'imageUrl': profileData['imageUrl'] ?? storedUser['imageUrl'] ?? '',
      'langKey': profileData['langKey'] ?? storedUser['langKey'] ?? 'en',
      'createdBy': profileData['userCreatedBy'] ?? storedUser['createdBy'] ?? 'admin',
      'createdDate': profileData['userCreatedDate'] ?? storedUser['createdDate'] ?? nowIso,
      'lastModifiedBy': profileData['userLastModifiedBy'] ?? storedUser['lastModifiedBy'] ?? 'admin',
      'lastModifiedDate': profileData['userLastModifiedDate'] ?? storedUser['lastModifiedDate'] ?? nowIso,
      'roles': profileData['roles'] ?? storedUser['roles'] ?? <Map<String, dynamic>>[],
      'phoneNumber': profileData['phoneNumber'] ?? storedUser['phoneNumber'] ?? '',
      'dateOfBirth': dobIso,
      'agreedToTermsOfUse': profileData['agreedToTermsOfUse'] ?? storedUser['agreedToTermsOfUse'] ?? 1,
      if (providedGender != null) 'gender': providedGender,
    };

    final Map<String, dynamic> payload = {
      'id': profileData['id'] ?? storedUser['id'] ?? 0,
      'uuid': profileData['uuid'] ?? storedUser['uuid'] ?? '',
      'weight': weight,
      'weightUnitType': weightUnitType,
      'height': height,
      'heightUnitType': heightUnitType,
      'active': active,
      'createdBy': profileData['createdBy'] ?? storedUser['createdBy'] ?? 'admin',
      'createdDate': profileData['createdDate'] ?? storedUser['createdDate'] ?? nowIso,
      'lastModifiedBy': profileData['lastModifiedBy'] ?? storedUser['lastModifiedBy'] ?? 'admin',
      'lastModifiedDate': profileData['lastModifiedDate'] ?? storedUser['lastModifiedDate'] ?? nowIso,
      'user': user,
    };

    debugPrint('DEBUG: Update Profile URL = $uri');
    debugPrint('DEBUG: Update Profile payload = ${jsonEncode(payload)}');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    ).timeout(timeoutDuration);

    debugPrint('DEBUG: Update Profile Response status = ${response.statusCode}');
    debugPrint('DEBUG: Update Profile Response body = ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    String message = 'Failed to update profile (${response.statusCode})';
    if (response.statusCode == 401) {
      message = 'Unauthorized. Please sign in again.';
    }
    try {
      final Map<String, dynamic> body = jsonDecode(response.body);
      if (body['message'] is String) {
        message = body['message'];
      } else if (body['error'] is String) {
        message = body['error'];
      }
    } catch (_) {}
    throw Exception(message);
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) {
      return double.tryParse(v);
    }
    return null;
  }

  static int? _mapGenderStringToId(String? name) {
    if (name == null) return null;
    switch (name.toLowerCase()) {
      case 'male':
        return 1;
      case 'female':
        return 2;
      case 'other':
        return 3;
    }
    return null;
  }

  static String? _normalizeDateIso(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    // Already ISO
    try {
      final parsed = DateTime.parse(dateStr);
      return parsed.toUtc().toIso8601String();
    } catch (_) {}
    // Try dd-MM-yyyy
    final dmY = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(dateStr);
    if (dmY != null) {
      final day = int.parse(dmY.group(1)!);
      final month = int.parse(dmY.group(2)!);
      final year = int.parse(dmY.group(3)!);
      return DateTime.utc(year, month, day).toIso8601String();
    }
    // Try dd MMM yyyy (e.g., 01 Jan 2000)
    final parts = RegExp(r'^(\d{2})\s+([A-Za-z]{3})\s+(\d{4})$').firstMatch(dateStr);
    if (parts != null) {
      final day = int.parse(parts.group(1)!);
      final monStr = parts.group(2)!.toLowerCase();
      final year = int.parse(parts.group(3)!);
      const months = {
        'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
        'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
      };
      final month = months[monStr] ?? 1;
      return DateTime.utc(year, month, day).toIso8601String();
    }
    return null;
  }
}
