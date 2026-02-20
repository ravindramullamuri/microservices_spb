import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/core/api_endpoints.dart';
import 'package:heart_thrive/models/home/heart_risk_meter_modal.dart';
import 'package:heart_thrive/models/userdetails.dart';
import 'package:heart_thrive/providers/user/user_details_provider.dart';
import 'package:heart_thrive/utils/secure_storage_utils.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/heart_risk_meter_comparison_model.dart';
import '../../models/risk_meter_home.dart';
import '../../providers/token_provider.dart';
import '../../utils/date_utils.dart';
import '../meal_services.dart';

final riskMetricServiceProvider = Provider<RiskMetricService>((ref) {
  return RiskMetricService(ref);
});
final riskMetricsFutureProvider = FutureProvider<RiskResponse>((ref) async {
  debugPrint("-----Inside riskMetricsFutureProvider-----");

  // watch the async state
  final service = ref.read(riskMetricServiceProvider);
  return service.fetchRiskMetricsHeroSection();
});


class RiskMetricService {
  final Ref _ref;

  RiskMetricService(this._ref);

  /// Fetches current risk metrics (dashboard)
  Future<RiskResponse> fetchRiskMetricsOld() async {
    debugPrint("------Inside fetchRiskMetrics-------");

    try {
      final userState = _ref.watch(userDetailsDataProvider);
      final UserDetails? userDetails = userState.value; // SAFE ACCESS

      if (userDetails == null) {
        debugPrint("UserDetails not loaded yet. Returning empty RiskResponse.");
        return RiskResponse();
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final secureStorageDetails = SecureStorageUtils();
      final token = _ref.watch(tokenProvider);
      final accessToken = secureStorageDetails.read(StorageKeys.accessToken);

      debugPrint("userDetails @@@ $userId  userDetails ${userDetails.id}");

      if (userId == null) {
        throw Exception("User ID not found in SharedPreferences");
      }
      if (token == null) {
        throw Exception("Access token not found");
      }

      final timezoneName = await getCurrentTimezoneName();

      final url = Uri.parse(
        ApiEndpoints.riskMetricDashboard(userId, timezoneName),
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RiskResponse.fromJson(data);
      } else {
        throw Exception("Failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error in fetchRiskMetrics: $e");
      return RiskResponse();
    }
  }

  Future<RiskResponse> fetchRiskMetrics() async {
    debugPrint("------Inside fetchRiskMetrics-------");

    try {

      //final token = _ref.watch(tokenProvider);
      final token = await SecureStorageUtils().read(StorageKeys.accessToken);
      final timezoneName = await getCurrentTimezoneName();
     // DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final fromDate = DateFormatUtil.startDateFormat(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
      final toDate = DateFormatUtil.startDateFormat(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
    HeartRiskSummaryResponse heartRiskSummaryResponse = await fetchHeartRiskMeterHistory(
        fromDate: fromDate,
        toDate: toDate,
        timezone: timezoneName
    );
      RiskResponse response =  RiskResponse(
        riskSymptom: heartRiskSummaryResponse.riskSymptom
      );

      return response;



    } catch (e) {
      debugPrint("Error in fetchRiskMetrics: $e");
      return RiskResponse();
    }
  }


  Future<RiskResponse> fetchRiskMetricsHeroSection() async {
    try {
      final today = DateTime.now();
      final formattedDate = DateFormatUtil.startDateFormat(
        DateTime(today.year, today.month, today.day),
      );

      //final token = _ref.watch(tokenProvider);
      final token = await SecureStorageUtils().read(StorageKeys.accessToken);
      if (token == null) throw Exception('Auth token missing');

      final timezoneName = await getCurrentTimezoneName();

      final requestBody = {
        'fromDate': formattedDate,
        'toDate': formattedDate,
        'timezone': timezoneName,
      };

      final response = await http.post(
        Uri.parse(ApiEndpoints.riskMetricHeroSection),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      ).timeout(timeoutDuration);

      if (kDebugMode) {
        debugPrint('📌 Request URL: ${ApiEndpoints.riskMetricHeroSection}');
        debugPrint('📤 Request Body: $requestBody');
        debugPrint('📥 Status: ${response.statusCode}');
        debugPrint('📥 Response: ${response.body}');
      }

      if (response.statusCode == 200) {
        return RiskResponse.fromJson(jsonDecode(response.body));
      }else{
        return RiskResponse();
      }

      throw Exception('Failed: ${response.statusCode} → ${response.body}');
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint("❌ Error in fetchRiskMetricsHeroSection: $e");
        //debugPrint(st);
      }
      rethrow;
    }
  }



  /// Fetches heart risk meter history (with date range)
  Future<HeartRiskSummaryResponse> fetchHeartRiskMeterHistory({
    required String fromDate,
    required String toDate,
    required String timezone,
  }) async {
    final url = Uri.parse(ApiEndpoints.heartRiskSummary);

    //final token = _ref.watch(tokenProvider); // Using Riverpod token provider
    final token = await SecureStorageUtils().read(StorageKeys.accessToken);
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'fromDate': fromDate,
        'toDate': toDate,
        'timezone': timezone,
      }),
    ).timeout(timeoutDuration);

    if (kDebugMode) {
      debugPrint('Request URL: $url');
      debugPrint('Request Body: ${jsonEncode({
        'fromDate': fromDate,
        'toDate': toDate,
        'timezone': timezone,
      })}');
      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
    }

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return HeartRiskSummaryResponse.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to fetch heart risk summary: ${response.statusCode}');
    }
  }
}

class RiskMetricComparisonService {
  Future<HeartRiskComparisonResponse> fetchRiskMetricComparison() async {
    final prefs = await SharedPreferences.getInstance();


    final storedUserId = prefs.getString('userId');
    debugPrint("storedUserId @@ $storedUserId");
    if (storedUserId == null) {
      throw Exception("UserId not found");
    }

    // Convert userId to int ✔️
    final int patientId = int.tryParse(storedUserId) ?? -1;

    debugPrint("patientId123: $patientId");

    if (patientId == -1) {
      throw Exception("Invalid patientId format");
    }

    final timezoneName = await getCurrentTimezoneName();

    // Fallback token
    final secureStorage = SecureStorageUtils();
    final token = await secureStorage.read("auth_token");

    if (token == null) {
      throw Exception("Auth token not found");
    }

    final url = Uri.parse(
      ApiEndpoints.heartRiskMetricComparisonEndpoint(
        patientId: patientId,      // ✔️ now sending an INT
        timezone: timezoneName,
      ),
    );

    debugPrint("url of heartRiskMetricComparisonEndpoint $url");
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ).timeout(timeoutDuration);

    if (response.statusCode == 200) {
      return HeartRiskComparisonResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        "Failed to fetch risk comparison: "
            "${response.statusCode} - ${response.body}",
      );
    }
  }
}


