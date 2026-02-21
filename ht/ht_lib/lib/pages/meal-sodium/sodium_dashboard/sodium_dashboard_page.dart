import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:heart_thrive/constants/heart_thrive_strings_constants.dart';
import 'package:heart_thrive/core/api_endpoints.dart';
import 'package:heart_thrive/utils/secure_storage_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:collection';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/date_utils.dart';


class Nutrient {
  final String name;
  final double amount;
  final double minValue;
  final double maxValue;
  final String? unitName;

  Nutrient({
    required this.name,
    required this.amount,
    required this.minValue,
    required this.maxValue,
    this.unitName,
  });

  factory Nutrient.fromJson(Map<String, dynamic> json) {
    return Nutrient(
      name: json['name'],
      amount: json['amount'].toDouble(),
      minValue: json['minValue'].toDouble(),
      maxValue: json['maxValue'].toDouble(),
      unitName: json['unitName'],
    );
  }
}

class DailySummary {
  final String date;
  final List<Nutrient> nutrients;

  DailySummary({required this.date, required this.nutrients});

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    var nutrientsJson = json['nutrients'] as List;
    List<Nutrient> nutrientsList = nutrientsJson.map((i) => Nutrient.fromJson(i)).toList();
    return DailySummary(date: json['date'], nutrients: nutrientsList);
  }

  double getSodiumAmount() {
    return nutrients.firstWhere((n) => n.name == 'Sodium', orElse: () => Nutrient(name: 'Sodium', amount: 0.0, minValue: 0.0, maxValue: 2500.0)).amount;
  }

  Map<String, double> getNutrientBreakdown() {
    return {
      'Calories': nutrients.firstWhere((n) => n.name == 'Calories', orElse: () => Nutrient(name: 'Calories', amount: 0.0, minValue: 0.0, maxValue: 2500.0)).amount,
      'Carbohydrates': nutrients.firstWhere((n) => n.name == 'Carbohydrates', orElse: () => Nutrient(name: 'Carbohydrates', amount: 0.0, minValue: 0.0, maxValue: 2500.0)).amount,
      'Fat': nutrients.firstWhere((n) => n.name == 'Fat', orElse: () => Nutrient(name: 'Fat', amount: 0.0, minValue: 0.0, maxValue: 2500.0)).amount,
      'Protein': nutrients.firstWhere((n) => n.name == 'Protein', orElse: () => Nutrient(name: 'Protein', amount: 0.0, minValue: 0.0, maxValue: 2500.0)).amount,
      'Sodium': getSodiumAmount(),
    };
  }
}

class NutritionData {
  final List<DailySummary> dailySummaries;
  final String fromDate;
  final String toDate;
  final String timezone;

  NutritionData({required this.dailySummaries, required this.fromDate, required this.toDate, required this.timezone});

  factory NutritionData.fromJson(Map<String, dynamic> json) {
    var summariesJson = json['dailySummaries'] as List;
    List<DailySummary> summariesList = summariesJson.map((i) => DailySummary.fromJson(i)).toList();
    return NutritionData(
      dailySummaries: summariesList,
      fromDate: json['fromDate'],
      toDate: json['toDate'],
      timezone: json['timezone'],
    );
  }
}



class SodiumIntakeScreen extends StatefulWidget {
  const SodiumIntakeScreen({super.key});

  @override
  State<SodiumIntakeScreen> createState() => _SodiumIntakeScreenState();
}

class _SodiumIntakeScreenState extends State<SodiumIntakeScreen> {
  late NutritionData nutritionData;
  String viewMode = 'day';
  bool isLoading = true;
  bool isError = false;
  DateTime currentDate = DateTime.now();
  late String? authToken ;

  @override
  void initState() {
    super.initState();
    updateAuthToken();



  }
  updateAuthToken() async{
    final storage = SecureStorageUtils();
    //final String? token = await storage.read("auth_token");
    authToken = await storage.read("auth_token");
    setState(() {
      authToken;
    });
    fetchData();
  }
  DateTime getPeriodStart() {
    if (viewMode == 'day') {
      return DateTime(currentDate.year, currentDate.month, currentDate.day);
    } else if (viewMode == 'week') {
      return currentDate.subtract(Duration(days: currentDate.weekday - 1));
    } else { // month
      return DateTime(currentDate.year, currentDate.month, 1);
    }
  }

