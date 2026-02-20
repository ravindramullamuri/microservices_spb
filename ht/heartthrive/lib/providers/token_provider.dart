// 1. Token (unchanged)

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/secure_storage_utils.dart';

final tokenFutureProvider = FutureProvider<String?>((ref) async {
  // Add dependency

  final storage = SecureStorageUtils();
  final token = await storage.read("auth_token");
  return token;
});

final tokenProviderOld = StateProvider<String>((ref) {
  final asyncToken = ref.watch(tokenFutureProvider);
  return asyncToken.when(
    data: (t) => t ?? (throw Exception('No token – please login')),
    loading: () => throw const _TokenLoading(),
    error: (_, __) => throw Exception('Failed to read token'),
  );
});

class _TokenLoading implements Exception {
  const _TokenLoading();
}

final tokenProvider = NotifierProvider<TokenNotifier, String?>(TokenNotifier.new);

class TokenNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setToken(String token) => state = token;

  void clear() => state = null;
}



