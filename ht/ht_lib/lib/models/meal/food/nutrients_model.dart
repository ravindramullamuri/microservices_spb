class Nutrients {
  final String name;
  final double amount;
  final double minValue;
  final double maxValue;
  final String unitName;

  Nutrients({
    required this.name,
    required this.amount,
    required this.minValue,
    required this.maxValue,
    required this.unitName,
  });

  factory Nutrients.fromJson(Map<String, dynamic> json) {
    return Nutrients(
      name: json['name'],
      amount: (json['amount'] as num).toDouble(),
      minValue: (json['minValue'] as num).toDouble(),
      maxValue: (json['maxValue'] as num).toDouble(),
      unitName: json['unitName'],
    );
  }
}