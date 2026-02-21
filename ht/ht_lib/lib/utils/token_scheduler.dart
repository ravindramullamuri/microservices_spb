import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:heart_thrive/services/auth_service.dart';
import 'package:heart_thrive/utils/secure_storage_utils.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class TokenScheduler {
  static final TokenScheduler _instance = TokenScheduler._internal();
  factory TokenScheduler() => _instance;
  TokenScheduler._internal();

  Timer? _timer;
  bool _refreshing = false;

  /// Call after LOGIN and after REFRESH
  Future<void> schedule() async {
    debugPrint("Schedule Called @@@@@ start");
    _timer?.cancel();
    final secureStorageUtils=SecureStorageUtils();

    final accessToken = await secureStorageUtils.read(StorageKeys.accessToken);
    if (accessToken == null) {
      _triggerRefresh();
      return;
    }

    final expiry = JwtDecoder.getExpirationDate(accessToken);
    final triggerTime = expiry.subtract(const Duration(minutes: 10));
    debugPrint("triggerTime @@@ $triggerTime}");

    final now = DateTime.now();
    if (triggerTime.isBefore(now)) {
      // already close to expiry → refresh immediately
      await _triggerRefresh();
      return;
    }

    final duration = triggerTime.difference(now);

    _timer = Timer(duration, _triggerRefresh);
  }

  Future<void> _triggerRefresh() async {
    debugPrint("TriggerRefresh Called @@@@@ start");
    if (_refreshing) return;

    try {
      _refreshing = true;
      await AuthService.refreshToken(); // YOUR EXISTING API
      await schedule(); // 🔁 re-schedule using NEW token
    } catch (_) {

     // await logout(); // refresh token expired
    } finally {
      _refreshing = false;
    }
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
