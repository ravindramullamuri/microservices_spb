class HeartRiskComparisonResponse {
  final String? riskLevel;
  final double? lastWeekRiskScorePercentage;
  final double? secondLastWeekRiskScorePercentage;
  final String? changeType;
  final double? changeValue;

  HeartRiskComparisonResponse({
    this.riskLevel,
    this.lastWeekRiskScorePercentage,
    this.secondLastWeekRiskScorePercentage,
    this.changeType,
    this.changeValue,
  });

  factory HeartRiskComparisonResponse.fromJson(Map<String, dynamic> json) {
    return HeartRiskComparisonResponse(
      riskLevel: json['riskLevel'] as String?,
      lastWeekRiskScorePercentage:
      (json['lastWeekRiskScorePercentage'] as num?)?.toDouble(),
      secondLastWeekRiskScorePercentage:
      (json['secondLastWeekRiskScorePercentage'] as num?)?.toDouble(),
      changeType: json['changeType'] as String?,
      changeValue: (json['changeValue'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    "riskLevel": riskLevel,
    "lastWeekRiskScorePercentage": lastWeekRiskScorePercentage,
    "secondLastWeekRiskScorePercentage":
    secondLastWeekRiskScorePercentage,
    "changeType": changeType,
    "changeValue": changeValue,
  };
}
