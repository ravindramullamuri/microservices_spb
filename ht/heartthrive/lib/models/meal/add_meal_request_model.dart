class AddMealRequestModel {
  final int mealTypeId;
  final double quantity;
  final String unitType;
  final String logDate; // yyyy-MM-dd
  final String foodItemName;
  final String brandName;
  final int foodCategoryId;
  final int foodTypeId;

  final double sodiumAmount;
  final double caloriesAmount;
  final double carbsAmount;
  final double proteinAmount;
  final double fatsAmount;

  final bool addToMealMenu;

  AddMealRequestModel({
    required this.mealTypeId,
    required this.quantity,
    required this.unitType,
    required this.logDate,
    required this.foodItemName,
    required this.brandName,
    required this.foodCategoryId,
    required this.foodTypeId,
    required this.sodiumAmount,
    required this.caloriesAmount,
    required this.carbsAmount,
    required this.proteinAmount,
    required this.fatsAmount,
    required this.addToMealMenu,
  });

  Map<String, dynamic> toJson() {
    return {
      "mealTypeId": mealTypeId,
      "quantity": quantity,
      "unitType": unitType,
      "logDate": logDate,
      "foodItemName": foodItemName,
      "brandName": brandName,
      "foodCategoryId": foodCategoryId,
      "foodTypeId": foodTypeId,
      "sodiumAmount": sodiumAmount,
      "caloriesAmount": caloriesAmount,
      "carbsAmount": carbsAmount,
      "proteinAmount": proteinAmount,
      "fatsAmount": fatsAmount,
      "addToMealMenu": addToMealMenu,
    };
  }
}
