import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:heart_thrive/components/decimal_formatter.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import 'package:heart_thrive/models/meal/nutrient_response.dart';
import 'package:heart_thrive/pages/meal-sodium/sodium_dashboard/sodium_dashboard_page.dart';
import 'package:heart_thrive/routes/app_router.dart';

import 'package:fl_chart/fl_chart.dart';

import '../../../services/meal_services.dart';
import '../../../theme/app_theme.dart';



class SodiumIntakeOverviewPage extends StatefulWidget {
  const SodiumIntakeOverviewPage({Key? key}) : super(key: key);

  @override
  State<SodiumIntakeOverviewPage> createState() => _SodiumIntakeOverviewPageState();
}

class _SodiumIntakeOverviewPageState extends State<SodiumIntakeOverviewPage> {
  String _selectedDayView = 'Today';
  final List<String> _dayViewOptions = ['Today', 'Yesterday', 'Last 7 Days', 'Last 30 Days'];

  // State variables for dynamic data
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _nutrientSummary;
  Map<String, dynamic>? _mealTypeSummary;
  List<Map<String, dynamic>> _historicalData = [];

  // Default values
  static const double _targetSodium = 2500.0; // mg per day

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final now = DateTime.now();
      final fromDate = DateTime(now.year, now.month, now.day, 0, 0);
      final toDate = DateTime(now.year, now.month, now.day, 23, 59);

      final results = await Future.wait([
        MealService.fetchNutrientSummaryOld(fromDate, toDate),
        MealService.fetchNutrientSummaryByMealType(fromDate, toDate),
      ]);

      _nutrientSummary = results[0];
      _mealTypeSummary = results[1];

      // Only load historical data for 7 or 30 days
      if (_selectedDayView == 'Last 7 Days' || _selectedDayView == 'Last 30 Days') {
        await _loadHistoricalData();
      } else {
        _historicalData = [
          {
            'sodiumAmount':
            (_nutrientSummary?['nutrients']?.firstWhere((n) => n['name'] == 'Sodium',
                orElse: () => {'amount': 0.0})['amount'] ??
                0.0)
          }
        ];
      }

      setState(() {
        _isLoading = false;
      });

