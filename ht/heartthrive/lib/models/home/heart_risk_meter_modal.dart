import 'package:heart_thrive/models/risk_meter_home.dart';

class HeartRiskSummaryResponse {
  final RiskSymptom? riskSymptom;
  final SodiumData? sodium;
  final MedicationData? medication;
  final WeightData? weight;

  HeartRiskSummaryResponse({
    this.riskSymptom,
    this.sodium,
    this.medication,
    this.weight,
  });

  factory HeartRiskSummaryResponse.fromJson(Map<String, dynamic> json) {
    return HeartRiskSummaryResponse(
      riskSymptom: json['riskSymptom'] != null
          ? RiskSymptom.fromJson(json['riskSymptom'])
          : null,
      sodium: json['sodium'] != null
          ? SodiumData.fromJson(json['sodium'])
          : null,
      medication: json['medication'] != null
          ? MedicationData.fromJson(json['medication'])
          : null,
      weight: json['weight'] != null
          ? WeightData.fromJson(json['weight'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "riskSymptom": riskSymptom?.toJson(),
    "sodium": sodium?.toJson(),
    "medication": medication?.toJson(),
    "weight": weight?.toJson(),
  };
}

class SodiumData {
  final double? value;
  final double? percentage;

  SodiumData({this.value, this.percentage});

  factory SodiumData.fromJson(Map<String, dynamic> json) {
    return SodiumData(
      value: (json['value'] as num?)?.toDouble(),
      percentage: (json['percentage'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    "value": value,
    "percentage": percentage,
  };
}

class MedicationData {
  final double? missedCount;
  final double? scheduleCount;
  final double? percentage;

  MedicationData({this.missedCount, this.scheduleCount, this.percentage});

  factory MedicationData.fromJson(Map<String, dynamic> json) {
    return MedicationData(
      missedCount: (json['missedCount'] as num?)?.toDouble(),
      scheduleCount: (json['scheduleCount'] as num?)?.toDouble(),
      percentage: (json['percentage'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    "missedCount": missedCount,
    "scheduleCount": scheduleCount,
    "percentage": percentage,
  };
}

class WeightData {
  final double? actualWeight;
  final double? baselineWeight;
  final double? increaseWeight;
  final double? percentage;
  final String? weightUnitType;
  final double? currentWeight;

  WeightData({
    this.actualWeight,
    this.baselineWeight,
    this.increaseWeight,
    this.percentage,
    this.weightUnitType,
    this.currentWeight,
  });

  factory WeightData.fromJson(Map<String, dynamic> json) {
    return WeightData(
      actualWeight: (json['actualWeight'] as num?)?.toDouble(),
      baselineWeight: (json['baselineWeight'] as num?)?.toDouble(),
      increaseWeight: (json['increaseWeight'] as num?)?.toDouble(),
      percentage: (json['percentage'] as num?)?.toDouble(),
      weightUnitType: json['weightUnitType'] as String?,
      currentWeight: (json['currentWeight'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'actualWeight': actualWeight,
    'baselineWeight': baselineWeight,
    'increaseWeight': increaseWeight,
    'percentage': percentage,
    'weightUnitType': weightUnitType,
    'currentWeight': currentWeight,
  };
}

