import 'package:intl/intl.dart';

String formatNumberWithCommas(dynamic value) {
  if (value == null) return "0";

  String raw = value.toString().trim();

  // Extract number pattern
  final match = RegExp(r'([-+]?\d+(?:\.\d+)?)').firstMatch(raw);
  if (match == null) return raw;

  String numPart = match.group(0)!;     // e.g. "629.556"
  String suffix = raw.replaceFirst(numPart, "").trim();

  List<String> parts = numPart.split('.');

  // Format the whole number with commas
  String wholePart = parts[0];
  String formattedWhole = NumberFormat('#,###').format(int.parse(wholePart));

  // No decimals → return formatted whole part
  if (parts.length == 1) {
    return suffix.isNotEmpty ? "$formattedWhole $suffix" : formattedWhole;
  }

  // --- DECIMAL HANDLING (MAX 2 DIGITS, NO ROUNDING) ---
  String decimalPart = parts[1];

  // If more than 2 decimal digits → truncate (NOT round)
  if (decimalPart.length > 2) {
    decimalPart = decimalPart.substring(0, 2);
  }

  // Remove trailing zeros
  decimalPart = decimalPart.replaceFirst(RegExp(r'0+$'), "");

  // If decimals become empty, return integer
  if (decimalPart.isEmpty) {
    return suffix.isNotEmpty ? "$formattedWhole $suffix" : formattedWhole;
  }

  final finalValue = "$formattedWhole.$decimalPart";
  return suffix.isNotEmpty ? "$finalValue $suffix" : finalValue;
}

