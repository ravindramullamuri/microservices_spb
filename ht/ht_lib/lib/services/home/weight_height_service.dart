import 'dart:convert';
import 'package:heart_thrive/core/api_endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import '../../constants/service_constants.dart';
import '../../models/home/weight_height_log_model.dart';
import '../../utils/secure_storage_utils.dart';
import '../user_service.dart';

class WeightHeightService {

  // Fetch weight/height logs from API
  static Future<List<WeightHeightLog>> fetchWeightHeightLogs() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read("auth_token");
    token = token??secureStorageToken;

    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.patientWeightHeightLogs),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $secureStorageToken',
        },
      ).timeout(timeoutDuration);

      debugPrint("URL: ${ApiEndpoints.patientWeightHeightLogs}");
      debugPrint("BMI Card Response Status: ${response.statusCode}");
      debugPrint("BMI Card Response Body: ${response.body}");

      if (response.statusCode == 200) {
        debugPrint("inside 200 ");
        List<dynamic> data = jsonDecode(response.body);
        List<WeightHeightLog> logs =
        data.map((json) => WeightHeightLog.fromJson(json)).toList();

        // 🔥 debugPrint BMI Status for each log
        // for (var log in logs) {
        //   debugPrint(
        //       "Log ID: ${log.id}, BMI Status ID: ${log.bmiStatusId}, Label: ${log.bmiStatusLabel}");
        // }

        return logs;
      } else {
        debugPrint('Failed to fetch weight/height logs: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching weight/height logs: $e');
      return [];
    }
  }


  // Fetch BMI Status by ID
  static Future<String?> fetchBmiStatusLabel(int id) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read("auth_token");
    token = token??secureStorageToken;

    try {
      // debugPrint("id is ****  in fetchBmiStatusLabel   $id");
      final response = await http.get(
        Uri.parse(ApiEndpoints.bmiStatus(id)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $secureStorageToken',
        },
      ).timeout(timeoutDuration);

      debugPrint("BMI Status API Response: ${response.statusCode}");
      debugPrint("BMI Status API Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['label']; // ✅ Get BMI label
      } else {
        debugPrint("Failed to fetch BMI status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Error fetching BMI status: $e");
      return null;
    }
  }



  static String toInstantString(DateTime date) {
    // Always send UTC time in ISO8601 with a single 'Z'
    return date
        .toUtc()
        .toIso8601String()
        .split('.')
        .first + 'Z';
  }

  // Fetch weight/height logs within a date range [start, end]
  static Future<List<WeightHeightLog>> fetchWeightHeightLogsInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read("auth_token");
    token = token??secureStorageToken;

    try {
      String toDateOnly(DateTime d) =>
          '${d
              .toUtc()
              .year
              .toString()
              .padLeft(4, '0')}-${d
              .toUtc()
              .month
              .toString()
              .padLeft(2, '0')}-${d
              .toUtc()
              .day
              .toString()
              .padLeft(2, '0')}';

      final uri = Uri
          .parse(ApiEndpoints.patientWeightHeightLogsRange)
          .replace(
        queryParameters: {
          'fromDate': toDateOnly(start),
          'toDate': toDateOnly(end),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $secureStorageToken',
        },
      ).timeout(timeoutDuration);
      debugPrint("uri range  debugPrint $uri");

      if (response.statusCode == 200) {
        debugPrint("inside range api 200");
        debugPrint("Range API Response body: ${response.body}");
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => WeightHeightLog.fromJson(json)).toList();
      } else {
        debugPrint('Failed to fetch range logs: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching range logs: $e');
      return [];
    }
  }

  // Get the latest weight/height log
  static Future<WeightHeightLog?> getLatestWeightHeightLog() async {
    try {
      final logs = await fetchWeightHeightLogs();
      if (logs.isNotEmpty) {
        // Sort by recordedAt date and get the latest
        logs.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
        return logs.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting latest weight/height log: $e');
      return null;
    }
  }

  // Get weight change in the last 24 hours
  static Future<double> getWeightChange24h() async {
    try {
      final logs = await fetchWeightHeightLogs();
      if (logs.length < 2) return 0.0;

      // Sort by recordedAt date
      logs.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));

      // Find the most recent log and the log from 24 hours ago
      WeightHeightLog? currentLog;
      WeightHeightLog? previousLog;

      for (var log in logs) {
        if (log.recordedAt.isAfter(yesterday)) {
          if (currentLog == null ||
              log.recordedAt.isAfter(currentLog.recordedAt)) {
            currentLog = log;
          }
        } else {
          if (previousLog == null ||
              log.recordedAt.isAfter(previousLog.recordedAt)) {
            previousLog = log;
          }
        }
      }

      if (currentLog != null && previousLog != null) {
        return currentLog.weight - previousLog.weight;
      }

      return 0.0;
    } catch (e) {
      debugPrint('Error calculating 24h weight change: $e');
      return 0.0;
    }
  }

  // Get weight change in the last 48 hours
  static Future<double> getWeightChange48h() async {
    try {
      final logs = await fetchWeightHeightLogs();
      if (logs.length < 2) return 0.0;

      // Sort by recordedAt date
      logs.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

      final now = DateTime.now();
      final twoDaysAgo = now.subtract(const Duration(hours: 48));

      // Find the most recent log and the log from 48 hours ago
      WeightHeightLog? currentLog;
      WeightHeightLog? previousLog;

      for (var log in logs) {
        if (log.recordedAt.isAfter(twoDaysAgo)) {
          if (currentLog == null ||
              log.recordedAt.isAfter(currentLog.recordedAt)) {
            currentLog = log;
          }
        } else {
          if (previousLog == null ||
              log.recordedAt.isAfter(previousLog.recordedAt)) {
            previousLog = log;
          }
        }
      }

      if (currentLog != null && previousLog != null) {
        return currentLog.weight - previousLog.weight;
      }

      return 0.0;
    } catch (e) {
      debugPrint('Error calculating 48h weight change: $e');
      return 0.0;
    }
  }

  // Get BMI status color
  static Color getBmiStatusColor(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'yellow':
      case 'amber':
        return Colors.amber;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

// Create a new weight/height log (BMI entry)
  // Create a new weight/height log (BMI entry)
  static Future<bool> createWeightHeightLog({
    required double weight,
    required String weightUnitType,
    required double height,
    required String heightUnitType,
    required double bmiValue,
    DateTime? recordedAt,
    String? otherInfo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read("auth_token");
    token = token??secureStorageToken;

    // 🔥 Get user ID dynamically
    final user = UserService.currentUser;
    if (user == null) {
      debugPrint('❌ No logged-in user found. Did you call UserService.initializeUser()?');
      return false;
    }

    final body = {
      "weight": weight,
      "weightUnitType": weightUnitType,
      "height": height,
      "heightUnitType": heightUnitType,
      "bmiValue": bmiValue,
      "otherInfo": otherInfo ?? '',
      "recordedAt": toInstantString(recordedAt ?? DateTime.now()),
      "active": true,
      "createdBy": "mobile_app",
      "createdDate": toInstantString(DateTime.now()),
      "lastModifiedBy": "mobile_app",
      "lastModifiedDate": toInstantString(DateTime.now()),

      // 🔥 Now sending user instead of patient
      "patient": {
        "id": user.id, // Use logged-in user's ID here
      },
    };

    try {

      //'$baseUrl/api/patient-weight-height-logs/create'
      final response = await http.post(
        Uri.parse(ApiEndpoints.createPatientWeightHeight),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $secureStorageToken',
        },
        body: jsonEncode(body),
      ).timeout(timeoutDuration);

      debugPrint('API Request URL: ${ApiEndpoints.createPatientWeightHeight}');
      debugPrint('API Request Body: ${jsonEncode(body)}');
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ BMI log created successfully!");
        return true;
      }
      debugPrint('❌ Failed to create BMI log: ${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      debugPrint('🔥 Error creating BMI log: $e');
      return false;
    }
  }

}