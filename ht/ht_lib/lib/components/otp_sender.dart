import 'dart:async';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class OtpResendRow extends StatefulWidget {
  final VoidCallback sendOtpCallback;

  const OtpResendRow({super.key, required this.sendOtpCallback});

  @override
  State<OtpResendRow> createState() => _OtpResendRowState();
}

class _OtpResendRowState extends State<OtpResendRow> {
  int counter = 60; // start from 59 → 00
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startCountdown();
  }

  void startCountdown() {
    _timer?.cancel(); // clear old timer if exists
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (counter == 0) {
        timer.cancel(); // stop when it reaches 0
        setState(() {});
      } else {
        setState(() {
          counter--;
        });
      }
    });
  }

  void onResendPressed() {
    widget.sendOtpCallback();
    setState(() {
      counter = 61; // reset to 59 seconds
    });
    startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Expanded(
          flex: 2,
            child: Text("Didn't receive the code? ")
        ),
        Expanded(
          child: TextButton(
            onPressed: (counter == 0) ? onResendPressed : null,
            child: counter > 0
                ? Text(
              "Resend in ${formatTime(counter)}s",
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 10
              ),
            )
                : const Text(
              "Resend",
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
