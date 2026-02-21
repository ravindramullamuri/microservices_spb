class WeightHeightLog {
  final int id;
  final String uuid;
  final double weight;
  final String weightUnitType;
  final double height;
  final String heightUnitType;
  final double bmiValue;
  final String otherInfo;
  final DateTime recordedAt;
  final bool active;
  final String createdBy;
  final DateTime createdDate;
  final String lastModifiedBy;
  final DateTime lastModifiedDate;
  final BmiStatus bmiStatus;
  final Patient patient;
  final int? bmiStatusId;
  final String? bmiStatusLabel;

  WeightHeightLog({
    required this.id,
    required this.uuid,
    required this.weight,
    required this.weightUnitType,
    required this.height,
    required this.heightUnitType,
    required this.bmiValue,
    required this.otherInfo,
    required this.recordedAt,
    required this.active,
    required this.createdBy,
    required this.createdDate,
    required this.lastModifiedBy,
    required this.lastModifiedDate,
    required this.bmiStatus,
    required this.patient,
    this.bmiStatusId,
    this.bmiStatusLabel,
  });

  factory WeightHeightLog.fromJson(Map<String, dynamic> json) {
    return WeightHeightLog(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      weightUnitType: json['weightUnitType'] ?? '',
      height: (json['height'] ?? 0).toDouble(),
      heightUnitType: json['heightUnitType'] ?? '',
      bmiValue: (json['bmiValue'] ?? 0).toDouble(),
      otherInfo: json['otherInfo'] ?? '',
      recordedAt: DateTime.parse(json['recordedAt'] ?? DateTime.now().toIso8601String()),
      active: json['active'] ?? false,
      createdBy: json['createdBy'] ?? '',
      createdDate: DateTime.parse(json['createdDate'] ?? DateTime.now().toIso8601String()),
      lastModifiedBy: json['lastModifiedBy'] ?? '',
      lastModifiedDate: DateTime.parse(json['lastModifiedDate'] ?? DateTime.now().toIso8601String()),
      bmiStatus: BmiStatus.fromJson(json['bmiStatus'] ?? {}),
      patient: Patient.fromJson(json['patient'] ?? {}),
      bmiStatusId: json['bmiStatus']?['id'],
      bmiStatusLabel: json['bmiStatus']?['label'],
    );
  }
}

class BmiStatus {
  final int id;
  final String uuid;
  final String label;
  final double minBmi;
  final double maxBmi;
  final String color;
  final bool active;
  final String createdBy;
  final DateTime createdDate;
  final String lastModifiedBy;
  final DateTime lastModifiedDate;

  BmiStatus({
    required this.id,
    required this.uuid,
    required this.label,
    required this.minBmi,
    required this.maxBmi,
    required this.color,
    required this.active,
    required this.createdBy,
    required this.createdDate,
    required this.lastModifiedBy,
    required this.lastModifiedDate,
  });

