import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import 'package:heart_thrive/theme/app_theme.dart';
import '../../models/medication/medication_intake_summary.dart';

class MedicationDoseBanner extends StatefulWidget {
  final IntakeMedicationSummary intakeSummary;
  final bool isMissedDose;

  const MedicationDoseBanner({
    Key? key,
    required this.intakeSummary,
    this.isMissedDose = false,
  }) : super(key: key);

  @override
  State<MedicationDoseBanner> createState() => _MedicationDoseBannerState();
}

class _MedicationDoseBannerState extends State<MedicationDoseBanner> {
  int _currentIndex = 0;
  Timer? _timer; // ← Use nullable Timer to avoid late error
  List<String> _statusMessages = [];

  @override
  void initState() {
    super.initState();
    _prepareStatusMessages();
    _startTimer(); // ← Safe: only starts if messages exist
  }

  void _prepareStatusMessages() {
    final data = widget.intakeSummary.data;
    if (data == null) {
      _statusMessages = [];
      return;
    }

    _statusMessages = widget.isMissedDose
        ? data.missedStatusMessages
        : data.statusMessages;

    // Filter out null/empty messages
    _statusMessages = _statusMessages.where((msg) => msg.trim().isNotEmpty).toList();
  }

  void _startTimer() {
    // Cancel any existing timer first
    _timer?.cancel();

    if (_statusMessages.isEmpty || !mounted) return;

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _currentIndex = (_currentIndex + 1) % _statusMessages.length;
      });
    });
  }

  void _goLeft() {
    if (_statusMessages.isEmpty) return;

    setState(() {
      _currentIndex = (_currentIndex - 1 + _statusMessages.length) % _statusMessages.length;
    });
    _restartTimer();
  }

  void _goRight() {
    if (_statusMessages.isEmpty) return;

    setState(() {
      _currentIndex = (_currentIndex + 1) % _statusMessages.length;
    });
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    _startTimer();
  }

  @override
  void didUpdateWidget(MedicationDoseBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-prepare messages if intakeSummary changes
    if (oldWidget.intakeSummary != widget.intakeSummary ||
        oldWidget.isMissedDose != widget.isMissedDose) {
      _prepareStatusMessages();
      _restartTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // ← Cancel BEFORE super.dispose()
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_statusMessages.isEmpty) {
      return const SizedBox.shrink();
    }

    final message = _statusMessages[_currentIndex];

    return Container(
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: widget.isMissedDose ? Color(0xFFF44336) : const Color(0xffFFEB3B),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.arrow_back_ios, size: 20, color: widget.isMissedDose? Colors.white : Colors.black87),
            onPressed: _goLeft,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.3),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Tooltip(
                message: message,
                waitDuration: const Duration(milliseconds: 300),
                child: Text(
                  message,
                  key: ValueKey<int>(_currentIndex),
                  textAlign: TextAlign.center,
                  style: AppTheme.title14.copyWith(
                    color:  widget.isMissedDose? Colors.white:Colors.black87,
                    fontSize: deviceWidth(context)>830?18:14
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.arrow_forward_ios, size: 20, color: widget.isMissedDose? Colors.white : Colors.black87),
            onPressed: _goRight,
          ),
        ],
      ),
    );
  }
}