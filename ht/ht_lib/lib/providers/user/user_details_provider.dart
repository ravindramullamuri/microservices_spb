import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/models/userdetails.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth_service.dart';
import '../../utils/secure_storage_utils.dart';

final authServiceProvider = Provider((ref) => AuthService());


class UserDetailsNotifier extends StateNotifier<AsyncValue<UserDetails?>> {
  final AuthService _service;

  UserDetailsNotifier(this._service) : super(const AsyncValue.loading());

  Future<void> loadUser({String? token}) async {
    try {
      //final accessToken = await SecureStorageUtils().read(StorageKeys.accessToken);
      state = const AsyncValue.loading();
      final user = await AuthService.fetchUserDetails(token: token);
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('userId',user!.id.toString());
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final userDetailsDataProvider =
StateNotifierProvider<UserDetailsNotifier, AsyncValue<UserDetails?>>((ref) {
  final service = ref.read(authServiceProvider);
  return UserDetailsNotifier(service);
});
