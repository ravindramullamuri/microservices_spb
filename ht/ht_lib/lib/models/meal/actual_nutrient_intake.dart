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
