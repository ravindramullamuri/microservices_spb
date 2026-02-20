class MealEditData {
  final int id;
  final String name;
  final String quantity;
  final String? servingUnit;
  final double calories;
  final double sodium;
  final double carbs;
  final double protein;
  final double fats;
  final int? mealTypeId;
  bool? isCustom;

  MealEditData({
    required this.id,
    required this.name,
    required this.quantity,
    this.servingUnit,
    required this.calories,
    required this.sodium,
    required this.carbs,
    required this.protein,
    required this.fats,
    required this.mealTypeId,
    this.isCustom=false
  });
}
