// bmi_dashboard_screen.dart
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '../../constants/ui_constants.dart';
import '../../theme/app_theme.dart';
import '../../utils/secure_storage_utils.dart';
import 'package:heart_thrive/core/api_endpoints.dart';

// ====================== MODELS ======================

class DeltaInfo {
  final String current;
  final String previous;
  final String changeType;
  final String deltaValue;

  DeltaInfo({
    required this.current,
    required this.previous,
    required this.changeType,
    required this.deltaValue,
  });

  factory DeltaInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return DeltaInfo(current: "0", previous: "0", changeType: "0", deltaValue: "0");
    }
    String read(String key) => (json.containsKey(key) && json[key] != null) ? json[key].toString() : "0";
    return DeltaInfo(
      current: read('currentWeight') != 'null' ? read('currentWeight') : read('currentWeekWeight'),
      previous: read('previousWeight') != 'null' ? read('previousWeight') : read('previousWeekWeight'),
      changeType: read('changeType'),
      deltaValue: read('deltaValue'),
    );
  }
}

class DayRecord {
  final int dayIndex;
  final String currentWeight;
  final DeltaInfo deltaWeight;
  final DeltaInfo deltaDay;
  final double bmiValue;
  final String bmiStatus;
  final String recordedAt;

  DayRecord({
    required this.dayIndex,
    required this.currentWeight,
    required this.deltaWeight,
    required this.deltaDay,
    required this.bmiValue,
    required this.bmiStatus,
    required this.recordedAt,
  });

  factory DayRecord.fromJson(Map<String, dynamic> json, int index) {
    double parseDouble(dynamic v) {
      try {
        if (v == null) return 0.0;
        return (v is num) ? v.toDouble() : double.parse(v.toString());
      } catch (_) {
        return 0.0;
      }
    }

    return DayRecord(
      dayIndex: json['day'] ?? (index + 1),
      currentWeight: json['currentWeight']?.toString() ?? '0',
      deltaWeight: DeltaInfo.fromJson(json['deltaWeight']),
      deltaDay: DeltaInfo.fromJson(json['deltaDay']),
      bmiValue: parseDouble(json['bmiValue']),
      bmiStatus: json['bmiStatus']?.toString() ?? '0',
      recordedAt: json['recordedAt']?.toString() ?? '',
    );
  }
}

class WeekRecord {
  final int weekIndex; // 1..5
  final String averageWeight; // value as string in API
  final DeltaInfo deltaWeek;
  final double averageBmiValue;
  final String bmiStatus;
  final String recordedAt;

  WeekRecord({
    required this.weekIndex,
    required this.averageWeight,
    required this.deltaWeek,
    required this.averageBmiValue,
    required this.bmiStatus,
    required this.recordedAt,
  });

  factory WeekRecord.fromJson(Map<String, dynamic> json, int index) {
    double parseDouble(dynamic v) {
      try {
        if (v == null) return 0.0;
        return (v is num) ? v.toDouble() : double.parse(v.toString());
      } catch (_) {
        return 0.0;
      }
    }

    return WeekRecord(
      weekIndex: (json['week'] != null) ? (int.tryParse(json['week'].toString()) ?? (index + 1)) : (index + 1),
      averageWeight: json['averageWeight']?.toString() ?? '0',
      deltaWeek: DeltaInfo.fromJson(json['deltaWeek'] as Map<String, dynamic>?),
      averageBmiValue: parseDouble(json['averageBmiValue']),
      bmiStatus: json['bmiStatus']?.toString() ?? '0',
      recordedAt: json['recordedAt']?.toString() ?? '',
    );
  }
}

class BmiDashboardResponse {
  final bool success;
  final String message;
  final String weightUnit; // "kgs" or "lbs"
  final String currentWeight;
  final double safeWeight;
  final List<DayRecord> dayRecords;
  final List<WeekRecord> weekRecords;

  BmiDashboardResponse({
    required this.success,
    required this.message,
    required this.weightUnit,
    required this.currentWeight,
    required this.safeWeight,
    required this.dayRecords,
    required this.weekRecords,
  });

