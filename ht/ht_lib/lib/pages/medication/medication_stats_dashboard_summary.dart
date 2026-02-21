import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:heart_thrive/routes/app_router.dart';
import 'package:heart_thrive/services/medication_services.dart';
import 'package:heart_thrive/theme/app_theme.dart';
import 'package:heart_thrive/utils/date_utils.dart';

import '../../constants/ui_constants.dart';
import '../../models/medication/medication_intake_response.dart';
import '../../utils/secure_storage_utils.dart';
import 'medication_stats_dashboard.dart';

/* =========================
   Main Dashboard Screen
   ========================= */
class MedicationIntakeStatsDashboard extends StatefulWidget {
  const MedicationIntakeStatsDashboard({super.key});

  @override
  State<MedicationIntakeStatsDashboard> createState() =>
      _MedicationIntakeStatsDashboardState();
}

class _MedicationIntakeStatsDashboardState
    extends State<MedicationIntakeStatsDashboard> {
  IntakeStatsResponse? _intakeStatsResponse;
  bool _isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      final storage = SecureStorageUtils();
      final authToken = await storage.read("auth_token");
      final now = DateTime.now();
      String fromDate = DateFormatUtil.getStartOfDay(now);
      String toDate = DateFormatUtil.getEndOfDay(now);
      final TimezoneInfo currentTimeZone =
          await FlutterTimezone.getLocalTimezone();
      final timeZone = currentTimeZone.identifier;

      final response = await MedicationService().fetchMedicationStatsSummary(
        authToken!,
        fromDate,
        toDate,
        timeZone,
      );

      setState(() {
        _intakeStatsResponse = response;
        _isLoading = false; // Hide loading indicator
      });
    } catch (e) {
      setState(() {
        _isLoading = false; // Hide loading indicator on error
      });
      // Optionally show error message to user
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: const Text('Medication Dashboard'),
        leading: GestureDetector(
          onTap: () {
            AppRouter.replaceWithHome(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset("lib/assets/Frame.png"),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 8,
                  color: Color(0xFF8B0000),
                ),
              ),
            )
          : _intakeStatsResponse == null
          ? const Center(child: Text('No data available'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TodaySummaryCard(data: _intakeStatsResponse!.data),
                  //const SizedBox(height: 5),
                  DailyBreakdownCard(
                    slotWise: _intakeStatsResponse!.data.slotWiseBreakdown,
                  ),
                  // const SizedBox(height: 5),
                  // Removed MedicationDashboardScreen to prevent recursion
                   Card(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: deviceWidth(context) > 750 ? 500:400,
                        child: MedicationDashboardScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Container(
      width: 100,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 15, color: Colors.white),
        ),
      ),
    );
  }
}

/* =========================
   UI Components
   ========================= */
class TodaySummaryCard extends StatelessWidget {
  final IntakeData data;
  const TodaySummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final taken = data.totalTaken;
    final missed = data.totalMissed;
    final remaining = (data.totalScheduled - (taken + missed)).clamp(
      0,
      data.totalScheduled,
    );
    final total = data.totalScheduled;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              "Today's Summary",
              style: TextStyle(
                fontSize:  deviceWidth(context) > 750 ? 25: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Center the Circular Progress Indicator
                Expanded(
                  flex: 2,
                  child: Center(
                    child: SizedBox(
                      width:  deviceWidth(context) > 750 ? 320:120,
                      height:  deviceWidth(context) > 750 ? 320:120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background circle
                          SizedBox(
                            width:  deviceWidth(context) > 750 ? 250:120,
                            height:  deviceWidth(context) > 750 ? 250:120,
                            child: CircularProgressIndicator(
                              value: 1.0,
                              strokeWidth: 8,
                              backgroundColor: Colors.grey.shade300,
                              color: data.totalTaken == 0
                                  ? Colors.grey
                                  : Colors.red,
                            ),
                          ), // Consumed progress
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              value:
                                  (data.totalTaken != null &&
                                      data.totalScheduled != null &&
                                      data.totalScheduled != 0)
                                  ? data.totalTaken! / data.totalScheduled!
                                  : 0,
                              // dynamic from API
                              strokeWidth: 8,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.green,
                              ),
                              backgroundColor: Colors.transparent,
                            ),
                          ), // Center text
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '${data.totalTaken} /${data.totalScheduled} ',
                                style:  TextStyle(
                                  fontSize:  deviceWidth(context) > 750 ? 25 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Target Dose :${data.totalScheduled} ',
                                style: deviceWidth(context) > 750 ? AppTheme.body16:AppTheme.body10,
                              ),
                              Text(
                                'Consumed Dose :${data.totalTaken} ',
                                style: deviceWidth(context) > 750 ? AppTheme.body16:AppTheme.body10,
                              ),
                              Text(
                                'Left Dose :${data.totalScheduled - (data.totalMissed + data.totalTaken)} ',
                                style: deviceWidth(context) > 750 ? AppTheme.body16:AppTheme.body10,
                              ),
                              Text(
                                'Missed Dose :${data.totalMissed} ',
                                style: deviceWidth(context) > 750 ? AppTheme.body16:AppTheme.body10,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // Legend on the right
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('TARGET', Colors.grey,context),
                      SizedBox(height: deviceWidth(context) > 750 ? 20:8),
                      _buildLegendItem('CONSUMED', Colors.green,context),
                      SizedBox(height: deviceWidth(context) > 750 ? 20:8),
                      _buildLegendItem('LEFT', Colors.red,context),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color,BuildContext context) {
    return Container(
      width: deviceWidth(context) > 750 ? 170: 100,
      height: deviceWidth(context) > 750 ? 50:28,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          text,
          style:  TextStyle(fontSize: deviceWidth(context) > 750 ? 20: 15, color: Colors.white),
        ),
      ),
    );
  }
}

