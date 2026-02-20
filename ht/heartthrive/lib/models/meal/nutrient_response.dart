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
      amount: (json['amount'] ?? 0).toDouble(),
      minValue: (json['minValue'] ?? 0).toDouble(),
      maxValue: (json['maxValue'] ?? 0).toDouble(),
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
class NutrientResponse {
  final List<Nutrient> nutrients;

  NutrientResponse({required this.nutrients});

  factory NutrientResponse.fromJson(Map<String, dynamic> json) {
    return NutrientResponse(
      nutrients: (json['nutrients'] as List<dynamic>)
          .map((e) => Nutrient.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nutrients': nutrients.map((e) => e.toJson()).toList(),
    };
  }
}
