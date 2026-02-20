import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:heart_thrive/core/api_endpoints.dart';
import 'package:heart_thrive/models/meal/meal_logs_response.dart';
import 'package:heart_thrive/models/meal/patient_meal_menus_models.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:intl/intl.dart';
import 'package:time_machine2/time_machine2.dart';
import '../models/meal/meal_nutrient_response.dart';
import '../models/meal/nutrient_response.dart';
import '../models/meal/food_item_with_nutrients_response.dart';
import '../utils/secure_storage_utils.dart';

class MealService {
  // Use the same simple base URL approach as weight_height_service.dart

  static final Map<String, int> _mealTypeMapping = {};

  static bool _isMealTypesLoaded = false;

  static Map<String, int> get mealTypeMapping {
    if (kDebugMode) {
      print('📦 Returning mealTypeMapping: $_mealTypeMapping');
    }
    return _mealTypeMapping;
  }

  static bool get isMealTypesLoaded {
    if (kDebugMode) {
      print('🔍 isMealTypesLoaded: $_isMealTypesLoaded');
    }
    return _isMealTypesLoaded;
  }

  static void testBaseUrl() {
    if (kDebugMode) {
      print('🧪 Testing base URL configuration...');
      print('🧪 Using hardcoded base URL: ${ApiEndpoints.baseUrl}');
    }
  }

  // Unified Version
  static Future<List<MealLog>> fetchMealLogsUnified(
      String mealTypeName, {
        int page = 0,
        int size = 20,
      }) async {
    debugPrint('🚀 Fetching meal logs for: $mealTypeName');

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    token = secureStorageToken;
    if (token == null || token.isEmpty) {
      debugPrint('❌ No auth token — aborting request.');
      return [];
    }

    try {
      // 📅 Date Range (Today: 00:00 → 23:59)
      final now = DateTime.now();
      final fromDate = DateTime(now.year, now.month, now.day, 0, 0);
      final toDate   = DateTime(now.year, now.month, now.day, 23, 59);

      String formatDate(DateTime dt) =>
          "${dt.day.toString().padLeft(2, '0')}-"
              "${dt.month.toString().padLeft(2, '0')}-"
              "${dt.year} "
              "${dt.hour.toString().padLeft(2, '0')}:"
              "${dt.minute.toString().padLeft(2, '0')}";

      final timezoneName = await getCurrentTimezoneName();
      debugPrint("🕒 Timezone: $timezoneName");

      String url;

      // =====================================================
      // CASE 1: All Meals → USE FULL ENDPOINT (NO mealTypeId)
      // =====================================================
      if (mealTypeName.toLowerCase() == "all") {
        url = ApiEndpoints.userMealLogsEndpoint(
          fromDate: formatDate(fromDate),
          toDate: formatDate(toDate),
          timezone: timezoneName,
          page: page,
          size: size,
        );

        debugPrint("🍽 Using ALL meals API → $url");
      }

      // =====================================================
      // CASE 2: Specific Meal Type → NEED mealTypeId
      // =====================================================
      else {
        final mealTypeId = await getMealTypeIdByName(mealTypeName);

        if (mealTypeId == null) {
          debugPrint("⚠️ No mealTypeId found for $mealTypeName");
          return [];
        }

        url = ApiEndpoints.userMealLogsByMealTypeIdEndpoint(
          mealTypeId: mealTypeId,
          fromDate: formatDate(fromDate),
          toDate: formatDate(toDate),
          timezone: timezoneName,
          page: page,
          size: size,
        );

        debugPrint("🍛 Using filtered meals API (id=$mealTypeId) → $url");
      }

      // --------------------- API CALL --------------------- //
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(timeoutDuration);

      debugPrint("📡 Status: ${response.statusCode}");

      if (response.statusCode != 200) {
        debugPrint("❌ API Error ${response.statusCode}");
        debugPrint("❌ Body: ${response.body}");
        return [];
      }

      final jsonMap = jsonDecode(response.body);

      // 🔥 BOTH APIs return SAME RESPONSE MODEL
      final mealResponse = MealLogResponse.fromJson(jsonMap);

      debugPrint("✅ Parsed ${mealResponse.content.length} records");
      return mealResponse.content;
    } catch (e, st) {
      debugPrint("🔥 Exception in fetchMealLogsUnified: $e");
      debugPrint("$st");
      return [];
    }
  }


