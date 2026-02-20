// -----------------------------------------------------------------------------
//  main.dart – Heart Thrive (Optimized Single File)
// -----------------------------------------------------------------------------
//  Responsibilities:
//   ✅ App bootstrap & initialization
//   ✅ Token validation & refresh
//   ✅ Firebase & notifications
//   ✅ Timezone + TimeMachine
//   ✅ Riverpod container setup
//   ✅ Token-based routing
// -----------------------------------------------------------------------------

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/pages/home_page.dart';
import 'package:heart_thrive/pages/landing_page.dart';
import 'package:heart_thrive/utils/app_life_cycle_observer.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:time_machine2/time_machine2.dart';
import 'package:workmanager/workmanager.dart';

// --------------------- APP IMPORTS ---------------------
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

import 'providers/token_provider.dart';
import 'providers/user/user_details_provider.dart';
import 'providers/bmi/bmi_provider.dart';

import 'services/auth_service.dart';
import 'services/user_service.dart';

import 'utils/secure_storage_utils.dart';
import 'utils/token_scheduler.dart';
import 'utils/notification/background_service.dart';
import 'utils/notification/notification_service.dart';

// -----------------------------------------------------------------------------
//  Globals
// -----------------------------------------------------------------------------
final RouteObserver<ModalRoute<void>> routeObserver =
RouteObserver<ModalRoute<void>>();

// Allow self-signed certificates (DEV only)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (_, __, ___) => true;
  }
}

// -----------------------------------------------------------------------------
//  MAIN
// -----------------------------------------------------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fast parallel startup (non-blocking UI)
  await Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    TimeMachine.initialize({'rootBundle': rootBundle}),
    TokenScheduler().schedule(),
  ]);

  if (!kIsWeb) {
    HttpOverrides.global = MyHttpOverrides();
  }

  final container = ProviderContainer();

  // Bootstrap everything & resolve initial token
  final initialToken = await _bootstrap(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: HeartThriveApp(initialToken: initialToken),
    ),
  );
}

// -----------------------------------------------------------------------------
//  BOOTSTRAP (Single Source of Truth)
// -----------------------------------------------------------------------------
Future<String?> _bootstrap(ProviderContainer container) async {
  WidgetsBinding.instance.addObserver(AppLifecycleObserver());
  await _initFirebase();
  await _initNotifications();
  await _initTimezone(container);
  await UserService.initializeUser();

  final storage = SecureStorageUtils();
  String? token = await storage.read("auth_token");

  if (token == null) return null;

  // Refresh token if expired
  if (JwtDecoder.isExpired(token)) {
    try {

      await AuthService.refreshToken();
      token = await storage.read("auth_token");

      if (token == null || JwtDecoder.isExpired(token)) {
        await storage.delete("auth_token");
        return null;
      }
    } catch (_) {
      await storage.delete("auth_token");
      return null;
    }
  }

  container.read(tokenProvider.notifier).setToken(token);
  return token;
}

// -----------------------------------------------------------------------------
//  FIREBASE
// -----------------------------------------------------------------------------
Future<void> _initFirebase() async {
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

// -----------------------------------------------------------------------------
//  NOTIFICATIONS
// -----------------------------------------------------------------------------
Future<void> _initNotifications() async {
  //await Workmanager().initialize(callbackDispatcher);
  await configureLocalTimeZone();
  await initNotifications();
  await FirebaseMessaging.instance.requestPermission();
  await requestPermissions();
  // Schedule hourly notifications
  //await scheduleHourlyNotifications();
  // Reschedule them daily at midnight
  //await registerDailyRescheduler();
  setupIOSForegroundPresentation();
}

// -----------------------------------------------------------------------------
//  TIMEZONE
// -----------------------------------------------------------------------------
Future<void> _initTimezone(ProviderContainer container) async {
  try {
    final timezone = await FlutterTimezone.getLocalTimezone();
    container.read(timeZoneProvider.notifier).state = timezone.identifier;
    if (kDebugMode) debugPrint("Timezone: $timezone");
  } catch (e) {
    if (kDebugMode) debugPrint("Timezone error: $e");
  }
}
// -----------------------------------------------------------------------------
//  MyApp – Root Widget
// -----------------------------------------------------------------------------

class HeartThriveApp extends StatelessWidget {
  final String? initialToken;

  const HeartThriveApp({super.key, this.initialToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Heart Thrive',
      theme: AppTheme.themeData,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },
      home: MyApp(initialToken: initialToken),
      onGenerateRoute: AppRouter.generateRoute,
      navigatorObservers: [routeObserver],
    );
  }
}

class MyApp extends ConsumerStatefulWidget {
  final String? initialToken;

  const MyApp({super.key, this.initialToken});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {

  @override
  void initState() {
    super.initState();

    final token = widget.initialToken;
    if (token != null) {
      Future.microtask(() {
        ref
            .read(userDetailsDataProvider.notifier)
            .loadUser(token: token);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.initialToken != null
        ? MainPage()
        : LandingPage();
  }
}

/*class MyApp extends ConsumerWidget {
  final String? initialToken;

  const MyApp({super.key, this.initialToken});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = initialToken;

    if (token != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(userDetailsDataProvider.notifier).loadUser(token: token);
      });
    }

    return MediaQuery(
      data: MediaQueryData.fromView(View.of(context))
          .copyWith(textScaler: const TextScaler.linear(1.0)),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Heart Thrive',
        theme: AppTheme.themeData,
        initialRoute:
        token != null ? AppRouter.home : AppRouter.landing,
        onGenerateRoute: AppRouter.generateRoute,
        navigatorObservers: [routeObserver],
      ),
    );
  }
}*/



