import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:heart_thrive/core/api_endpoints.dart';
import 'package:heart_thrive/models/symptoms/SymptomSummaryResponse.dart';
import 'package:heart_thrive/services/meal_services.dart';
import 'package:heart_thrive/utils/secure_storage_utils.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SymptomService {

  Future<SymptomSummaryResponse> fetchSymptoms({
    required String fromDate,
    required String toDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    // fallback to secure storage
    // Secure Storage
    final secureStorage = SecureStorageUtils();
    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    token = secureStorageToken;

    if (token == null) {
      throw Exception("Auth token not found");
    }

    final timezoneName = await getCurrentTimezoneName();
    debugPrint("Timezone: $timezoneName");
    // ✅ Use API endpoint constant
    final url = Uri.parse(
      ApiEndpoints.symptomReportSummary(
        fromDate: fromDate,
        toDate: toDate,
        timezone: timezoneName,
      ),
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ).timeout(timeoutDuration);

    if (response.statusCode == 200) {
      debugPrint("Symptoms Data  @@@ 47b ${response.body}");
      return SymptomSummaryResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        "Failed to fetch symptoms: ${response.statusCode} - ${response.body}",
      );
    }
  }
}
