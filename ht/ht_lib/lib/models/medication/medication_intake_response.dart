class IntakeStatsResponse {
  final bool success;
  final String message;
  final IntakeData data;

  IntakeStatsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory IntakeStatsResponse.fromJson(Map<String, dynamic> json) {
    return IntakeStatsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: IntakeData.fromJson(json['data'] ?? {}),
    );
  }
}

class IntakeData {
  final int totalScheduled;
  final int totalTaken;
  final int totalMissed;
  final List<SlotWiseBreakdown> slotWiseBreakdown;

  IntakeData({
    required this.totalScheduled,
    required this.totalTaken,
    required this.totalMissed,
    required this.slotWiseBreakdown,
  });

  factory IntakeData.fromJson(Map<String, dynamic> json) {
    return IntakeData(
      totalScheduled: json['totalScheduled'] ?? 0,
      totalTaken: json['totalTaken'] ?? 0,
      totalMissed: json['totalMissed'] ?? 0,
      slotWiseBreakdown: (json['slotWiseBreakdown'] as List<dynamic>?)
          ?.map((e) => SlotWiseBreakdown.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class SlotWiseBreakdown {
  final String timeSlot;
  final int totalScheduled;
  final int totalTaken;

  SlotWiseBreakdown({
    required this.timeSlot,
    required this.totalScheduled,
    required this.totalTaken,
  });

  factory SlotWiseBreakdown.fromJson(Map<String, dynamic> json) {
    return SlotWiseBreakdown(
      timeSlot: json['timeSlot'] ?? '',
      totalScheduled: json['totalScheduled'] ?? 0,
      totalTaken: json['totalTaken'] ?? 0,
    );
  }
}
