import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:heart_thrive/core/api_endpoints.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:collection';
import 'dart:math';

import '../../constants/ui_constants.dart';
import '../../theme/app_theme.dart';
import '../../utils/secure_storage_utils.dart';

// ====================== MODEL CLASSES ======================
class WeightHeightLog {
  final String weight;
  final double bmiValue;
  final String bmiStatus;
  final String recordedAt; // "2025-10-28"
  final String last24h;

  WeightHeightLog({
    required this.weight,
    required this.bmiValue,
    required this.bmiStatus,
    required this.recordedAt,
    required this.last24h,
  });

  factory WeightHeightLog.fromJson(Map<String, dynamic> json) {
    return WeightHeightLog(
      weight: json['weight'] as String,
      bmiValue: (json['bmiValue'] as num).toDouble(),
      bmiStatus: json['bmiStatus'] as String,
      recordedAt: json['recordedAt'] as String,
      last24h: json['last24h'] as String,
    );
  }
}

class BmiDashboardData {
  final bool success;
  final String message;
  final String weightUnit;
  final List<WeightHeightLog> logs;

  BmiDashboardData({
    required this.success,
    required this.message,
    required this.weightUnit,
    required this.logs,
  });

  factory BmiDashboardData.fromJson(Map<String, dynamic> json) {
    return BmiDashboardData(
      success: json['success'] as bool,
      message: json['message'] as String,
      weightUnit: json['weight unit'] as String,
      logs: (json['data'] as List<dynamic>)
          .map((e) => WeightHeightLog.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ====================== MAIN SCREEN ======================
class BmiDashboardScreen extends StatefulWidget {
  const BmiDashboardScreen({super.key});

  @override
  State<BmiDashboardScreen> createState() => _BmiDashboardScreenState();
}

class _BmiDashboardScreenState extends State<BmiDashboardScreen> {
  late BmiDashboardData bmiData;
  String viewMode = 'week'; // default
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
    if (viewMode == 'day') {
      return DateFormat('MMMM dd, yyyy').format(start);
    } else if (viewMode == 'week') {
      return '${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd, yyyy').format(end)}';
    } else {
      return DateFormat('MMMM yyyy').format(start);
    }
  }

  Future<void> fetchBmiData() async {
    setState(() {
      isLoading = true;
      isError = false;
    });

    final start = getPeriodStart();
    final end = getPeriodEnd();
    final timezone = await FlutterTimezone.getLocalTimezone();

    final url = Uri.parse(
      ApiEndpoints.dashboardWeightAndHeightEndpoint(
          start: start,
          end: end,
          timezone: timezone.identifier
      ),
    );

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $authToken'},
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        bmiData = BmiDashboardData.fromJson(json);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      isError = true;
      bmiData = BmiDashboardData(
        success: false,
        message: 'Failed to load',
        weightUnit: 'kgs',
        logs: [],
      );
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
    return currentDate.year > 2024 ||
        (currentDate.year == 2024 && currentDate.month > 9);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: Colors.red,
      child: Column(
        children: [
          _buildDateNavigator(),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : isError || bmiData.logs.isEmpty
              ? const Center(child: Text('No BMI data available'))
              : BmiBarChart(
            data: bmiData,
            viewMode: viewMode,
            currentDate: currentDate,
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavigator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left arrow
        Container(
          height: 82,
          width: 60,
          decoration: boxDecoration(),
          child: IconButton(
            onPressed: canNavigate(false) ? () => navigateDate(false) : null,
            icon: const Icon(Icons.chevron_left,size: 40,),
            color: canNavigate(false) ? null : Colors.grey,
          ),
        ),

        // Center date selector (no Expanded)
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
        // Right arrow
        Container(
          height: 82,
          width: 60,
          decoration: boxDecoration(),
          child: IconButton(
            onPressed: canNavigate(true) ? () => navigateDate(true) : null,
            icon: const Icon(Icons.chevron_right,size: 40,),
            color: canNavigate(true) ? null : Colors.grey,
          ),
        ),
      ],
    );
  }
}

// ====================== BAR CHART WIDGET ======================
class BmiBarChart extends StatefulWidget {
  final BmiDashboardData data;
  final String viewMode;
  final DateTime currentDate;

  const BmiBarChart({
    super.key,
    required this.data,
    required this.viewMode,
    required this.currentDate,
  });

  @override
  State<BmiBarChart> createState() => _BmiBarChartState();
}

class _BmiBarChartState extends State<BmiBarChart> {
  List<LinkedHashMap<String, dynamic>> groupedData = [];
  Map<String, dynamic>? touchedGroup;

  @override
  Widget build(BuildContext context) {
    groupedData = _aggregateBmiData();

    if (groupedData.isEmpty ||
        groupedData.every((e) => e['avgBmi'] == 0.0)) {
      return const Center(child: Text('No BMI data to display'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxY(),
                barTouchData: _getBarTouchData(),
                titlesData: FlTitlesData(

                  bottomTitles: AxisTitles(
                      axisNameSize: 35, // gives space for axis label
                      sideTitles: _bottomTitles(),
                      axisNameWidget:  Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          widget.viewMode == "month"?'Weeks of the Month':widget.viewMode == "week"?'Days of the Week':"Day",
                          style: AppTheme.body12,
                          textAlign: TextAlign.center,
                        ),
                      )
                  ),
                  rightTitles: AxisTitles(
                    axisNameSize: 35, // space for the label
                    sideTitles: _rightTitles(),
                    axisNameWidget: const Center(
                      child: RotatedBox(
                        quarterTurns: 10, // rotates clockwise (top to bottom)
                        child: Text(
                          "Body Mass Index (BMI)",
                          style: AppTheme.body12,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    drawBelowEverything: true,
                  ),
                  topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData:
                const FlGridData(show: true, horizontalInterval: 5,verticalInterval: 1),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: _getBarGroups(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
          //if (touchedGroup != null) _buildTouchInfo(),
        ],
      ),
    );
  }

  double _getMaxY() {
    final maxBmi = groupedData
        .map((e) => e['avgBmi'] as double)
        .reduce(max) +
        5;
    return (maxBmi / 5).ceil() * 5;
  }

  List<BarChartGroupData> _getBarGroups() {
    return groupedData.asMap().entries.map((entry) {
      final index = entry.key;
      final avgBmi = entry.value['avgBmi'] as double;
      final color = getBMIValueBasedCategoryColor(avgBmi);

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: avgBmi,
            color: color,
            width: 18,
            borderRadius: BorderRadius.zero,
          ),
        ],
      );
    }).toList();
  }

  BarTouchData _getBarTouchData() {
    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        //tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
        tooltipPadding: const EdgeInsets.all(8),
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final item = groupedData[groupIndex];
          final avgBmi = item['avgBmi'] as double;
          final count = item['count'] as int;
          final label = item['label'] as String;

          return BarTooltipItem(
            '$label\nBMI: ${avgBmi.toStringAsFixed(2)}\nRecords: $count',
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          );
        },
      ),
      touchCallback: (event, response) {
        if (event is FlTapUpEvent && response?.spot != null) {
          final index = response!.spot!.touchedBarGroupIndex;
          setState(() {
            touchedGroup = Map.from(groupedData[index]);
          });
        }
      },
    );
  }

  SideTitles _bottomTitles() {
    return SideTitles(
      showTitles: true,
      getTitlesWidget: (value, meta) {
        final index = value.toInt();
        if (index < 0 || index >= groupedData.length) return const Text('');
        final label = groupedData[index]['label'] as String;
        return Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(label, style: AppTheme.body12),
        );
      },
    );
  }

  SideTitles _rightTitles() {
    return SideTitles(
      showTitles: true,
      interval: 5,
      getTitlesWidget: (value, meta) =>
          Text(value.toInt().toString(), style: AppTheme.body12),
    );
  }

  //
  Widget _buildLegend() {
    final items = [
      ('Underweight (< 18.5)', const Color(0xff29E33C)),
      ('Normal (18.5 - 24.9)', const Color(0xff9FB12B)),
      ('Overweight (25.0 - 29.9)', const Color(0xffFECA2A)),
      ('Obesity (30.0 - 39.9)', const Color(0xffF56200)),
      ('Extreme (>= 40)', const Color(0xffF60000)),
    ];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 0,
          crossAxisSpacing: 4,
          childAspectRatio: 8.0,
        ),
        itemBuilder: (context, index) {
          final (label, color) = items[index];
          return Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.title10,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
    );
  }


  Widget _buildLegendOld() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _legendItem('Underweight (< 18.5)', const Color(0xff29E33C)),
        _legendItem('Normal (18.5 - 24.9)', const Color(0xff9FB12B)),
        _legendItem('Overweight (25.0- 29.9)', const Color(0xffFECA2A)),
        _legendItem('Obesity (30.0- 39.9)', const Color(0xffF56200)),
        _legendItem('Extreme (>= 40)', const Color(0xffF60000)),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildTouchInfo() {
    final avgBmi = touchedGroup!['avgBmi'] as double;
    final status = _getBmiStatus(avgBmi);
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Average BMI: ${avgBmi.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Status: $status'),
            Text('Records: ${touchedGroup!['count']}'),
          ],
        ),
      ),
    );
  }

  String _getBmiStatus(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    if (bmi < 40) return 'Obese';
    return 'Severely Obese';
  }

  // ====================== AGGREGATION LOGIC ======================
  List<LinkedHashMap<String, dynamic>> _aggregateBmiData() {
    final logs = widget.data.logs;

    // ---- Parse dates safely ----
    final List<Map<String, dynamic>> parsed = [];
    for (final log in logs) {
      try {
        final parts = log.recordedAt.split('-');
        if (parts.length != 3) continue; // malformed date
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        parsed.add({
          'date': DateTime(year, month, day),
          'bmi': log.bmiValue,
        });
      } catch (_) {
        // skip bad dates
      }
    }

    // Sort once
    parsed.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    final List<LinkedHashMap<String, dynamic>> result = [];

    // ---------- DAY ----------
    if (widget.viewMode == 'day') {
      final target = DateTime(
          widget.currentDate.year, widget.currentDate.month, widget.currentDate.day);
      final dayLogs = parsed.where((l) => _isSameDay(l['date'] as DateTime, target)).toList();
      final avg = dayLogs.isEmpty
          ? 0.0
          : dayLogs.map((e) => e['bmi'] as double).reduce((a, b) => a + b) /
          dayLogs.length;

      result.add(LinkedHashMap.from({
        'label': widget.currentDate.day.toString(),
        'avgBmi': avg,
        'count': dayLogs.length,
      }));
    }

    // ---------- WEEK ----------
    else if (widget.viewMode == 'week') {
      final startOfWeek = widget.currentDate
          .subtract(Duration(days: widget.currentDate.weekday - 1));
      for (int i = 0; i < 7; i++) {
        final day = startOfWeek.add(Duration(days: i));
        final dayLogs = parsed.where((l) => _isSameDay(l['date'] as DateTime, day)).toList();
        final avg = dayLogs.isEmpty
            ? 0.0
            : dayLogs.map((e) => e['bmi'] as double).reduce((a, b) => a + b) /
            dayLogs.length;

        result.add(LinkedHashMap.from({
          'label': day.day.toString().padLeft(2, '0'),
          'avgBmi': avg,
          'count': dayLogs.length,
        }));
      }
    }

    // ---------- MONTH ----------
    else if (widget.viewMode == 'month') {
      final year = widget.currentDate.year;
      final month = widget.currentDate.month;
      final weekStarts = [
        DateTime(year, month, 1),
        DateTime(year, month, 8),
        DateTime(year, month, 15),
        DateTime(year, month, 22),
        DateTime(year, month, 29),
      ];

      for (int i = 0; i < weekStarts.length; i++) {
        final start = weekStarts[i];
        final end = (i < weekStarts.length - 1)
            ? weekStarts[i + 1].subtract(const Duration(days: 1))
            : DateTime(year, month + 1, 0);

        final weekLogs = parsed.where((l) {
          final d = l['date'] as DateTime;
          return d.isAfter(start.subtract(const Duration(days: 1))) &&
              d.isBefore(end.add(const Duration(days: 1)));
        }).toList();

        final avg = weekLogs.isEmpty
            ? 0.0
            : weekLogs.map((e) => e['bmi'] as double).reduce((a, b) => a + b) /
            weekLogs.length;

        result.add(LinkedHashMap.from({
          'label': 'W${i + 1}',
          'avgBmi': avg,
          'count': weekLogs.length,
        }));
      }
    }

    return result;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ====================== COLOR HELPER ======================
Color? getBMIValueBasedCategoryColor(double bmi) {
  if (bmi < 18.5) return const Color(0xff29E33C);   // Underweight
  if (bmi < 25.0) return const Color(0xff9FB12B);   // Normal
  if (bmi < 30.0) return const Color(0xffFECA2A);   // Overweight
  if (bmi < 40.0) return const Color(0xffF56200);   // Obese
  return const Color(0xffF60000);                   // Severely Obese
}