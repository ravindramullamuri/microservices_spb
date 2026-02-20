import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_timezone/timezone_info.dart';

String? getBMICategory(double bmi) {
  if (bmi < 18.5) return "Underweight";
  if (bmi < 25.0) return "Normal";
  if (bmi < 30.0) return "Overweight";
  if (bmi < 40.0) return "Obesity";
  return "Extreme";
}

Color getCategoryColor(String? category) {
  switch (category) {
    case "Underweight":
      return const Color(0xff29E33C);
    case "Normal":
      return const Color(0xff9FB12B);
    case "Overweight":
      return const Color(0xffFECA2A);
    case "Obesity":
      return const Color(0xffF56200);
    case "Extreme":
      return const Color(0xffF60000);
    default:
      return Colors.grey; // Default color for invalid state
  }
}
Color getIndexColor(int index) {
  switch (index) {
    case 1:
      return const Color(0xff29E33C);
    case 2:
      return const Color(0xff9FB12B);
    case 3:
      return const Color(0xffFECA2A);
    case 4:
      return const Color(0xffF56200);
    case 5:
      return const Color(0xffF60000);
    default:
      return Colors.grey; // Default color for invalid state
  }
}

Map<String, dynamic> parseMeasurement(String input) {
  final regex = RegExp(r'([\d.]+)\s*(kg|lb|cm|in)', caseSensitive: false);
  final match = regex.firstMatch(input.trim());

  if (match != null) {
    final value = double.tryParse(match.group(1)!) ?? 0.0;
    final unit = match.group(2)!.toLowerCase();
    return {'value': value, 'unit': unit};
  }

  return {'value': 0.0, 'unit': ''};
}

//
String formatDurationHMS(Duration d) {
final h = d.inHours.toString().padLeft(2, '0');
final m = (d.inMinutes % 60).toString().padLeft(2, '0');
final s = (d.inSeconds % 60).toString().padLeft(2, '0');
return "$h:$m:$s";
}

Future<String> getTimeZone() async {
  final TimezoneInfo timezoneInfo = await FlutterTimezone.getLocalTimezone();
  return timezoneInfo.identifier;
}


