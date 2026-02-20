import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:heart_thrive/components/circular_graph.dart';
import 'package:heart_thrive/components/heart_risk_meter.dart';
import 'package:heart_thrive/constants/heart_thrive_strings_constants.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import 'package:heart_thrive/models/symptoms/SymptomSummaryResponse.dart';
import 'package:heart_thrive/models/symptoms/symptoms_model.dart';
import 'package:heart_thrive/routes/app_router.dart';
import 'package:heart_thrive/services/symptoms/fetch_symptomps_list.dart' show SymptomService;
import 'package:intl/intl.dart';
import '../../../utils/secure_storage_utils.dart';
import '../../models/heart_risk_meter_comparison_model.dart';
import '../../models/home/heart_risk_meter_modal.dart';
import '../../services/home/risk_meter_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart'; // provides DateFormatUtil.startDateFormat

class HeartRiskDashboardPage extends ConsumerStatefulWidget {
  const HeartRiskDashboardPage({super.key});

  @override
  ConsumerState<HeartRiskDashboardPage> createState() => _HeartRiskDashboardPageState();
}

class _HeartRiskDashboardPageState extends ConsumerState<HeartRiskDashboardPage> {
  bool isLoading = true;
  bool isError = false;
  late HeartRiskSummaryResponse heartRiskSummary;
  late String? authToken;
  late SymptomSummaryResponse symptomSummary;
  HeartRiskComparisonResponse? comparison;

  String? _lastFetchedFromDate;
  String? _lastFetchedToDate;

