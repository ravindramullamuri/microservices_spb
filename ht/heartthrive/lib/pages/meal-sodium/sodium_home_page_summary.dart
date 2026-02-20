import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/components/ui_components.dart';
import 'package:heart_thrive/pages/meal-sodium/user_today_food.dart';
import 'package:heart_thrive/routes/app_router.dart';

import '../../constants/ui_constants.dart';
import '../../models/meal/food/meal_nutrient_summary.dart';
import '../../models/meal/food/nutrients_model.dart';
import '../../providers/meal/meal_sodium_provider.dart';
import '../../theme/app_theme.dart';

// toggle of less & more info
final showMoreInfoProvider = StateProvider<bool>((ref) => false);

class SodiumHomePageSummary extends ConsumerStatefulWidget {
  const SodiumHomePageSummary({super.key});

  @override
  ConsumerState<SodiumHomePageSummary> createState() =>
      _SodiumHomePageSummaryState();
}

class _SodiumHomePageSummaryState extends ConsumerState<SodiumHomePageSummary> {
  //bool _showMoreInfo = false;

  // -------------------------------------------------------------
  // Get sodium consumed for a given meal safely
  // -------------------------------------------------------------
  double _getMealSodium(NutrientSummaryResponse response, String mealName) {
    final meal = response.summaries.firstWhere(
          (e) => e.mealType.name.toLowerCase() == mealName.toLowerCase(),
      orElse: () => MealTypeNutrientSummary(
        mealType: MealType(
          id: 0,
          uuid: '',
          name: mealName,
          description: '',
          active: false,
        ),
        nutrients: const [],
      ),
    );

    final sodium = meal.nutrients.firstWhere(
          (n) => n.name.toLowerCase() == 'sodium',
      orElse: () => Nutrients(
        name: 'Sodium',
        amount: 0,
        minValue: 0,
        maxValue: 0,
        unitName: 'mg',
      ),
    );

    return sodium.amount;
  }

  Widget _mealTab(
      NutrientSummaryResponse response,
      String meal,
      int target,
      Color color,
      ) {
    return MealProgressTab(
      title: meal,
      consumed: _getMealSodium(response, meal),
      target: target,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(todayNutrientProvider, (previous, next) {
      if (next.hasValue) {
        ref.invalidate(nutrientSummaryByMealTypeProvider);
      }
    });
    final nutrientAsync = ref.watch(todayNutrientProvider);
    final mealSummaryAsync = ref.watch(nutrientSummaryByMealTypeProvider);
    final showMoreInfo = ref.watch(showMoreInfoProvider);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= HEADER + SUMMARY GROUP =================
          buildWrapperInkWell(
            context,
                () {
              final route = MaterialPageRoute(
                builder: (BuildContext context) {
                  return MealLogsPage();
                },
              );

              Navigator.push(context, route);
            },
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -------- Header --------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      headerTitle(context, "Sodium (mg)"),
                      buildAddNewButton(context, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MealLogsPage()),
                        );
                      }),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // -------- Overall Summary --------
                  nutrientAsync.when(
                    loading: () => const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => SodiumNutrientSummary(nutrients: []),
                    data: (nutrients) =>
                        SodiumNutrientSummary(nutrients: nutrients),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ---------------- More / Less Toggle ----------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildLessAndMoreInfoButton(
                context,
                showMoreInfo: showMoreInfo,
                onTap: () {
                  ref.read(showMoreInfoProvider.notifier).state = !showMoreInfo;
                },
              ),
              buildDashboardButton(context, () {
                AppRouter.navigateToSodiumIntakeOverview(context);
              }),
            ],
          ),

          // ---------------- Meal-wise Summary ----------------
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: showMoreInfo
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: mealSummaryAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
              error: (e, _) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MealProgressTab(
                        consumed: 0,
                        title: "Breakfast",
                        target: 700,
                        color: Colors.orange,
                      ),
                      MealProgressTab(
                        consumed: 0,
                        title: "Lunch",
                        target: 700,
                        color: Colors.blue,
                      ),
                      MealProgressTab(
                        consumed: 0,
                        title: "Snacks",
                        target: 400,
                        color: Colors.purple,
                      ),
                      MealProgressTab(
                        consumed: 0,
                        title: "Dinner",
                        target: 400,
                        color: Colors.indigo,
                      ),
                    ],
                  ),
                );
              },
              data: (summary) {
                if (summary.summaries.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "No meal-wise sodium data available",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _mealTab(summary, "Breakfast", 700, Colors.orange),
                      _mealTab(summary, "Lunch", 700, Colors.blue),
                      _mealTab(summary, "Snacks", 400, Colors.purple),
                      _mealTab(summary, "Dinner", 700, Colors.indigo),
                    ],
                  ),
                );
              },
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class SodiumNutrientSummary extends StatelessWidget {
  final List<Nutrients> nutrients;
  const SodiumNutrientSummary({super.key, required this.nutrients});

  double _getAmount(String name) {
    return nutrients
        .firstWhere(
          (e) => e.name.toLowerCase() == name.toLowerCase(),
      orElse: () => Nutrients(
        name: name,
        amount: 0,
        minValue: 0,
        maxValue: 0,
        unitName: 'mg',
      ),
    )
        .amount;
  }

  @override
  Widget build(BuildContext context) {
    const double target = 2500;
    final consumed = _getAmount('Sodium');
    final double progress = (consumed / target).clamp(0, 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _InfoColumn(
          value: "${consumed.toStringAsFixed(2)} mg",
          label: "Consumed",
        ),
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation(
                      AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                consumed > target
                    ? "${(consumed - target).toStringAsFixed(2)} mg \nlimit exceeded"
                    : "${(target - consumed).toStringAsFixed(2)} mg left",
                style: TextStyle(
                  fontSize: deviceWidth(context) > 750 ? 16 : 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const _InfoColumn(value: "2,500 mg", label: "Target"),
      ],
    );
  }
}

class MealProgressTab extends StatelessWidget {
  final String title;
  final double consumed;
  final int target;
  final Color color;

  const MealProgressTab({
    super.key,
    required this.title,
    required this.consumed,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = target == 0 ? 0 : (consumed / target).clamp(0, 1);

    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: deviceWidth(context) > 750 ? 18 : 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: deviceWidth(context) > 750 ? 150 : 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "${consumed.toStringAsFixed(2)} / $target",
          style: TextStyle(
            fontSize: deviceWidth(context) > 750 ? 18 : 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String value;
  final String label;

  const _InfoColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: deviceWidth(context) > 750 ? 18 : 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (label.isNotEmpty)
          Text(
            label,
            style: TextStyle(
              fontSize: deviceWidth(context) > 750 ? 16 : 12,
              color: Colors.grey.shade600,
            ),
          ),
      ],
    );
  }
}
