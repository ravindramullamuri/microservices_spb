import 'package:flutter/services.dart';

class FirstLetterAlphaAlnumFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;

    if (text.isEmpty) return newValue;

    // ✅ First character must be an alphabet
    if (!RegExp(r'^[A-Za-z]').hasMatch(text[0])) {
      return oldValue;
    }

    // ✅ Allow alphabets, numbers, and spaces after the first character
    if (!RegExp(r'^[A-Za-z0-9 ]*$').hasMatch(text)) {
      return oldValue;
    }

    return newValue;
  }
}

class DecimalTextInputFormatter extends TextInputFormatter {
  final int maxDigitsBeforeDecimal;
  final int maxDigitsAfterDecimal;

  DecimalTextInputFormatter({this.maxDigitsBeforeDecimal = 3, this.maxDigitsAfterDecimal = 2});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text;

    if (text.isEmpty) return newValue;

    // Split by decimal point
    final parts = text.split('.');

    // Check digits before decimal
    if (parts[0].length > maxDigitsBeforeDecimal) {
      return oldValue; // block further input
    }

    // Check digits after decimal
    if (parts.length > 1 && parts[1].length > maxDigitsAfterDecimal) {
      return oldValue; // block further input
    }

    // Allow
    return newValue;
  }
}

