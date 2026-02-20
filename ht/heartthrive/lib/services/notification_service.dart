import 'dart:convert';
import 'package:heart_thrive/core/api_endpoints.dart';
import 'package:heart_thrive/utils/secure_storage_utils.dart';
import 'package:http/http.dart' as http;

import '../models/notification/notification_model.dart';


class NotificationService {
  //static const baseUrl = "https://ciheartthrive.schoolyug.com/api/notifications";

  static Future<List<NotificationItem>> fetchNotifications({
    required int page,
    required int size,
    required String token,
  }) async {
    final url = Uri.parse(ApiEndpoints.notificationsDataURL(page: page,size: size));
    token = (await SecureStorageUtils().read(StorageKeys.accessToken))!;
    final response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
    }).timeout(timeoutDuration);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data as List)
          .map((e) => NotificationItem.fromJson(e))
          .toList();
    } else {
      throw Exception("Failed to load notifications");
    }
  }
  // 🔥 MARK AS SEEN API
  static Future<bool> markSeen(String token, List<String> uuids) async {
    final url = Uri.parse(ApiEndpoints.notificationMarkSeen);
    token = (await SecureStorageUtils().read(StorageKeys.accessToken))!;
    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"notificationUuids": uuids}),
    ).timeout(timeoutDuration);

    return response.statusCode == 200;
  }
}