  factory BmiDashboardResponse.fromJson(Map<String, dynamic> json) {
    final weightUnit = json['weight unit']?.toString() ?? json['weightUnit']?.toString() ?? 'kgs';
    final currentWeight = json['currentWeight']?.toString() ?? '0';
    double parseSafe(dynamic v) {
      try {
        if (v == null) return 0.0;
        return (v is num) ? v.toDouble() : double.parse(v.toString());
      } catch (_) {
        return 0.0;
      }
    }

    final raw = json['data'] as List<dynamic>? ?? [];

    // Detect which shape: day objects have 'day' key, week objects have 'week' key
    final dayRecords = <DayRecord>[];
    final weekRecords = <WeekRecord>[];

    for (int i = 0; i < raw.length; i++) {
      final item = raw[i] as Map<String, dynamic>;
      if (item.containsKey('day')) {
        dayRecords.add(DayRecord.fromJson(item, i));
      } else if (item.containsKey('week')) {
        weekRecords.add(WeekRecord.fromJson(item, i));
      } else {
        // fallback heuristics: if it has 'averageWeight' treat as week
        if (item.containsKey('averageWeight') || item.containsKey('deltaWeek')) {
          weekRecords.add(WeekRecord.fromJson(item, i));
        } else {
          dayRecords.add(DayRecord.fromJson(item, i));
        }
      }
    }

    return BmiDashboardResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      weightUnit: weightUnit,
      currentWeight: currentWeight,
      safeWeight: parseSafe(json['safeWeight']),
      dayRecords: dayRecords,
      weekRecords: weekRecords,
    );
  }
}

// ====================== MAIN SCREEN ======================

class WeightDashboardScreen extends StatefulWidget {
  const WeightDashboardScreen({super.key});

  @override
  State<WeightDashboardScreen> createState() => _WeightDashboardScreenState();
}

