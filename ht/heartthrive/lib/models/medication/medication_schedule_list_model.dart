import 'dart:convert';

class MedicationScheduleResponse {
  final bool success;
  final String? message;
  final MedicationScheduleData? data;

  MedicationScheduleResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory MedicationScheduleResponse.fromJson(Map<String, dynamic> json) {
    return MedicationScheduleResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null
          ? MedicationScheduleData.fromJson(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'data': data?.toJson(),
  };
}

class MedicationScheduleData {
  final String fromDate;
  final String toDate;
  final String timezone;
  final int totalSchedules;
  final int totalMedications;
  final Map<String, List<MedicationSchedule>>? schedulesByDate;
  final List<MedicationSchedule>? allSchedules;

  MedicationScheduleData({
    required this.fromDate,
    required this.toDate,
    required this.timezone,
    required this.totalSchedules,
    required this.totalMedications,
    this.schedulesByDate,
    this.allSchedules,
  });

  factory MedicationScheduleData.fromJson(Map<String, dynamic> json) {
    Map<String, List<MedicationSchedule>>? schedulesByDate;

    if (json['schedulesByDate'] != null) {
      schedulesByDate = {};
      json['schedulesByDate'].forEach((date, schedules) {
        schedulesByDate![date] = List<MedicationSchedule>.from(
          schedules.map((s) => MedicationSchedule.fromJson(s)),
        );
      });
    }

    List<MedicationSchedule>? allSchedules;
    if (json['allSchedules'] != null) {
      allSchedules = List<MedicationSchedule>.from(
        json['allSchedules'].map((s) => MedicationSchedule.fromJson(s)),
      );
    }

    return MedicationScheduleData(
      fromDate: json['fromDate'] ?? '',
      toDate: json['toDate'] ?? '',
      timezone: json['timezone'] ?? '',
      totalSchedules: json['totalSchedules'] ?? 0,
      totalMedications: json['totalMedications'] ?? 0,
      schedulesByDate: schedulesByDate,
      allSchedules: allSchedules,
    );
  }

  Map<String, dynamic> toJson() => {
    'fromDate': fromDate,
    'toDate': toDate,
    'timezone': timezone,
    'totalSchedules': totalSchedules,
    'totalMedications': totalMedications,
    'schedulesByDate': schedulesByDate?.map(
            (k, v) => MapEntry(k, v.map((s) => s.toJson()).toList())),
    'allSchedules': allSchedules?.map((s) => s.toJson()).toList(),
  };
}

class MedicationSchedule {
  final String date;
  final String dayOfWeek;
  final String? patientMedicationUuid;
  final String medicationName;
  final String medicationBrand;
  final String? medicationForm;
  final String? medicationStrength;
  final String? scheduleUuid;
  final String? doseDescription;
  final String? quantity;
  final bool? isAfterMeal;
  final String? intakePattern;
  final String? daysOfWeek; // comma-separated string
  final String timeSlot;
  final String? scheduledTime; // can be null
  bool? isTaken;
  final String? intakeUuid;

  MedicationSchedule({
    required this.date,
    required this.dayOfWeek,
    this.patientMedicationUuid,
    required this.medicationName,
    required this.medicationBrand,
    this.medicationForm,
    this.medicationStrength,
    this.scheduleUuid,
    this.doseDescription,
    this.quantity,
    this.isAfterMeal,
    this.intakePattern,
    this.daysOfWeek,
    required this.timeSlot,
    this.scheduledTime,
    this.isTaken,
    this.intakeUuid,
  });

  factory MedicationSchedule.fromJson(Map<String, dynamic> json) {
    return MedicationSchedule(
      date: json['date'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? '',
      patientMedicationUuid: json['patientMedicationUuid'],
      medicationName: json['medicationName'] ?? '',
      medicationBrand: json['medicationBrand'],
      medicationForm: json['medicationForm'],
      medicationStrength: json['medicationStrength'],
      scheduleUuid: json['scheduleUuid'],
      doseDescription: json['doseDescription'],
      quantity: json['quantity'],
      isAfterMeal: json['isAfterMeal'],
      intakePattern: json['intakePattern'],
      daysOfWeek: json['daysOfWeek'],
      timeSlot: json['timeSlot'] ?? '',
      scheduledTime: json['scheduledTime'],
      isTaken: json['isTaken'],
      intakeUuid: json['intakeUuid'],
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'dayOfWeek': dayOfWeek,
    'patientMedicationUuid': patientMedicationUuid,
    'medicationName': medicationName,
    'medicationBrand': medicationBrand,
    'medicationForm': medicationForm,
    'medicationStrength': medicationStrength,
    'scheduleUuid': scheduleUuid,
    'doseDescription': doseDescription,
    'quantity': quantity,
    'isAfterMeal': isAfterMeal,
    'intakePattern': intakePattern,
    'daysOfWeek': daysOfWeek,
    'timeSlot': timeSlot,
    'scheduledTime': scheduledTime,
    'isTaken': isTaken,
    'intakeUuid': intakeUuid,
  };
}

// Helper function
MedicationScheduleResponse medicationScheduleResponseFromJson(String str) =>
    MedicationScheduleResponse.fromJson(json.decode(str));
