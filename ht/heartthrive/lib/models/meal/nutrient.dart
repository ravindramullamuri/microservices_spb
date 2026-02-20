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
      name: json['name'],
      amount: (json['amount'] ?? 0).toDouble(),
      minValue: (json['minValue'] ?? 0).toDouble(),
      maxValue: (json['maxValue'] ?? 0).toDouble(),
      unitName: json['unitName'],
    );
  }
}
