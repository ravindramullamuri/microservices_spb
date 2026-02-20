class SymptomSummaryResponse {
  final bool success;
  final String message;
  final List<SymptomTrackItem> symptoms;

  SymptomSummaryResponse({
    required this.success,
    required this.message,
    required this.symptoms,
  });

  factory SymptomSummaryResponse.fromJson(Map<String, dynamic> json) {
    return SymptomSummaryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      symptoms: (json['symptomsTrackData'] as List<dynamic>?)
          ?.map((e) => SymptomTrackItem.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class SymptomTrackItem {
  final String symptomName;
  final String trackedOn;
  final List<String> symptomLevel;
  final List<String> descriptions;
  final bool customType;

  /// 🚀 THIS is what you want!
  final SymptomLevelCount symptomLevelCount;

  SymptomTrackItem({
    required this.symptomName,
    required this.trackedOn,
    required this.symptomLevel,
    required this.symptomLevelCount,
    required this.descriptions,
    required this.customType
  });

  factory SymptomTrackItem.fromJson(Map<String, dynamic> json) {
    final List<String> levels =
        (json['symptomLevel'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final List<String> descriptions =
        (json['descriptions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    final count = SymptomLevelCount.fromList(levels);

    return SymptomTrackItem(
      symptomName: json['symptomName'] ?? '',
      trackedOn: json['trackedOn'] ?? '',
      symptomLevel: levels,
      symptomLevelCount: count,
      descriptions: descriptions,
      customType: json['customType'] ?? false
    );
  }
}

class SymptomLevelCount {
  final int none;
  final int mild;
  final int moderate;
  final int severe;

  SymptomLevelCount({
    required this.none,
    required this.mild,
    required this.moderate,
    required this.severe,
  });

  factory SymptomLevelCount.fromList(List<String> levels) {
    int none = 0;
    int mild = 0;
    int moderate = 0;
    int severe = 0;

    for (var level in levels) {
      switch (level.toLowerCase()) {
        case "none":
          none++;
          break;
        case "mild":
          mild++;
          break;
        case "moderate":
          moderate++;
          break;
        case "severe":
          severe++;
          break;
      }
    }

    return SymptomLevelCount(
      none: none,
      mild: mild,
      moderate: moderate,
      severe: severe,
    );
  }
}
