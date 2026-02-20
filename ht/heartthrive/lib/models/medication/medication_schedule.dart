// Model for individual dose schedule entries
class DoseSchedule {
  final String time;
  final String medicine;
  final String status;

  DoseSchedule({
    required this.time,
    required this.medicine,
    required this.status,
  });

  factory DoseSchedule.fromJson(Map<String, dynamic> json) {
    return DoseSchedule(
      time: json['time'] as String,
      medicine: json['medicine'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'time': time,
    'medicine': medicine,
    'status': status,
  };
}

// Model for dose information (used for nextDoses and missedDoses)
class DoseInfo {
  final String time;
  final String medicine;

  DoseInfo({
    required this.time,
    required this.medicine,
  });

  factory DoseInfo.fromJson(Map<String, dynamic> json) {
    return DoseInfo(
      time: json['time'] as String,
      medicine: json['medicine'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'time': time,
    'medicine': medicine,
  };
}

// Model for the entire medication schedule
class MedicationTodaySchedule {
  final List<DoseSchedule> todaySchedule;
  final List<DoseInfo> nextDoses;
  final List<DoseInfo> missedDoses;

  MedicationTodaySchedule({
    required this.todaySchedule,
    required this.nextDoses,
    required this.missedDoses,
  });

  factory MedicationTodaySchedule.fromJson(Map<String, dynamic> json) {
    return MedicationTodaySchedule(
      todaySchedule: (json['todaySchedule'] as List<dynamic>)
          .map((item) => DoseSchedule.fromJson(item as Map<String, dynamic>))
          .toList(),
      nextDoses: (json['nextDoses'] as List<dynamic>)
          .map((item) => DoseInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
      missedDoses: (json['missedDoses'] as List<dynamic>)
          .map((item) => DoseInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'todaySchedule': todaySchedule.map((item) => item.toJson()).toList(),
    'nextDoses': nextDoses.map((item) => item.toJson()).toList(),
    'missedDoses': missedDoses.map((item) => item.toJson()).toList(),
  };
}