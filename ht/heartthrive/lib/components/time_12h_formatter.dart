String formatTo12Hour(dynamic value) {
  Duration duration;

  // 🔥 If input is already Duration
  if (value is Duration) {
    duration = value;
  }

  // 🔥 If input is String: "HH:mm:ss" or "HH:mm"
  else if (value is String) {
    final trimmed = value.trim();

    final parts = trimmed.split(":");
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;

      duration = Duration(hours: hour, minutes: minute);
    } else {
      throw FormatException("Invalid time format: $value");
    }
  }

  // ❌ Unsupported type
  else {
    throw ArgumentError("formatTo12Hour() only accepts Duration or HH:mm:ss string");
  }

  // Convert duration → 12-hour format
  int totalMinutes = duration.inMinutes;
  int hours = totalMinutes ~/ 60;
  int minutes = totalMinutes % 60;

  String period = hours >= 12 ? "PM" : "AM";

  int hour12 = hours % 12;
  if (hour12 == 0) hour12 = 12; // handles 00 => 12 AM & 12 => 12 PM

  final minuteStr = minutes.toString().padLeft(2, '0');

  return "$hour12:$minuteStr $period";
}
