
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:heart_thrive/providers/token_provider.dart';
import 'package:intl/intl.dart';

import '../../models/meal/food/food_response_model.dart';
import '../../models/meal/food/meal_nutrient_summary.dart' hide Nutrient;
import '../../models/meal/food/nutrients_model.dart';
import '../../models/meal/food/user_meal_menu_model.dart';
import '../../services/meal/meal_services.dart';

final mealLogsProvider = StateNotifierProvider.autoDispose<MealLogsNotifier, AsyncValue<List<FoodLogEntry>>>(
      (ref) => MealLogsNotifier(),
);


class MealLogsNotifier extends StateNotifier<AsyncValue<List<FoodLogEntry>>> {
  MealLogsNotifier() : super(const AsyncLoading()) {
    loadInitialLogs();
  }

  int _page = 0;
  final int _size = 30;
  bool _isLast = false;
  bool _isFetchingMore = false;

  final List<FoodLogEntry> _logs = [];

  /// ---------------- INITIAL LOAD ----------------
  Future<void> loadInitialLogs() async {
    _page = 0;
    _isLast = false;
    _logs.clear();

    state = const AsyncLoading();

    try {
      final response = await SodiumMealServices().fetchMealLogs(page: _page, size: _size);

      _logs.addAll(response.content);
      _isLast = response.last ?? true;
      _page++;

      state = AsyncData(List.from(_logs));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// ---------------- LOAD MORE ----------------
  Future<void> loadMoreLogs() async {
    if (_isLast || _isFetchingMore) return;

    _isFetchingMore = true;

    try {
      final response = await SodiumMealServices().fetchMealLogs(page: _page, size: _size);

      _logs.addAll(response.content);
      _isLast = response.last ?? true;
      _page++;

      // ✅ IMPORTANT: emit AsyncData ONLY
      state = AsyncData(List.from(_logs));
    } catch (e, st) {
      // keep previous data visible
      state = AsyncError(e, st);
      state = AsyncData(List.from(_logs));
    } finally {
      _isFetchingMore = false;
    }
  }

  bool get isFetchingMore => _isFetchingMore;
}


// =======================
// RIVERPOD PROVIDERS
// =======================
final nutrientSummaryProvider = FutureProvider.autoDispose
    .family<List<Nutrients>, String>((ref, dateKey) async {
  final now = DateTime.now();
  final date = DateFormat('dd-MM-yyyy').format(now);
  final fromDate = '$date 00:00';
  final toDate = '$date 23:59';
  final timezone = await FlutterTimezone.getLocalTimezone();
  return await SodiumMealServices().fetchNutrientSummary(
    fromDate: fromDate,
    toDate: toDate,
    timezone: timezone.identifier,
  );
});

// Today's date key to trigger refresh if needed
final todayNutrientProvider = nutrientSummaryProvider(DateTime.now().toIso8601String());

// User Meal Menu provider
final mealApiProvider = Provider((ref) => SodiumMealServices());

final mealsProvider =
StateNotifierProvider<MealMenuNotifier, AsyncValue<List<MealMenu>>>(
      (ref) => MealMenuNotifier(ref),
);

class MealMenuNotifier extends StateNotifier<AsyncValue<List<MealMenu>>> {
  MealMenuNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadMeals();
  }

  final Ref ref;

  Future<void> loadMeals() async {
    try {
     // ref.invalidate(tokenProvider);
      final token = ref.watch(tokenProvider);
      final api = ref.read(mealApiProvider);

      final meals =
      await api.fetchMeals(page: 0, size: 10, token: token!);

      state = AsyncValue.data(meals);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 🔥 IMMEDIATE REMOVE + BACKGROUND REFRESH
  Future<void> deleteMeal(int mealId) async {
    final current = state.value ?? [];

    // 1️⃣ Optimistic UI update
    state = AsyncValue.data(
      current.where((m) => m.id != mealId).toList(),
    );

    // 2️⃣ Background network refresh
    await loadMeals();
  }
}

// Sodium Provider
final sodiumMealServiceProvider = Provider<SodiumMealServices>((ref) {
  return SodiumMealServices();
});

final nutrientSummaryByMealTypeProvider =
FutureProvider<NutrientSummaryResponse>((ref) async {
  final token = ref.watch(tokenProvider);
  final service = ref.read(sodiumMealServiceProvider);

  // Get today's date range
  final now = DateTime.now();
  final formatter = DateFormat('dd-MM-yyyy');

  final fromDate = '${formatter.format(now)} 00:00';
  final toDate = '${formatter.format(now)} 23:59';

  return service.fetchNutrientSummaryByMealType(
    token: token!,
    fromDate: fromDate,
    toDate: toDate,

  );
});



