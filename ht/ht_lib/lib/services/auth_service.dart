import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpClient;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/core/api_endpoints.dart';
import 'package:heart_thrive/utils/secure_storage_utils.dart';
import 'package:heart_thrive/utils/token_scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/userdetails.dart';
import '../providers/token_provider.dart';
import '../providers/user/user_details_provider.dart';
import '../utils/fcm_util.dart';

class AuthService {
  // Resolve base URL per platform. Use --dart-define to override host/port.

  static const String _signupBearer = String.fromEnvironment(
    'SIGNUP_BEARER',
    defaultValue: '',
  );
  static final secureStorage = SecureStorageUtils();

  static Future<String> authenticate({
    required String username,
    required String password,
    bool rememberMe = false,
  }) async {
    final ioc = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    final client = IOClient(ioc);

    final uri = Uri.parse(ApiEndpoints.authenticateURL);
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'password': password,
            'rememberMe': rememberMe,
          }),
        )
        .timeout(timeoutDuration);
    debugPrint('🔹 Request URL: $uri');
    debugPrint(
      '🔹 Request body: ${jsonEncode({'username': username, 'password': password, 'rememberMe': rememberMe})}',
    );
    debugPrint('🔹 Response status: ${response.statusCode}');
    debugPrint('🔹 Response body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final Map<String, dynamic> body = jsonDecode(response.body);
        // Toke Schedule call
        await SecureStorageUtils().saveTokens(
          accessToken: body['id_token'],
          refreshToken: body['refresh_token'],
        );
        await TokenScheduler().schedule(); // recalculated using new refresh token
        // Support common token keys
        final String? token = (body['token'] ?? body['id_token']) as String?;
        if (token != null && token.isNotEmpty) {
          return token;
        }
      } catch (_) {}
      // Fallback: try Authorization header
      final authHeader =
          response.headers['authorization'] ??
          response.headers['Authorization'];
      if (authHeader != null &&
          authHeader.toLowerCase().startsWith('bearer ')) {
        return authHeader.substring(7);
      }
      throw Exception('Invalid server response: token missing');
    }

    String message = 'Sign in failed (${response.statusCode})';
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

  // Get User Details

  /// Fetch user details using token
  static Future<UserDetails?> fetchUserDetails({String? token}) async {
    final url = Uri.parse(ApiEndpoints.getUser);
    debugPrint("URL ${ApiEndpoints.getUser}");
    final accessToken = await SecureStorageUtils().read(StorageKeys.accessToken);
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse is Map && jsonResponse['data'] != null) {
          UserDetails? userDetails = UserDetails.fromJson(jsonResponse['data']);

          final secFcmToken = await secureStorage.read("fcm_token");
          final prefs = await SharedPreferences.getInstance();
          final sharedFcmToken = prefs.get("heartThriveFCMToken");
          if (sharedFcmToken == null) {
            FcmHelper.registerFcmDevice(userDetails);
          }
          return UserDetails.fromJson(jsonResponse['data']);
        } else if (jsonResponse is List && jsonResponse.isNotEmpty) {
          return UserDetails.fromJson(jsonResponse.first);
        } else {
          debugPrint("API returned no data: $jsonResponse");
          return null;
        }
      } else {
        debugPrint("Request failed with status: ${response.body}");
        SecureStorageUtils().delete("auth_token");
        return null;
      }
    } catch (e) {
      debugPrint("Exception in fetchUserDetails: $e");
      return null;
    }
  }

  static Future<String> fetchUserId(String token, String signedInEmail) async {
    debugPrint("Token!! $token");
    debugPrint("Email!! $signedInEmail");

    final ioc = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    final client = IOClient(ioc);

    final uri = Uri.parse(ApiEndpoints.getCurrentUser);

    try {
      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);

        for (var user in users) {
          debugPrint(
            "Checking user: login=${user['login']}, email=${user['email']}",
          );
        }
        debugPrint("Looking for: $signedInEmail");

        // Find the user with matching email
        final matchedUser = users.firstWhere(
          (user) =>
              (user['email']?.toLowerCase() == signedInEmail.toLowerCase()) ||
              (user['login']?.toLowerCase() == signedInEmail.toLowerCase()),
          orElse: () => null,
        );

        if (matchedUser == null) {
          throw Exception('User with email/login $signedInEmail not found');
        }

        // Extract userId
        final String userId = matchedUser['id'].toString();

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userId);

        debugPrint('User ID saved: $userId');
        return userId;
      } else {
        throw Exception(
          'Failed to fetch users: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching user: $e');
    } finally {
      client.close();
    }
  }

  static Future<void> createUser({
    required String name,
    required String email,
    required String password,
    String? countryCode,
    String? phone,
    String? genderName, // 'Male' | 'Female' | 'Other'
    String? dobDdMmYyyy, // 'dd/MM/yyyy'
    required String userType, // unused by API, kept for app context
    bool agreedToTerms = true,
    required int roleId,
    String? roleName, // 'Patient' | 'Doctor'
    double? weight,
    String? weightUnitType, // "kg" | "lbs"
    double? height,
    String? heightUnitType, // "cm" | "inch"
  }) async {
    final ioc = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    final client = IOClient(ioc);

    final uri = Uri.parse(ApiEndpoints.userCreateURL);

    debugPrint('DEBUG: Signup URL = $uri');

    // Split full name
    String firstName = name.trim();
    String lastName = '';
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.length > 1) {
      firstName = parts.first;
      lastName = parts.sublist(1).join(' ');
    }

    // Convert DOB into ISO
    String? dobIso;
    if (dobDdMmYyyy != null && dobDdMmYyyy.isNotEmpty) {
      try {
        final match = RegExp(
          r'^(\d{2})/(\d{2})/(\d{4})$',
        ).firstMatch(dobDdMmYyyy);
        if (match != null) {
          final month = int.parse(match.group(1)!);
          final day = int.parse(match.group(2)!);
          final year = int.parse(match.group(3)!);
          dobIso = DateTime.utc(year, month, day).toIso8601String();
        }
      } catch (_) {}
    }

    // Generate a UUID for the user if backend doesn’t auto-generate
    final userUuid = DateTime.now().millisecondsSinceEpoch.toString();

    // Build payload
    final Map<String, dynamic> payload = {
      'uuid': userUuid,
      'login': email.isNotEmpty ? email : (phone ?? ''),
      'passwordHash': password,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'active': true,
      'imageUrl': '',
      'langKey': 'en',
      'createdBy': 'system',
      'createdDate': DateTime.now().toUtc().toIso8601String(),
      'lastModifiedBy': 'system',
      'lastModifiedDate': DateTime.now().toUtc().toIso8601String(),
      'agreedToTermsOfUse': agreedToTerms ? 1 : 0,
      'roles': [
        {'id': roleId, 'name': roleName ?? 'Patient'},
      ],
    };

    // Optional fields
    if (phone != null && phone.isNotEmpty) {
      payload['phoneNumber'] = phone;
    }
    if (countryCode != null && countryCode.isNotEmpty) {
      // Always send ISO Alpha-2 code
      payload['countryCode'] = countryCode.toUpperCase();
    }
    if (dobIso != null) {
      payload['dateOfBirth'] = dobIso;
    }
    if (genderName != null && genderName.isNotEmpty) {
      payload['gender'] = {
        "name":
            genderName[0].toUpperCase() + genderName.substring(1).toLowerCase(),
      };
    }
    if (weight != null &&
        weightUnitType != null &&
        height != null &&
        heightUnitType != null) {
      payload['healthInfo'] = {
        "weight": weight,
        "weightUnitType": weightUnitType,
        "height": height,
        "heightUnitType": heightUnitType,
      };
    }

    debugPrint('DEBUG: Signup payload = ${jsonEncode(payload)}');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_signupBearer.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_signupBearer';
      debugPrint('DEBUG: Using SIGNUP_BEARER token');
    }

    final response = await http
        .post(uri, headers: headers, body: jsonEncode(payload))
        .timeout(timeoutDuration);

    debugPrint('DEBUG: Response status = ${response.statusCode}');
    debugPrint('DEBUG: Response body = ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    String message = 'Sign up failed (${response.statusCode})';
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

  // Regiter Notication FCM
  Future<int?> registerDevice({
    required String userId,
    required String fcmToken,
    required String platForm,
  }) async {
    final url = ApiEndpoints.registerFCM;

    final String? token = await secureStorage.read("auth_token");

    if (token == null) {
      debugPrint("❌ Auth token is null");
      return null;
    }

    final body = {
      "userUuid": userId,
      "deviceToken": fcmToken,
      "platform": platForm,
    };

    debugPrint("📤 Register Device Request: ${jsonEncode(body)}");

    try {
      final response = await http
          .post(
            Uri.parse(url),
            body: jsonEncode(body),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(timeoutDuration);

      debugPrint("✅ Register Device STATUS: ${response.statusCode}");
      debugPrint("📥 Register Device RESPONSE: ${response.body}");

      return response.statusCode;
    } on TimeoutException catch (e) {
      debugPrint("⏳ Timeout Error: $e");
      return null;
    } catch (e) {
      debugPrint("❌ Register Device ERROR: $e");
      return null;
    }
  }

  Future<void> removeDevice({
    String? userId,
    String? fcmToken,
    String? authToken,
  }) async {
    final url = ApiEndpoints.removeFCM;

    final body = {"userUuid": userId, "deviceToken": fcmToken};
    debugPrint("Remove Device Data ${jsonEncode(body)}");

    try {
      final response = await http
          .delete(
            Uri.parse(url),
            body: jsonEncode(body),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $authToken",
            },
          )
          .timeout(timeoutDuration);

      debugPrint("Remove Device STATUS: ${response.statusCode}");
      debugPrint("Remove Device RESPONSE: ${response.body}");
    } catch (e) {
      debugPrint("ERROR: $e");
    }
  }

  static Future<void> refreshToken() async {
    final container = ProviderContainer();
    final storage = SecureStorageUtils();
    final prefs = await SharedPreferences.getInstance();

    final refreshToken = await storage.read(StorageKeys.refreshToken);
    if (refreshToken == null) {
      throw Exception('No refresh token');
    }

    final uri = Uri.parse(
      ApiEndpoints.refreshTokenURL,
    ).replace(queryParameters: {'refreshToken': refreshToken});

    final response = await http.post(
      uri,
      headers: {'Authorization': 'Bearer $refreshToken'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);


      final newAccessToken = data['id_token'];
      final newRefreshToken = data['refresh_token'];

      // ✅ Always await writes
      await storage.write(StorageKeys.accessToken, newAccessToken);
      await storage.write(StorageKeys.refreshToken, newRefreshToken);

      debugPrint("✅ Token refreshed and saved");

      await prefs.setString(StorageKeys.accessToken, data['id_token']);
      debugPrint("Old Token ${container.read(tokenProvider)}");
      // 2️⃣ IMMEDIATE STATE UPDATE (THIS IS WHAT YOU WANT)
      final secureAccessToken =await storage.read(StorageKeys.accessToken);
      debugPrint("secureAccessToken @@@ $secureAccessToken");
      container.read(tokenProvider.notifier).setToken(secureAccessToken!);
      debugPrint("New Token ${container.read(tokenProvider)}");
     // await TokenScheduler().schedule(); // recalculated using new refresh token
    } else {
      throw Exception('Refresh token failed');
    }
  }


}

class AuthManager {
  const AuthManager(this.ref);

  final Ref ref;

  /// Call this after successful login
  Future<void> setToken(String token) async {
    //final storage = SecureStorageUtils();

    // 1. Save to secure storage

    //await storage.write("auth_token", token);

    // 2. Invalidate future so next read gets fresh value
    //ref.invalidate(tokenFutureProvider);

    // 3. Wait for the future to complete and update state
    //final newToken = await ref.read(tokenFutureProvider.future);

    // 4. Load user details
    ref.read(userDetailsDataProvider.notifier).loadUser(token: token);
  }

  /// Optional: Logout
  Future<void> logout() async {
    final storage = SecureStorageUtils();
    await storage.delete("auth_token");
    await SecureStorageUtils().delete("auth_token"); // Only deletes the token
    await SecureStorageUtils().delete("fcm_token");
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("heartThriveFCMToken");
    await prefs.remove("auth_token");
  }
}