      debugPrint("Nutrient summary: $_nutrientSummary");
      debugPrint("Meal type summary: $_mealTypeSummary");
      debugPrint("Historical data: $_historicalData");
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }


  Future<void> _loadHistoricalData() async {
    final now = DateTime.now();
    List<Map<String, dynamic>> tempData = [];

    int days = _selectedDayView == 'Last 7 Days'
        ? 7
        : _selectedDayView == 'Last 30 Days'
        ? 30
        : 1;

    for (int i = days - 1; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final fromDate = DateTime(day.year, day.month, day.day, 0, 0);
      final toDate = DateTime(day.year, day.month, day.day, 23, 59);

      try {
        final NutrientResponse? summary = await MealService.fetchNutrientSummary(fromDate, toDate);

        double sodium = 0.0;
        final nutrients = summary?.nutrients;
        final sodiumData = nutrients?.firstWhereOrNull((n) => n.name == 'Sodium');;

        if (sodiumData != null) {
          sodium = (sodiumData.amount ?? 0.0).toDouble();
        }

        tempData.add({'sodiumAmount': sodium});
      } catch (e) {
        tempData.add({'sodiumAmount': 0.0}); // fallback if API fails
      }
    }

    setState(() {
      _historicalData = tempData;
    });

    debugPrint("Historical data: $_historicalData");
  }




  Map<String, String> _getDateRange(String dayView) {
    final now = DateTime.now();
    switch (dayView) {
      case 'Today':
        final today = DateTime(now.year, now.month, now.day);
        return {
          'fromDate': '${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year} 00:00',
          'toDate': '${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year} 23:59',
        };
      case 'Yesterday':
        final yesterday = DateTime(now.year, now.month, now.day - 1);
        return {
          'fromDate': '${yesterday.day.toString().padLeft(2, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.year} 00:00',
          'toDate': '${yesterday.day.toString().padLeft(2, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.year} 23:59',
        };
      case 'Last 7 Days':
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        return {
          'fromDate': '${sevenDaysAgo.day.toString().padLeft(2, '0')}-${sevenDaysAgo.month.toString().padLeft(2, '0')}-${sevenDaysAgo.year} 00:00',
          'toDate': '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year} 23:59',
        };
      case 'Last 30 Days':
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        return {
          'fromDate': '${thirtyDaysAgo.day.toString().padLeft(2, '0')}-${thirtyDaysAgo.month.toString().padLeft(2, '0')}-${thirtyDaysAgo.year} 00:00',
          'toDate': '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year} 23:59',
        };
      default:
        return {
          'fromDate': '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year} 00:00',
          'toDate': '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year} 23:59',
        };
    }
  }

  double _getConsumedSodium() {
    if (_nutrientSummary == null) return 0.0;
    final nutrients = _nutrientSummary!['nutrients'] as List<dynamic>? ?? [];
    final sodium = nutrients.firstWhere(
          (n) => n['name'] == 'Sodium',
      orElse: () => null,
    );
    return sodium != null ? (sodium['amount'] as num).toDouble() : 0.0;
  }


  double _getRemainingSodium() {
    debugPrint("172 : _targetSodium $_targetSodium");
    debugPrint("171 @@@@@ ${ _getConsumedSodium()}");
    if(_targetSodium > _getConsumedSodium()){
      return _targetSodium - _getConsumedSodium();
    }else{
      return _getConsumedSodium() - _targetSodium;
    }

  }
  String _getRemainingSodiumTitle() {
    if (_getConsumedSodium() <= _targetSodium) {
      return "LEFT";  // includes 0mg remaining
    } else {
      return "LIMIT EXCEEDED";
    }
  }


  double _getProgressValue() {
    final consumed = _getConsumedSodium();
    return (consumed / _targetSodium);
  }

  List<Map<String, dynamic>> _getMealBreakdownData() {
    debugPrint("*********** Inside _getMealBreakdownData **************");
    if (_mealTypeSummary == null) return [];

    final List<Map<String, dynamic>> mealData = [];
    final summaries = _mealTypeSummary!['mealTypeNutrientSummaries'] as List<dynamic>? ?? [];

    for (var summary in summaries) {
      final mealType = summary['mealType']?['name'] ?? 'Unknown';

      // 🚨 Skip "All" if somehow present
      if (mealType.toLowerCase() == 'all') continue;

      final nutrients = summary['nutrients'] as List<dynamic>? ?? [];
      final sodium = nutrients.firstWhere(
            (n) => n['name'] == 'Sodium',
        orElse: () => null,
      );

      final consumed = sodium != null ? (sodium['amount'] as num).toDouble() : 0.0;

      mealData.add({
        'name': mealType,
        'consumed': consumed,
        'target': _getMealTarget(mealType),
      });
    }

    // 🧩 Define the preferred order
    const order = ['Breakfast', 'Lunch', 'Snacks', 'Dinner'];

    // 🪄 Sort mealData based on that order
    mealData.sort((a, b) {
      final aIndex = order.indexOf(a['name']);
      final bIndex = order.indexOf(b['name']);
      return aIndex.compareTo(bIndex);
    });

    debugPrint('mealData $mealData');

    return mealData;
  }



  double _getMealTarget(String mealType) {
    // Define targets for different meal types
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 700.0;
      case 'lunch':
        return 700.0;
      case 'snacks':
        return 400.0;
      case 'dinner':
        return 700.0;
      default:
        return 500.0;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: const Text('Sodium Intake Overview'),
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
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Today's Summary
                       Text(
                        'Today\'s Summary',
                        style: deviceWidth(context)>750?AppTheme.title20:AppTheme.title18,
                      ),
                      const SizedBox(height: 16),
                      // Circular Progress Indicator with proper layout
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Center the Circular Progress Indicator
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: SizedBox(
                                width: deviceWidth(context)>750?150:120,
                                height: deviceWidth(context)>750?150:120,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Background circle
                                    SizedBox(
                                      width: deviceWidth(context)>750?150:120,
                                      height: deviceWidth(context)>750?150:120,
                                      child: CircularProgressIndicator(
                                        value: 1.0,
                                        strokeWidth: 8,
                                        backgroundColor: Colors.grey.shade300,
                                        color: _getRemainingSodium().toInt() == 2500?  Colors.grey:Colors.red,
                                      ),
                                    ),
                                    // Consumed progress
                                    SizedBox(
                                      width: deviceWidth(context)>750?150:120,
                                      height: deviceWidth(context)>750?150:120,
                                      child: CircularProgressIndicator(
                                        value: _getProgressValue(), // dynamic from API
                                        strokeWidth: 8,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                                        backgroundColor: Colors.transparent,
                                      ),
                                    ),
                                    // Center text
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${formatNumberWithCommas(_getRemainingSodium())} mg',
                                          style: deviceWidth(context)>750?AppTheme.title18:AppTheme.title16,
                                        ),
                                         Flexible(
                                           child: Text(
                                            _getRemainingSodiumTitle(),
                                            style: deviceWidth(context)>750?AppTheme.title16:AppTheme.title12,
                                           ),
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
                                _buildLegendItem('TARGET', Colors.grey),
                                const SizedBox(height: 8),
                                _buildLegendItem('CONSUMED', Colors.green),
                                const SizedBox(height: 8),
                                _buildLegendItem('LEFT', Colors.red),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meals - Sodium Breakdown
                       Text(
                        'Meals - Sodium(in mg) Breakdown',
                        style: deviceWidth(context)>750?AppTheme.title20:AppTheme.title16
                      ),
                       SizedBox(height: deviceWidth(context)>750?20:10),
                      // Meal Breakdown Circles
                      SizedBox(
                          height: deviceWidth(context)>750?180:120,
                          child: _buildMealBreakdownSection(context)
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Bar Chart
             // const SodiumIntakeScreen(),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 500,
                    child: SodiumIntakeScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),


            ],
          ),
        ),
      ),
    );
  }

  Color _getMealColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Color(0xFFFFA500);
      case 'lunch':
        return Color(0xFF42A5F5);
      case 'snacks':
        return Color(0xFFAB47BC);
      case 'dinner':
        return Color(0xFF3F51B5);
      default:
        return Colors.grey; // fallback
    }
  }


  Widget _buildMealBreakdownSectionOld() {
    final mealData = _getMealBreakdownData();

    if (mealData.isEmpty) {
      return const Text("No meal breakdown data available");
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // so all items can fit in one row
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: mealData.map((meal) {
          final name = meal['name'] ?? 'Unknown';
          final consumed = (meal['consumed'] ?? 0.0);
          final target = (meal['target'] ?? 1.0).toDouble(); // Prevent division by zero
          final progress = (consumed / target).clamp(0.0, 1.0);
          final color = _getMealColor(name);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _MealProgressIndicator(
              name: name,
              consumed: consumed,
              target: target,
              progress: progress,
              color: color,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMealBreakdownSection(BuildContext context) {
    final mealData = _getMealBreakdownData();

    if (mealData.isEmpty) {
      return const Text("No meal breakdown data available");
    }

    final screenWidth = deviceWidth(context);
    final isWideScreen = screenWidth > 750;

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: mealData.map((meal) {
        final name = meal['name'] ?? 'Unknown';
        final consumed = (meal['consumed'] ?? 0.0);
        final target = (meal['target'] ?? 1.0).toDouble();
        final progress = (consumed / target).clamp(0.0, 1.0);
        final color = _getMealColor(name);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            width: deviceWidth(context)>750?150:110,
            child: _MealProgressIndicator(
              name: name,
              consumed: consumed,
              target: target,
              progress: progress,
              color: color,
            ),
          ),
        );
      }).toList(),
    );

    /// ✅ Wide screens → Horizontal scroll
    if (isWideScreen) {
      return SizedBox(
        height: 140,
        child: SingleChildScrollView(
          child: content,
        ),
      );
    }

    /// ✅ Small screens → Wrap (no scroll)
    return SizedBox(
      height: 140,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: content,
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
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
    );
  }

  Widget _buildMealBreakdown(String meal, String value, Color color, double progress) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 4,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.grey),
                ),
              ),
              // Progress circle
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              // Center text
              Text(
                value,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          meal,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    if (_historicalData.isEmpty) {
      return const Center(child: Text("No data available"));
    }

    final double maxSodiumValue = _historicalData
        .map((e) => (e['sodiumAmount'] ?? 0).toDouble())
        .fold(0.0, (prev, curr) => curr > prev ? curr : prev);
    //maxSodiumValue = 100000.00;
   // final double adjustedMaxY = maxSodiumValue > 5000 ? (maxSodiumValue * 1.1) : 5000;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 2500, // max sodium in mg
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            //tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final sodiumMg =
              (_historicalData[groupIndex]['sodiumAmount'] ?? 0).toInt();
              return BarTooltipItem(
                '$sodiumMg mg',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 250, // 500 mg steps
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  space: 2,
                  meta: meta,
                  child: Text('${value.toInt()}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: bottomTitles,
              reservedSize: 36,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            right: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 500,
         // verticalInterval:500,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
            dashArray: [5],
          ),
        ),
        barGroups: List.generate(_historicalData.length, (index) {
          final sodiumMg = (_historicalData[index]['sodiumAmount'] ?? 0).toDouble();
          Color barColor =
          sodiumMg < 2200 ? Colors.green : sodiumMg < 2500 ? Colors.yellow : Colors.red;
          final double displayY = sodiumMg > 2500 ? 2500 : sodiumMg;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: displayY,
                width: 16,
                color: barColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }


  Widget rightTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      fontSize: 10,
      color: Colors.grey,
    );
    return SideTitleWidget(
      meta: meta,
      space: 0,
      child: Text('${value.toStringAsFixed(1)} g', style: style),
    );
  }



  Widget bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('01', style: style);
        break;
      case 1:
        text = const Text('02', style: style);
        break;
      case 2:
        text = const Text('03', style: style);
        break;
      case 3:
        text = const Text('04', style: style);
        break;
      case 4:
        text = const Text('05', style: style);
        break;
      case 5:
        text = const Text('06', style: style);
        break;
      case 6:
        text = const Text('07', style: style);
        break;
      case 7:
        text = const Text('08', style: style);
        break;
      default:
        text = const Text('');
        break;
    }
    return SideTitleWidget(
      space: 16,
      child: text,
      //axisSide: AxisSide.bottom,
      meta: meta,
    );
  }


  Widget _buildBarLegend(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.rectangle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _MealProgressIndicator extends StatelessWidget {
  final String name;
  final double consumed;
  final double target;
  final double progress;
  final Color color;

  const _MealProgressIndicator({
    required this.name,
    required this.consumed,
    required this.target,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            _buildCircle(
              value: 1.0,
              color: Colors.grey,
              backgroundColor: Colors.grey.shade300,
              deviceWidth: deviceWidth
            ),
            _buildCircle(
              value: progress,
              color: color,
              backgroundColor: Colors.transparent,
                deviceWidth: deviceWidth
            ),
            Column(
              children: [
                Text(
                  '${formatNumberWithCommas(consumed)}/${target.toInt()}',
                  style:  TextStyle(
                    fontSize: deviceWidth > 390? 12:10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(fontSize: 12),
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
    required double deviceWidth
  }) {
    return SizedBox(
      width: deviceWidth >750?150:deviceWidth >390?80:75,
      height: deviceWidth >750?150:deviceWidth >390?80:75,
      child: CircularProgressIndicator(
        value: value,
        strokeWidth: 6,
        valueColor: AlwaysStoppedAnimation<Color>(color),
        backgroundColor: backgroundColor,
      ),
    );
  }
}


// PieChart
class SodiumSummaryChart extends StatefulWidget {
  const SodiumSummaryChart({Key? key}) : super(key: key);

  @override
  State<SodiumSummaryChart> createState() => _SodiumSummaryChartState();
}

class _SodiumSummaryChartState extends State<SodiumSummaryChart> {
  bool hasData = true; // 🔹 Set false to test grey full circle

  double total = 2500;
  double taken = 900;

  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    double left = total - taken;
    double takenPercent = hasData ? taken / total : 0;
    double leftPercent = hasData ? left / total : 1;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => touchedIndex = 1); // show tooltip
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => touchedIndex = -1);
        });
      },
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                startDegreeOffset: -90,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {},
                ),
                sections: hasData
                    ? [
                  PieChartSectionData(
                    color: Colors.green,
                    value: takenPercent,
                    showTitle: false,
                    radius: 20,
                  ),
                  PieChartSectionData(
                    color: Colors.red,
                    value: leftPercent,
                    showTitle: false,
                    radius: 20,
                  ),
                ]
                    : [
                  PieChartSectionData(
                    color: Colors.grey.shade400,
                    value: 1,
                    showTitle: false,
                    radius: 20,
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  hasData ? "${left.toInt()}mg" : "0mg",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "LEFT",
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            if (touchedIndex != -1 && hasData)
              Positioned(
                top: 0,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${taken.toInt()}mg",
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

