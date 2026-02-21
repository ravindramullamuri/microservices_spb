// lib/services/notification_service.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// Initialize notifications
Future<void> initNotifications() async {
  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

  const InitializationSettings settings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings,
    onDidReceiveNotificationResponse: (response) {
      developer.log('Notification tapped: ${response.payload}');
    },
  );
}

/// Request permissions for Android + iOS
Future<void> requestPermissions() async {
  final androidImpl = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (androidImpl != null) {
    await androidImpl.requestNotificationsPermission();
    await androidImpl.requestExactAlarmsPermission();
  }

  final iosImpl = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
  if (iosImpl != null) {
    await iosImpl.requestPermissions(alert: true, badge: true, sound: true);
  }
}

/// Configure timezone once
Future<void> configureLocalTimeZone() async {
  tz.initializeTimeZones();
  final TimezoneInfo timeZoneName = await FlutterTimezone.getLocalTimezone();
  final tz.Location location = tz.getLocation(timeZoneName.identifier);
  tz.setLocalLocation(location);
  developer.log("Time zone configured: $timeZoneName");
}

/// Schedule notifications every hour between 6AM – 11PM
Future<void> scheduleHourlyNotificationsOld() async {
  await flutterLocalNotificationsPlugin.cancelAll();

  final now = tz.TZDateTime.now(tz.local);
  developer.log("Scheduling hourly notifications starting from ${now.toLocal()}");

  for (int hour = 6; hour < 24; hour++) {
    final next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
    );

    final scheduleTime = next.isBefore(now)
        ? next.add(const Duration(days: 1))
        : next;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      hour,
      'Heart Thrive Reminder',
      'It’s ${scheduleTime.hour}:00 — your hourly reminder!',
      scheduleTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'hourly_channel',
          'Hourly Notifications',
          channelDescription: 'Notifications every hour between 6 AM – 11 PM',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    developer.log("Scheduled: ${scheduleTime.toLocal()}");
  }
}
Future<void> scheduleHourlyNotifications() async {
  await flutterLocalNotificationsPlugin.cancelAll();

  final now = tz.TZDateTime.now(tz.local);
  developer.log("Scheduling notifications starting from ${now.toLocal()}");

  final Map<int, String> customTitle = {
    6: '🌤️ Good Morning from Heart Thrive!',
    9: '🍳 Time for a healthy breakfast!',
    13: '🍱 Good Afternoon It’s lunch time — enjoy your meal!',
    17: '☕ Snack time — have something light!',
    19: '🍽️ Dinner time — eat well and relax!',
  };

  final Map<int, String> customMessage = {
    6: '🌤️ A Fresh start for your heart! Update your daily weight, review your meal plan, and stay on track with your medicines. You’ve got this! 🌿',
    9: '☕ Don’t skip breakfast! A nutritious start helps keep your heart and sodium levels in check',
    13: '🥦 Take a moment for a balanced meal — your heart deserves care this afternoon.',
    17: '☕ Snack time — have something light!',
    19: '🌙 Dinner time! Enjoy a light, heart-healthy meal to end your day strong.',
  };

  // Hours to skip
  final List<int> skipHours = [6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24];

  for (int hour = 6; hour < 24; hour++) {

    if (skipHours.contains(hour)) {
      developer.log("Skipped hour: $hour");
      return;
      //continue; // skip scheduling for this hour
    }

    final next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
    );

    final scheduleTime = next.isBefore(now)
        ? next.add(const Duration(days: 1))
        : next;

    final title = customTitle[hour] ?? 'Heart Thrive reminder!';
    final message = customMessage[hour] ?? getTimeBasedWishMessage(hour);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      hour,
      title,
      message,
      scheduleTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'hourly_channel',
          'Hourly Notifications',
          channelDescription: 'Notifications every hour between 6 AM – 11 PM',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    developer.log("Scheduled: ${scheduleTime.toLocal()} -> $message");
  }
}

String getTimeBasedWishMessage(int hour) {
  String wishMsg;

  if (hour >= 5 && hour < 12) {
    wishMsg = "Good morning!,";
  } else if (hour >= 12 && hour < 17) {
    wishMsg = "Good afternoon!,";
  } else if (hour >= 17 && hour < 21) {
    wishMsg = "Good evening!,";
  } else {
    wishMsg = "Good night!";
  }

  return "$wishMsg Update your daily weight, review your meal plan, and stay on track with your medicines. You’ve got this!";
}

/// For instant test notification
Future<void> showNotificationNow(String title, String body) async {
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'instant_channel',
      'Instant Notification',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''), // 👈 This enables full text display
    ),
    iOS: DarwinNotificationDetails(),
  );

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title,
    body,
    details,
  );
}

Future<void> setupIOSForegroundPresentation() async {
    if (Platform.isIOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    if (Platform.isAndroid) {
      initFCMForeGroundNotifications();
    }
}



//
StreamSubscription<RemoteMessage>? _fcmSub;

Future<void> initFCMForeGroundNotifications() async {
  _fcmSub?.cancel(); // prevent duplicates

  _fcmSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      showNotificationNow(
        notification.title ?? '',
        notification.body ?? '',
      );
    }
  });
}

