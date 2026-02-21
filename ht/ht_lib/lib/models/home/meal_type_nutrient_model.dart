class MealTypeNutrientSummary {
  final List<MealTypeNutrientData> mealTypeNutrientSummaries;

  MealTypeNutrientSummary({
    required this.mealTypeNutrientSummaries,
  });

  factory MealTypeNutrientSummary.fromJson(Map<String, dynamic> json) {
    return MealTypeNutrientSummary(
      mealTypeNutrientSummaries: (json['mealTypeNutrientSummaries'] as List<dynamic>)
          .map((item) => MealTypeNutrientData.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mealTypeNutrientSummaries': mealTypeNutrientSummaries
          .map((item) => item.toJson())
          .toList(),
    };
  }
}

class MealTypeNutrientData {
  final MealType mealType;
  final List<Nutrient> nutrients;

  MealTypeNutrientData({
    required this.mealType,
    required this.nutrients,
  });

  factory MealTypeNutrientData.fromJson(Map<String, dynamic> json) {
    return MealTypeNutrientData(
      mealType: MealType.fromJson(json['mealType']),
      nutrients: (json['nutrients'] as List<dynamic>)
          .map((item) => Nutrient.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mealType': mealType.toJson(),
      'nutrients': nutrients.map((item) => item.toJson()).toList(),
    };
  }
}

class MealType {
  final int? id;
  final String name;
  final String description;
  final bool active;

  MealType({
    required this.id,
    required this.name,
    required this.description,
    required this.active,
  });

  factory MealType.fromJson(Map<String, dynamic> json) {
    return MealType(
      id: json['id'] != null ? (json['id'] as num).toInt() : null, // safe conversion
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      active: json['active'] ?? false,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'active': active,
    };
  }
}

class Nutrient {
  final String name;
  final double amount;
  final double minValue;
  final double maxValue;
  final String unitName;

  Nutrient({
    required this.name,
    required this.amount,
    required this.minValue,
    required this.maxValue,
    required this.unitName,
  });

  factory Nutrient.fromJson(Map<String, dynamic> json) {
    return Nutrient(
      name: json['name'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      minValue: (json['minValue'] ?? 0.0).toDouble(),
      maxValue: (json['maxValue'] ?? 0.0).toDouble(),
      unitName: json['unitName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'minValue': minValue,
      'maxValue': maxValue,
      'unitName': unitName,
    };
  }
}
