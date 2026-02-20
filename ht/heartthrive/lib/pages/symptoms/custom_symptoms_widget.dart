import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomSymptomInput extends StatefulWidget {
  final TextEditingController controller;
  final int maxLength;
  final FocusNode? focusNode;
  final Function(String)? onChanged;

  const CustomSymptomInput({
    super.key,
    required this.controller,
    this.maxLength = 250,
    this.focusNode,
    this.onChanged,
  });

  @override
  State<CustomSymptomInput> createState() =>
      _CustomSymptomInputState();
}

class _CustomSymptomInputState
    extends State<CustomSymptomInput> {
  int _currentLength = 0;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _currentLength = widget.controller.text.length;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Custom symptom',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: TextInputType.text,           // normal text keyboard
          enableSuggestions: true,                    // keep true if you want auto-correct
          autocorrect: true,
          /// 🔑 THIS IS THE KEY
          minLines: 1,        // starts compact
          maxLines: null,        // grows naturally, then scrolls

          maxLength: widget.maxLength,

          onChanged: (value) {
            setState(() {
              _currentLength = value.length;
              if (value.trim().isNotEmpty &&
                  value.trim().length < 3) {
                _errorText = 'Enter at least 3 characters';
              } else {
                _errorText = null;
              }
            });

            widget.onChanged?.call(value);
          },

          decoration: InputDecoration(
            hintText:
            'Type symptom (e.g., "shoes feel tighter")',
            errorText: _errorText,
            filled: true,
            fillColor: const Color(0xFFF3F3F3),
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$_currentLength / ${widget.maxLength} characters',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
