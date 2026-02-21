import 'dart:convert';
import 'package:heart_thrive/core/api_endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../constants/service_constants.dart';
import '../models/api_response.dart';
import '../models/home/user_model.dart';
import '../utils/secure_storage_utils.dart';

class UserService {
  //
  // Resolve base URL per platform (same as AuthService)
  static const String _envHost = String.fromEnvironment('API_HOST', defaultValue: 'localhost');
  static const int _envPort = int.fromEnvironment('API_PORT', defaultValue: 8080);

  // static String get _baseUrl {
  //   if (!kIsWeb) {
  //     try {
  //       if (Platform.isAndroid) {
  //         return 'http://localhost:8080/$_envPort';
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

  // Global user instance
  static User? _currentUser;
  static String _userFirstName = '';

  // Getter for current user
  static User? get currentUser => _currentUser;

  // Getter for user first name
  static String get userFirstName => _userFirstName.isNotEmpty ? _userFirstName : 'User';

  // Initialize user data (call this when app starts)
  static Future<void> initializeUser() async {
    try {
      // Get stored token and fetch current user
      final secureStorage = SecureStorageUtils();
      final prefs = await SharedPreferences.getInstance();
     final secureToken =  await secureStorage.read(StorageKeys.accessToken);
      String? token = prefs.getString('auth_token');
       token = secureToken;
      
      if (token != null && token.isNotEmpty) {
        User? user = await fetchCurrentUser(token);
        if (user != null) {
          _currentUser = user;
          _userFirstName = user.firstname??'';
          await saveUserName(user.firstname??'');
          debugPrint("_userFirstName*** $_userFirstName");
        }
      }
    } catch (e) {
      debugPrint('Error initializing user data: $e');
    }
  }

  // Fetch current authenticated user from API and store raw JSON
  static Future<User?> fetchCurrentUser(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.getCurrentUser),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        Map<String, dynamic>? userJson;
        if (data is List && data.isNotEmpty) {
          userJson = data.first as Map<String, dynamic>;
        } else if (data is Map<String, dynamic>) {
          userJson = data;
        }
        if (userJson != null) {
          // Persist full raw user JSON for later profile requests
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_raw_json', jsonEncode(userJson));

          final user = User.fromJson(userJson);
          return user;
        }
      } else {
        debugPrint('fetchCurrentUser failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching current user: $e');
    }
    return null;
  }

  // Save username to SharedPreferences
  static Future<void> saveUserName(String name) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', name);
    } catch (e) {
      debugPrint('Error saving username: $e');
    }
  }

  // Get username from SharedPreferences
  static Future<String?> getUserName() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('username');
    } catch (e) {
      debugPrint('Error getting username: $e');
      return null;
    }
  }

  // Get stored raw user JSON
  static Future<Map<String, dynamic>?> getStoredRawUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('user_raw_json');
      if (jsonStr == null) return null;
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error reading stored raw user: $e');
      return null;
    }
  }

  // Update user first name (for testing or manual updates)
  static void updateUserFirstName(String firstName) {
    _userFirstName = firstName;
  }

  // Clear user data (for logout)
  static void clearUserData() async {
    _currentUser = null;
    _userFirstName = '';
    // Also clear stored token and user JSON
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('username');
    await prefs.remove('user_raw_json');
  }

  // update user
  Future<ApiResponse> updateUser(int userId,var requestBody) async {
    debugPrint("requestBody $requestBody");
    var url = Uri.parse(ApiEndpoints.updateUser(userId));
    final storage = SecureStorageUtils();
    final String? token = await storage.read("auth_token");
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };


    final response = await http.patch(url, headers: headers, body: jsonEncode(requestBody)).timeout(timeoutDuration);

    if (response.statusCode == 200) {
      debugPrint('User updated successfully');
      return ApiResponse(
        status: response.statusCode,
        data: response.body,
        success: true,
        error: null,
        message:"User updated successfully",
      );
    } else {
      debugPrint('Failed to update user: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      return ApiResponse(
        status: response.statusCode,
        data: response.body,
        success: false,
        error: "Failed User updated successfully",
        message:"Failed updated successfully",
      );
    }
  }

  Future<ApiResponse> createPatientWeightHeightLog(var requestData) async {
    final url = Uri.parse(ApiEndpoints.createPatientWeightAndHeight);

    final storage = SecureStorageUtils();
    final String? token = await storage.read("auth_token");
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    final body = jsonEncode({
      "weight": 92,
      "weightUnitType": "kg",
      "height": 169.00,
      "heightUnitType": "cm",
    });

    try {
      debugPrint("requestData 198 ${requestData}");
      final response = await http.post(
        url,
        headers: headers,
        body: requestData,
      ).timeout(timeoutDuration);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Success: ${response.body}");
        return ApiResponse(
            status: response.statusCode,
            success: true,
            data: response.body,
            error: null,
            message: "Success"
        );
      } else {
        debugPrint("Failed with status: ${response.statusCode}");
        debugPrint("Response: ${response.body}");
        return ApiResponse(
            status: response.statusCode,
            success: false,
            data: response.body,
            error: null,
            message: "Failed"
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      return ApiResponse(
          status: 400,
          success: false,
          data: null,
          error: e.toString(),
          message: "Failed"
      );
    }
  }
}
