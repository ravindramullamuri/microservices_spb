import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:heart_thrive/core/api_endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/meal/food/food_response_model.dart';
import '../../models/meal/food/meal_nutrient_summary.dart' hide Nutrient;
import '../../models/meal/food/user_meal_menu_model.dart';
import '../../models/meal/food/nutrients_model.dart';
import '../../utils/component_utils.dart';
import '../../utils/secure_storage_utils.dart';

class SodiumMealServices{
  /// =======================
  /// API
  /// =======================

  String buildMealLogsUrl({required int page, required int size,required String timezone}) {
    final now = DateTime.now();
    final date = DateFormat('dd-MM-yyyy').format(now);

    final fromDate = '$date 00:00';
    final toDate = '$date 23:59';

    return Uri.encodeFull(
      '${ApiEndpoints.userMealLogs}'
          '?fromDate=$fromDate'
          '&toDate=$toDate&timezone=$timezone'
          '&page=$page'
          '&size=$size',
    );
  }

  Future<FoodLogPageResponse> fetchMealLogs({
    required int page,
    required int size,
  }) async {
     final String timezone  = await getTimeZone();
    debugPrint("size @@@ $size $timezone");

    final url = buildMealLogsUrl(page: page, size: size,timezone: timezone);
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(StorageKeys.accessToken);
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    token = token??secureStorageToken;
    debugPrint("Meal $url");
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $secureStorageToken',
      },
    ).timeout(timeoutDuration);

    if (response.statusCode == 200) {
      return FoodLogPageResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }
  Future<List<Nutrients>> fetchNutrientSummary({
    required String fromDate,
    required String toDate,
    required String timezone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();
    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    token = token ?? secureStorageToken;
    final String baseUrl = ApiEndpoints.patientMealLogsNutrientSummary;
    final uri = Uri.parse(baseUrl).replace(queryParameters: {
      'fromDate': fromDate, // e.g. 22-12-2025 00:00
      'toDate': toDate, // e.g. 22-12-2025 23:59
      'timezone': timezone // Asia/Kolkata
    });

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $secureStorageToken',
        'Content-Type': 'application/json',
      },
    ).timeout(timeoutDuration);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List list = data['nutrients'] ?? [];

      return list.map((e) => Nutrients.fromJson(e)).toList();
    } else {
      throw Exception(
          'Failed to load nutrients: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<MealMenu>> fetchMeals({
    required int page,
    required int size,
    required String token,
  }) async {
    // Secure Storage
    final secureStorage = SecureStorageUtils();
    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    final baseUrl = ApiEndpoints.patientMealMenusWithNutrients;
    final uri = Uri.parse('$baseUrl?page=$page&size=$size');
    debugPrint("uri @@@ $uri");
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $secureStorageToken',
        'Content-Type': 'application/json',
      },
    ).timeout(timeoutDuration);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      debugPrint("Meal Menu data $data");
      return MealMenuResponse.fromJson(data).content;
    } else {
      throw Exception('Failed to load meals');
    }
  }

  // Nutrient Summary for Meal Type based Break Down
  Future<NutrientSummaryResponse> fetchNutrientSummaryByMealType({
    required String token,
    required String fromDate,
    required String toDate,
  }) async {
    // Secure Storage
    final secureStorage = SecureStorageUtils();
    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    final String timezone =await getTimeZone();
    final uri = Uri.parse(
      '${ApiEndpoints.patientMealLogsNutrientSummaryByMealType}'
          '?fromDate=$fromDate&toDate=$toDate&timezone=$timezone',
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $secureStorageToken',
        'Content-Type': 'application/json',
      },
    ).timeout(timeoutDuration);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return NutrientSummaryResponse.fromJson(data);
    } else {
      throw Exception(
        'Failed to fetch nutrient summary: ${response.statusCode}',
      );
    }
  }

}