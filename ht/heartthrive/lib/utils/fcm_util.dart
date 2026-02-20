import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:heart_thrive/utils/secure_storage_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/userdetails.dart';
import '../services/auth_service.dart';

class FcmHelper {
  static bool _isRegisteringFcm = false;

  /// Call this after user is logged in (e.g. in initState or after login)
  static Future<void> registerFcmDevice(UserDetails? user) async {
    if (_isRegisteringFcm) {
      debugPrint('FCM: Already registering, skipping duplicate call');
      return;
    }
    _isRegisteringFcm = true;

    final secureStorage = SecureStorageUtils(); // your secure storage wrapper

    try {
      if (user == null) {
        debugPrint('FCM: User not logged in yet – will retry later');
        return;
      }

      debugPrint('FCM: Starting registration for user ${user.uuid}');

      // 1. Request notification permission
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM: User denied notification permission');
        return;
      }

      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        debugPrint('FCM: User has not responded to permission yet');
        return;
      }

      // 2. Read previously saved token
      //final savedToken = await secureStorage.read("fcm_token");

      String? fcmToken;
      final platform = Platform.isIOS ? "IOS" : "ANDROID";

      // ========================= iOS PATH =========================
      if (Platform.isIOS) {
        debugPrint('FCM: iOS detected – waiting for APNs token...');

        String? apnsToken;
        // Try up to 2 minutes (cold starts on slow devices / first install can take time)
        for (int i = 0; i < 40; i++) {
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          if (apnsToken != null) {
            debugPrint('✅ APNs token received after ${(i + 1) * 3}s');
            break;
          }
          await Future.delayed(const Duration(seconds: 3));
        }

        if (apnsToken == null) {
          debugPrint('❌ APNs token never received – cannot proceed on iOS');
          return;
        }

        // Small extra delay – this is the magic fix for 99% of "null FCM token" issues
        await Future.delayed(const Duration(milliseconds: 1000));

        fcmToken = await FirebaseMessaging.instance.getToken();

        // Ultimate fallback: wait for the first token refresh event
        if (fcmToken == null) {
          debugPrint(
            'FCM token still null – waiting for onTokenRefresh stream...',
          );
          try {
            fcmToken = await FirebaseMessaging.instance.onTokenRefresh
                .firstWhere((token) => token != null)
                .timeout(const Duration(seconds: 30));
          } catch (_) {
            debugPrint('❌ Timeout waiting for token refresh');
            return;
          }
        }
      }
      // ========================= ANDROID PATH =========================
      else {
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
              alert: true,
              badge: true,
              sound: true,
            );

        fcmToken = await FirebaseMessaging.instance.getToken();
      }

      // Final safety check
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('❌ Failed to obtain FCM token on $platform');
        return;
      }

      debugPrint('✅ FCM Token obtained (${fcmToken.length} chars)');

      // 3. Token unchanged? → skip everything
      /*if (savedToken == fcmToken) {
        debugPrint('✨ FCM token unchanged – no backend call needed');
        return;
      }*/

      // 4. Subscribe to global topic (safe to call multiple times)
      await FirebaseMessaging.instance.subscribeToTopic("all_users");
      debugPrint('Subscribed to topic: all_users');

      // 5. Register device on your backend
      print("User id${user.email} ${user.uuid}");
      try {
        final status = await AuthService().registerDevice(
          fcmToken: fcmToken,
          platForm: platform,
          userId: user.uuid.toString(),
        );
        if (status == 200 || status == 201) {
          // 6. Save new token locally (both secure + SharedPreferences for legacy)
          //await secureStorage.write("fcm_token", fcmToken);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("heartThriveFCMToken", fcmToken);

          debugPrint('FCM registration completed successfully!');
          debugPrint("✅ Device registered successfully");
        } else if (status == 401) {
          debugPrint("❌ Unauthorized – token expired or invalid");
        } else {
          debugPrint("⚠️ Device registration failed: $status");
        }
      } catch (e) {
        debugPrint('⚠️ Backend registration failed: $e');
        // Don't return – we still want to cache the token locally
      }
    } catch (e, stack) {
      debugPrint('FCM registration error: $e');
      if (kDebugMode) print(stack);
    } finally {
      _isRegisteringFcm = false;
    }
  }

  /// Call this once at app startup (e.g. main.dart)
  static void setupTokenRefreshListener(UserDetails user) {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM Token refreshed!');

      final secureStorage = SecureStorageUtils();
      await secureStorage.write("fcm_token", newToken);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("heartThriveFCMToken", newToken);

      // Re-register on backend if user is logged in

      if (user != null) {
        final platform = Platform.isIOS ? "IOS" : "ANDROID";
        try {
          await AuthService().registerDevice(
            fcmToken: newToken,
            platForm: platform,
            userId: user.id.toString(),
          );
        } catch (e) {
          debugPrint('Failed to update token on backend after refresh: $e');
        }
      }
    });
  }

  // Remove Logout Device
  static Future<void> removeDeviceTokenByUser(
    UserDetails? user,
    String? fcmToken,
    String? authToken,
  ) async {
    if (user == null || user.uuid == null) {
      debugPrint("❌ removeDeviceTokenByUser: User or UUID is null");
      return;
    }

    if (fcmToken == null || fcmToken.isEmpty) {
      debugPrint("❌ removeDeviceTokenByUser: FCM Token is null");
      return;
    }

    try {
      // Unsubscribe from topics
      await FirebaseMessaging.instance.unsubscribeFromTopic("all_users");

      // Remove device FCM token from backend
      await AuthService().removeDevice(
        fcmToken: fcmToken,
        userId: user.uuid, // Now safe — checked above
        authToken: authToken,
      );

      debugPrint("✅ Device token removed successfully");
    } catch (e) {
      debugPrint("❌ Error removing device token: $e");
    }
  }
}
