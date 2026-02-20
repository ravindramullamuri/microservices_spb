import 'nutrients_model.dart';
class MealType {
  final int id;
  final String uuid;
  final String name;
  final String description;
  final bool active;

  MealType({
    required this.id,
    required this.uuid,
    required this.name,
    required this.description,
    required this.active,
  });

  factory MealType.fromJson(Map<String, dynamic> json) {
    return MealType(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      active: json['active'] ?? false,
    );
  }
}
class MealTypeNutrientSummary {
  final MealType mealType;
  final List<Nutrients> nutrients;

  MealTypeNutrientSummary({
    required this.mealType,
    required this.nutrients,
  });

  factory MealTypeNutrientSummary.fromJson(Map<String, dynamic> json) {
    return MealTypeNutrientSummary(
      mealType: MealType.fromJson(json['mealType']),
      nutrients: (json['nutrients'] as List<dynamic>)
          .map((e) => Nutrients.fromJson(e))
          .toList(),
    );
  }
}
class NutrientSummaryResponse {
  final List<MealTypeNutrientSummary> summaries;

  NutrientSummaryResponse({required this.summaries});

  factory NutrientSummaryResponse.fromJson(Map<String, dynamic> json) {
    return NutrientSummaryResponse(
      summaries: (json['mealTypeNutrientSummaries'] as List<dynamic>)
          .map((e) => MealTypeNutrientSummary.fromJson(e))
          .toList(),
    );
  }
}

