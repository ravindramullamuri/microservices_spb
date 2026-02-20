import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

final internetStatusProvider = StreamProvider<InternetStatus>((ref) {
  return InternetConnection().onStatusChange;
});
final isOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(internetStatusProvider).value;
  return status == InternetStatus.connected;
});
