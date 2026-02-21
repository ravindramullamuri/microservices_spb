class User {
  final int id;
  final String? firstname;
  final String? lastname;
  final String? email;
  final String? profileImage;
  final HealthInfo? healthInfo;

  // Convenience getters
  double? get weight => healthInfo?.weight;
  double? get height => healthInfo?.height;
  double? get bmi => healthInfo?.bmi;

  User({
    required this.id,
    this.firstname,
    this.lastname,
    this.email,
    this.profileImage,
    this.healthInfo,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstname: json['firstName'],
      lastname: json['lastName'],
      email: json['email'],
      profileImage: json['profileImage'],
      healthInfo: json['healthInfo'] != null
          ? HealthInfo.fromJson(json['healthInfo'])
          : null,
    );
  }
}

class HealthInfo {
  final double? weight;
  final String? weightUnitType;
  final double? height;
  final String? heightUnitType;
  final double? bmi;

  HealthInfo({
    this.weight,
    this.weightUnitType,
    this.height,
    this.heightUnitType,
    this.bmi,
  });

  factory HealthInfo.fromJson(Map<String, dynamic> json) {
    return HealthInfo(
      weight: (json['weight'] as num?)?.toDouble(),
      weightUnitType: json['weightUnitType'],
      height: (json['height'] as num?)?.toDouble(),
      heightUnitType: json['heightUnitType'],
      bmi: (json['bmi'] as num?)?.toDouble(),
    );
  }
}
