class SymptomModel {
  final String customSymptom;
  final String? swellingToLegs;
  final String? shortOfBreathWithActivity;
  final String? shortOfBreathWhenLyingFlat;
  final String? wakingUpAtNightShortOfBreath;

  const SymptomModel({
    required this.customSymptom,
    this.swellingToLegs,
    this.shortOfBreathWithActivity,
    this.shortOfBreathWhenLyingFlat,
    this.wakingUpAtNightShortOfBreath,
  });

  /// Convert from JSON
  factory SymptomModel.fromJson(Map<String, dynamic> json) {
    return SymptomModel(
      customSymptom: json['customSymptom'] as String,
      swellingToLegs: json['swellingToLegs'] as String?,
      shortOfBreathWithActivity:
      json['shortOfBreathWithActivity'] as String?,
      shortOfBreathWhenLyingFlat:
      json['shortOfBreathWhenLyingFlat'] as String?,
      wakingUpAtNightShortOfBreath:
      json['wakingUpAtNightShortOfBreath'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'customSymptom': customSymptom,
      'swellingToLegs': swellingToLegs,
      'shortOfBreathWithActivity': shortOfBreathWithActivity,
      'shortOfBreathWhenLyingFlat': shortOfBreathWhenLyingFlat,
      'wakingUpAtNightShortOfBreath': wakingUpAtNightShortOfBreath,
    };
  }

  /// Optional: copyWith for immutability
  SymptomModel copyWith({
    String? customSymptom,
    String? swellingToLegs,
    String? shortOfBreathWithActivity,
    String? shortOfBreathWhenLyingFlat,
    String? wakingUpAtNightShortOfBreath,
  }) {
    return SymptomModel(
      customSymptom: customSymptom ?? this.customSymptom,
      swellingToLegs: swellingToLegs ?? this.swellingToLegs,
      shortOfBreathWithActivity:
      shortOfBreathWithActivity ?? this.shortOfBreathWithActivity,
      shortOfBreathWhenLyingFlat:
      shortOfBreathWhenLyingFlat ?? this.shortOfBreathWhenLyingFlat,
      wakingUpAtNightShortOfBreath:
      wakingUpAtNightShortOfBreath ??
          this.wakingUpAtNightShortOfBreath,
    );
  }
}
