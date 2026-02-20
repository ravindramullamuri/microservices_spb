import 'package:flutter/material.dart';

class SymptomRadioGroup extends StatefulWidget {
  final String question;
  final ValueChanged<bool?> onChanged; // true = Yes, false = No, null = none

  const SymptomRadioGroup({
    super.key,
    required this.question,
    required this.onChanged,
  });

  @override
  State<SymptomRadioGroup> createState() => _SymptomRadioGroupState();
}

class _SymptomRadioGroupState extends State<SymptomRadioGroup> {
  bool? _selectedValue; // null = none, true = Yes, false = No

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.question,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // YES Option
            GestureDetector(
              onTap: () {
                setState(() => _selectedValue = true);
                widget.onChanged(true);
              },
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF8C1B1A),
                        width: 2,
                      ),

                    ),
                    child: _selectedValue == true
                        ? Center(
                      child: Icon(
                        Icons.circle,
                        size: 14,
                        color:_selectedValue == true
                            ? const Color(0xFF8C1B1A)
                            : Colors.transparent,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Yes",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40),

            // NO Option
            GestureDetector(
              onTap: () {
                setState(() => _selectedValue = false);
                widget.onChanged(false);
              },
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF8C1B1A),
                        width: 2,
                      ),

                    ),
                    child: _selectedValue == false
                        ? Center(
                      child: Icon(
                        Icons.circle,
                        size: 14,
                        color: _selectedValue == false
                            ? const Color(0xFF8C1B1A)
                            : Colors.transparent,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "No",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}