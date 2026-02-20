import 'package:go_router/go_router.dart';
import '../pages/landing_page.dart';
import '../pages/home_page.dart';
import '../pages/meal-sodium/user_today_food.dart';
import '../pages/meal/add_meal_page.dart';
import '../models/meal/edit_meal_model.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LandingPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => MainPage(),
    ),
    GoRoute(
      path: '/all-meal-intake',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        return MealLogsPage(
          initialIndex: args?['tabIndex'],
          pageType: args?['pageType'],
        );
      },
    ),
    GoRoute(
      path: '/add-meal',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        return AddMealPage(
          editData: args?['editData'] as MealEditData?,
          isEditMode: args?['isEditMode'] ?? false,
          mealMenuMode: args?['mealMenuMode'] ?? false,
        );
      },
    ),
  ],
);