  factory BmiStatus.fromJson(Map<String, dynamic> json) {
    return BmiStatus(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      label: json['label'] ?? '',
      minBmi: (json['minBmi'] ?? 0).toDouble(),
      maxBmi: (json['maxBmi'] ?? 0).toDouble(),
      color: json['color'] ?? '',
      active: json['active'] ?? false,
      createdBy: json['createdBy'] ?? '',
      createdDate: DateTime.parse(json['createdDate'] ?? DateTime.now().toIso8601String()),
      lastModifiedBy: json['lastModifiedBy'] ?? '',
      lastModifiedDate: DateTime.parse(json['lastModifiedDate'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class Patient {
  final int id;
  final String uuid;
  final String login;
  final String firstName;
  final String lastName;
  final String email;
  final bool active;
  final String imageUrl;
  final String langKey;
  final String createdBy;
  final DateTime createdDate;
  final String lastModifiedBy;
  final DateTime lastModifiedDate;
  final List<Role> roles;
  final String phoneNumber;
  final DateTime dateOfBirth;
  final int agreedToTermsOfUse;
  final Gender gender;

  Patient({
    required this.id,
    required this.uuid,
    required this.login,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.active,
    required this.imageUrl,
    required this.langKey,
    required this.createdBy,
    required this.createdDate,
    required this.lastModifiedBy,
    required this.lastModifiedDate,
    required this.roles,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.agreedToTermsOfUse,
    required this.gender,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      login: json['login'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      active: json['active'] ?? false,
      imageUrl: json['imageUrl'] ?? '',
      langKey: json['langKey'] ?? '',
      createdBy: json['createdBy'] ?? '',
      createdDate: DateTime.parse(json['createdDate'] ?? DateTime.now().toIso8601String()),
      lastModifiedBy: json['lastModifiedBy'] ?? '',
      lastModifiedDate: DateTime.parse(json['lastModifiedDate'] ?? DateTime.now().toIso8601String()),
      roles: (json['roles'] as List<dynamic>? ?? []).map((role) => Role.fromJson(role)).toList(),
      phoneNumber: json['phoneNumber'] ?? '',
      dateOfBirth: DateTime.parse(json['dateOfBirth'] ?? DateTime.now().toIso8601String()),
      agreedToTermsOfUse: json['agreedToTermsOfUse'] ?? 0,
      gender: Gender.fromJson(json['gender'] ?? {}),
    );
  }
}

class Role {
  final int id;
  final String uuid;
  final String name;
  final String description;
  final bool active;
  final String createdBy;
  final DateTime createdDate;
  final String lastModifiedBy;
  final DateTime lastModifiedDate;
  final List<Permission> permissions;

  Role({
    required this.id,
    required this.uuid,
    required this.name,
    required this.description,
    required this.active,
    required this.createdBy,
    required this.createdDate,
    required this.lastModifiedBy,
    required this.lastModifiedDate,
    required this.permissions,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      active: json['active'] ?? false,
      createdBy: json['createdBy'] ?? '',
      createdDate: DateTime.parse(json['createdDate'] ?? DateTime.now().toIso8601String()),
      lastModifiedBy: json['lastModifiedBy'] ?? '',
      lastModifiedDate: DateTime.parse(json['lastModifiedDate'] ?? DateTime.now().toIso8601String()),
      permissions: (json['permissions'] as List<dynamic>? ?? []).map((permission) => Permission.fromJson(permission)).toList(),
    );
  }
}

class Permission {
  final int id;
  final String uuid;
  final String name;
  final String description;
  final bool active;
  final String createdBy;
  final DateTime createdDate;
  final String lastModifiedBy;
  final DateTime lastModifiedDate;

  Permission({
    required this.id,
    required this.uuid,
    required this.name,
    required this.description,
    required this.active,
    required this.createdBy,
    required this.createdDate,
    required this.lastModifiedBy,
    required this.lastModifiedDate,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      active: json['active'] ?? false,
      createdBy: json['createdBy'] ?? '',
      createdDate: DateTime.parse(json['createdDate'] ?? DateTime.now().toIso8601String()),
      lastModifiedBy: json['lastModifiedBy'] ?? '',
      lastModifiedDate: DateTime.parse(json['lastModifiedDate'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class Gender {
  final int id;
  final String uuid;
  final String name;
  final String description;
  final bool active;
  final String createdBy;
  final DateTime createdDate;
  final String lastModifiedBy;
  final DateTime lastModifiedDate;
  final GenderGroup group;

  Gender({
    required this.id,
    required this.uuid,
    required this.name,
    required this.description,
    required this.active,
    required this.createdBy,
    required this.createdDate,
    required this.lastModifiedBy,
    required this.lastModifiedDate,
    required this.group,
  });

  factory Gender.fromJson(Map<String, dynamic> json) {
    return Gender(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      active: json['active'] ?? false,
      createdBy: json['createdBy'] ?? '',
      createdDate: DateTime.parse(json['createdDate'] ?? DateTime.now().toIso8601String()),
      lastModifiedBy: json['lastModifiedBy'] ?? '',
      lastModifiedDate: DateTime.parse(json['lastModifiedDate'] ?? DateTime.now().toIso8601String()),
      group: GenderGroup.fromJson(json['group'] ?? {}),
    );
  }
}

class GenderGroup {
  final int id;
  final String uuid;
  final String name;
  final String description;
  final bool active;
  final String createdBy;
  final DateTime createdDate;
  final String lastModifiedBy;
  final DateTime lastModifiedDate;

  GenderGroup({
    required this.id,
    required this.uuid,
    required this.name,
    required this.description,
    required this.active,
    required this.createdBy,
    required this.createdDate,
    required this.lastModifiedBy,
    required this.lastModifiedDate,
  });

  factory GenderGroup.fromJson(Map<String, dynamic> json) {
    return GenderGroup(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      active: json['active'] ?? false,
      createdBy: json['createdBy'] ?? '',
      createdDate: DateTime.parse(json['createdDate'] ?? DateTime.now().toIso8601String()),
      lastModifiedBy: json['lastModifiedBy'] ?? '',
      lastModifiedDate: DateTime.parse(json['lastModifiedDate'] ?? DateTime.now().toIso8601String()),
    );
  }
}
