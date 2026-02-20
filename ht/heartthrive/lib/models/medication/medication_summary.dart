class MedicationSummary {
  final int dosesTaken;
  final int targetDoses;
  final int dosesLeft;
  final int missedDoses;
  final NextDose nextDose;
  final String statusMessage;

  MedicationSummary({
    required this.dosesTaken,
    required this.targetDoses,
    required this.dosesLeft,
    required this.missedDoses,
    required this.nextDose,
    required this.statusMessage,
  });

  factory MedicationSummary.fromJson(Map<String, dynamic> json) {
    return MedicationSummary(
      dosesTaken: json['dosesTaken'] ?? 0,
      targetDoses: json['targetDoses'] ?? 0,
      dosesLeft: json['dosesLeft'] ?? 0,
      missedDoses: json['missedDoses'] ?? 0,
      nextDose: NextDose.fromJson(json['nextDose'] ?? {}),
      statusMessage: json['statusMessage'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dosesTaken': dosesTaken,
      'targetDoses': targetDoses,
      'dosesLeft': dosesLeft,
      'missedDoses': missedDoses,
      'nextDose': nextDose.toJson(),
      'statusMessage': statusMessage,
    };
  }
}

class NextDose {
  final String time;
  final String label;

  NextDose({
    required this.time,
    required this.label,
  });

  factory NextDose.fromJson(Map<String, dynamic> json) {
    return NextDose(
      time: json['time'] ?? '',
      label: json['label'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'label': label,
    };
  }
}
