class MedicationData {
  final List<DailyMedicationSummary> dailyStats;
  final String fromDate;
  final String toDate;
  final String timezone;
  final int totalDays;
  final List<String> includedTimeSlots;

  MedicationData({
    required this.dailyStats,
    required this.fromDate,
    required this.toDate,
    required this.timezone,
    required this.totalDays,
    required this.includedTimeSlots,
  });

  factory MedicationData.fromJson(Map<String, dynamic> json) {
    return MedicationData(
      dailyStats: (json['data']['dailyStats'] as List)
          .map((e) => DailyMedicationSummary.fromJson(e))
          .toList(),
      fromDate: json['data']['fromDate'],
      toDate: json['data']['toDate'],
      timezone: json['data']['timezone'],
      totalDays: json['data']['totalDays'],
      includedTimeSlots: List<String>.from(json['data']['includedTimeSlots']),
    );
  }
}

class DailyMedicationSummary {
  final String date;
  final int totalMedications;
  final int totalScheduled;
  final int totalTaken;
  final int totalNotTaken;
  final int totalMissed;
  final double adherencePercentage;

  DailyMedicationSummary({
    required this.date,
    required this.totalMedications,
    required this.totalScheduled,
    required this.totalTaken,
    required this.totalNotTaken,
    required this.totalMissed,
    required this.adherencePercentage,
  });

  factory DailyMedicationSummary.fromJson(Map<String, dynamic> json) {
    return DailyMedicationSummary(
      date: json['date'],
      totalMedications: json['totalMedications'],
      totalScheduled: json['totalScheduled'],
      totalTaken: json['totalTaken'],
      totalNotTaken: json['totalNotTaken'],
      totalMissed: json['totalMissed'],
      adherencePercentage: json['adherencePercentage'].toDouble(),
    );
  }
}