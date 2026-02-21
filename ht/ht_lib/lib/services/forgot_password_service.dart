import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:heart_thrive/core/api_endpoints.dart';
import 'package:http/http.dart' as http;



class ForgotPasswordService {
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

  static Future<void> sendForgotPasswordRequest(String email) async {
    final uri = Uri.parse(ApiEndpoints.forgotPassword);
    
    debugPrint('DEBUG: Forgot Password URL = $uri');
    debugPrint('DEBUG: Email = $email');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
      }),
    ).timeout(timeoutDuration);

    debugPrint('DEBUG: Response status = ${response.statusCode}');
    debugPrint('DEBUG: Response body = ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    String message = 'Failed to send reset link (${response.statusCode})';
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
}
