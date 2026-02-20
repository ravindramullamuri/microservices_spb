import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heart_thrive/theme/app_theme.dart';
import 'package:intl/intl.dart';

import '../constants/ui_constants.dart';

class DOBField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final bool isMyMedList;
  final bool allowFutureDates;
  final String? Function(String?)? validator; // <-- added validator

  const DOBField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.isMyMedList = false,
    this.allowFutureDates = false,
    this.validator, // <-- accept validator
  });

  @override
  State<DOBField> createState() => _DOBFieldState();
}

class _DOBFieldState extends State<DOBField> {
  final _dobFocusNode = FocusNode();

  void _formatAndValidate(String input) {
    String numbers = input.replaceAll(RegExp(r'[^0-9]'), "");

    if (numbers.length > 8) numbers = numbers.substring(0, 8);

    String formatted = "";
    if (numbers.length >= 2) {
      String dd = numbers.substring(0, 2);
      int day = int.tryParse(dd) ?? 0;
      if (day <= 0 || day > 31) {
        _showError("Invalid day");
        return;
      }
      formatted = dd.padLeft(2, "0") + "/";
    } else {
      formatted = numbers;
    }

    if (numbers.length >= 4) {
      String mm = numbers.substring(2, 4);
      int month = int.tryParse(mm) ?? 0;
      if (month <= 0 || month > 12) {
        _showError("Invalid month");
        return;
      }
      formatted += mm.padLeft(2, "0") + "/";
    } else if (numbers.length > 2) {
      formatted += numbers.substring(2);
    }

    if (numbers.length > 4) {
      String yyyy = numbers.substring(4);
      formatted += yyyy;
      if (yyyy.length == 4) {
        try {
          final parsed = DateFormat("mm/dd/yyyy").parseStrict(formatted);
          if (!widget.allowFutureDates && parsed.isAfter(DateTime.now())) {
            _showError("Date cannot be in the future");
            return;
          }
        } catch (_) {
          _showError("Invalid date");
          return;
        }
      }
    }

    if (formatted != widget.controller.text) {
      widget.controller.text = formatted;
      widget.controller.selection =
          TextSelection.fromPosition(TextPosition(offset: formatted.length));
    }

    if (widget.onChanged != null) {
      widget.onChanged!(formatted);
    }
  }

  void _showError(String msg) {
    widget.controller.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.isMyMedList ? now : now.subtract(const Duration(days: 365 * 18)),
      firstDate: widget.isMyMedList ? now : DateTime(1900),
      lastDate: widget.allowFutureDates ? DateTime(2100) : now,
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('MM/dd/yyyy').format(pickedDate);
      widget.controller.text = formattedDate;
      widget.onChanged?.call(formattedDate);
    }
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) return 'Date is required';

    try {
      final parts = value.split('/');
      if (parts.length != 3) return 'Enter date in MM/dd/yyyy format';

      final month = int.tryParse(parts[0]);
      final day = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day == null || month == null || year == null) {
        return 'Invalid date numbers';
      }

      final dob = DateTime(year, month, day);
      final now = DateTime.now();

      if (!widget.allowFutureDates && dob.isAfter(now)) {
        return 'Date cannot be in the future';
      }

      if (year < 1900 || year > now.year) {
        return 'Enter a valid year';
      }

      if (day < 1 || day > 31 || month < 1 || month > 12) {

        return 'Enter a valid day or month(MM/DD/YYYY)';

      }

      if (dob.day != day || dob.month != month || dob.year != year) {
        return 'Enter a valid date';
      }

      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }

      if (age < 18) {
        return 'Age must be 18 or above';
      }

      return null;
    } catch (_) {
      return 'Invalid date format';
    }
  }


  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _dobFocusNode,
      keyboardType: TextInputType.number,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style:  TextStyle(
        fontSize: deviceWidth(context)>750? 20.0:15.0,
        color: Colors.black87,
      ),
      validator: widget.validator ?? _defaultValidator, // <-- use external validator if provided
      inputFormatters: [CleanDateFormatter()],
      decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Colors.grey, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.0),
          ),
          hintText: widget.hintText,
          hintStyle: TextStyle(fontSize: deviceWidth(context)>750? 20.0:15.0, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 16.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today_outlined, color: Colors.black),
            onPressed: () async {
              _dobFocusNode.unfocus();
              await _pickDate();
            },
          ),
          errorStyle: TextStyle(
              fontSize: deviceWidth(context)>750?18:12
          )
      ),
      onChanged: widget.onChanged,
    );
  }
}

class CleanDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {

    // Allow deletion naturally
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    String text = newValue.text;
    int cursor = newValue.selection.baseOffset;

    // Auto insert slash after 2 digits
    if (text.length == 2 && !text.contains('/')) {
      text = '$text/';
      cursor++;
    }

    // Auto insert slash after 5 characters (MM/DD)
    if (text.length == 5 && text[4] != '/') {
      text = '${text.substring(0, 5)}/';
      cursor++;
    }

    // Limit length
    if (text.length > 10) {
      text = text.substring(0, 10);
      cursor = cursor.clamp(0, 10);
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}
class DOBTextInputFormatter extends TextInputFormatter {
  static const _template = "MM/DD/YYYY";
  static const _maxLength = 10;

  bool _isDigit(String s) => RegExp(r'\d').hasMatch(s);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String oldText = _normalize(oldValue.text);
    int cursor = newValue.selection.baseOffset;

    // Detect deletion
    if (newValue.text.length < oldValue.text.length) {
      int deleteIndex = oldValue.selection.baseOffset - 1;
      if (deleteIndex < 0) deleteIndex = 0;

      if (deleteIndex == 2 || deleteIndex == 5) {
        deleteIndex--; // skip /
      }

      oldText = _replaceAt(oldText, deleteIndex, '');
      cursor = deleteIndex;
    }

    // Detect insertion
    if (newValue.text.length > oldValue.text.length) {
      String inserted =
      newValue.text.replaceFirst(oldValue.text, '');
      if (_isDigit(inserted)) {
        if (cursor == 2 || cursor == 5) cursor++;
        oldText = _replaceAt(oldText, cursor - 1, inserted);
      }
    }

    String result = _clean(oldText);

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(
        offset: cursor.clamp(0, result.length),
      ),
    );
  }

  String _normalize(String text) {
    List<String> chars = List.filled(_maxLength, '');
    for (int i = 0, j = 0; i < _maxLength && j < text.length; i++) {
      if (i == 2 || i == 5) {
        chars[i] = '/';
      } else if (_isDigit(text[j])) {
        chars[i] = text[j++];
      } else {
        j++;
      }
    }
    chars[2] = '/';
    chars[5] = '/';
    return chars.join();
  }

  String _replaceAt(String text, int index, String value) {
    if (index < 0 || index >= _maxLength) return text;
    List<String> chars = text.split('');
    chars[index] = value;
    return chars.join();
  }

  String _clean(String text) {
    List<String> chars = text.split('');
    chars[2] = '/';
    chars[5] = '/';
    return chars.join().replaceAll(RegExp(r'\s+$'), '');
  }
}