  DateTime getPeriodEnd() {
    final start = getPeriodStart();
    if (viewMode == 'day') {
      return start;
    } else if (viewMode == 'week') {
      return start.add(const Duration(days: 6));
    } else { // month
      return DateTime(start.year, start.month + 1, 0);
    }
  }

  String getPeriodDisplayText() {
    final start = getPeriodStart();
    final end = getPeriodEnd();
    if (viewMode == 'day') {
      return DateFormat('MMM dd, yyyy').format(start);
    } else if (viewMode == 'week') {
      return '${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd, yyyy').format(end)}';
    } else { // month
      return DateFormat('MMMM yyyy').format(start);
    }
  }


  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      isError = false;
    });
    final start = getPeriodStart();
    final end = getPeriodEnd();
    final fromDate = DateFormatUtil.startDateFormat(start);
    final toDate = DateFormatUtil.startDateFormat(end);
    final timezone = await FlutterTimezone.getLocalTimezone();
    try {
      final URL = ApiEndpoints.dailyNutrientSummary(
          fromDate: fromDate,
          toDate: toDate,
          timezone: timezone.identifier
      );
      debugPrint("URL @@@ $URL");
      final response = await http.get(
        Uri.parse(ApiEndpoints.dailyNutrientSummary(
            fromDate: fromDate,
            toDate: toDate,
            timezone: timezone.identifier
        )),
        headers: {'Authorization': 'Bearer $authToken'},
      ).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        nutritionData = NutritionData.fromJson(jsonDecode(response.body));

      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      isError = true;
      final timezone = await FlutterTimezone.getLocalTimezone();
      nutritionData = NutritionData(
        dailySummaries: [],
        fromDate: fromDate,
        toDate: toDate,
        timezone: timezone.identifier,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void navigateDate(bool forward) {
    setState(() {
      isLoading = true;
      if (viewMode == 'day') {
        currentDate = forward
            ? currentDate.add(const Duration(days: 1))
            : currentDate.subtract(const Duration(days: 1));
      } else if (viewMode == 'week') {
        currentDate = forward
            ? currentDate.add(const Duration(days: 7))
            : currentDate.subtract(const Duration(days: 7));
      } else { // month
        currentDate = DateTime(
          currentDate.year,
          currentDate.month + (forward ? 1 : -1),
          1,
        );
      }
    });
    fetchData();
  }

  bool canNavigate(bool forward) {
    if(isLoading) return false;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (forward) {
      if (viewMode == 'day') {
        return currentDate.isBefore(todayDate);
      } else if (viewMode == 'week') {
        return getPeriodEnd().isBefore(todayDate);
      } else { // month
        return DateTime(currentDate.year, currentDate.month + 1, 1).isBefore(todayDate);
      }
    }
    return currentDate.year > 2024 || (currentDate.year == 2024 && currentDate.month > 9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left arrow
              Container(
                height: 82,
                width: 60,
                decoration: _boxDecoration(),
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
                  decoration: _boxDecoration(),
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
                            } else if (viewMode == 'week') {
                              // reset to start of the week (optional)
                              final now = DateTime.now();
                              currentDate = now.subtract(Duration(days: now.weekday - 1)); // Monday start
                            }
                          });
                          fetchData();
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
                decoration: _boxDecoration(),
                child: IconButton(
                  onPressed: canNavigate(true) ? () => navigateDate(true) : null,
                  icon: const Icon(Icons.chevron_right,size: 40,),
                  color: canNavigate(true) ? null : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : isError || (nutritionData != null && nutritionData.dailySummaries.isEmpty )
                ? noSodiumInformation(): SodiumBarChart(data: nutritionData, viewMode: viewMode, currentDate: currentDate),
          ),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.grey.shade50,
      border: Border.all(
        color: Colors.grey.shade300,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(4),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

}





// Your models remain unchanged
// ... (Nutrient, DailySummary, NutritionData classes you provided)

class SodiumBarChart extends StatefulWidget {
  final NutritionData data;           // changed to your actual response type
  final String viewMode;             // "day" / "week" / "month"
  final DateTime currentDate;

  const SodiumBarChart({
    super.key,
    required this.data,
    required this.viewMode,
    required this.currentDate,
  });

  @override
  State<SodiumBarChart> createState() => _SodiumBarChartState();
}

class _SodiumBarChartState extends State<SodiumBarChart> {
  List<LinkedHashMap<String, dynamic>> groupedData = [];

  // -----------------------------------------------------------------
  // Helper: get list of dates to display (day / week / month)
  // -----------------------------------------------------------------
  List<DateTime> _getDatesForView() {
    if (widget.viewMode == 'day') {
      return [widget.currentDate];
    }
    if (widget.viewMode == 'week') {
      final start =
      widget.currentDate.subtract(Duration(days: widget.currentDate.weekday - 1));
      return List.generate(7, (i) => start.add(Duration(days: i)));
    } else {
      // month
      final year = widget.currentDate.year;
      final month = widget.currentDate.month;
      final daysInMonth = DateTime(year, month + 1, 0).day;
      return List.generate(daysInMonth, (i) => DateTime(year, month, i + 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dates = _getDatesForView();
    final isMonthView = widget.viewMode == 'month';
    final isDayView = widget.viewMode == 'day';

    // -----------------------------------------------------------------
    // Build grouped data (same logic as before, just cleaner)
    // -----------------------------------------------------------------
    final dailyData = widget.data.dailySummaries.map((s) {
      final parts = s.date.split("-");
      final dt = DateTime(
        int.parse(parts[2]), // year
        int.parse(parts[1]), // month
        int.parse(parts[0]), // day
      );
      final sodium = s.getSodiumAmount();
      return {
        'date': dt,
        'sodium': sodium,
        'value': getUnitValue(sodium),
      };
    }).toList()
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

// Now build groupedData from sorted dailyData
    groupedData = dates.map((date) {
      final found = dailyData.firstWhere(
            (e) => sameDay(e['date'] as DateTime, date),
        orElse: () => {'sodium': 0.0, 'value': 0.0},
      );
      return LinkedHashMap<String, dynamic>()
        ..['label'] =  DateFormat('MMM dd').format(date)
        ..['sodium'] = found['sodium']
        ..['value'] = found['value'];
    }).toList();

    if (groupedData.isEmpty || groupedData.every((e) => e['value'] == 0.0)) {
      return noSodiumInformation();
    }

    // -----------------------------------------------------------------
    // Dynamic bar width & spacing (prevents overlap in month view)
    // -----------------------------------------------------------------
    final availableWidth = MediaQuery.of(context).size.width * 0.85;
    final barCount = groupedData.length;

    final spacePerBar = availableWidth / barCount;
    final barWidth = isMonthView
        ? (spacePerBar * 0.6).clamp(4.0, 12.0)   // thin but visible
        : isDayView
        ? 30.0
        : 20.0;

    final groupsSpace = isMonthView
        ? spacePerBar * 0.4
        : isDayView
        ? 0.0
        : 20.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: isMonthView || widget.viewMode == 'week'
                    ? BarChartAlignment.spaceBetween
                    : BarChartAlignment.center,
                maxY: 3.0,
                groupsSpace: groupsSpace,
                gridData: const FlGridData(
                  show: true,
                  horizontalInterval: 0.5,
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= groupedData.length) {
                          return const SizedBox.shrink();
                        }

                        // In month view → show only day 1 and every 4th day
                        final date = dates[index];
                        final showLabel = !isMonthView ||
                            date.day == 1 ||
                            (date.day % 4 == 1); // 1,5,9,13,17,21,25,29

                        if (!showLabel) return const SizedBox.shrink();

                        final text = isDayView
                            ? DateFormat('MMM dd yyyy').format(date)
                            : date.day.toString();

                        return SideTitleWidget(
                          meta: meta,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              text,
                              style: TextStyle(
                                fontSize: isDayView ? 16 : 11,
                                fontWeight: date.day == 1 ? FontWeight.bold : FontWeight.w600,
                                color: date.day == 1 ? Colors.purple : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    axisNameWidget: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        widget.viewMode == "month"
                            ? "Day of the Month"
                            : widget.viewMode == "week"
                            ? "Days of the Week"
                            : "Date",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    axisNameSize: 40,
                  ),
                ),
                barTouchData: getBarTouchData(),
                barGroups: groupedData.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final val = entry.value['value'] as double;
                  final sodium = entry.value['sodium'] as double;
                  final label = entry.value['label'] as String;

                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: val,
                        color: getColor(val),
                        width: barWidth,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Optional legend (you can remove if not needed)
          buildLegend(),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // Your existing helpers (unchanged)
  // -----------------------------------------------------------------
  Color getColor(double value) {
    if (value <= 0.99) return const Color(0xff00CE34);
    if (value < 1.5) return const Color(0xff9EB22B);
    if (value < 2.0) return const Color(0xffFECA29);
    if (value < 2.5) return const Color(0xffF46300);
    return const Color(0xffF50100);
  }

  BarTouchData getBarTouchData() {
    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        maxContentWidth: 200,
        fitInsideHorizontally: true,
        tooltipPadding: const EdgeInsets.all(10),
        tooltipMargin: 8,
        getTooltipItem: (group, _, rod, __) {
          final data = groupedData[group.x.toInt()];
          return BarTooltipItem(
            "Date: ${data['label']}"
                "\nSodium: ${data['sodium'].toStringAsFixed(2)} mg"
                "\nUnits: ${data['value'].toStringAsFixed(2)}",
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.start
          );
        },
      ),
    );
  }

  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  double getUnitValue(double mg) {
    if (mg <= 0) return 0.0;

    if (mg <= 2200) return truncateTo2(mg / 2200);

    if (mg < 2500) {
      final f = (mg - 2200) / 300;
      return truncateTo2(1.0 + f * 0.35);
    }

    if (mg < 2700) {
      final f = (mg - 2500) / 200;
      return truncateTo2(1.35 + f * 0.15);
    }

    if (mg < 3200) {
      final f = (mg - 2700) / 500;
      return truncateTo2(1.5 + f * 0.5);
    }

    double units = 2.0 + ((mg - 3200) / 500) * 0.5;
    if (units > 3.0) units = 3.0;

    return truncateTo2(units);
  }
  double truncateTo2(double value) {
    return (value * 100).truncate() / 100;
  }

  Widget buildLegend() {
    final legends = [
      _buildBarLegend('0 units (<2200)', getColor(0.5)),
      _buildBarLegend('1 unit (=>2200)', getColor(1.1)),
      _buildBarLegend('1.5 units (=>2700)', getColor(1.6)),
      _buildBarLegend('2 units (=>3200)', getColor(2.1)),
      _buildBarLegend('2.5 units (=>3700)', getColor(2.7)),
    ];

    return SizedBox(
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              legends[0],
              legends[1],
            ],
          ),
          TableRow(
            children: [
              legends[2],
              legends[3],
            ],
          ),
          TableRow(
            children: [
              legends[4],
              const SizedBox(), // empty slot for alignment
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildBarLegend(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: AppTheme.title12,
          ),
        ],
      ),
    );
  }
}

// No Sodium UI Layout
Widget noSodiumInformation(){
  return SizedBox(
    width: double.infinity,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'lib/assets/no_sodium_data.png',
                height: 160,),
              const SizedBox(height: 20),
               Text(
                HeartThriveStrings.noSodiumDashBoardTitle,
                textAlign: TextAlign.center,
                style: AppTheme.title16.copyWith(
                    fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                HeartThriveStrings.noSodiumDashBoardDescription,
                textAlign: TextAlign.center,
                style: AppTheme.body14,
              ),
            ],
          ),
        ),
      ),
    ),
  );

}