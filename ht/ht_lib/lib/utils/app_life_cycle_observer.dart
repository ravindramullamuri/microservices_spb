import 'package:flutter/widgets.dart';
import 'package:heart_thrive/utils/token_scheduler.dart';

class AppLifecycleObserver extends WidgetsBindingObserver {
  static final AppLifecycleObserver _instance =
  AppLifecycleObserver._internal();

  factory AppLifecycleObserver() => _instance;

  AppLifecycleObserver._internal();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
      // App reopened / foreground
        _onAppResumed();
        break;

      case AppLifecycleState.paused:
      // App minimized / background
        _onAppPaused();
        break;

      case AppLifecycleState.inactive:
        _onAppDetached();
      // Temporary interruption
        break;

      case AppLifecycleState.detached:
        _onAppDetached();
      // App closed
        break;
      case AppLifecycleState.hidden:
        // TODO: Handle this case.
        _onAppDetached();
        break;
    }
  }

  void _onAppResumed() {
    // ✅ Global logic here
    // Example: refresh token, revalidate session, reload API
    TokenScheduler().schedule();
    debugPrint('App Resumed');
  }

  void _onAppPaused() {
    // ✅ Save state, stop timers, etc.
    debugPrint('App Paused');
  }
  void _onAppDetached() {
    // ✅ Save state, stop timers, etc.
    debugPrint('App Closed or InActive');
  }
}
