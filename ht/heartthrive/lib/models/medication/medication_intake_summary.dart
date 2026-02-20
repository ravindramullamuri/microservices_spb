class IntakeMedicationSummary {
  final bool success;
  final String message;
  final IntakeSummaryData? data;

  IntakeMedicationSummary({
    required this.success,
    required this.message,
    this.data,
  });

  factory IntakeMedicationSummary.fromJson(Map<String, dynamic> json) {
    return IntakeMedicationSummary(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? IntakeSummaryData.fromJson(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class IntakeSummaryData {
  final int totalMedications;
  final int totalScheduled;
  final int totalTaken;
  final int totalNotTaken;
  final int totalMissed;
  final double overallAdherencePercentage;
  final int totalUpcomingDoses;
  final List<Medication> upcomingMedications;
  final List<String> statusMessages;
  final int totalMissedDoses;
  final List<Medication> missedMedications;
  final List<String> missedStatusMessages;
  final String? mostMissedMedication; // ✅ Nullable
  final int mostMissedCount;
  final String fromDate;
  final String toDate;
  final String timezone;

  IntakeSummaryData({
    required this.totalMedications,
    required this.totalScheduled,
    required this.totalTaken,
    required this.totalNotTaken,
    required this.totalMissed,
    required this.overallAdherencePercentage,
    required this.totalUpcomingDoses,
    required this.upcomingMedications,
    required this.statusMessages,
    required this.totalMissedDoses,
    required this.missedMedications,
    required this.missedStatusMessages,
    required this.mostMissedMedication,
    required this.mostMissedCount,
    required this.fromDate,
    required this.toDate,
    required this.timezone,
  });

  factory IntakeSummaryData.fromJson(Map<String, dynamic> json) {
    return IntakeSummaryData(
      totalMedications: (json['totalMedications'] ?? 0) as int,
      totalScheduled: (json['totalScheduled'] ?? 0) as int,
      totalTaken: (json['totalTaken'] ?? 0) as int,
      totalNotTaken: (json['totalNotTaken'] ?? 0) as int,
      totalMissed: (json['totalMissed'] ?? 0) as int,
      overallAdherencePercentage:
      (json['overallAdherencePercentage'] ?? 0).toDouble(),
      totalUpcomingDoses: (json['totalUpcomingDoses'] ?? 0) as int,
      upcomingMedications: (json['upcomingMedications'] as List?)
          ?.map((e) => Medication.fromJson(e))
          .toList() ??
          [],
      statusMessages:
      (json['statusMessages'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      totalMissedDoses: (json['totalMissedDoses'] ?? 0) as int,
      missedMedications: (json['missedMedications'] as List?)
          ?.map((e) => Medication.fromJson(e))
          .toList() ??
          [],
      missedStatusMessages: (json['missedStatusMessages'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      mostMissedMedication:
      json['mostMissedMedication']?.toString(), // ✅ safely handle null
      mostMissedCount: (json['mostMissedCount'] ?? 0) as int,
      fromDate: json['fromDate']?.toString() ?? '',
      toDate: json['toDate']?.toString() ?? '',
      timezone: json['timezone']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMedications': totalMedications,
      'totalScheduled': totalScheduled,
      'totalTaken': totalTaken,
      'totalNotTaken': totalNotTaken,
      'totalMissed': totalMissed,
      'overallAdherencePercentage': overallAdherencePercentage,
      'totalUpcomingDoses': totalUpcomingDoses,
      'upcomingMedications': upcomingMedications.map((e) => e.toJson()).toList(),
      'statusMessages': statusMessages,
      'totalMissedDoses': totalMissedDoses,
      'missedMedications': missedMedications.map((e) => e.toJson()).toList(),
      'missedStatusMessages': missedStatusMessages,
      'mostMissedMedication': mostMissedMedication,
      'mostMissedCount': mostMissedCount,
      'fromDate': fromDate,
      'toDate': toDate,
      'timezone': timezone,
    };
  }
}

class Medication {
  final String date;
  final String dayOfWeek;
  final String medicationName;
  final String medicationBrand;
  final String medicationStrength;
  final String? scheduledTime;
  final String statusMessage;

  Medication({
    required this.date,
    required this.dayOfWeek,
    required this.medicationName,
    required this.medicationBrand,
    required this.medicationStrength,
    this.scheduledTime,
    required this.statusMessage,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      date: json['date']?.toString() ?? '',
      dayOfWeek: json['dayOfWeek']?.toString() ?? '',
      medicationName: json['medicationName']?.toString() ?? '',
      medicationBrand: json['medicationBrand']?.toString() ?? '',
      medicationStrength: json['medicationStrength']?.toString() ?? '',
      scheduledTime: json['scheduledTime']?.toString(),
      statusMessage: json['statusMessage']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'dayOfWeek': dayOfWeek,
      'medicationName': medicationName,
      'medicationBrand': medicationBrand,
      'medicationStrength': medicationStrength,
      'scheduledTime': scheduledTime,
      'statusMessage': statusMessage,
    };
  }
}