class _WeightDashboardScreenState extends State<WeightDashboardScreen> {
  BmiDashboardResponse? responseData;
  String viewMode = 'week'; // default (user can pick day/week/month)
  bool isLoading = true;
  bool isError = false;
  DateTime currentDate = DateTime.now();
  String? authToken;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    final storage = SecureStorageUtils();
    authToken = await storage.read("auth_token");
    if (authToken == null || authToken!.isEmpty) {
      setState(() => isError = true);
      return;
    }
    await fetchBmiData();
  }

  DateTime getPeriodStart() {

    if (viewMode == 'day') {
      return DateTime(currentDate.year, currentDate.month, currentDate.day);
    } else if (viewMode == 'week') {
      return currentDate.subtract(Duration(days: currentDate.weekday - 1));
    } else {
      return DateTime(currentDate.year, currentDate.month, 1);
    }
  }

  DateTime getPeriodEnd() {
    final start = getPeriodStart();
    if (viewMode == 'day') return start;
    if (viewMode == 'week') return start.add(const Duration(days: 6));
    return DateTime(start.year, start.month + 1, 0);
  }

  String getPeriodDisplayText() {
    final start = getPeriodStart();
    final end = getPeriodEnd();
    if (viewMode == 'day') return DateFormat('MMM dd, yyyy').format(start);
    if (viewMode == 'week') {
      return '${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd, yyyy').format(end)}';
    }
    return DateFormat('MMMM yyyy').format(start);
  }

  Future<void> fetchBmiData() async {
    setState(() {
      isLoading = true;
      isError = false;
    });

    final start = getPeriodStart();
    final end = getPeriodEnd();
    final timezone = await FlutterTimezone.getLocalTimezone();

    // IMPORTANT: groupBy per your new API requirement:
    final groupBy = (viewMode == 'month') ? 'day' : 'day';
    String dashboardUrl = ApiEndpoints.dashboardWeightAndHeightEndpoint(
      start: start,
      end: end,
      timezone: timezone.identifier,
      groupBy: groupBy,
    );
    debugPrint("dashboardUrl @@@ $dashboardUrl");
    final url = Uri.parse(
      ApiEndpoints.dashboardWeightAndHeightEndpoint(
        start: start,
        end: end,
        timezone: timezone.identifier,
        groupBy: groupBy,
      ),
    );

    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer $authToken'}).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
        responseData = BmiDashboardResponse.fromJson(jsonMap);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      isError = true;
      responseData = null;
    } finally {
      setState(() => isLoading = false);
    }
  }

  void navigateDate(bool forward) {
    setState(() {
      if (viewMode == 'day') {
        currentDate = forward
            ? currentDate.add(const Duration(days: 1))
            : currentDate.subtract(const Duration(days: 1));
      } else if (viewMode == 'week') {
        currentDate = forward
            ? currentDate.add(const Duration(days: 7))
            : currentDate.subtract(const Duration(days: 7));
      } else {
        currentDate = DateTime(
          currentDate.year,
          currentDate.month + (forward ? 1 : -1),
          1,
        );
      }
    });
    fetchBmiData();
  }

  bool canNavigate(bool forward) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (forward) {
      return getPeriodEnd().isBefore(todayDate);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDateNavigator(),
        if (isLoading) const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: CircularProgressIndicator()),
        )
        else if (isError || responseData == null)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: Text('No BMI data available')),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15,horizontal: 8),
            child: WeightBarChart(
              response: responseData!,
              viewMode: viewMode,
              currentDate: currentDate,
            ),
          ),
      ],
    );
  }

  Widget _buildDateNavigator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 82,
          width: 60,
          decoration: boxDecoration(),
          child: IconButton(
            onPressed: canNavigate(false) ? () => navigateDate(false) : null,
            icon: const Icon(Icons.chevron_left, size: 40),
            color: canNavigate(false) ? null : Colors.grey,
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            height: 82,
            decoration: boxDecoration(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                DropdownButton<String>(
                  value: viewMode,
                  onChanged: (String? newValue) {
                    setState(() {
                      viewMode = newValue!;
                      if (viewMode == 'month') {
                        currentDate = DateTime(currentDate.year, currentDate.month, 1);
                      } else if (viewMode == 'day') {

                        // reset to today's date

                        currentDate = DateTime.now();

                      }

                      else if (viewMode == 'week') {

                        // reset to start of the week (optional)

                        final now = DateTime.now();

                        currentDate = now.subtract(Duration(days: now.weekday - 1)); // Monday start

                      }
                    });
                    fetchBmiData();
                  },
                  items: <String>['day', 'week', 'month']
                      .map((String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value[0].toUpperCase() + value.substring(1)),
                  ))
                      .toList(),
                ),
                Text(
                  getPeriodDisplayText(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        Container(
          height: 82,
          width: 60,
          decoration: boxDecoration(),
          child: IconButton(
            onPressed: canNavigate(true) ? () => navigateDate(true) : null,
            icon: const Icon(Icons.chevron_right, size: 40),
            color: canNavigate(true) ? null : Colors.grey,
          ),
        ),
      ],
    );
  }
}

// ====================== BAR CHART WIDGET ======================

// ====================== BAR CHART WIDGET (UPDATED) ======================

// === ONLY REPLACE THIS CLASS ===
// ====================== FIXED BAR CHART WIDGET ======================
// ====================== FINAL NO-SCROLL MONTH BAR CHART ======================
// ====================== FULLY DYNAMIC BAR CHART WIDGET ======================


class WeightBarChart extends StatefulWidget {
  final BmiDashboardResponse response;
  final String viewMode;
  final DateTime currentDate;

  const WeightBarChart({
    super.key,
    required this.response,
    required this.viewMode,
    required this.currentDate,
  });

  @override
  State<WeightBarChart> createState() => _WeightBarChartState();
}

class _WeightBarChartState extends State<WeightBarChart> {
  int touchedIndex = -1;

  List<DateTime> _getDates() {
    if (widget.viewMode == 'day') {
      return [widget.currentDate];
    }
    if (widget.viewMode == 'week') {
      final start = widget.currentDate.subtract(Duration(days: widget.currentDate.weekday - 1));
      return List.generate(7, (i) => start.add(Duration(days: i)));
    } else {
      // month
      final year = widget.currentDate.year;
      final month = widget.currentDate.month;
      final daysInMonth = DateTime(year, month + 1, 0).day;
      return List.generate(daysInMonth, (i) => DateTime(year, month, i + 1));
    }
  }

