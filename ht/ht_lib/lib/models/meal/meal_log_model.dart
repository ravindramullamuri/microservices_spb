import 'meal_type_model.dart';
import 'food_item_with_nutrients.dart';
import 'actual_nutrient_intake.dart';

class MealLogModel {
  final int id;
  final String uuid;
  final String logDate;
  final String quantity;
  final MealTypeModel mealType;
  final FoodItemWithNutrients foodItemWithNutrients;
  final List<ActualNutrientIntake> actualNutrientIntakes;

  MealLogModel({
    required this.id,
    required this.uuid,
    required this.logDate,
    required this.quantity,
    required this.mealType,
    required this.foodItemWithNutrients,
    required this.actualNutrientIntakes,
  });

  factory MealLogModel.fromJson(Map<String, dynamic> json) {
    return MealLogModel(
      id: json['id'],
      uuid: json['uuid'] ?? '',
      logDate: json['logDate'] ?? '',
      quantity: json['quantity'] ?? '',
      mealType: MealTypeModel.fromJson(json['mealType']),
      foodItemWithNutrients:
          FoodItemWithNutrients.fromJson(json['foodItemWithNutrients']),
      actualNutrientIntakes: (json['actualNutrientIntakes'] as List<dynamic>)
          .map((e) => ActualNutrientIntake.fromJson(e))
          .toList(),
    );
  }
}
