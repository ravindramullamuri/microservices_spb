import '../../pages/meal-sodium/sodium_dashboard/sodium_dashboard_page.dart';

class MealLogResponse {
  final List<MealLog> content;
  final int totalElements;
  final int totalPages;
  final bool last;
  final bool first;
  final int size;
  final int number;
  final int numberOfElements;

  MealLogResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.last,
    required this.first,
    required this.size,
    required this.number,
    required this.numberOfElements,
  });

  factory MealLogResponse.fromJson(Map<String, dynamic> json) {
    return MealLogResponse(
      content: (json['content'] as List<dynamic>)
          .map((e) => MealLog.fromJson(e))
          .toList(),
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
      last: json['last'] ?? true,
      first: json['first'] ?? true,
      size: json['size'] ?? 20,
      number: json['number'] ?? 0,
      numberOfElements: json['numberOfElements'] ?? 0,
    );
  }
}
class MealLog {
  final int id;
  final String uuid;
  final String logDate;
  final String quantity;
  final MealType mealType;
  final FoodItemWithNutrients foodItem;
  final List<ActualNutrientIntake> actualIntakes;

  MealLog({
    required this.id,
    required this.uuid,
    required this.logDate,
    required this.quantity,
    required this.mealType,
    required this.foodItem,
    required this.actualIntakes,
  });

  factory MealLog.fromJson(Map<String, dynamic> json) {
    return MealLog(
      id: json['id'],
      uuid: json['uuid'],
      logDate: json['logDate'],
      quantity: json['quantity'],
      mealType: MealType.fromJson(json['mealType']),
      foodItem: FoodItemWithNutrients.fromJson(json['foodItemWithNutrients']),
      actualIntakes: (json['actualNutrientIntakes'] as List<dynamic>)
          .map((i) => ActualNutrientIntake.fromJson(i))
          .toList(),
    );
  }
}
class MealType {
  final int id;
  final String? name;

  MealType({
    required this.id,
    this.name,
  });

  factory MealType.fromJson(Map<String, dynamic> json) {
    return MealType(
      id: json['id'],
      name: json['name'],
    );
  }
}
class FoodItemWithNutrients {
  final int id;
  final String uuid;
  final String description;
  final String brandName;
  final double servingSize;
  final String servingUnit;
  final List<Nutrient> nutrients;

  FoodItemWithNutrients({
    required this.id,
    required this.uuid,
    required this.description,
    required this.brandName,
    required this.servingSize,
    required this.servingUnit,
    required this.nutrients,
  });

  factory FoodItemWithNutrients.fromJson(Map<String, dynamic> json) {
    return FoodItemWithNutrients(
      id: json['id'],
      uuid: json['uuid'],
      description: json['description'] ?? '',
      brandName: json['brandName'] ?? '',
      servingSize: (json['servingSize'] ?? 0).toDouble(),
      servingUnit: json['servingUnit'] ?? '',
      nutrients: (json['nutrients'] as List<dynamic>)
          .map((e) => Nutrient.fromJson(e))
          .toList(),
    );
  }
}

class ActualNutrientIntake {
  final int id;
  final String nutrientName;
  final double quantity;
  final String unitType;

  ActualNutrientIntake({
    required this.id,
    required this.nutrientName,
    required this.quantity,
    required this.unitType,
  });

  factory ActualNutrientIntake.fromJson(Map<String, dynamic> json) {
    return ActualNutrientIntake(
      id: json['id'],
      nutrientName: json['nutrientName'],
      quantity: (json['quantity'] ?? 0).toDouble(),
      unitType: json['unitType'],
    );
  }
}
