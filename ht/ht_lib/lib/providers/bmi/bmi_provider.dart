// providers/weight_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/bmi/weight_height_model.dart';
import '../../services/auth_service.dart';
import '../../services/bmi/bmi_api.dart';
import '../../utils/secure_storage_utils.dart';

// Timezone
final timeZoneProvider = StateProvider<String?>((ref) => null);

// Provider to access AuthManager
final authManagerProvider = Provider<AuthManager>((ref) => AuthManager(ref));
// ---------------------------------------------------------------------
// 1. Token (unchanged)

// providers/auth_providers.dart





// 2. API Service (unchanged)
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref);
});

// ---------------------------------------------------------------------
// 3. Create / Update Notifier – **FIXED: Now emits success/error states**
class WeightLogNotifier extends StateNotifier<AsyncValue<String>> {
  WeightLogNotifier(this.ref) : super(AsyncValue.data('idle'));

  final Ref ref;

  Future<void> createOrUpdate(WeightHeightLog log, {bool isUpdate = false}) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(apiServiceProvider);
      if (log.id != null) {
        await api.update(log);               // expects 200
      } else {
        await api.create(log);               // expects 201
      }

      // ✅ SUCCESS: Invalidate providers AND emit success state
      ref.invalidate(heroDashboardProvider);
      ref.invalidate(currentAndPastProvider);

      state = const AsyncValue.data('success');    // ← This triggers UI rebuild

      // Auto-reset to idle after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) state = const AsyncValue.data('idle');
      });

    } catch (e, st) {
      state = AsyncValue.error(e, st);       // ← This shows error in UI
    }
  }
}

final weightLogNotifierProvider =
StateNotifierProvider<WeightLogNotifier, AsyncValue<String>>((ref) {
  return WeightLogNotifier(ref);
});

// ---------------------------------------------------------------------
// 4. Hero Dashboard (unchanged)
final heroDashboardProvider = FutureProvider.autoDispose<BmiResponse>((ref) async {
  return ref.read(apiServiceProvider).heroDashboard();
});

// ---------------------------------------------------------------------
// 5. Current + Past (unchanged)
final currentAndPastProvider = FutureProvider.autoDispose<CurrentAndPastData>((ref) async {
  return ref.read(apiServiceProvider).currentAndPast();
});