/* =========================
   Daily Breakdown Card (with thick circular progress)
   ========================= */
class DailyBreakdownCard extends StatelessWidget {
  final List<SlotWiseBreakdown> slotWise;
  const DailyBreakdownCard({super.key, required this.slotWise});

  // Tool Tip Design
  WidgetSpan showToolTip({
    String? slotName,
    int? targetDoses,
    int? notTaken,
    int? taken,
  }) {
    return WidgetSpan(
      child: SizedBox(
        width: 200, // adjust if needed
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 6),

            // 🔥 Morning + Target (left–right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    slotName ?? "",
                    style: AppTheme.title12.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Target : ${targetDoses} Doses",
                    textAlign: TextAlign.end,
                    style: AppTheme.body12.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),

            SizedBox(height: 10),

            //  Taken (left–right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Taken",
                      style: AppTheme.title12.copyWith(color: Colors.green),
                    ),
                  ],
                ),
                Text(
                  "$taken",
                  style: AppTheme.body12.copyWith(color: Colors.white),
                ),
              ],
            ),
            SizedBox(height: 6),

            // Not Taken (left–right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side (dot + label)
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Not Taken",
                      style: AppTheme.title12.copyWith(color: Colors.red),
                    ),
                  ],
                ),

                // Right side (value)
                Text(
                  "$notTaken",
                  style: AppTheme.body12.copyWith(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slots = {
      'MORNING': Colors.orange,
      'AFTERNOON': Colors.blue,
      'EVENING': Colors.pink,
    };

    // Enforce display order: Morning -> Afternoon -> Evening
    final orderMap = {'MORNING': 0, 'AFTERNOON': 1, 'EVENING': 2};
    final orderedSlots =
        slotWise
            .where((slot) => orderMap.containsKey(slot.timeSlot.toUpperCase()))
            .toList()
          ..sort(
            (a, b) => orderMap[a.timeSlot.toUpperCase()]!.compareTo(
              orderMap[b.timeSlot.toUpperCase()]!,
            ),
          );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              'Daily Medication Breakdown',
              style: TextStyle(
                  fontSize: deviceWidth(context) > 750 ? 25:16,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: deviceWidth(context) > 750 ? 20:16),
            orderedSlots.isNotEmpty
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: orderedSlots.map((slot) {
                      final color =
                          slots[slot.timeSlot.toUpperCase()] ?? Colors.grey;
                      final percent = slot.totalScheduled == 0
                          ? 0.0
                          : slot.totalTaken / slot.totalScheduled;
                      return Tooltip(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        richMessage: showToolTip(
                          slotName: slot.timeSlot,
                          targetDoses: slot.totalScheduled,
                          taken: slot.totalTaken,
                          notTaken: slot.totalScheduled - slot.totalTaken,
                        ),
                        child: _MedicationProgressIndicator(
                          name: slot.timeSlot,
                          consumed: slot.totalTaken.toDouble(),
                          target: slot.totalScheduled.toDouble(),
                          progress: percent,
                          color: color,
                        ),
                      );
                    }).toList(),
                  )
                :  Center(
                    child: Text(
                      "No medication data available",
                      style: TextStyle(
                        fontSize: deviceWidth(context)>750?20:14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

/* =========================
   Reusable Circular Progress Widget
   ========================= */
class _MedicationProgressIndicator extends StatelessWidget {
  final String name;
  final double consumed;
  final double target;
  final double progress;
  final Color color;

  const _MedicationProgressIndicator({
    required this.name,
    required this.consumed,
    required this.target,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentText = '${(progress * 100).toStringAsFixed(0)}%';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Base ring
            _buildCircle(
              value: 1.0,
              color: Colors.grey.shade300,
              backgroundColor: Colors.grey.shade200,
              context: context
            ), // Foreground ring
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return _buildCircle(
                  value: value,
                  color: color,
                  backgroundColor: Colors.transparent,
                  context: context
                );
              },
            ), // Center text
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${consumed.toInt()}/${target.toInt()}',
                  style:  TextStyle(
                    fontSize: deviceWidth(context) > 750 ? 20: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  name,
                  style:  TextStyle(
                      fontSize: deviceWidth(context) > 750 ? 18:12, color: Colors.grey),
                ),
                Text(
                  percentText,
                  style: TextStyle(
                    fontSize:deviceWidth(context) > 750 ? 18 : 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircle({
    required double value,
    required Color color,
    required Color backgroundColor,
    required BuildContext context
  }) {
    return SizedBox(
      width: deviceWidth(context) > 750 ? 150:85,
      height: deviceWidth(context) > 750 ? 150:85,
      child: CircularProgressIndicator(
        value: value,
        strokeWidth: 8,
        strokeCap: StrokeCap.round,
        valueColor: AlwaysStoppedAnimation<Color>(color),
        backgroundColor: backgroundColor,
      ),
    );
  }
}
