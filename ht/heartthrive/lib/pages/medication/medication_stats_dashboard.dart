import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:heart_thrive/constants/ui_constants.dart' show boxDecoration, deviceWidth;
import 'package:heart_thrive/core/api_endpoints.dart';
import 'package:heart_thrive/utils/secure_storage_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'dart:collection';
import '../../constants/heart_thrive_strings_constants.dart';
import '../../constants/ui_constants.dart' show boxDecoration;
import '../../models/medication/medication_dailly_stats.dart';
import '../../theme/app_theme.dart';

class MedicationDashboardScreen extends StatefulWidget {
  const MedicationDashboardScreen({super.key});

  @override
  State<MedicationDashboardScreen> createState() => _MedicationDashboardScreenState();
}

class _MedicationDashboardScreenState extends State<MedicationDashboardScreen> {
  late MedicationData medicationData;
  String viewMode = 'day';
  bool isLoading = true;
  bool isError = false;
  DateTime currentDate = DateTime.now();
  String? authToken;

  @override
  void initState() {
    super.initState();
    updateAuthToken();
  }

  Future<void> updateAuthToken() async {
    final storage = SecureStorageUtils();
    //final String? token = await storage.read("auth_token");
    authToken = await storage.read("auth_token");
    setState(() {
      authToken;
    });
    setState(() {});
    fetchData();
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
    if (viewMode == 'day') {
      return start;
    } else if (viewMode == 'week') {
      return start.add(const Duration(days: 6));
    } else {
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
    } else {
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
    final fromDate = DateFormat('dd-MM-yyyy').format(start);
    final toDate = DateFormat('dd-MM-yyyy').format(end);
    try {
      final TimezoneInfo timezoneInfo =await FlutterTimezone.getLocalTimezone();
      debugPrint("Data ${jsonEncode({
        'fromDate': fromDate,
        'toDate': toDate,
        'timezone': timezoneInfo.identifier,
      })}");
      final response = await http.post(
        Uri.parse(ApiEndpoints.medicationsDailyIntakeStats),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'fromDate': fromDate,
          'toDate': toDate,
          'timezone': timezoneInfo.identifier,
        }),
      ).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        debugPrint("Success 96@@@@ ${response.body}");
        medicationData = MedicationData.fromJson(jsonDecode(response.body));
        debugPrint('Data ${medicationData.dailyStats.isEmpty} $isError');
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      isError = true;
      setState(() => isLoading = false);
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
      } else {
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
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (forward) {
      if (viewMode == 'day') {
        return currentDate.isBefore(todayDate);
      } else if (viewMode == 'week') {
        return getPeriodEnd().isBefore(todayDate);
      } else {
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
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
                            }else if (viewMode == 'day') {
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
                decoration: boxDecoration(),
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
                : isError || medicationData.dailyStats.isEmpty
                ? noMedInformation(context)
                : MedicationBarChart(
              data: medicationData,
              viewMode: viewMode,
              currentDate: currentDate,
            ),
          ),
        ],
      ),
    );
  }
}

class MedicationBarChart extends StatefulWidget {
  final MedicationData data;
  final String viewMode;
  final DateTime currentDate;

  const MedicationBarChart({
    super.key,
    required this.data,
    required this.viewMode,
    required this.currentDate,
  });

  @override
  State<MedicationBarChart> createState() => _MedicationBarChartState();
}

class _MedicationBarChartState extends State<MedicationBarChart> {
  List<LinkedHashMap<String, dynamic>> groupedData = [];
  DailyMedicationSummary? touchedSummary;

