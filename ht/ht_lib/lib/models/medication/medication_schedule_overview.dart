import 'package:heart_thrive/components/time_12h_formatter.dart';

class MedicationInfoScheduleOverview {
  final bool success;
  final String message;
  final ScheduleData data;

  MedicationInfoScheduleOverview({
    required this.success,
    required this.message,
    required this.data,
  });

  factory MedicationInfoScheduleOverview.fromJson(Map<String, dynamic> json) {
    return MedicationInfoScheduleOverview(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: ScheduleData.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.toJson(),
    };
  }
}

class ScheduleData {
  final int totalSchedules;
  final List<Schedule> allSchedules;
  final int totalUpcoming;
  final List<Schedule> upcomingSchedules;
  final List<String> upcomingStatusMessages;
  final int totalMissed;
  final List<Schedule> missedSchedules;
  final String mostMissedMedication;
  final int mostMissedCount;
  final int totalTaken;
  final int totalMedications;
  final String fromDate;
  final String toDate;
  final String timezone;

  ScheduleData({
    required this.totalSchedules,
    required this.allSchedules,
    required this.totalUpcoming,
    required this.upcomingSchedules,
    required this.upcomingStatusMessages,
    required this.totalMissed,
    required this.missedSchedules,
    required this.mostMissedMedication,
    required this.mostMissedCount,
    required this.totalTaken,
    required this.totalMedications,
    required this.fromDate,
    required this.toDate,
    required this.timezone,
  });

  factory ScheduleData.fromJson(Map<String, dynamic> json) {
    return ScheduleData(
      totalSchedules: json['totalSchedules'] ?? 0,
      allSchedules: (json['allSchedules'] as List)
          .map((e) => Schedule.fromJson(e))
          .toList(),
      totalUpcoming: json['totalUpcoming'] ?? 0,
      upcomingSchedules: (json['upcomingSchedules'] as List)
          .map((e) => Schedule.fromJson(e))
          .toList(),
      upcomingStatusMessages:
      List<String>.from(json['upcomingStatusMessages'] ?? []),
      totalMissed: json['totalMissed'] ?? 0,
      missedSchedules: (json['missedSchedules'] as List)
          .map((e) => Schedule.fromJson(e))
          .toList(),
      mostMissedMedication: json['mostMissedMedication'] ?? '',
      mostMissedCount: json['mostMissedCount'] ?? 0,
      totalTaken: json['totalTaken'] ?? 0,
      totalMedications: json['totalMedications'] ?? 0,
      fromDate: json['fromDate'] ?? '',
      toDate: json['toDate'] ?? '',
      timezone: json['timezone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSchedules': totalSchedules,
      'allSchedules': allSchedules.map((e) => e.toJson()).toList(),
      'totalUpcoming': totalUpcoming,
      'upcomingSchedules': upcomingSchedules.map((e) => e.toJson()).toList(),
      'upcomingStatusMessages': upcomingStatusMessages,
      'totalMissed': totalMissed,
      'missedSchedules': missedSchedules.map((e) => e.toJson()).toList(),
      'mostMissedMedication': mostMissedMedication,
      'mostMissedCount': mostMissedCount,
      'totalTaken': totalTaken,
      'totalMedications': totalMedications,
      'fromDate': fromDate,
      'toDate': toDate,
      'timezone': timezone,
    };
  }
}

class Schedule {
  final String date;
  final String dayOfWeek;
  final String medicationName;
  final String medicationBrand;
  final String medicationStrength;
  final String? scheduledTime;
  final bool isTaken;

  Schedule({
    required this.date,
    required this.dayOfWeek,
    required this.medicationName,
    required this.medicationBrand,
    required this.medicationStrength,
    this.scheduledTime,
    required this.isTaken,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      date: json['date'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? '',
      medicationName: json['medicationName'] ?? '',
      medicationBrand: json['medicationBrand'] ?? '',
      medicationStrength: json['medicationStrength'] ?? '',
      scheduledTime: json['scheduledTime'],
      isTaken: json['isTaken'] ?? false,
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
      'isTaken': isTaken,
    };
  }

  // 🔥 Add this computed getter to auto convert to 12H format
  String get formattedTime {
    if (scheduledTime == null || scheduledTime!.trim().isEmpty) {
      return "Not set";
    }

    try {
      return formatTo12Hour(scheduledTime!);
    } catch (_) {
      return scheduledTime!;
    }
  }
}
