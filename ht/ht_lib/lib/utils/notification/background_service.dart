// lib/services/background_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';
import 'dart:developer' as developer;

const String dailyRescheduleTask = "dailyRescheduleTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    developer.log("Background task executed: $task");

    if (task == dailyRescheduleTask) {
      await configureLocalTimeZone();
      await initNotifications();
      //await scheduleHourlyNotifications();
      developer.log("Rescheduled hourly notifications for the new day.");
    }

    return Future.value(true);
  });
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("Handling background message: ${message.messageId}");
    print('Message data: ${message.data}');
    print('Message notification: ${message.notification?.title}');
    print('Message notification: ${message.notification?.body}');
  }
  // You can add custom logic here, e.g., show local notification if needed
}

/// Register daily background task
Future<void> registerDailyRescheduler() async {
  await Workmanager().cancelByUniqueName(dailyRescheduleTask);
  await Workmanager().registerPeriodicTask(
    dailyRescheduleTask,
    dailyRescheduleTask,
    frequency: const Duration(hours: 24),
    constraints: Constraints(
      networkType: NetworkType.notRequired,
    ),
  );
  developer.log("Daily rescheduler registered.");
}