  @override
  Widget build(BuildContext context) {
    print("Medication Data ${widget.data.dailyStats.isEmpty}");
    groupedData = getGroupedData();
    if (groupedData.every((e) => (e['taken'] as num) == 0 && (e['notTaken'] as num) == 0)) {
      return noMedInformation(context);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: deviceWidth(context) > 750 ? 320: 210,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: getMaxY(),
              barTouchData: getBarTouchData(),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                    axisNameSize: 35,
                    sideTitles: bottomTitles(),
                    axisNameWidget:  Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        widget.viewMode == "month"?'Weeks of the Month':widget.viewMode == "week"?'Days of the Week':"Day",
                        style: deviceWidth(context) > 750 ? AppTheme.body16:AppTheme.body12,
                        textAlign: TextAlign.center,
                      ),
                    )
                ),
                rightTitles: AxisTitles(
                    axisNameSize: 35,
                    sideTitles: leftTitles(),
                    axisNameWidget:  Center(
                    child: RotatedBox(
                      quarterTurns: 10, // rotates clockwise (top to bottom)
                      child: Text(
                        "Dose Count",
                        style: deviceWidth(context) > 750 ? AppTheme.body16: AppTheme.body12,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true, horizontalInterval: 2,verticalInterval: 1),
              borderData: FlBorderData(show: false),
              barGroups: getBarGroups(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        buildLegend(),
       // if (touchedSummary != null && widget.viewMode != 'month') buildDetailedInfo(),
      ],
    );
  }

  double getMaxY() {
    if (groupedData.isEmpty) return 12.0;
    num maxTaken = groupedData.map((e) => e['taken'] as num).reduce(max);
    num maxNotTaken = groupedData.map((e) => e['notTaken'] as num).reduce(max);
    double maxValue = max(maxTaken.toDouble(), maxNotTaken.toDouble());
    return ((maxValue / 2).ceil() * 2).toDouble();
  }

  BarTouchData getBarTouchDataOld() {
    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        tooltipPadding: const EdgeInsets.all(8),
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final label = groupedData[groupIndex]['label'] as String;
          final taken = groupedData[groupIndex]['taken'] as int;
          final notTaken = groupedData[groupIndex]['notTaken'] as int;
          String tooltipText = '';
          DateTime? date;

          if (widget.viewMode == 'day') {
            date = DateTime(widget.currentDate.year, widget.currentDate.month, int.parse(label));
            touchedSummary = widget.data.dailyStats.firstWhere(
                  (s) =>
              s.date ==
                  '${date!.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}',
              orElse: () => DailyMedicationSummary(
                date: '',
                totalMedications: 0,
                totalScheduled: 0,
                totalTaken: 0,
                totalNotTaken: 0,
                totalMissed: 0,
                adherencePercentage: 0.0,
              ),
            );
            tooltipText = 'Date: ${DateFormat('MMM dd yyyy').format(date)}\n'
                'Taken: $taken doses\n'
                'Not Taken: $notTaken doses\n'
                'Adherence: ${touchedSummary!.adherencePercentage.toStringAsFixed(2)}%';
          } else if (widget.viewMode == 'week') {
            final startOfWeek = widget.currentDate.subtract(Duration(days: widget.currentDate.weekday - 1));
            date = startOfWeek.add(Duration(days: groupIndex));
            touchedSummary = widget.data.dailyStats.firstWhere(
                  (s) =>
              s.date ==
                  '${date!.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}',
              orElse: () => DailyMedicationSummary(
                date: '',
                totalMedications: 0,
                totalScheduled: 0,
                totalTaken: 0,
                totalNotTaken: 0,
                totalMissed: 0,
                adherencePercentage: 0.0,
              ),
            );
            tooltipText = 'Date: ${DateFormat('MMM dd yyyy').format(date)}\n'
                'Taken: $taken doses\n'
                'Not Taken: $notTaken doses\n'
                'Adherence: ${touchedSummary!.adherencePercentage.toStringAsFixed(2)}%';
          } else {
            final weekNum = int.parse(label.replaceAll('W', ''));
            final startDate = DateTime(widget.currentDate.year, widget.currentDate.month, (weekNum - 1) * 7 + 1);
            final endDate = (weekNum < 5)
                ? DateTime(widget.currentDate.year, widget.currentDate.month, weekNum * 7)
                : DateTime(widget.currentDate.year, widget.currentDate.month + 1, 0);
            tooltipText = 'Week $weekNum: ${DateFormat('MMM dd').format(startDate)}-${DateFormat('MMM dd yyyy').format(endDate)}\n'
                'Avg Daily Taken: ${taken.toStringAsFixed(2)} doses\n'
                'Avg Daily Not Taken: ${notTaken.toStringAsFixed(2)} doses';
          }

          return BarTooltipItem(
            tooltipText,
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.start
          );
        },
      ),
    );
  }
  BarTouchData getBarTouchData() {
    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        maxContentWidth: 150,
        tooltipPadding: const EdgeInsets.all(8),
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final label = groupedData[groupIndex]['label'] as String;
          final taken = groupedData[groupIndex]['taken'] as num;
          final notTaken = groupedData[groupIndex]['notTaken'] as num;
          String tooltipText = '';
          DateTime? date;

          if (widget.viewMode == 'day') {
            date = DateTime(widget.currentDate.year, widget.currentDate.month, int.parse(label));
            touchedSummary = widget.data.dailyStats.firstWhere(
                  (s) =>
              s.date ==
                  '${date!.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}',
              orElse: () => DailyMedicationSummary(
                date: '',
                totalMedications: 0,
                totalScheduled: 0,
                totalTaken: 0,
                totalNotTaken: 0,
                totalMissed: 0,
                adherencePercentage: 0.0,
              ),
            );
            tooltipText = 'Date: ${DateFormat('MMM dd yyyy').format(date)}\n'
                'Taken: ${taken.toInt()} doses\n'  // Use .toInt() for display if needed, but safe since it's count
                'Not Taken: ${notTaken.toInt()} doses\n'
                'Adherence: ${touchedSummary!.adherencePercentage.toStringAsFixed(2)}%';
          } else if (widget.viewMode == 'week') {
            final startOfWeek = widget.currentDate.subtract(Duration(days: widget.currentDate.weekday - 1));
            date = startOfWeek.add(Duration(days: groupIndex));
            touchedSummary = widget.data.dailyStats.firstWhere(
                  (s) =>
              s.date ==
                  '${date!.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}',
              orElse: () => DailyMedicationSummary(
                date: '',
                totalMedications: 0,
                totalScheduled: 0,
                totalTaken: 0,
                totalNotTaken: 0,
                totalMissed: 0,
                adherencePercentage: 0.0,
              ),
            );
            tooltipText = 'Date: ${DateFormat('MMM dd yyyy').format(date)}\n'
                'Taken: ${taken.toInt()} doses\n'
                'Not Taken: ${notTaken.toInt()} doses\n'
                'Adherence: ${touchedSummary!.adherencePercentage.toStringAsFixed(2)}%';
          } else {
            final weekNum = int.parse(label.replaceAll('W', ''));
            final startDate = DateTime(widget.currentDate.year, widget.currentDate.month, (weekNum - 1) * 7 + 1);
            final endDate = (weekNum < 5)
                ? DateTime(widget.currentDate.year, widget.currentDate.month, weekNum * 7)
                : DateTime(widget.currentDate.year, widget.currentDate.month + 1, 0);
            tooltipText = 'Week $weekNum: ${DateFormat('MMM dd').format(startDate)}-${DateFormat('MMM dd yyyy').format(endDate)}\n'
                'Avg Daily Taken: ${taken.toStringAsFixed(2)} doses\n'
                'Avg Daily Not Taken: ${notTaken.toStringAsFixed(2)} doses';
          }

          return BarTooltipItem(
            tooltipText,
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            textAlign: TextAlign.start
          );
        },
      ),
    );
  }

  List<BarChartGroupData> getBarGroupsOld() {
    return groupedData.asMap().entries.map((entry) {
      final index = entry.key;
      final taken = entry.value['taken'] as int;
      final notTaken = entry.value['notTaken'] as int;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: taken.toDouble(),
            color: Colors.green, width: 16,
            borderRadius: BorderRadius.zero,
          ),
          BarChartRodData(
            toY: notTaken.toDouble(),
            color: Colors.red,
            width: 16,
            borderRadius: BorderRadius.zero,
          ),

        ],
      );
    }).toList();
  }
  List<BarChartGroupData> getBarGroups() {
    return groupedData.asMap().entries.map((entry) {
      final index = entry.key;
      final taken = entry.value['taken'] as num;
      final notTaken = entry.value['notTaken'] as num;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(toY: taken.toDouble(), color: Colors.green, width: 8, borderRadius: BorderRadius.zero,),
          BarChartRodData(toY: notTaken.toDouble(), color: Colors.red, width: 8, borderRadius: BorderRadius.zero,),
        ],
      );
    }).toList();
  }

  List<LinkedHashMap<String, dynamic>> getGroupedData() {
    final List<DailyMedicationSummary> summaries = widget.data.dailyStats;
    final List<LinkedHashMap<String, dynamic>> dateAmounts = summaries.map((summary) {
      final parts = summary.date.split('-');
      final dt = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      final map = LinkedHashMap<String, dynamic>();
      map['date'] = dt;
      map['taken'] = summary.totalTaken;
      map['notTaken'] = summary.totalNotTaken;
      return map;
    }).toList();

    dateAmounts.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    if (widget.viewMode == 'day') {
      final current = dateAmounts.firstWhere(
            (d) =>
        (d['date'] as DateTime).day == widget.currentDate.day &&
            (d['date'] as DateTime).month == widget.currentDate.month &&
            (d['date'] as DateTime).year == widget.currentDate.year,
        orElse: () => LinkedHashMap<String, dynamic>.from({
          'taken': 0,
          'notTaken': 0,
          'date': widget.currentDate,
        }),
      );
      final map = LinkedHashMap<String, dynamic>();
      map['label'] = widget.currentDate.day.toString().padLeft(2, '0');
      map['taken'] = current['taken'] as int;
      map['notTaken'] = current['notTaken'] as int;
      return [map];
    } else if (widget.viewMode == 'week') {
      final DateTime startOfWeek = widget.currentDate.subtract(Duration(days: widget.currentDate.weekday - 1));
      final List<LinkedHashMap<String, dynamic>> weekData = [];
      for (int i = 0; i < 7; i++) {
        final day = startOfWeek.add(Duration(days: i));
        final data = dateAmounts.firstWhere(
              (d) =>
          (d['date'] as DateTime).day == day.day &&
              (d['date'] as DateTime).month == day.month &&
              (d['date'] as DateTime).year == day.year,
          orElse: () => LinkedHashMap<String, dynamic>.from({
            'taken': 0,
            'notTaken': 0,
            'date': day,
          }),
        );
        final map = LinkedHashMap<String, dynamic>();
        map['label'] = day.day.toString().padLeft(2, '0');
        map['taken'] = data['taken'] as int;
        map['notTaken'] = data['notTaken'] as int;
        weekData.add(map);
      }
      return weekData;
    } else {
      final List<LinkedHashMap<String, dynamic>> weekTotals = [];
      final int month = widget.currentDate.month;
      final int year = widget.currentDate.year;
      final List<DateTime> weekStarts = [
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
        final List<LinkedHashMap<String, dynamic>> weekAmounts = dateAmounts
            .where((d) =>
        (d['date'] as DateTime).isAfter(start.subtract(const Duration(days: 1))) &&
            (d['date'] as DateTime).isBefore(end.add(const Duration(days: 1))))
            .toList();
        final sumTaken = weekAmounts.fold(0, (prev, curr) => prev + (curr['taken'] as int));
        final sumNotTaken = weekAmounts.fold(0, (prev, curr) => prev + (curr['notTaken'] as int));
        final numDays = end.difference(start).inDays + 1;
        final avgTaken = numDays > 0 ? sumTaken / numDays : 0.0;
        final avgNotTaken = numDays > 0 ? sumNotTaken / numDays : 0.0;
        final map = LinkedHashMap<String, dynamic>();
        map['label'] = '${i + 1}W';
        map['taken'] = avgTaken;
        map['notTaken'] = avgNotTaken;
        weekTotals.add(map);
      }
      return weekTotals;
    }
  }

  SideTitles bottomTitles() {
    return SideTitles(
      showTitles: true,
      reservedSize: 32,
      getTitlesWidget: (double value, TitleMeta meta) {
        final index = value.toInt();
        if (index < 0 || index >= groupedData.length) return const Text('');
        return SideTitleWidget(
          meta: meta,
          space: 4,
          child: Text(groupedData[index]['label'] as String),
        );
      },
    );
  }

  SideTitles leftTitles() {
    return SideTitles(
      showTitles: true,
      reservedSize: 40,
      interval: 2,
      getTitlesWidget: (double value, TitleMeta meta) {
        if (value % 2 == 0) {
          return SideTitleWidget(
            meta: meta,
            space: 4,
            child: Text(value.toInt().toString()),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget buildLegendOld() {
    return deviceWidth(context) > 750? Padding(
      padding: const EdgeInsets.only(left: 50.0,right: 50.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _buildBarLegend('Medication Taken', Colors.green),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildBarLegend('Medication Not Taken', Colors.red),
          ),
        ],
      ),
    ):Row(
      //mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: _buildBarLegend('Medication Taken', Colors.green),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildBarLegend('Medication Not Taken', Colors.red),
        ),
      ],
    );
  }
  Widget buildLegend() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 750;

        return Center(
          child: SizedBox(
            width: isWide ? 600 : constraints.maxWidth,
            child: Row(
              children:  [
                Expanded(
                  child: _buildBarLegend('Medication Taken', Colors.green),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildBarLegend('Medication Not Taken', Colors.red),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildBarLegend(String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, // ✅ center vertically
      children: [
        Container(
          width: deviceWidth(context) > 750 ? 16 : 12,
          height: deviceWidth(context) > 750 ? 16:12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        // ✅ Use Flexible to allow text wrapping but keep alignment
        Flexible(
          child: Text(
            text,
            softWrap: true,
            maxLines: 2, // allow 2 lines
            overflow: TextOverflow.visible,
            style: AppTheme.title12.copyWith(
                color: Colors.grey,
                fontSize: deviceWidth(context) > 750 ? 16:deviceWidth(context)> 390? 12:deviceWidth(context) > 360?11:10
            ),
          ),
        ),
      ],
    );
  }



  Widget buildDetailedInfo() {
    if (touchedSummary == null) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details for ${touchedSummary!.date}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Total Medications: ${touchedSummary!.totalMedications}'),
            Text('Scheduled Doses: ${touchedSummary!.totalScheduled}'),
            Text('Taken Doses: ${touchedSummary!.totalTaken}'),
            Text('Not Taken Doses: ${touchedSummary!.totalNotTaken}'),
            Text('Missed Doses: ${touchedSummary!.totalMissed}'),
            Text('Adherence: ${touchedSummary!.adherencePercentage.toStringAsFixed(2)}%'),
          ],
        ),
      ),
    );
  }
}
Widget noMedInformation(BuildContext context){
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
                'lib/assets/no_med_found.jpeg',
                height: deviceWidth(context)> 750? 200:140,),
              const SizedBox(height: 10),
              Text(
                HeartThriveStrings.noMedDashboardInformationTitle,
                textAlign: TextAlign.center,
                style: AppTheme.title16.copyWith(
                    fontSize: deviceWidth(context)> 750?20:16),
              ),
              const SizedBox(height: 8),
               Text(
                HeartThriveStrings.noMedDashboardInformationDescription,
                textAlign: TextAlign.center,
                style: deviceWidth(context)> 750?AppTheme.body18:AppTheme.body14,
              ),
            ],
          ),
        ),
      ),
    ),
  );

}