  static Future<List<Map<String, dynamic>>> fetchMealTypes() async {
    debugPrint('=== MealService.fetchMealTypes() STARTED ===');
    if (kDebugMode) {
      print('🚀 Starting fetchMealTypes...');
      testBaseUrl();
    }

    if (kDebugMode) {
      print('🔑 Getting SharedPreferences...');
    }
    debugPrint('=== GETTING SHARED PREFERENCES ===');
    final prefs = await SharedPreferences.getInstance();
    debugPrint('=== SHARED PREFERENCES GOT ===');
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    token = secureStorageToken;
    debugPrint("Token in fetchMealTypes: $token");
    if (kDebugMode) {
      print('🔑 Token: ${token != null ? "FOUND" : "NOT FOUND"}');
    }

    if (token == null || token.isEmpty) {
      if (kDebugMode) {
        print('❌ No auth token, returning empty list.');
      }
      return [];
    }

    try {
      final url = ApiEndpoints.getMealTypesURL;
      if (kDebugMode) {
        print('🌍 Fetching Meal Types from $url');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'User-Agent': 'FlutterApp/1.0',
        },

      ).timeout(timeoutDuration);
      if (kDebugMode) {
        print('📡 Response Status: ${response.statusCode}');
        print('📡 Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Parsing response JSON...');
        }
        final List<dynamic> data = jsonDecode(response.body);
        if (kDebugMode) {
          print('✅ Parsed ${data.length} meal types');
        }

        _mealTypeMapping.clear();
        if (kDebugMode) {
          print('🧹 Cleared old mealTypeMapping');
        }

        final List<Map<String, dynamic>> typedData = data.cast<Map<String, dynamic>>();
        for (var mealType in typedData) {
          if (kDebugMode) {
            print('➡️ Processing mealType: ${mealType['name']}');
          }
          if (mealType['id'] != null && mealType['name'] != null) {
            _mealTypeMapping[mealType['name']] = mealType['id'];
          }
        }

        _isMealTypesLoaded = true;
        if (kDebugMode) {
          print('✅ Meal types loaded: $_mealTypeMapping');
        }
        return typedData;
      } else {
        if (kDebugMode) {
          print('❌ Failed to fetch meal types, Status: ${response.statusCode}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔥 Exception in fetchMealTypes: $e');
      }
      return [];
    }
  }

  // Fetch all meal logs from the API
  static Future<MealLogsResponse?> fetchMealLogs(
      String mealTypeName, {
        int page = 0,
        int size = 20,
      }) async {
    if (kDebugMode) {
      print('🚀 Starting fetchMealLogs for $mealTypeName...');
    }

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    token = secureStorageToken;

    if (kDebugMode) {
      print('🔑 Token: ${token != null ? "FOUND" : "NOT FOUND"}');
    }

    // ❌ Cannot return [] because return type is MealLogsResponse?
    if (token == null || token.isEmpty) {
      if (kDebugMode) print('❌ No auth token, cannot proceed.');
      return null;
    }

    try {
      // 🔍 Resolve mealTypeId
      final mealTypeId = await getMealTypeIdByName(mealTypeName);

      if (mealTypeId == null) {
        if (kDebugMode) print('⚠️ No mealTypeId found for $mealTypeName');
        return null;
      }

      // 👉 Today’s date range
      final now = DateTime.now();
      final fromDate = DateTime(now.year, now.month, now.day, 0, 0);
      final toDate = DateTime(now.year, now.month, now.day, 23, 59);

      // Format: dd-MM-yyyy HH:mm
      String formatDate(DateTime dt) {
        return "${dt.day.toString().padLeft(2, '0')}-"
            "${dt.month.toString().padLeft(2, '0')}-"
            "${dt.year} "
            "${dt.hour.toString().padLeft(2, '0')}:"
            "${dt.minute.toString().padLeft(2, '0')}";
      }

      final timezoneName = await getCurrentTimezoneName();
      if (kDebugMode) print('🕒 Using timezone: $timezoneName');

      final url = ApiEndpoints.userMealLogsByMealTypeIdEndpoint(
        mealTypeId: mealTypeId,
        fromDate: formatDate(fromDate),
        toDate: formatDate(toDate),
        timezone: timezoneName,
        page: page,
        size: size,
      );

      if (kDebugMode) {
        print('🌍 Fetching meals for $mealTypeName (id=$mealTypeId) from:');
        print(url);
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      if (kDebugMode) {
        print('📡 Status: ${response.statusCode}');
        print('📡 Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return MealLogsResponse.fromJson(decoded);
      }

      if (kDebugMode) {
        print('❌ Failed to fetch meal logs: ${response.statusCode}');
      }
      return null;

    } catch (e, stack) {
      if (kDebugMode) {
        print('🔥 Exception in fetchMealLogs: $e');
        print('🪵 Stacktrace: $stack');
      }
      return null;
    }
  }


  static Future<List<Map<String, dynamic>>> fetchMealLogsForAllMeals(
      String mealTypeName, {
        int page = 0,
        int size = 20,
      }) async {
    if (kDebugMode) {
      print('🚀 Starting fetchMealLogs for $mealTypeName...');
    }

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    token = secureStorageToken;
    if (kDebugMode) {
      print('🔑 Token: ${token != null ? "FOUND" : "NOT FOUND"}');
      print('Current Token $token');
    }

    if (token == null || token.isEmpty) {
      if (kDebugMode) {
        print('❌ No auth token, cannot proceed.');
      }
      return [];
    }

    try {

      // 👉 Define today’s date range (start of day → end of day)
      final now = DateTime.now();
      final fromDate = DateTime(now.year, now.month, now.day);
      final toDate = DateTime(now.year, now.month, now.day);

      // Format date as dd-MM-yyyy HH:mm
      String formatDate(DateTime dt) {
        return "${dt.day.toString().padLeft(2, '0')}-"
            "${dt.month.toString().padLeft(2, '0')}-"
            "${dt.year} "
            "${dt.hour.toString().padLeft(2, '0')}:"
            "${dt.minute.toString().padLeft(2, '0')}";
      }

      final timezoneName = await getCurrentTimezoneName();
      if (kDebugMode) print('🕒 Using timezone: $timezoneName');

      final fromDateStr = formatDate(fromDate);
      final toDateStr = formatDate(toDate);

      /*final url =
          '$baseUrl/api/patient-meal-logs/user-meal-logs'
          '?fromDate=$fromDateStr'
          '&toDate=$toDateStr'
          '&timezone=$timezoneName'
          '&page=$page'
          '&size=$size';*/
      final url = ApiEndpoints.userMealLogsEndpoint(
          fromDate: fromDateStr,
          toDate: toDateStr,
          timezone: timezoneName,
          page: page,
          size: size
      );

      if (kDebugMode) {
        print('🌍 Fetching meals for $mealTypeName from $url');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'User-Agent': 'FlutterApp/1.0',
        },
      ).timeout(timeoutDuration);

      if (kDebugMode) {
        print('📡 Response Status: ${response.statusCode}');
        print('📡 Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);

        final List<dynamic>? content = decoded['content'];
        if (content != null) {
          if (kDebugMode) {
            print('✅ Received ${content.length} meal logs for $mealTypeName');
          }
          return content.cast<Map<String, dynamic>>();
        } else {
          if (kDebugMode) {
            print('⚠️ No "content" in response for $mealTypeName');
          }
          return [];
        }
      } else {
        if (kDebugMode) {
          print('❌ Failed to fetch meal logs for $mealTypeName: ${response.statusCode}');
        }
        return [];
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('🔥 Exception in fetchMealLogs for $mealTypeName: $e');
        print('🪵 Stacktrace: $stack');
      }
      return [];
    }
  }

  // New Model Class based Code
  static Future<List<MealLog>> fetchMealLogsForAllMealsNew(
      String mealTypeName, {
        int page = 0,
        int size = 20,
      }) async {
    debugPrint('🚀 Fetching meal logs for $mealTypeName...');

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    token = secureStorageToken;

    if (token == null || token.isEmpty) {
      debugPrint('❌ No auth token — aborting request.');
      return [];
    }

    try {
      // ---- Date Range: Start & End of Today ---- //
      final now = DateTime.now();
      final fromDate = DateTime(now.year, now.month, now.day, 0, 0);
      final toDate   = DateTime(now.year, now.month, now.day, 23, 59);

      String formatDate(DateTime dt) =>
          "${dt.day.toString().padLeft(2, '0')}-"
              "${dt.month.toString().padLeft(2, '0')}-"
              "${dt.year} "
              "${dt.hour.toString().padLeft(2, '0')}:"
              "${dt.minute.toString().padLeft(2, '0')}";

      final timezoneName = await getCurrentTimezoneName();
      debugPrint("🕒 Timezone: $timezoneName");

      final url = ApiEndpoints.userMealLogsEndpoint(
        fromDate: formatDate(fromDate),
        toDate: formatDate(toDate),
        timezone: timezoneName,
        page: page,
        size: size,
      );

      debugPrint("🌍 GET $url");

      // ---- API Call ---- //
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'User-Agent': 'FlutterApp/1.0',
        },
      ).timeout(timeoutDuration);

      debugPrint("📡 Status: ${response.statusCode}");

      if (response.statusCode != 200) {
        debugPrint("❌ API Error ${response.statusCode}");
        return [];
      }

      final jsonMap = jsonDecode(response.body);

      // Parse to model
      final mealResponse = MealLogResponse.fromJson(jsonMap);

      debugPrint("✅ Received ${mealResponse.content.length} logs.");

      return mealResponse.content;
    } catch (e, st) {
      debugPrint("🔥 Exception: $e\n$st");
      return [];
    }
  }





  static Future<FoodItemWithNutrientsResponse?> fetchAllMealLogs({
    required String mealTypeName,
    String foodItemName = '',
    int page = 0,
    int size = 20,
  }) async
  {
    if (kDebugMode) print('🔄 Fetching meal logs for $mealTypeName...');

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    token = secureStorageToken;
    if (token == null || token.isEmpty) return null;

    try {
      Map<String, String> queryParams = {
        'page': page.toString(),
        'size': size.toString(),
        'foodItemName': foodItemName,
      };

      // Add mealTypeId only if mealTypeName is not "All Meal"

      /*if (mealTypeName.toLowerCase() != 'all meal') {
        final mealTypeId = await getMealTypeIdByName(mealTypeName); // your helper
        if (mealTypeId != null) {
          queryParams['mealTypeId'] = mealTypeId.toString();
        }
      }*/

      final url = Uri.parse(ApiEndpoints.foodItemsWithNutrients)
          .replace(queryParameters: queryParams);

      if (kDebugMode) print('🌍 Fetching from $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'User-Agent': 'FlutterApp/1.0',
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (kDebugMode) print("Search data : $decoded");
        return FoodItemWithNutrientsResponse.fromJson(decoded);
      }

      return null;
    } catch (e) {
      if (kDebugMode) print('🔥 Exception in fetchAllMealLogs: $e');
      return null;
    }
  }


  static Future<bool> deleteMealLog(int mealLogId) async {
    if (kDebugMode) {
      print('🚀 Starting deleteMealLog for id: $mealLogId');
    }

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    token = secureStorageToken;

    if (token == null || token.isEmpty) {
      if (kDebugMode) {
        print('❌ No auth token, cannot proceed.');
      }
      return false;
    }

    try {
      final url = ApiEndpoints.userPatientMealLogs(mealLogId);
      if (kDebugMode) {
        print('🌍 DELETE request to $url');
      }

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(timeoutDuration);

      if (kDebugMode) {
        print('📡 Response Status: ${response.statusCode}');
        print('📡 Response Body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (kDebugMode) print('✅ Meal log deleted successfully!');
        return true;
      } else {
        if (kDebugMode) print('❌ Failed to delete meal log: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('🔥 Exception in deleteMealLog: $e');
      return false;
    }
  }

  static Future<bool> deleteMealMenu(int mealLogId) async {
    if (kDebugMode) {
      print('🚀 Starting deleteMealLog for id: $mealLogId');
    }

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    token = secureStorageToken;

    if (token == null || token.isEmpty) {
      if (kDebugMode) {
        print('❌ No auth token, cannot proceed.');
      }
      return false;
    }

    try {
      //final url = '$baseUrl/api/patient-meal-menus/$mealLogId';
      final url = ApiEndpoints.userPatientMealMenuLogs(mealLogId);
      if (kDebugMode) {
        print('🌍 DELETE request to $url');
      }

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(timeoutDuration);

      if (kDebugMode) {
        print('📡 Response Status: ${response.statusCode}');
        print('📡 Response Body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (kDebugMode) print('✅ Meal log deleted successfully!');
        return true;
      } else {
        if (kDebugMode) print('❌ Failed to delete meal log: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('🔥 Exception in deleteMealLog: $e');
      return false;
    }
  }


  /// ✅ Helper to get mealTypeId by mealType name
  static Future<int?> getMealTypeIdByName(String mealTypeName) async {
    // If mapping is empty, fetch meal types first
    if (_mealTypeMapping.isEmpty) {
      if (kDebugMode) print("ℹ️ Meal types not loaded yet, fetching...");
      await fetchMealTypes();
    }

    final mealTypeId = _mealTypeMapping[mealTypeName];

    if (kDebugMode) {
      if (mealTypeId != null) {
        print("✅ Found mealTypeId=$mealTypeId for '$mealTypeName'");
      } else {
        print("❌ No mealTypeId found for '$mealTypeName'");
      }
    }

    return mealTypeId;
  }

  static Future<bool> createMealLog({
    required String mealType,
    required String quantity,
    required DateTime logDate,
    required String foodItemName,
    String? unitType,
    String? brandName,
    int foodCategoryId = 0,
    int foodTypeId = 0,
    double sodiumAmount = 0,
    double caloriesAmount = 0,
    double carbsAmount = 0,
    double proteinAmount = 0,
    double fatsAmount = 0,
    bool addToMealMenu = true,
  }) async
  {
    if (kDebugMode) {
      print('🚀 Starting createMealLog...');
      print('🔍 Params:  mealType=$mealType, quantity=$quantity');
    }

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    token = secureStorageToken;
    if (kDebugMode) {
      print('🔑 Token: ${token != null ? "FOUND" : "NOT FOUND"}');
    }

    if (token == null || token.isEmpty) {
      if (kDebugMode) {
        print('❌ No auth token, cannot proceed.');
      }
      return false;
    }

    // ✅ Use helper to get mealTypeId
    final mealTypeId = await getMealTypeIdByName(mealType);

    if (kDebugMode) {
      print('🔍 mealTypeId for $mealType: $mealTypeId');
    }

    if (mealTypeId == null) {
      if (kDebugMode) {
        print('❌ Invalid meal type: $mealType');
      }
      return false;
    }

    final formattedDate =
        '${logDate.year}-${logDate.month.toString().padLeft(2, '0')}-${logDate.day.toString().padLeft(2, '0')}';
    if (kDebugMode) {
      print('📅 Formatted Date: $formattedDate');
    }

    final body = {
      "mealTypeId": mealTypeId,
      "quantity": quantity,
      "unitType": unitType,
      "logDate": formattedDate,
      "foodItemName": foodItemName,
      "brandName": brandName ?? "",
      "foodCategoryId": foodCategoryId,
      "foodItemId": foodTypeId == 0?null:foodTypeId,
      "sodiumAmount": sodiumAmount,
      "caloriesAmount": caloriesAmount,
      "carbsAmount": carbsAmount,
      "proteinAmount": proteinAmount,
      "fatsAmount": fatsAmount,
      "addToMealMenu": addToMealMenu,
    };

    if (kDebugMode) {
      print('📦 Request Body: $body');
    }

    try {

      final url = ApiEndpoints.createMeal;
      if (kDebugMode) {
        print('🌍 Posting to $url');
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(timeoutDuration);

      if (kDebugMode) {
        print('📡 Response Status: ${response.statusCode}');
        print('📡 Response Body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('✅ Meal log created successfully!');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ Failed to create meal log: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔥 Exception in createMealLog: $e');
      }
      return false;
    }
  }


  static Future<bool> updateMealLog({
    required int mealId,
    required String mealType,
    required String quantity,
    required DateTime logDate,
    required String foodItemName,
    String? unitType,
    String? brandName,
    int foodCategoryId = 0,
    int foodTypeId = 0,
    double sodiumAmount = 0,
    double caloriesAmount = 0,
    double carbsAmount = 0,
    double proteinAmount = 0,
    double fatsAmount = 0,
    bool addToMealMenu = true,
  })
  async {
    if (kDebugMode) {
      print('🚀 Starting updateMealLog...');
    }

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    token = secureStorageToken;

    if (token == null || token.isEmpty) {
      if (kDebugMode) print('❌ No auth token found');
      return false;
    }
    if (secureStorageToken == null || secureStorageToken.isEmpty) {
      if (kDebugMode) print('❌ No auth token found');
      return false;
    }

    final mealTypeId = await getMealTypeIdByName(mealType);

    final formattedDate =
        '${logDate.year}-${logDate.month.toString().padLeft(2, '0')}-${logDate.day.toString().padLeft(2, '0')}';

    final body = {
      // ✅ must send ID for editing
      "mealTypeId": mealTypeId,
      "quantity": quantity,
      "unitType": unitType,
      "sodiumAmount": sodiumAmount,
      "caloriesAmount": caloriesAmount,
      "carbsAmount": carbsAmount,
      "proteinAmount": proteinAmount,
      "fatsAmount": fatsAmount,
    };

    debugPrint("Edit Body: $body");
    try {
      final url = ApiEndpoints.editMeal(mealId);
      if (kDebugMode) print('🌍 PUT $url');

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(timeoutDuration);

      if (kDebugMode) {
        print('📡 Response Status: ${response.statusCode}');
        print('📡 Response Body: ${response.body}');
      }

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('🔥 Exception in updateMealLog: $e');
      return false;
    }
  }

  static Future<bool> updateMealMenu({
    required int mealId,
    required String mealType,
    required String quantity,
    required DateTime logDate,
    required String foodItemName,
    String? unitType,
    String? brandName,
    int foodCategoryId = 0,
    int foodTypeId = 0,
    double sodiumAmount = 0,
    double caloriesAmount = 0,
    double carbsAmount = 0,
    double proteinAmount = 0,
    double fatsAmount = 0,
    bool addToMealMenu = true,
  })
  async {
    if (kDebugMode) {
      print('🚀 Starting updateMealLog...');
    }

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    token = secureStorageToken;
    if (token == null || token.isEmpty) {
      if (kDebugMode) print('❌ No auth token found');
      return false;
    }

    final mealTypeId = await getMealTypeIdByName(mealType);

    final formattedDate =
        '${logDate.year}-${logDate.month.toString().padLeft(2, '0')}-${logDate.day.toString().padLeft(2, '0')}';

    final body = {
      // ✅ must send ID for editing
      "mealMenuId": mealId,
      "name": foodItemName,
      "mealTypeId": mealTypeId,
      "quantity": quantity,
      "unitType": unitType,
      "sodiumAmount": sodiumAmount,
      "caloriesAmount": caloriesAmount,
      "carbsAmount": carbsAmount,
      "proteinAmount": proteinAmount,
      "fatsAmount": fatsAmount,
      "addToMealMenu": true
    };

    debugPrint("Edit Body: $body");
    try {
      final url = ApiEndpoints.editMealMenu;
      if (kDebugMode) print('🌍 PUT $url');

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(timeoutDuration);

      if (kDebugMode) {
        print('📡 Response Status: ${response.statusCode}');
        print('📡 Response Body: ${response.body}');
      }

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('🔥 Exception in updateMealLog: $e');
      return false;
    }
  }

  // Fetch patient meal menus with nutrients
  static Future<PatientMealMenusResponse?> fetchPatientMealMenusWithNutrients({
    required String fromDate,
    required String toDate,
    required int mealTypeId,
    int page = 0,
    int size = 20,
  }) async
  {
    if (kDebugMode) {
      print('🚀 Starting fetchPatientMealMenusWithNutrients...');
      print('🔍 Params: fromDate=$fromDate, toDate=$toDate, mealTypeId=$mealTypeId, page=$page, size=$size');
    }

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    token = secureStorageToken;

    if (kDebugMode) {
      print('🔑 Token: ${token != null ? "FOUND" : "NOT FOUND"}');
    }

    if (token == null || token.isEmpty) {
      if (kDebugMode) print('❌ No auth token, cannot proceed.');
      return null;
    }

    try {
      final timezoneName = await getCurrentTimezoneName();
      if (kDebugMode) print('🕒 Using timezone: $timezoneName');

      // Build query parameters
      final queryParams = {
       // 'fromDate': fromDate,
       // 'toDate': toDate,
        'timezone': timezoneName,
        'page': page.toString(),
        'size': size.toString(),
      };

      // Only include mealTypeId if not 20
      if (mealTypeId != 20) {
        queryParams['mealTypeId'] = mealTypeId.toString();
      }

      final url = Uri.parse(ApiEndpoints.patientMealMenusWithNutrients)
          .replace(queryParameters: queryParams);

      if (kDebugMode) {
        print('🌍 Request URL: ${Uri.decodeFull(url.toString())}');
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      if (kDebugMode) {
        print('📡 Status: ${response.statusCode}');
        print('📡 Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
      }

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        return PatientMealMenusResponse.fromJson(parsed);
      } else {
        if (kDebugMode) {
          print('❌ Failed with status ${response.statusCode}');
        }
        return null;
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('🔥 Exception in fetchPatientMealMenusWithNutrients: $e');
        print('🪵 Stacktrace: $stack');
      }
      return null;
    }
  }



  static Future<List<Map<String, dynamic>>> fetchPatientMealMenusWithNutrientsForAllMenu({
    required String fromDate,
    required String toDate,
    int page = 0,
    int size = 20,
  }) async {
    if (kDebugMode) {
      print('🚀 Starting fetchPatientMealMenusWithNutrients...');
      print('🔍 Params: fromDate=$fromDate, toDate=$toDate, page=$page, size=$size');
    }

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);
    token = secureStorageToken;
    if (kDebugMode) {
      print('🔑 Token: ${token != null ? "FOUND" : "NOT FOUND"}');
    }

    if (token == null || token.isEmpty) {
      if (kDebugMode) {
        print('❌ No auth token, cannot proceed.');
      }
      return [];
    }

    try {
      final url = Uri.parse(ApiEndpoints.patientMealMenusWithNutrients).replace(
        queryParameters: {
          'fromDate': fromDate,
          'toDate': toDate,
          'page': page.toString(),
          'size': size.toString(),
        },
      );

      if (kDebugMode) {
        print('🌍 Fetching patient meal menus from $url');
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      if (kDebugMode) {
        print('📡 Response Status: ${response.statusCode}');
        print('📡 Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> parsed = jsonDecode(response.body);
        debugPrint("parsed1 $parsed");
        if (parsed.containsKey("content")) {
          List<dynamic> content = parsed["content"];
          if (kDebugMode) {
            print('✅ Parsed ${content.length} patient meal menus');
          }
          return List<Map<String, dynamic>>.from(content);
        } else {
          if (kDebugMode) {
            print('⚠️ No "content" key in response');
          }
          return [];
        }
      } else {
        if (kDebugMode) {
          print('❌ Failed to fetch patient meal menus: ${response.statusCode}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔥 Exception in fetchPatientMealMenusWithNutrients: $e');
      }
      return [];
    }
  }

  // Fetch nutrient summary for a specific date
  static Future<Map<String, dynamic>?> fetchNutrientSummaryOld(
      DateTime fromDate, DateTime toDate,
      {int? mealTypeId}) async
  {
    if (kDebugMode) print('🚀 Starting fetchNutrientSummary...');

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    // Secure Storage
    final secureStorage = SecureStorageUtils();

    String? secureStorageToken = await secureStorage.read(StorageKeys.accessToken);;
    token = secureStorageToken;
    if (kDebugMode) print('🔑 Token: ${token != null ? "FOUND" : "NOT FOUND"}');

    if (token == null || token.isEmpty) return null;

    try {
      final dateFormat = DateFormat('dd-MM-yyyy HH:mm');
      final fromDateStr = dateFormat.format(fromDate);
      final toDateStr = dateFormat.format(toDate);

      final timezoneName = await getCurrentTimezoneName();
      if (kDebugMode) print('🕒 Using timezone: $timezoneName');

      // Build query parameters
      final queryParams = {
        'fromDate': fromDateStr,
        'toDate': toDateStr,
        'timezone': timezoneName,
        if (mealTypeId != null) 'mealTypeId': mealTypeId.toString(),
      };

      // Use Uri.https to properly encode

      final uri = Uri.parse(ApiEndpoints.patientMealLogsNutrientSummary).replace(
        queryParameters: queryParams,
      );

      if (kDebugMode) print('🌍 Fetching nutrient summary from $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(timeoutDuration);

      if (kDebugMode) {
        print('📡 Response Status: ${response.statusCode}');
        print('📡 Response Body of sodium data : ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (kDebugMode) print('✅ Parsed nutrient summary data');
        return data;
      } else {
        if (kDebugMode) print('❌ Failed to fetch nutrient summary: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('🔥 Exception in fetchNutrientSummary: $e');
      return null;
    }
  }
  // New Method
  static Future<NutrientResponse?> fetchNutrientSummary(
      DateTime fromDate,
      DateTime toDate, {
        int? mealTypeId,
      }) async {
    final prefs =  SecureStorageUtils();
    String? token = await prefs.read('auth_token');


    if (token == null || token.isEmpty) {
      debugPrint("❌ No auth token found");
      return null;
    }

    try {
      final uri = await _buildNutrientSummaryUri(fromDate, toDate, mealTypeId);

      debugPrint("🌍 Request: $uri");

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(timeoutDuration);

      debugPrint("📡 Status: ${response.statusCode}");
      debugPrint("📡 Body: ${response.body}");

      if (response.statusCode != 200) {
        debugPrint("❌ Failed nutrient summary fetch");
        return null;
      }

      return NutrientResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      debugPrint("🔥 Error fetching nutrient summary: $e");
      return null;
    }
  }

  static Future<Uri> _buildNutrientSummaryUri(
      DateTime fromDate,
      DateTime toDate,
      int? mealTypeId,
      ) async {
    final formatter = DateFormat('dd-MM-yyyy HH:mm');
    final timezone = await getCurrentTimezoneName();

    final queryParams = {
      'fromDate': formatter.format(fromDate),
      'toDate': formatter.format(toDate),
      'timezone': timezone,
      if (mealTypeId != null) 'mealTypeId': mealTypeId.toString(),
    };


    final uri = Uri.parse(ApiEndpoints.patientMealLogsNutrientSummary).replace(
      queryParameters: queryParams,
    );
    return uri;
  }

  // Fetch nutrient summary by meal type for a specific date range
  static Future<Map<String, dynamic>?> fetchNutrientSummaryByMealType(
      DateTime fromDate, DateTime toDate) async {
    if (kDebugMode) {
      print('🚀 Starting fetchNutrientSummaryByMealType...');
    }

    final prefs = SecureStorageUtils();
    final token =await prefs.read('auth_token');
    if (kDebugMode) {
      print('🔑 Token: ${token != null ? "FOUND" : "NOT FOUND"}');
    }

    if (token == null || token.isEmpty) {
      if (kDebugMode) print('❌ No auth token, cannot proceed.');
      return null;
    }


    try {
      final dateFormat = DateFormat('dd-MM-yyyy HH:mm');
      final fromDateStr = dateFormat.format(fromDate);
      final toDateStr = dateFormat.format(toDate);
      final timezoneName = await getCurrentTimezoneName();
      // final url = '$baseUrl/api/patient-meal-logs/nutrient-summary-by-meal-type?fromDate=:00&toDate=11-09-2025 23:59$timezoneName';

      // ✅ Format date as dd-MM-yyyy HH:mm
      if (kDebugMode) print('🕒 Using timezone: $timezoneName');

      final queryParams = {
        'fromDate': fromDateStr,
        'toDate': toDateStr,
        'timezone': timezoneName,
      };

      // Use Uri.https to properly encode
      //final url = ApiEndpoints.patientMealLogsNutrientSummaryByMealType;
      final uri = Uri.parse(ApiEndpoints.patientMealLogsNutrientSummaryByMealType)
          .replace(queryParameters: queryParams);

      // final uri = Uri.parse(url).replace(queryParameters: {
      //   'fromDate': fromDateStr,
      //   'toDate': toDateStr,
      // });

      if (kDebugMode) {
        print('🌍 Fetching nutrient summary by meal type from $uri');
      }

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(timeoutDuration);

      if (kDebugMode) {
        print('📡 Response Status: ${response.statusCode}');
        print('📡 Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (kDebugMode) {
          print('✅ Parsed nutrient summary by meal type data');
        }
        return data;
      } else {
        if (kDebugMode) {
          print('❌ Failed: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔥 Exception in fetchNutrientSummaryByMealType: $e');
      }
      return null;
    }
  }
}
Future<String> getCurrentTimezoneName() async {
  // Gets the local timezone ID (e.g. "Asia/Kolkata")
  final DateTimeZone localZone = DateTimeZone.local;
  final TimezoneInfo  timezoneInfo= await FlutterTimezone.getLocalTimezone();
  return timezoneInfo.identifier;
}