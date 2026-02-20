class RiskResponse {
  final RiskSymptom? riskSymptom;

  RiskResponse({this.riskSymptom});

  factory RiskResponse.fromJson(Map<String, dynamic> json) {
    return RiskResponse(
      riskSymptom: json['riskSymptom'] != null
          ? RiskSymptom.fromJson(json['riskSymptom'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'riskSymptom': riskSymptom?.toJson(),
  };
}
class RiskSymptom {
  final double? score;
  final String? category;
  final String? message;
  final List<Scale>? scale;

  RiskSymptom({
    this.score,
    this.category,
    this.message,
    this.scale,
  });

  factory RiskSymptom.fromJson(Map<String, dynamic> json) {
    return RiskSymptom(
      score: json['score'],
      category: json['category'],
      message: json['message'],
      scale: (json['scale'] as List<dynamic>?)
          ?.map((e) => Scale.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'score': score,
    'category': category,
    'message': message,
    'scale': scale?.map((e) => e.toJson()).toList(),
  };
}
class Scale {
  final String? range;
  final String? label;

  Scale({this.range, this.label});

  factory Scale.fromJson(Map<String, dynamic> json) {
    return Scale(
      range: json['range'],
      label: json['label'],
    );
  }

  Map<String, dynamic> toJson() => {
    'range': range,
    'label': label,
  };
}