  DayRecord? _findRecord(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    try {
      return widget.response.dayRecords.firstWhere((r) => r.recordedAt == dateStr);
    } catch (_) {
      return null;
    }
  }

  double _parse(String s) => double.tryParse(s) ?? 0.0;

  Color _getBarColor(String changeType) {
    debugPrint("changeType @@@ $changeType");
    if (changeType == "1" || changeType.toLowerCase().contains("increase")) return Colors.red;
    if (changeType == "2" || changeType.toLowerCase().contains("decrease")) return const Color(0xFFFFB800);
    return Colors.green;
  }

  String _formatDelta(String current, String previous, String changeType) {
    final c = _parse(current);
    final p = _parse(previous);
    if (c <= 0 || p <= 0) return "";
    final delta = c - p;
    final sign = delta > 0 ? "+" : "";
    final arrow = delta > 0 ? "↑" : delta < 0 ? "↓" : "";
    return "$sign${delta.toStringAsFixed(1)} $arrow";
  }

  // ====================== DYNAMIC Y-AXIS LOGIC ======================
  double _niceNumber(double value, bool roundUp) {
    if (value <= 0) return 1;
    final magnitude = math.pow(10, (math.log(value) / math.log(10)).floor()).toDouble();
    final normalized = value / magnitude;

    double nice;
    if (roundUp) {
      if (normalized < 1.5) nice = 2;
      else if (normalized < 3) nice = 3;
      else if (normalized < 7) nice = 7;
      else nice = 10;
    } else {
      if (normalized <= 1) nice = 1;
      else if (normalized <= 2) nice = 2;
      else if (normalized <= 5) nice = 5;
      else nice = 10;
    }
    return nice * magnitude;
  }

  double _niceCeil(double value) {
    if (value <= 0) return 100;
    final magnitude = math.pow(10, (math.log(value) / math.log(10)).floor()).toDouble();
    final normalized = value / magnitude;

    double ceiling;
    if (normalized < 1.1) ceiling = 1.1;
    else if (normalized < 2.5) ceiling = 2.5;
    else if (normalized < 5) ceiling = 5;
    else ceiling = normalized.ceil().toDouble();

    return ceiling * magnitude;
  }

  ({double maxY, double minY, double interval}) _calculateDynamicAxis() {
    final List<double> allWeights = [];

    // Current weight
    final currentW = double.tryParse(widget.response.currentWeight) ?? 0.0;
    if (currentW > 0) allWeights.add(currentW);

    // All day records
    for (final record in widget.response.dayRecords) {

      final w1 = _parse(record.deltaWeight.current);
      final w2 = _parse(record.deltaDay.current);
      final w = w1 > 0 ? w1 : w2;
      if (w > 0) allWeights.add(w);
    }

    // Safe weight
    final safeWeight = widget.response.safeWeight;
    if (safeWeight > 0) allWeights.add(safeWeight);

    if (allWeights.isEmpty) {
      allWeights.addAll([60, 80]); // fallback
    }

    final maxRecorded = allWeights.reduce(math.max);
    final minRecorded = allWeights.isNotEmpty ? allWeights.reduce(math.min) : maxRecorded;

    double maxY = maxRecorded * 1.15;
    if (safeWeight > maxY) maxY = safeWeight * 1.1;
    maxY = _niceCeil(maxY);

    // Ensure safe weight is clearly visible
    if (safeWeight > maxY * 0.9) {
      maxY = safeWeight * 1.15;
      maxY = _niceCeil(maxY);
    }

    final roughInterval = maxY / 6.0;
    double interval = _niceNumber(roughInterval, false);

    final minInterval = widget.response.weightUnit.toLowerCase() == 'lbs' ? 10.0 : 5.0;
    if (interval < minInterval) {
      interval = _niceNumber(minInterval, true);
    }

    return (maxY: maxY, minY: 0.0, interval: interval);
  }

