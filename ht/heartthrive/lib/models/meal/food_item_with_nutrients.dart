import 'nutrient.dart';

class FoodItemWithNutrients {
  final int id;
  final String uuid;
  final int fdcId;
  final String description;
  final String? brandName;
  final double servingSize;
  final String servingUnit;
  final List<Nutrient> nutrients;

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
      id: json['id'],
      uuid: json['uuid'],
      fdcId: json['fdcId'],
      description: json['description'],
      brandName: json['brandName'],
      servingSize: (json['servingSize'] ?? 0).toDouble(),
      servingUnit: json['servingUnit'],
      nutrients: (json['nutrients'] as List<dynamic>)
          .map((e) => Nutrient.fromJson(e))
          .toList(),
    );
  }
}
