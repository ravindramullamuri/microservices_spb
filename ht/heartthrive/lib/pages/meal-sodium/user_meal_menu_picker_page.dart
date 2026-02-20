import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import 'package:heart_thrive/utils/error_response.dart';
import '../../constants/heart_thrive_strings_constants.dart';
import '../../models/meal/edit_meal_model.dart';
import '../../models/meal/food/nutrients_model.dart';
import '../../models/meal/food/user_meal_menu_model.dart';
import '../../providers/internet_provider.dart';
import '../../providers/meal/meal_sodium_provider.dart';
import '../../routes/app_router.dart';
import '../../services/meal_services.dart';
import '../../theme/app_theme.dart';


class MealListScreen extends ConsumerStatefulWidget {
  const MealListScreen({super.key});

  @override
  ConsumerState<MealListScreen> createState() => _MealListScreenState();
}

class _MealListScreenState extends ConsumerState<MealListScreen> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    final mealsAsync = ref.watch(mealsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Column(
          children: [
            // 🔍 Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: TextField(
                  decoration:  InputDecoration(
                    hintText: 'Food or Meal',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    hintStyle: AppTheme.title14.copyWith(fontWeight: FontWeight.normal),
                    prefixIcon: const Icon(Icons.search, size: 26, color: Colors.black54),
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(40.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(40.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(40.0)),
                      borderSide: BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                  onChanged: (v) =>
                      setState(() => search = v.toLowerCase()),
                ),
              ),
            ),

            Expanded(
              child: mealsAsync.when(
                data: (meals) {
                  final filtered = meals
                      .where((m) =>
                      m.name.toLowerCase().contains(search))
                      .toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyUI();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return MealCard(meal: filtered[index]);
                    },
                  );
                },
                loading: () =>
                const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    noDataUI(mapException(e).message),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Error Time UI
  Widget noDataUI(String ? message){
    final isOnline = ref.watch(isOnlineProvider);
    return SizedBox(
      width: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Text(
                  !isOnline?HeartThriveStrings.noInternet :message??HeartThriveStrings.noSodiumDashBoardTitle,
                  textAlign: TextAlign.center,
                  style: AppTheme.title16.copyWith(
                      fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  !isOnline?HeartThriveStrings.noInternetDescription :HeartThriveStrings.noSodiumDashBoardDescription,
                  textAlign: TextAlign.center,
                  style: AppTheme.body14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // No Data
  Widget _buildEmptyUI({int? index}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(HeartThriveStrings.noMealMenuSectionMsg, textAlign: TextAlign.center, style: AppTheme.title16),
            const SizedBox(height: 10),
            Image.asset("lib/assets/ss-removebg-preview 1.png", width: 200, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }

}

class MealCard extends StatelessWidget {
  final MealMenu meal;

  const MealCard({super.key, required this.meal});




  @override
  Widget build(BuildContext context) {
    //List<Nutrient> nutrients = meal.food!.nutrients!;
    final carbs = meal.food.nutrients.quantity('Carbohydrates');
    final protein = meal.food.nutrients.quantity('Protein');
    final fat = meal.food.nutrients.quantity('Fat');
    final sodium = meal.food.nutrients.quantity('Sodium');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Title + actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  meal.name.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:AppTheme.title20.copyWith(
                      fontSize: AppTheme.responsiveTitleFontSize(context)
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: deviceWidth(context)> 830? 40:25,
                height: deviceWidth(context)> 830? 40:25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryColor, width: 1),
                ),
                child: Center(
                  child: Image.asset(
                    _getImageOfMealType(index: meal.mealType.id),
                    height: deviceWidth(context)> 830?30:15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _circleIcon(Icons.add, filled: true,onPressed: () async {
                final result =
                await AppRouter.navigateToAddMeal(context,
                  editData: MealEditData(
                    id: meal.id,
                    name: meal.food.description,
                    quantity: meal.food.servingSize.toString(),
                    servingUnit: meal.food.servingUnit,
                    calories: meal.food.nutrients.quantity("Calories"),
                    sodium: sodium,
                    carbs: carbs,
                    protein: protein,
                    fats: meal.food.nutrients.quantity("Fat"),
                    mealTypeId: meal.mealType.id,
                  ),);
              },context: context),

              const SizedBox(width: 8),
              Consumer(
                builder: (context, ref, _) {
                  return _circleIcon(Icons.delete, filled: true,onPressed: (){
                    _showDeleteMealLogDialog(
                        context,
                        meal.id,
                        meal.food.description,
                        ref
                    );
                  },context: context);
                },
              ),
            ],
          ),

          const SizedBox(height: 6),

          // 🔹 Sodium
          Text(
            'Sodium ${sodium.toStringAsFixed(2)} mg',
            style: AppTheme.body16.copyWith(
              fontSize: AppTheme.responsiveParaFontSize(context)
            ),
          ),

          const Divider(height: 20),

          // 🔹 Macros
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _macroDot(
                  color: Colors.orange,
                  label: 'Carbs ${carbs.toStringAsFixed(2)}g',
                  context: context
              ),
              _macroDot(
                  color: Colors.blue,
                  label:
                  'Proteins ${protein.toStringAsFixed(2)}g',
                  context: context
              ),
              _macroDot(
                  color: Colors.yellow.shade700,
                  label: 'Fats ${fat.toStringAsFixed(2)}g',
                  context: context
              ),
            ],
          ),
        ],
      ),
    );
  }


  //
  String _getImageOfMealType({int? index}) {
    switch (index) {
      case 21:
        return "lib/assets/breakfast.png";
      case 22:
        return "lib/assets/Lunch.png";
      case 23:
        return "lib/assets/snacks.png";
      case 24:
        return "lib/assets/dinner.png";
      default:
        return "lib/assets/All Meal.png";
    }
  }

  Widget _circleIcon(
      IconData icon, {
        bool filled = false,
        VoidCallback? onPressed,
        required BuildContext context
      }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: deviceWidth(context)> 830?40:28,
        height: deviceWidth(context)> 830?40:28,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF8B0000) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF8B0000)),
        ),
        child: Icon(
          icon,
          size: deviceWidth(context)> 830?28:16,
          color: filled ? Colors.white : const Color(0xFF8B0000),
        ),
      ),
    );
  }

  void _showDeleteMealLogDialog(
      BuildContext context,
      int mealLogId,
      String mealName,
      ref
      ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: AppTheme.primaryColor,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Are you sure you want to delete "$mealName"?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                            isDeleting ? null : () => Navigator.pop(dialogContext),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isDeleting
                                ? null
                                : () async {
                              setState(() => isDeleting = true);

                              final bool success = await MealService.deleteMealMenu(mealLogId);

                              if (success) {
                                Navigator.pop(dialogContext);

                                // ✅ RIVERPOD REFRESH (THIS IS THE FIX)
                                ref.read(mealsProvider.notifier).deleteMeal(mealLogId);
                                _showMealDeletedSuccess(context, mealName,ref);
                              } else {
                                setState(() => isDeleting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to delete meal.'),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                            ),
                            child: isDeleting
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text('Delete'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Delete Success Message
  void _showMealDeletedSuccess(BuildContext context, String mealName,ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  child: Image.asset(
                    'lib/assets/Check Mark.png',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '"$mealName" deleted successfully!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6F6C90)
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      //_refreshMealRelatedProviders(ref);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('OK',style: AppTheme.whiteTitle14,),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _macroDot(
      {required Color color, required String label,required BuildContext context}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
          BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTheme.body16.copyWith(
            fontSize: AppTheme.responsiveParaFontSize(context),
          ),
        ),
      ],
    );
  }
}

extension NutrientUtils on List<Nutrients> {
  String nutrientValueOf(String name) {
    final n = firstWhere(
          (e) => e.name.toLowerCase() == name.toLowerCase(),
      orElse: () => Nutrients(
        name: '',
        amount: 0,
        unitName: '',
        minValue: 0,
        maxValue: 0,
      ),
    );
    return '${n.amount.toStringAsFixed(1)}${n.unitName}';
  }

  double quantity(String name) {
    final n = firstWhere(
          (e) => e.name.toLowerCase() == name.toLowerCase(),
      orElse: () => Nutrients(
        name: '',
        amount: 0,
        unitName: '',
        minValue: 0,
        maxValue: 0,
      ),
    );
    return n.amount;
  }
}