  @override
  Widget build(BuildContext context) {
    final isLbs = widget.response.weightUnit.toLowerCase() == 'lbs';
    final unit = isLbs ? 'lbs' : 'kg';
    final safeWeight = widget.response.safeWeight;


    final axis = _calculateDynamicAxis();
    final maxY = axis.maxY;
    final interval = axis.interval;

    final dates = _getDates();
    final isDayView = widget.viewMode == 'day';
    final isMonthView = widget.viewMode == 'month';



    final alignment = isDayView
        ? BarChartAlignment.center
        : isMonthView
        ? BarChartAlignment.spaceBetween
        : BarChartAlignment.spaceAround;

    final availableWidth = MediaQuery.of(context).size.width *0.8;
    debugPrint("availableWidth @@ $availableWidth");
    final daysCount = dates.length;
    final spacePerDay = availableWidth / (isDayView ? 1 : daysCount);
    debugPrint("577 spacePerDay @@@ $spacePerDay");
    final barWidth = isDayView
        ? 20.0
        : isMonthView
        ? (spacePerDay * 0.15).clamp(5.0, 16.0)
        : 20.0;
    final groupSpace = isDayView ? 0.0 : isMonthView ? (spacePerDay * 1.35) : 28.0;
    debugPrint("577 barWidth @@@ $barWidth groupSpace : $groupSpace");
    final barGroups = dates.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      final record = _findRecord(date);

      double weight = 0.0;
      String deltaWeightCurrent = "0", deltaWeightPrevious = "0", deltaWeightType = "0";

      if (record != null) {
        weight = _parse(record.currentWeight);
        if (weight <= 0) weight = _parse(record.currentWeight);
        debugPrint("safeWeight @@@ $safeWeight");
        double changeWeight = weight - safeWeight;
        double eps = 1e-6; // small tolerance
        debugPrint("changeWeight @@@ $changeWeight");
        if (changeWeight > 0) {
          deltaWeightType = "increase";
        } else if (changeWeight < 0) {
          deltaWeightType = "decrease";
        } else {
          deltaWeightType = "no change";
        }


      }

      final displayY = weight <= 0 ? 0.5 : weight;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: displayY,
            color: weight <= 0
                ? Colors.grey.withValues(alpha: 0.3)
                : _getBarColor(deltaWeightType),
            width: barWidth,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
          ),
        ],
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SizedBox(
            height: 320,
            //width: MediaQuery.of(context).size.width,
            child: BarChart(
              BarChartData(
                alignment: alignment,
                maxY: maxY,
                minY: 0,
                groupsSpace: groupSpace,
                gridData: FlGridData(show: true,verticalInterval: interval),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        final isSafeLine = (value - safeWeight).abs() < (interval * 0.1);
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            value.toInt() == value ? value.toInt().toString() : value.toStringAsFixed(1),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSafeLine ? FontWeight.bold : FontWeight.w800,
                              color: isSafeLine ? Colors.green : Colors.black87,
                            ),

                          ),
                        );
                      },
                    ),
                    axisNameSize: 20,
                    axisNameWidget: Center(
                      child: RotatedBox(
                        quarterTurns: 10, // rotates clockwise (top to bottom)
                        child: Text(
                          "Weight(${isLbs ? 'lbs' : 'kg'})",
                          style: AppTheme.body12,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= dates.length) return const SizedBox();

                        if (isMonthView && index % 4 != 0 && dates[index].day != 1) {
                          return const SizedBox();
                        }

                        final dayText = DateFormat(
                          isDayView
                              ? 'MMM dd  yyyy'
                              : isMonthView && dates[index].day == 1
                              ? 'MMM dd'
                              : 'dd',
                        ).format(dates[index]);

                        return SideTitleWidget(
                          meta: meta,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              dayText,
                              style: TextStyle(
                                fontSize: isDayView ? 16 : 11,
                                fontWeight: FontWeight.w600,
                                color: dates[index].day == 1 ? Colors.purple : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    axisNameWidget:  Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          widget.viewMode == "month"?'Day of the Month':widget.viewMode == "week"?'Days of the Week':"Day",
                          style: AppTheme.body12,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    axisNameSize: 35,
                  ),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    maxContentWidth: 200,
                    fitInsideHorizontally: true,
                    tooltipPadding: const EdgeInsets.all(10),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final date = dates[group.x];
                      final record = _findRecord(date);
                      if (record == null) return null;




                      final currentDayWeight = _parse(record.deltaWeight.current);
                      final prevDayWeight = _parse(record.deltaWeight.previous);
                      final deltaDayWeight = currentDayWeight > 0 && prevDayWeight > 0 ? (currentDayWeight - prevDayWeight) : 0.0;

                      final deltaW = deltaDayWeight != 0
                          ? "${deltaDayWeight > 0 ? '+' : ''}${deltaDayWeight.toStringAsFixed(2)} $unit ${deltaDayWeight > 0 ? '↑' : '↓'}"
                          : "0 $unit";

                      final currentDay = _parse(record.deltaDay.current);
                      final prevDay = _parse(record.deltaDay.previous);
                      final deltaDay = currentDay > 0 && prevDay > 0 ? (currentDay - prevDay) : 0.0;

                      final deltaDayText = deltaDay != 0
                          ? "${deltaDay > 0 ? '+' : ''}${deltaDay.toStringAsFixed(2)} ${unit} ${deltaDay > 0 ? '↑' : '↓'}"
                          : "0 $unit";

                      return BarTooltipItem(
                        '',
                        const TextStyle(color: Colors.white, fontSize: 13),

                        children: [
                          /// Date
                          TextSpan(
                            text: DateFormat('MMM dd').format(date),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              /// Current Weight
                              TextSpan(
                                text: '\nCurrent Weight: ${record.currentWeight} $unit\n',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ]
                          ),



                          /// Delta vs Previous
                          TextSpan(
                            text: 'Delta weight (in $unit):\n${record.deltaWeight.current} - ${record.deltaWeight.previous} = \t',
                            style: const TextStyle(
                              height: 2.0,
                              fontSize: 12,
                              color: Colors.white70,
                                fontWeight: FontWeight.bold
                            ),
                            children: [
                              TextSpan(
                                text: '$deltaW\n',
                                style:  TextStyle(
                                    height: 1.0,
                                  fontSize: 13,
                                  color: deltaDayWeight > 0 ?Colors.red:Colors.green,
                                  backgroundColor: Colors.white,
                                  fontWeight: FontWeight.bold
                                ),
                              )
                            ]
                          ),

                          /// 3-Day Delta
                          TextSpan(
                              text: 'Delta ${record.dayIndex} Day (in $unit):\n${record.deltaDay.current} - ${record.deltaDay.previous} = \t',
                            style: const TextStyle(
                                height: 2.0,
                              fontSize: 13,
                              color: Colors.white70,
                                fontWeight: FontWeight.bold
                            ),
                              children: [
                                TextSpan(
                                  text: '$deltaDayText\n',
                                  style: TextStyle(
                                      height: 1.0,
                                      fontSize: 13,
                                      color: deltaDay > 0 ? Colors.red:Colors.green,
                                      backgroundColor: Colors.white,
                                      fontWeight: FontWeight.bold
                                  ),
                                )
                              ]
                          ),

                        ],
                        textAlign: TextAlign.start
                      );
                    },
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: safeWeight > 0 && safeWeight < maxY
                      ? [
                    HorizontalLine(
                      y: safeWeight,
                      color: Colors.green.withValues(alpha: 0.8),
                      strokeWidth: 2.8,
                      dashArray: [12, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.only(left: 0, top: 4),
                        style:  AppTheme.title16.copyWith(
                          color: Colors.green,
                        ),
                        labelResolver: (_) => 'Safe Weight → ${safeWeight.toStringAsFixed(2)} $unit',
                      ),
                    ),
                  ]
                      : [],
                ),
                barGroups: barGroups,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend("Normal", Colors.green),
              const SizedBox(width: 16),
              _legend("Increased", Colors.red),
              const SizedBox(width: 16),
              _legend("Decreased", const Color(0xFFFFB800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
  // Day
  String formatDayWithSuffix(DateTime date) {
    int day = int.parse(DateFormat('d').format(date));

    if (day >= 11 && day <= 13) {
      return "${day}th"; // special case for 11th–13th
    }

    switch (day % 10) {
      case 1:
        return "${day}st";
      case 2:
        return "${day}nd";
      case 3:
        return "${day}rd";
      default:
        return "${day}th";
    }
  }

}

