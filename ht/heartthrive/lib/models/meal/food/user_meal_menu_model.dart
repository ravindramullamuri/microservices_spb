import 'nutrients_model.dart';
// Data
class MealMenuResponse {
  final List<MealMenu> content;

  MealMenuResponse({required this.content});

  factory MealMenuResponse.fromJson(Map<String, dynamic> json) {
    return MealMenuResponse(
      content: (json['content'] as List? ?? [])
          .map((e) => MealMenu.fromJson(e))
          .toList(),
    );
  }
}

class MealMenu {
  final int id;
  final String name;
  final String latestQuantity;
  final MealType mealType;
  final FoodItemWithNutrients food;

  MealMenu({
    required this.id,
    required this.name,
    required this.latestQuantity,
    required this.mealType,
    required this.food,
  });

  factory MealMenu.fromJson(Map<String, dynamic> json) {
    return MealMenu(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      latestQuantity: json['latestQuantity'] ?? '',
      mealType: MealType.fromJson(json['mealType'] ?? {}),
      food: FoodItemWithNutrients.fromJson(
        json['latestFoodItemWithNutrients'] ?? {},
      ),
    );
  }
}

class MealType {
  final int id;
  final String name;

  MealType({
    required this.id,
    required this.name,
  });

  factory MealType.fromJson(Map<String, dynamic> json) {
    return MealType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class FoodItemWithNutrients {
  final int id;
  final String uuid;
  final int fdcId;
  final String description;
  final String brandName;
  final double servingSize;
  final String servingUnit;
  final List<Nutrients> nutrients;

  FoodItemWithNutrients({
    required this.id,
    required this.uuid,
    required this.fdcId,
    required this.description,
    required this.brandName,
    required this.servingSize,
    required this.servingUnit,
    required this.nutrients,
  });

  factory FoodItemWithNutrients.fromJson(Map<String, dynamic> json) {
    return FoodItemWithNutrients(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      fdcId: (json['fdcId'] as num?)?.toInt() ?? 0,   // ✅ SAFE
      description: json['description'] ?? '',
      brandName: json['brandName'] ?? '',
      servingSize: (json['servingSize'] as num?)?.toDouble() ?? 0.0, // ✅ FIX
      servingUnit: json['servingUnit'] ?? '',
      nutrients: (json['nutrients'] as List? ?? [])
          .map((e) => Nutrients.fromJson(e))
          .toList(),
    );
  }
}







