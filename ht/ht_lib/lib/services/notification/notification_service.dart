import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/core/api_endpoints.dart';
import 'package:http/http.dart' as http;
import '../../models/notification/notification_model.dart';
import '../../providers/token_provider.dart';


class NotificationApiService {
  final Ref ref;
  NotificationApiService(this.ref);

  String get _token {
    final token = ref.watch(tokenProvider);

    if (token == null) throw Exception("Missing token");
    return token;
  }

  final String baseUrl = "https://ciheartthrive.schoolyug.com";

  Future<List<NotificationItem>> fetchNotifications() async {
    final url = Uri.parse(ApiEndpoints.notificationsDataURL());

    final res = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $_token",
        "Content-Type": "application/json",
      },
    ).timeout(timeoutDuration);

    if (res.statusCode != 200) {
      throw Exception("Failed: ${res.statusCode}");
    }

    final List data = jsonDecode(res.body);

    return data.map((e) => NotificationItem.fromJson(e)).toList();
  }

  /// Update seen = true
  Future<bool> markSeen(String uuid) async {
    final url = Uri.parse("$baseUrl/api/notifications/$uuid/seen");

    final res = await http.patch(
      url,
      headers: {
        "Authorization": "Bearer $_token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"seen": true}),
    ).timeout(timeoutDuration);

    return res.statusCode == 200;
  }
}
