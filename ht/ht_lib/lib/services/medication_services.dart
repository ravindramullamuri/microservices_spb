import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:heart_thrive/core/api_endpoints.dart';
import 'package:heart_thrive/models/medication/medication_intake_response.dart';
import 'package:heart_thrive/models/medication/medication_intake_summary.dart';
import 'package:heart_thrive/models/medication/medication_schedule_list_model.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication/medication_dailly_stats.dart';
import '../models/medication/medication_model.dart';
import '../models/medication/medication_schedule_overview.dart';
import '../utils/component_utils.dart';
import '../utils/secure_storage_utils.dart';
import 'meal_services.dart';


class MedicationService {

  static Future<List<Map<String, dynamic>>> searchMedications({
    required String name,
    String brand = "",
    int page = 0,
    int size = 10,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);;
    token = secureStorageToken;

    if (token == null) throw Exception("User not authenticated");

    final url = Uri.parse(ApiEndpoints.medicationsList(page: page,size: size));

    final body = {
      "name": name,
      "brand": name
    };

    debugPrint("body search medicine ${json.encode(body)}");
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: json.encode(body),
    ).timeout(timeoutDuration);

    debugPrint("searching $url");
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      debugPrint("$data");
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception(
          "Failed to search medications. Status code: ${response.statusCode}, body: ${response.body}");
    }
  }

  static Future<bool> trackMedicationIntake({
    required String scheduleUuid,
    required String date,          // Format: "dd-MM-yyyy"
    required String timeSlot,      // "MORNING", "AFTERNOON", "EVENING"
    required bool isTaken,
    String timezone = "Asia/Kolkata",
  }) async {
    final TimezoneInfo  timezoneInfo= await FlutterTimezone.getLocalTimezone();
    debugPrint("Timezone Track @@@@ ${timezone}");
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    token = secureStorageToken;

    if (token == null) throw Exception("User not authenticated");

    final url = Uri.parse(ApiEndpoints.trackInTakeMedications);

    final body = {
      "scheduleUuid": scheduleUuid,
      "date": date,
      "timeSlot": timeSlot,
      "isTaken": isTaken,
      "timezone": timezoneInfo.identifier,
    };

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: json.encode(body),
    ).timeout(timeoutDuration);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        debugPrint("✅ ${data['message']}");
        return true;
      } else {
        debugPrint("⚠️ Failed to track intake: ${data['message']}");
        return false;
      }
    } else {
      debugPrint("❌ Failed to track intake. Status code: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");
      throw Exception("Failed to track medication intake");
    }
  }


  static Future<MedicationScheduleResponse> fetchMedications({
    bool? isMorning,
    bool? isAfternoon,
    bool? isEvening,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    token = secureStorageToken;
    final timezoneName = await getCurrentTimezoneName();
    final now = DateTime.now();
    final dateFormat = DateFormat('dd-MM-yyyy');
    final TimezoneInfo timezoneInfo = await FlutterTimezone.getLocalTimezone();
    // Base body
    final body = {
      "fromDate": dateFormat.format(now),
      "toDate": dateFormat.format(now),
      "timezone": timezoneInfo.identifier,
    };

    debugPrint('Pass data for Medication Schedule $body');
    // Add optional filters if provided
    if (isMorning != null) body['isMorning'] = isMorning.toString();
    if (isAfternoon != null) body['isAfternoon'] = isAfternoon.toString();
    if (isEvening != null) body['isEvening'] = isEvening.toString();

    final response = await http.post(
      Uri.parse(ApiEndpoints.medicationsScheduleList),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    ).timeout(timeoutDuration);
    debugPrint("response in MedicationScheduleService  ${response.body}");



    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      debugPrint("Medication Schedule $jsonData");
      if (jsonData['success'] == true && jsonData['data'] != null) {
        return MedicationScheduleResponse.fromJson(jsonData);
      } else {
        throw Exception('No data found');
      }
    } else {
      throw Exception('Failed to load medications (${response.statusCode})');
    }
  }




  static Future<List<MedicationModel>> fetchMyMedications() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    token = secureStorageToken;// ✅ assuming stored token

    debugPrint('Token in MedicationService $token');
    final response = await http.post(
      Uri.parse(ApiEndpoints.myMedicationsList),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(timeoutDuration);


    debugPrint("response in MedicationService ${ApiEndpoints.myMedicationsList} ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);

      if (jsonData['success'] == true && jsonData['data'] != null) {
        final List<dynamic> dataList = jsonData['data'];
        return dataList.map((e) => MedicationModel.fromJson(e)).toList();
      } else {
        throw Exception('No data found');
      }
    } else {
      throw Exception('Failed to load medications (${response.statusCode})');
    }
  }

  static Future<Map<String, dynamic>> getMedicationIntakeStats({
    required String fromDate,
    required String toDate,
    String timezone = "Asia/Kolkata",
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    token = secureStorageToken;

    if (token == null) {
      throw Exception("User not authenticated — token missing.");
    }

    final url = Uri.parse(ApiEndpoints.intakeStatsOfMedications);
    final TimezoneInfo  timezoneInfo= await FlutterTimezone.getLocalTimezone();
    final body = {
      "fromDate": fromDate,
      "toDate": toDate,
      "timezone": timezoneInfo.identifier,
    };

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: json.encode(body),
    ).timeout(timeoutDuration);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      debugPrint("Medication Stats: $data");
      return data;
    } else {
      throw Exception(
        "Failed to fetch intake stats. Status code: ${response.statusCode}, Response: ${response.body}",
      );
    }
  }

  static String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute:00";
  }

  static Future<bool> updateMedicationSchedule({
    required String scheduleUuid,
    required String startDate,
    required String endDate,
    required bool morning,
    required bool afternoon,
    required bool evening,
    Duration? morningTime,
    Duration? afternoonTime,
    Duration? eveningTime,
    required bool isAfterMeal,
    required String doseDescription,
    required String dosageFrequency,
    required List<String> daysOfWeek,
    bool? isUpdateToMyMedication
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    token = secureStorageToken;

    if (token == null) throw Exception('User not authenticated');

    final url = Uri.parse(ApiEndpoints.editScheduleMedications);

    final body = {
      "scheduleUuid": scheduleUuid,
      "startDate": startDate,
      "endDate": endDate,
      "morning": morning,
      "afternoon": afternoon,
      "evening": evening,
      "morningTime": morningTime != null ? formatDurationHMS(morningTime) : null,
      "afternoonTime": afternoonTime != null ? formatDurationHMS(afternoonTime) : null,
      "eveningTime": eveningTime != null ? formatDurationHMS(eveningTime) : null,
      "afterMeal": isAfterMeal,
      "doseDescription": doseDescription,
      "dosageFrequency": dosageFrequency,
      "daysOfWeek": daysOfWeek,
      "isUpdateToMyMedication" : isUpdateToMyMedication
    };


    debugPrint("Edit Request body ${json.encode(body)}");

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    ).timeout(timeoutDuration);

    if (response.statusCode == 200) {
      debugPrint("287 ${response.body}");
      final data = json.decode(response.body);
      if (data['success'] == true) {
        debugPrint("✅ Schedule updated successfully: ${data['message']}");
        return true;
      } else {
        debugPrint("⚠️ Update failed: ${data['message']}");
        return false;
      }
    } else {
      debugPrint("❌ Failed to update schedule. Status code: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");
      throw Exception('Failed to update medication schedule');
    }
  }

  static Future<MedicationModel?> fetchMedicationScheduleByUuid(String scheduleUuid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      // Secure Storage
      final secureStorage = SecureStorageUtils();

      String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
      token = secureStorageToken;

      if (token == null) {
        throw Exception("Authentication token not found");
      }

      final url = Uri.parse(ApiEndpoints.medicationScheduleByUUID(scheduleUuid));

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        debugPrint("DATA => ${response.body}");
        if (decoded['success'] == true && decoded['data'] != null) {
          MedicationModel medicationModel = MedicationModel.fromJson(decoded['data']);
          return medicationModel;
        } else {
          throw Exception(decoded['message'] ?? "Failed to fetch schedule details");
        }
      } else {
        throw Exception("Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching medication schedule: $e");
      return null;
    }
  }

  static Future<bool> deleteMedicationMenuItem({required String menuUuid}) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    token = secureStorageToken;

    if (token == null) {
      throw Exception("User not authenticated");
    }

    final url = Uri.parse(ApiEndpoints.removeMyMedication);

    final response = await http.post(
      url, // use POST since body is included
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "scheduleUuid": menuUuid,
      }),
    ).timeout(timeoutDuration);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        debugPrint("✅ ${data['message']}");
        return true;
      } else {
        debugPrint("⚠️ Failed to delete medication: ${data['message']}");
        return false;
      }
    } else {
      debugPrint("❌ Failed to delete medication. Status code: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");
      throw Exception("Failed to delete medication");
    }
  }

  static Future<bool> deleteMedicationSchedule(String scheduleUuid) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    token = secureStorageToken;

    if (token == null) {
      throw Exception('User not authenticated');
    }

    final url = Uri.parse(ApiEndpoints.deleteMedicationByScheduleUUID(scheduleUuid));

    debugPrint("🗑️ Deleting medication schedule: $scheduleUuid");

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(timeoutDuration);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['success'] == true) {
        debugPrint("✅ ${data['message']}");
        return true;
      } else {
        debugPrint("⚠️ Deletion failed: ${data['message']}");
        return false;
      }
    } else {
      debugPrint("❌ Failed to delete medication schedule. "
          "Status code: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");
      throw Exception('Failed to delete medication schedule');
    }
  }


  // Intake Summary Medication
  Future<IntakeMedicationSummary?> fetchIntakeCountSummary(String token,String fromDate,String toDate,String timeZone) async {
    final url = Uri.parse(
      ApiEndpoints.intakeMedicationCountSummary,
    );

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final timezoneName = await getCurrentTimezoneName();
    if (kDebugMode) debugPrint('🕒 Using timezone: $timezoneName');

    final body = jsonEncode({
      'fromDate': fromDate,
      'toDate': toDate,
      'timezone': timezoneName,
    });



    debugPrint("$url");
    debugPrint("intake-count-summary Body: $body");
    try {
      final response = await http.post(url, headers: headers, body: body).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Success1234: ${data}');
        return IntakeMedicationSummary.fromJson(data);

      } else {
        debugPrint('❌ Error1234 ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('⚠️ Exception: $e');
    }
  }

  // Medication Schedule Summary
  Future<MedicationInfoScheduleOverview?> fetchMedicationInfoSummary(String token,String fromDate,String toDate,String timeZone) async {
    final url = Uri.parse(
      ApiEndpoints.medicationScheduleOverviewInfo,
    );

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'fromDate': fromDate,
      'toDate': toDate,
      'timezone': timeZone,
    });

    try {
      final response = await http.post(url, headers: headers, body: body).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Success: ${data}');
        return MedicationInfoScheduleOverview.fromJson(data);

      } else {
        debugPrint('❌ Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('⚠️ Exception: $e');
    }
  }

  // Medication Intake stats
  Future<IntakeStatsResponse?> fetchMedicationStatsSummary(String token,String fromDate,String toDate,String timeZone) async {
    final url = Uri.parse(
      ApiEndpoints.medicationsIntakeStats,
    );

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'fromDate': fromDate,
      'toDate': toDate,
      'timezone': timeZone,
      "isSlotWiseBreakDownRequired": true
    });

    try {
      final response = await http.post(url, headers: headers, body: body).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Success: ${data}');
        return IntakeStatsResponse.fromJson(data);

      } else {
        debugPrint('❌ Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('⚠️ Exception: $e');
    }
  }

  // Medication dailly Intake stats
  Future<MedicationData?> fetchMedicationDailyIntakeStatsSummary(String token,String fromDate,String toDate,String timeZone) async {
    final url = Uri.parse(
      ApiEndpoints.medicationsDailyIntakeStats,
    );

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'fromDate': fromDate,
      'toDate': toDate,
      'timezone': timeZone,
    });

    try {
      final response = await http.post(url, headers: headers, body: body).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Success: ${data}');
        return MedicationData.fromJson(data);

      } else {
        debugPrint('❌ Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('⚠️ Exception: $e');
    }
  }


}
