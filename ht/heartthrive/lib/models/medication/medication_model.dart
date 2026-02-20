import 'medication_schedule_list_model.dart';

class MedicationModel {
  final String? medicationUuid;
  final String? medicationName;
  final String? medicationBrand;
  final String? medicationForm;
  final String? scheduleUuid;
  final String? doseDescription;
  final String? dosageFrequency;
  final List<String>? daysOfWeek;
  final bool? isMorning;
  final bool? isAfterNoon;
  final bool? isEvening;
  final String? morningTime;
  final String? afternoonTime;
  final String? eveningTime;
  final String? startDate;
  final String? endDate;
  final bool? isAfterMeal;
  final bool? active;

  MedicationModel({
     this.medicationUuid,
     this.medicationName,
     this.medicationBrand,
     this.medicationForm,
     this.scheduleUuid,
     this.doseDescription,
     this.dosageFrequency,
     this.daysOfWeek,
     this.isMorning,
     this.isAfterNoon,
     this.isEvening,
     this.morningTime,
     this.afternoonTime,
     this.eveningTime,
     this.startDate,
     this.endDate,
     this.isAfterMeal,
     this.active,
  });

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      medicationUuid: json['medicationUuid'] ?? '',
      medicationName: json['medicationName'] ?? '',
      medicationBrand: json['medicationBrand'] ?? '',
      medicationForm: json['medicationForm'] ?? '',
      scheduleUuid: json['scheduleUuid'] ?? '',
      doseDescription: json['doseDescription'] ?? '',
      dosageFrequency: json['dosageFrequency'] ?? '',
      // ✅ FIXED: supports list, string, null safely
      daysOfWeek: _parseDays(json['daysOfWeek']),
      isMorning: (json['isMorning'] ?? json['morning']) ?? false,
      isAfterNoon: (json['isAfterNoon'] ?? json['afternoon']) ?? false,
      isEvening: (json['isEvening'] ?? json['evening']) ?? false,
      morningTime: json['morningTime'],
      afternoonTime: json['afternoonTime'],
      eveningTime: json['eveningTime'],
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      isAfterMeal: json['isAfterMeal'] ?? false,
      active: json['active'] ?? false,
    );
  }
  /// ✔ Creates model only with available fields
  /// ✔ Everything else stays null
  factory MedicationModel.fromPartialJson(Map<String, dynamic> json) {
    return MedicationModel(
      medicationUuid: json['medicationUuid'],
      scheduleUuid: json['scheduleUuid'],
      medicationName: json['medicationName'],
      medicationBrand: json['medicationBrand'],
      doseDescription: json['doseDescription'],
    );
  }

  /// Helper method to safely parse daysOfWeek from any format
  static List<String> _parseDays(dynamic raw) {
    if (raw == null) return [];

    // Case 1: Already List<String>
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }

    // Case 2: String: "Mon,Tue,Wed"
    if (raw is String) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return [];
  }
}


MedicationModel convertToMedicationModel(MedicationSchedule s) {
  // Convert comma string → list
  final days = (s.daysOfWeek?.isNotEmpty ?? false)
      ? s.daysOfWeek!.split(',').map((e) => e.trim()).toList()
      : <String>[];

  final slot = s.timeSlot.toLowerCase();

  return MedicationModel(
    medicationName: s.medicationName,
    medicationBrand: s.medicationBrand,
    medicationForm: s.medicationForm ?? '',
    scheduleUuid: s.scheduleUuid ?? '',
    doseDescription: s.doseDescription ?? '',
    dosageFrequency: s.intakePattern ?? '',

    daysOfWeek: days,

    // Timeslot mapping
    isMorning: slot == 'morning',
    isAfterNoon: slot == 'afternoon',
    isEvening: slot == 'evening',

    morningTime: slot == 'morning' ? s.scheduledTime : null,
    afternoonTime: slot == 'afternoon' ? s.scheduledTime : null,
    eveningTime: slot == 'evening' ? s.scheduledTime : null,

    // Schedule has only 1 date → use same for both
    startDate: s.date,
    endDate: s.date,

    isAfterMeal: s.isAfterMeal ?? false,

    // Default since schedule doesn't provide it
    active: true,
  );
}
extension ScheduleMapper on MedicationSchedule {
  MedicationModel toModel() => convertToMedicationModel(this);
}
