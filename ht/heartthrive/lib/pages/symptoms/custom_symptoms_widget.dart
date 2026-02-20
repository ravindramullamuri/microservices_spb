import 'package:flutter/material.dart';

class CustomSymptomInput extends StatefulWidget {
  final TextEditingController controller;
  final int maxLength;
  final FocusNode? focusNode;
  final Function(String)? onChanged;
  final String? errorText; // 👈 Parent-controlled error

  const CustomSymptomInput({
    super.key,
    required this.controller,
    this.maxLength = 250,
    this.focusNode,
    this.onChanged,
    this.errorText,
  });

  @override
  State<CustomSymptomInput> createState() => _CustomSymptomInputState();
}

class _CustomSymptomInputState extends State<CustomSymptomInput> {
  int _currentLength = 0;

  @override
  void initState() {
    super.initState();
    _currentLength = widget.controller.text.length;

    widget.controller.addListener(_updateLength);
  }

  void _updateLength() {
    if (mounted) {
      setState(() {
        _currentLength = widget.controller.text.length;
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateLength);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Custom symptom',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),

        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: TextInputType.text,
          enableSuggestions: true,
          autocorrect: true,
          minLines: 1,
          maxLines: null,
          maxLength: widget.maxLength,

          onChanged: widget.onChanged,

          decoration: InputDecoration(
            hintText: 'Type symptom (e.g., "shoes feel tighter")',
            errorText: widget.errorText,
            filled: true,
            fillColor: const Color(0xFFF3F3F3),

            counterText: '',

            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}