  String viewMode = 'day';
  DateTime currentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchData();
  }

  Future<void> _loadTokenAndFetchData() async {
    final storage = SecureStorageUtils();
    authToken = await storage.read(StorageKeys.accessToken);
    comparison = await RiskMetricComparisonService().fetchRiskMetricComparison();

    if (authToken == null) {
      setState(() {
        isError = true;
        isLoading = false;
      });
      return;
    }

    await _fetchData();
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

  // This week
  String getThisWeekDisplayText() {
    final start = getPeriodStart();
    final end = getPeriodEnd();
    return '${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd').format(end)}';
  }
  // Past week
  DateTime getPastWeekStart() {
    return getPeriodStart().subtract(const Duration(days: 7));
  }
  DateTime getPastWeekEnd() {
    return getPastWeekStart().add(const Duration(days: 6));
  }

  String getPastWeekDisplayText() {
    final start = getPastWeekStart();
    final end = getPastWeekEnd();
    return '${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd').format(end)}';
  }


  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      isError = false;
    });

    final start = getPeriodStart();
    final end = getPeriodEnd();
    final fromDate = DateFormatUtil.startDateFormat(start);
    final toDate = DateFormatUtil.startDateFormat(end);
    final fromDate2 = DateFormat('yyyy-MM-dd').format(start);
    final toDate2  = DateFormat('yyyy-MM-dd').format(end);

    final TimezoneInfo timezoneInfo =await FlutterTimezone.getLocalTimezone();
    try {
      final result =  await ref.read(riskMetricServiceProvider).fetchHeartRiskMeterHistory(
        fromDate: fromDate,
        toDate: toDate,
        timezone: timezoneInfo.identifier,
      );

      final symptomResult = await SymptomService().fetchSymptoms(
        fromDate: fromDate2,
        toDate: toDate2,
      );

      setState(() {
        symptomSummary = symptomResult;
        heartRiskSummary = result;
        _lastFetchedFromDate = fromDate;
        _lastFetchedToDate = toDate;
        isLoading = false;
        isError = false;
      });
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching ${HeartThriveStrings.riskTitle} summary: $e');
        //debugPrint(stack);
      }
      setState(() {
        isError = true;
        isLoading = false;
      });
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
    _fetchData();
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
      appBar: AppBar(
          leading: GestureDetector(
            onTap: () {
              AppRouter.replaceWithHome(context);
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image.asset("lib/assets/Frame.png"),
            ),
          ),

          title: Row(
            children: [
              SizedBox(width: 5),
              const Text('${HeartThriveStrings.riskTitle} Dashboard'),
            ],
          )
      ),
      body: Padding(
        //Main Column
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Date selector and navigation
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

                              }

                              else if (viewMode == 'week') {

                                // reset to start of the week (optional)

                                final now = DateTime.now();

                                currentDate = now.subtract(Duration(days: now.weekday - 1)); // Monday start

                              }
                            });
                            _fetchData();
                          },
                          items: <String>['day', 'week']
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

            const SizedBox(height: 16),

            // Body
            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (isError)
              const Expanded(child: Center(child: Text('Error loading data')))
            else
            // We have data — show the detailed UI
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dynamic rich UI
                      _buildHeartRiskSummaryUI(heartRiskSummary, viewMode),
                      SizedBox(height: 10,),
                      _buildSymptomsSummaryUI(symptomSummary.symptoms,viewMode),

                      viewMode =='week'?!isPastPeriod()?HeartRiskComparisonCard(heartRiskSummary: heartRiskSummary, titleValue: viewMode):SizedBox(height: 0,width: 0,):SizedBox(height: 0,width: 0,)
                      // Comparison and Tip are added inside _buildHeartRiskSummaryUI already, but you can add more here.
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int getDayIndexInWeek(DateTime start) {
    return DateTime.now().difference(start).inDays + 1;
  }

  Widget _buildHeartRiskSummaryUI(HeartRiskSummaryResponse summary, String titleValue) {
    // Convert titleValue to display version
    String displayTitle;

    switch (titleValue.toLowerCase()) {
      case 'day':
        displayTitle = 'Daily';
        break;
      case 'week':
        displayTitle = 'Weekly';
        break;
      case 'month':
        displayTitle = 'Monthly';
        break;
      default:
        displayTitle = titleValue;
    }

    final riskData = summary.riskSymptom;
    final score = (riskData?.score ?? 0).toDouble();
    final category = riskData?.category ?? 'N/A';
    final message = (riskData?.message?.isNotEmpty == true) ? riskData!.message! : 'No details available';

    // Risk Meter value (unchanged)
    final normalizedScore = (score / 10).clamp(0.0, 10.0);

    // Status color + emoji + text
    Color statusColor;
    String emoji;
    String statusTitle;

    if (score >= 0 && score <= 2) {
      statusColor = Colors.green;
      emoji = 'lib/assets/risk_meter/Heart-Data-Very-Low.png';
      statusTitle = "You're doing good!";
    } else if (score > 2 && score <= 4) {
      statusColor = Colors.orange;
      emoji = 'lib/assets/risk_meter/Heart-Data-Low.png';
      statusTitle = "Keep an eye on your health!";
    } else if (score > 4 && score <= 6) {
      statusColor = Colors.orange;
      emoji = 'lib/assets/risk_meter/Heart-Data-Moderate.png';
      statusTitle = "Keep an eye on your health!";
    } else if (score >6 && score <= 8) {
      statusColor = Colors.orange;
      emoji = 'lib/assets/risk_meter/Heart-Data-High.png';
      statusTitle = "Keep an eye on your health!";
    } else if (score > 8) {
      statusColor = Colors.red;
      emoji = 'lib/assets/risk_meter/Heart-Data-Critical.png';
      statusTitle = "High Risk Alert!";
    } else {
      statusColor = Colors.green;
      emoji = 'lib/assets/risk_meter/Heart-Data-Very-Low.png';
      statusTitle = "You're doing good!";
    }

    // Highest scale range
    String criticalThreshold = '> 8 (Critical)';
    if (riskData?.scale != null && riskData!.scale!.isNotEmpty) {
      final last = riskData.scale!.last;
      criticalThreshold = '${last.range ?? '>8'} (${last.label ?? 'Critical'})';
    }

    final sodium      = summary.sodium?.value ?? 0.0;
    final sodiumPct   = summary.sodium?.percentage ?? 0.0;

    final missed      = summary.medication?.missedCount ?? 0.0;
    final scheduledMed= summary.medication?.scheduleCount ?? 0.0;
    final missedPct   = summary.medication?.percentage ?? 0.0;

    final bmi         = summary.weight?.baselineWeight ?? 0.0;
    final actualWeight = summary.weight?.actualWeight ?? 0.0;
    final bmiPct      = summary.weight?.percentage ?? 0.0;
    final weightChange = summary.weight?.increaseWeight ?? 0.0;
    final weightUnit  = summary.weight?.weightUnitType ?? "kg";
    final start = getPeriodStart();
     int? completedDays =1;
     if(viewMode == 'week' ){
       if(!isPastPeriod()){
         completedDays = getDayIndexInWeek(start);
       }else{
         completedDays =7;
       }
     }



    debugPrint("Completed Days = $completedDays");

    final sodiumDisplay = sodium > 10
        ? '$sodium mg/${getDisplayTitle(viewMode)}'
        : '$sodium g/${getDisplayTitle(viewMode)}';

    final missedDisplay = missed > 0
        ? '${missed.toInt()}/${scheduledMed.toStringAsFixed(0)} missed'
        : '0/${scheduledMed.toStringAsFixed(0)} missed';


    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================  RISK METER  ==================
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$displayTitle ${HeartThriveStrings.riskTitle} Metrics", style: TextStyle(fontSize: deviceWidth(context) > 750 ? 25 :14, fontWeight:FontWeight.bold),),
                    CustomRiskMeter(value: score),
                  ],
                ),
              ),
              SizedBox(width: 5),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRiskIndicator(context,'0-2 (Very Low)',Colors.green,score<=2),
                    const SizedBox(height: 8),
                    _buildRiskIndicator(context,'2-4 (Low)',Colors.lightGreen,(score>2 && score<=4)),
                    const SizedBox(height: 8),
                    _buildRiskIndicator(context,'4-6 (Moderate)',Colors.amber,(score>4 && score<=6)),
                    const SizedBox(height: 8),
                    _buildRiskIndicator(context,'6-8 (High)',Colors.orange,(score>6 && score<=8)),
                    const SizedBox(height: 8),
                    _buildRiskIndicator(context,'> 8 (Critical)',Colors.red,(score>8)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),
          Image.asset(emoji),
          const SizedBox(height: 5),

          // ==================  PIE SECTION  ==================
          Text('$displayTitle ${HeartThriveStrings.riskTitle} Breakdown',
              style: TextStyle(fontSize:deviceWidth(context) > 750 ? 25 : 18,fontWeight:FontWeight.bold)),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: MealProgressIndicator(
                  title: "Sodium Intake",
                  percent: sodiumPct,
                  valueLabel: sodiumDisplay,
                  progressValue: sodium,
                  color: Colors.orange,
                  dayCount: completedDays,
                ),
              ),
              //const SizedBox(width: 8),
              Expanded(
                child: MealProgressIndicator(
                  title: "Medication",
                  percent: missedPct,
                  valueLabel: missedDisplay,
                  progressValue: missed,
                  color: const Color(0xFF2196F3),
                ),
              ),
              //const SizedBox(width: 8),
              Expanded(
                child: MealProgressIndicator(
                  title: "Body Weight",
                  percent: bmiPct,
                  valueLabel: "${bmi.toStringAsFixed(2)} $weightUnit",
                  progressValue: bmi,
                  color: const Color(0xFF9C27B0),
                  weightChange: weightChange,
                  weightUnit: weightUnit,
                  safeWeight: bmi,
                    actualWeight:actualWeight
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

        ],
      ),
    );
  }
  Widget _buildSymptomsSummaryUI( List<SymptomTrackItem> symptomList, String titleValue){
    String displayTitle;
    final DateTime now = DateTime.now();
    final DateTime todayDateOnly = DateTime(now.year, now.month, now.day);
    bool?  isSameDay =todayDateOnly.isAtSameMomentAs(getPeriodStart());
    switch (titleValue.toLowerCase()) {
      case 'day':
        displayTitle = 'Daily';
        break;
      case 'week':
        displayTitle = 'Weekly';
        break;
      case 'month':
        displayTitle = 'Monthly';
        break;
      default:
        displayTitle = titleValue;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Symptoms Tracked $displayTitle',
                style: TextStyle(fontSize: deviceWidth(context) > 750 ? 25:18, fontWeight: FontWeight.bold),
              ),
              isSameDay && symptomList.isNotEmpty ?IconButton(onPressed: (){
               // AppRouter.navigateToAddSymptoms(context);
                String? swellingToLegs;
                String? shortOfBreathWhenLyingFlat;
                String? shortOfBreathWithActivity;
                String? wakingUpAtNightShortOfBreath;
                String? customSymptom;

                symptomList.forEach((s){
                  if(s.symptomName.contains("Swelling to legs")){
                    swellingToLegs = s.symptomLevel[0];
                  }
                  if(s.symptomName.contains("Short of breath with activity")){
                    shortOfBreathWithActivity = s.symptomLevel[0];
                  }
                  if(s.symptomName.contains("Short of breath when lying flat")){
                    shortOfBreathWhenLyingFlat = s.symptomLevel[0];
                  }
                  if(s.symptomName.contains("Waking up at night short of breath")){
                    wakingUpAtNightShortOfBreath = s.symptomLevel[0];
                  }
                  if(s.symptomName.contains("Other symptoms")){
                    customSymptom = s.descriptions[0];
                  }
                });

                SymptomModel symptomModel = SymptomModel(
                    customSymptom: customSymptom == null?'':customSymptom!,
                    swellingToLegs: swellingToLegs,
                    shortOfBreathWhenLyingFlat: shortOfBreathWhenLyingFlat,
                    shortOfBreathWithActivity: shortOfBreathWithActivity,
                    wakingUpAtNightShortOfBreath: wakingUpAtNightShortOfBreath

                );
                AppRouter.navigateToAddSymptomsWithEdit(context, symptomModel, true, false);
              }, icon: Icon(Icons.edit_sharp,color: AppTheme.primaryColor,)):SizedBox()
            ],
          ),
          const SizedBox(height: 12),

          if (symptomList.isEmpty)
            Center(
              child: isPastPeriod()
                  ? buildEmptyStatePast(
                imagePath: 'lib/assets/symptoms/symptoms_cal.png',
                title: '${HeartThriveStrings.noSymptomsTitlePastDynamic} ${getDisplayTitle(titleValue)}',
                subtitle: HeartThriveStrings.noSymptomsDescriptionPast,
              )
                  : noSymptomsCard(() {
                AppRouter.navigateToReplaceAddSymptoms(context);
              }),
            )
          else
            ...symptomList.map((s) {
              debugPrint("Mild ${s.symptomLevelCount.mild}");
              return s.customType ? Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildCustomSymptomItem(
                  imagePath: getSymptomImage(s.symptomName),
                  title: s.symptomName,
                  subtitle: s.trackedOn,
                  trackedOn: buildSymptomDescription(
                      s.symptomName, s.trackedOn, viewMode,s.symptomLevelCount
                  ),
                  description: s.descriptions[0]
                ),
              ):Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildSymptomItem(
                  symptomLevelCount:s.symptomLevelCount,
                  imagePath: getSymptomImage(s.symptomName),
                  title: s.symptomName,
                  subtitle: s.trackedOn,
                  description: buildSymptomDescription(
                      s.symptomName, s.trackedOn, viewMode,s.symptomLevelCount
                  ),
                ),
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildSymptomItem(
                  symptomLevelCount:s.symptomLevelCount,
                  imagePath: getSymptomImage(s.symptomName),
                  title: s.symptomName,
                  subtitle: s.trackedOn,
                  description: buildSymptomDescription(
                      s.symptomName, s.trackedOn, viewMode,s.symptomLevelCount
                  ),
                ),
              );
            }).toList(),
          //const SizedBox(height: 8),
        ],
      ),
    );
  }
  String getDisplayTitle(titleValue){
    String displayTitle;

    switch (titleValue.toLowerCase()) {
      case 'day':
        displayTitle = 'Day';
        break;
      case 'week':
        displayTitle = 'Week';
        break;
      case 'month':
        displayTitle = 'Month';
        break;
      default:
        displayTitle = titleValue;
    }
    return displayTitle;
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      border: Border.all(
        color: Colors.grey.shade300,
        width: 1.5,
      ),
      borderRadius: BorderRadius.circular(4),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }


  /// Helper to map label → color


  Widget _buildRiskIndicator(BuildContext context, String text, Color color, bool isActive) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive scaling factor for smaller screens
    final scale = screenWidth <= 390 ? 0.9 : 1.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10 * scale,
          height: 12 * scale,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isActive ? Border.all(color: Colors.black, width: 2 * scale) : null,
          ),
        ),
        SizedBox(width: 8 * scale),
        Text(
          text,
          style: TextStyle(
            fontSize: deviceWidth(context) > 750 ? 20 :12 * scale,
            color: isActive ? Colors.black87 : Color(0xFF909090),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomSymptomItem({required String imagePath,
    required String title,
    required String subtitle,        // from API
    required String trackedOn,
    required String description
  }){
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _boxDecoration().copyWith(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Image.asset(
                imagePath,
                width: deviceWidth(context) > 750 ? 80 :60,
                //height: 50,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TEXT — Wraps to next line, but stays in same row structure
                        Expanded(
                          child: RichText(
                            textWidthBasis: TextWidthBasis.longestLine,
                            softWrap: true,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "$title ",
                                  style: TextStyle(
                                    fontSize: deviceWidth(context) > 750 ? 20: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),

                              ],
                            ),
                          ),
                        )


                      ],
                    ),
                    const SizedBox(height: 4),
                    // 🔹 SUBTITLE (API text)
                    Text(
                      'Tracked on : $trackedOn ',
                      style: TextStyle(
                        fontSize: deviceWidth(context) > 750 ? 18: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),


                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8,),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Directionality(
                textDirection: ui.TextDirection.ltr,
                child: Text(
                  description,
                  style: deviceWidth(context) > 750
                      ? AppTheme.body16.copyWith(color: Colors.black)
                      : AppTheme.body14.copyWith(color: Colors.black),
                  textAlign: TextAlign.start,
                ),
              ),
            ),
          ),


        ],
      ),
    );
  }

  Widget _buildSymptomItem({
    required String imagePath,
    required String title,
    required String subtitle,        // from API
    required String description,
    required SymptomLevelCount symptomLevelCount,     // static message
  }) {
    final int  total = symptomLevelCount.severe + symptomLevelCount.moderate+symptomLevelCount.mild;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _boxDecoration().copyWith(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Image.asset(
                imagePath,
                width: deviceWidth(context) > 750 ? 80 :60,
                //height: 50,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TEXT — Wraps to next line, but stays in same row structure
                        Expanded(
                          child: RichText(
                            textWidthBasis: TextWidthBasis.longestLine,
                            softWrap: true,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "$title ",
                                  style: TextStyle(
                                    fontSize: deviceWidth(context) > 750 ? 20: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),

                              ],
                            ),
                          ),
                        )


                      ],
                    ),
                    const SizedBox(height: 4),
                    // 🔹 SUBTITLE (API text)
                    Text(
                      'Tracked on : ${total > 1?'$total times':'$total time'}  in ${getDisplayTitle(viewMode)}',
                      style: TextStyle(
                        fontSize: deviceWidth(context) > 750 ? 18: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),


                  ],
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPill("Mild", symptomLevelCount.mild, Color(0xff43A047)),
              //SizedBox(width: 10,),
              _buildPill("Moderate", symptomLevelCount.moderate, Color(0xffFBC02D)),
              //SizedBox(width: 10,),
              _buildPill("Severe", symptomLevelCount.severe, Color(0xffE53935)),
             // SizedBox(width: 10,),
            ],
          ),
          SizedBox(height: 8,),
          Padding(
            padding: const EdgeInsets.only(left: 8.0,top: 8),
            child: Text(
              description,
              style:deviceWidth(context) > 750 ? AppTheme.body16.copyWith(
                  color: Colors.black
              ): AppTheme.body14.copyWith(
                color: Colors.black
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }
  bool isPastPeriod() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (viewMode == "day") {
      final selected = DateTime(currentDate.year, currentDate.month, currentDate.day);
      return selected.isBefore(today);
    }

    if (viewMode == "week") {
      final periodStart = getPeriodStart();
      final periodEnd = getPeriodEnd();
      return periodEnd.isBefore(today);
    }

    return false; // month not used yet
  }

  Widget noSymptomsCard(VoidCallback onAddSymptoms) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- Illustration Image ---
          SizedBox(
            height: deviceWidth(context) > 750 ? 180 :140,
            child: Image.asset(
              'lib/assets/symptoms/no_symptoms.png',   // <-- replace with your image
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 16),

          // --- Title ---
           Text(
            HeartThriveStrings.noSymptomsTitle,
            style:deviceWidth(context) > 750 ? AppTheme.title20 : AppTheme.title16,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // --- Subtitle ---
          Text(
            HeartThriveStrings.noSymptomsDescription,
            style: deviceWidth(context) > 750 ? AppTheme.body18 :AppTheme.body14,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 18),

          // --- Button ---
          ElevatedButton.icon(
            onPressed: onAddSymptoms,
            style: ElevatedButton.styleFrom(
              backgroundColor:AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: Row(
              children: [
                Text(
                  "Add Symptoms",
                  style: deviceWidth(context) > 750 ? AppTheme.title20.copyWith(
                      color: Colors.white
                  ): AppTheme.title16.copyWith(
                    color: Colors.white
                  ),
                ),
                SizedBox(width: 8,),
                Icon(Icons.add_circle,size: deviceWidth(context) > 750 ? 25: 18,)
              ],
            ),
            label: SizedBox(),
          ),
        ],
      ),
    );
  }
  Widget buildEmptyStatePast({
    required String imagePath,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Image
          SizedBox(
            height:deviceWidth(context) > 750 ? 160 : 140,
            width: deviceWidth(context) > 750 ? 160 :140,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize:deviceWidth(context) > 750 ? 30 : 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            subtitle,
            style: TextStyle(
              fontSize: deviceWidth(context) > 750 ? 20:14,
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Widget _buildPill(String label, int count, Color color) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal:deviceWidth(context) > 750 ? 12: 6, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTheme.title12.copyWith(
                fontSize: deviceWidth(context) > 750 ? 20:deviceWidth(context) > 390?14:deviceWidth(context) > 360?12:10,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              "($count)",
              style: AppTheme.title12.copyWith(
                fontSize: deviceWidth(context) > 750 ? 20:deviceWidth(context) > 390?14:deviceWidth(context) > 360?12:10,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }


  String buildSymptomDescription(
      String symptomName,
      String trackedOn,
      String viewMode,
      SymptomLevelCount symptomLevelCount

      ) {
    // Extract number from "1 of last 5 days"
    final numberMatch = RegExp(r'(\d+)').firstMatch(trackedOn);
    int count = numberMatch != null ? int.parse(numberMatch.group(0)!) : 0;

    String timesText = count == 1 ? "1 time" : "$count times";

    // Determine period based on viewMode
    String period;
    switch (viewMode.toLowerCase()) {
      case "day":
        period = "today";
        break;
      case "week":
        period = "this week";
        break;
      case "month":
        period = "this month";
        break;
      default:
        period = "this period";
    }

    final nameLower = symptomName.toLowerCase();

    if (nameLower.contains("with activity")) {
       final int total = symptomLevelCount.mild + symptomLevelCount.moderate + symptomLevelCount.severe;
      return "You experienced shortness of breath with activity $total $period. "
          "Monitor hydration & sodium levels.";
    }

    if (nameLower.contains("lying flat")) {
      final int total = symptomLevelCount.mild + symptomLevelCount.moderate + symptomLevelCount.severe;
      return "You experienced shortness of breath while lying flat $total $period. "
          "Consider sleeping with elevated pillows.";
    }

    if (nameLower.contains("waking up")) {
      final int total = symptomLevelCount.mild + symptomLevelCount.moderate + symptomLevelCount.severe;
      return "You woke up at night short of breath $total $period. "
          "Monitor night-time breathing & discuss with your doctor.";
    }

    if (nameLower.contains("swelling")) {
      final int total = symptomLevelCount.mild + symptomLevelCount.moderate + symptomLevelCount.severe;
      return "You experienced swelling to legs $total $period. "
          "Monitor hydration & sodium levels.";
    }

    return "You reported this symptom $timesText $period.";
  }


  String getSymptomImage(String symptomName) {
    final normalized = symptomName.toLowerCase();

    if (normalized.contains("lying flat")) {
      return "lib/assets/symptoms/short_breath_ lying_flat.png";
    }
    else if (normalized.contains("with activity")) {
      return "lib/assets/symptoms/short_breath_activity.png";
    }
    else if (normalized.contains("swelling")) {
      return "lib/assets/symptoms/swelling_legs.png";
    }
    else if (normalized.contains("waking up")) {
      return "lib/assets/symptoms/waking_ night_short_breath.png";
    }
    else if (normalized.contains("other symptoms")) {
      return "lib/assets/symptoms/other-symptoms.png";
    }

    // default fallback
    return "lib/assets/symptoms/no_symptoms.png";
  }

  // Heart Comparison Not Available
  Widget HeartRiskComparisonCard({required HeartRiskSummaryResponse heartRiskSummary,required String titleValue}) {
    debugPrint("heartRiskSummary @@@ ${jsonEncode(heartRiskSummary)}");
    String displayTitle;

    switch (titleValue.toLowerCase()) {
      case 'day':
        displayTitle = 'Day';
        break;
      case 'week':
        displayTitle = 'Week';
        break;
      case 'month':
        displayTitle = 'Month';
        break;
      default:
        displayTitle = titleValue;
    }
    final riskData = heartRiskSummary.riskSymptom;
    final currentScore = (riskData?.score ?? 0).toDouble();
    final category = riskData?.category ?? 'N/A';

    // Determine color based on risk level
    Color riskColor;
    final lowerCat = category.toLowerCase();
    if (lowerCat.contains('low') || lowerCat.contains('very low')) {
      riskColor = const Color(0xFF4CAF50); // Green
    } else if (lowerCat.contains('moderate')) {
      riskColor = Colors.orange;
    } else if (lowerCat.contains('high') || lowerCat.contains('critical')) {
      riskColor = Colors.red;
    } else {
      riskColor = const Color(0xFF4CAF50); // Default to green
    }

    Color getRiskColor(double? percentage) {
      if (percentage == null) return Colors.grey; // fallback color

      if (percentage <= 50) {
        return Colors.green;
      } else if (percentage <= 80) {
        return Colors.yellow.shade700;
      } else {
        return Colors.red;
      }
    }

    // Calculate comparison (simulate last week data - in real app, this would come from API)
    // For now, we'll use a simple calculation: if current score is low, show improvement



    // Format risk level text
    String riskLevelText;
    if (lowerCat.contains('very low')) {
      riskLevelText = 'Very Low Risk Level';
    } else if (lowerCat.contains('low')) {
      riskLevelText = 'Low Risk Level';
    } else if (lowerCat.contains('moderate')) {
      riskLevelText = 'Moderate Risk Level';
    } else if (lowerCat.contains('high')) {
      riskLevelText = 'High Risk Level';
    } else if (lowerCat.contains('critical')) {
      riskLevelText = 'Critical Risk Level';
    } else {
      riskLevelText = 'Low Risk Level';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child:  comparison == null ||
          comparison?.lastWeekRiskScorePercentage == null ||
          comparison?.secondLastWeekRiskScorePercentage == null
          ? Center(
        child: buildNoWeekToWeekCard(),
      )
          :
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            displayTitle == "Day"? "${HeartThriveStrings.riskTitle} Comparison ($displayTitle vs Last $displayTitle)":"${HeartThriveStrings.riskTitle} Comparison (${getThisWeekDisplayText()} vs ${getPastWeekDisplayText()})",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 16),

          // ==============================
          //        RISK STATUS BOX
          // ==============================
          Row(
            children: [
              // LEFT: Percent Box (this week's %)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: getRiskColor(comparison?.lastWeekRiskScorePercentage),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${comparison?.lastWeekRiskScorePercentage?.toStringAsFixed(0)}% ",
                  style: AppTheme.title18.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // RIGHT: Risk info + comparison text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Risk level and info icon
                    Row(
                      children: [
                        Text(
                          comparison?.riskLevel?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.red.shade400,
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Increase / decrease arrow + text
                    Row(
                      children: [
                        Icon(
                          comparison?.changeType?.toLowerCase() == "decreased"
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          size: 16,
                          color: const Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "${comparison?.changeType} by ${comparison?.changeValue?.toStringAsFixed(1)}% "
                                "from last week (${comparison?.secondLastWeekRiskScorePercentage?.toStringAsFixed(0)}%)",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ==============================
          //            TIP BOX
          // ==============================
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
              border: const Border(
                left: BorderSide(
                  color: Color(0xFF4CAF50),
                  width: 5,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.green.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Tip: Great job! Continue your healthy habits. Regular check-ins will help maintain your status.",
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget buildNoWeekToWeekCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${HeartThriveStrings.riskTitle} Comparison",style: AppTheme.title16,),
          SizedBox(height: 10,),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // LEFT ICON
              Expanded(
                flex: 3,
                child: Image.asset(
                    "lib/assets/risk_meter/heart_comp_note.png",
                    fit: BoxFit.cover,
                    //color: Colors.red,
                ),
              ),
              const SizedBox(width: 8),

              // TEXTS
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:  [
                    Text(
                      HeartThriveStrings.noHeartComparisonTitle,
                      style: AppTheme.title16
                    ),
                    SizedBox(height: 6),
                    Text(
                      HeartThriveStrings.noHeartComparisonDescription,
                      style: AppTheme.body14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }




}

/// PieChartPainter that accepts numeric values and normalizes them to percentages.
/// Use PieChartPainter.fromValues(sodiumValue, missedValue, bmiValue)
class PieChartPainter extends CustomPainter {
  final double sodiumVal;
  final double missedVal;
  final double bmiVal;
  final List<double> _percentages;
  final List<Color> _colors;

  PieChartPainter._(
      this.sodiumVal,
      this.missedVal,
      this.bmiVal,
      this._percentages,
      this._colors,
      );

  /// ✅ Create painter from raw numeric values (auto-normalized)
  factory PieChartPainter.fromValues(double sodiumVal, double missedVal, double bmiVal) {
    final values = [sodiumVal.abs(), missedVal.abs(), bmiVal.abs()];
    final total = values.fold(0.0, (p, e) => p + e);
    final perc = total > 0
        ? values.map((v) => v / total).toList()
        : [0.4, 0.3, 0.3]; // default fallback

    // ✅ Color order: Blue (Sodium), Orange (Missed Meds), Purple (Body Weight)
    final colors = [
      const Color(0xFF2196F3), // Sodium
      const Color(0xFFFF9800), // Missed Medication
      const Color(0xFF9C27B0), // Body Weight
    ];

    return PieChartPainter._(sodiumVal, missedVal, bmiVal, perc, colors);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    double startAngle = -math.pi / 2; // start from top

    for (int i = 0; i < _percentages.length; i++) {
      final sweepAngle = _percentages[i] * 2 * math.pi;
      paint.color = _colors[i];

      // Draw segment
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw percentage label
      final labelAngle = startAngle + sweepAngle / 2;
      final labelRadius = radius * 0.65;
      final labelPos = Offset(
        center.dx + labelRadius * math.cos(labelAngle),
        center.dy + labelRadius * math.sin(labelAngle),
      );

      final percentText = '${(_percentages[i] * 100).round()}%';
      final tp = TextPainter(
        text: TextSpan(
          text: percentText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: ui.TextDirection.ltr,
      );

      tp.layout();
      tp.paint(
        canvas,
        Offset(labelPos.dx - tp.width / 2, labelPos.dy - tp.height / 2),
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
