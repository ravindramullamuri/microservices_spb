import 'dart:convert';

class UserDetails {
  final int id;
  final String username;
  final String uuid;
  final String? password;
  final String? email;
  final String? firstname;
  final String? lastname;
  final String? fullname;
  final List<dynamic> authorities;
  final String? countryCode;
  final String? phone;
  final String? dateOfBirth; // keep as String, or DateTime if you want parsing
  final String? gender;
  final int? patientWeightHeightId;
  final String? height;
  final String? weight;
  final double? bmi;
  final String? bmiStatus;
  final String? profileImage;

  const UserDetails({
    required this.id,
    required this.username,
    required this.uuid,
    this.password,
    this.email,
    this.firstname,
    this.lastname,
    this.fullname,
    this.authorities = const [],
    this.countryCode,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.patientWeightHeightId,
    this.height,
    this.weight,
    this.bmi,
    this.bmiStatus,
    this.profileImage,
  });

  /// Convert JSON -> UserData
  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      id: json['id'],
      username: json['username'],
      uuid: json['uuid'],
      password: json['password'],
      email: json['email'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      fullname: json['fullname'],
      authorities: List<dynamic>.from(json['authorities'] ?? []),
      countryCode: json['countryCode'],
      phone: json['phone'],
      dateOfBirth: json['dateOfBirth'],
      gender: json['gender'],
      patientWeightHeightId: json['patientWeightHeightId'],
      height: json['height'] ,
      weight: json['weight'],
      bmi: (json['bmi'] as num?)?.toDouble(),
      bmiStatus: json['bmiStatus'],
      profileImage: json['profileImage'],
    );
  }

  /// Convert UserData -> JSON
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "username": username,
      "uuid": uuid,
      "password": password,
      "email": email,
      "firstname": firstname,
      "lastname": lastname,
      "fullname": fullname,
      "authorities": authorities,
      "countryCode":countryCode,
      "phone": phone,
      "dateOfBirth": dateOfBirth,
      "gender": gender,
      "patientWeightHeightId": patientWeightHeightId,
      "height": height,
      "weight": weight,
      "bmi": bmi,
      "bmiStatus": bmiStatus,
      "profileImage": profileImage,
    };
  }

  /// Create a copy with updated fields
  UserDetails copyWith({
    int? id,
    String? username,
    String? uuid,
    String? password,
    String? email,
    String? firstname,
    String? lastname,
    String? fullname,
    List<dynamic>? authorities,
    String? countryCode,
    String? phone,
    String? dateOfBirth,
    String? gender,
    int? patientWeightHeightId,
    String? height,
    String? weight,
    double? bmi,
    String? bmiStatus,
    String? profileImage,
  }) {
    return UserDetails(
      id: id ?? this.id,
      username: username ?? this.username,
      uuid: uuid ?? this.uuid,
      password: password ?? this.password,
      email: email ?? this.email,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      fullname: fullname ?? this.fullname,
      authorities: authorities ?? this.authorities,
      countryCode: countryCode?? this.countryCode,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      patientWeightHeightId:
      patientWeightHeightId ?? this.patientWeightHeightId,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bmi: bmi ?? this.bmi,
      bmiStatus: bmiStatus ?? this.bmiStatus,
      profileImage: profileImage ?? this.profileImage,
    );
  }

  /// For quick debugging
  @override
  String toString() => jsonEncode(toJson());
}
