import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import 'package:heart_thrive/providers/bmi/bmi_provider.dart';
import 'package:heart_thrive/routes/app_router.dart';
import '../../models/bmi/weight_height_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/component_utils.dart';
import 'new_bmi_dashboard.dart';

class WeightTrendDashboardPage extends ConsumerWidget {
  const WeightTrendDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardHeroData = ref.watch(heroDashboardProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: const Text('Weight Trend Dashboard'),
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
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(8.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SizedBox(
                    height: deviceWidth(context)>830?480:350,
                    child: WeightMetricsPage(
                      heroDashboardData: dashboardHeroData.value?.data,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: 500,
                        child: WeightDashboardScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeightTrendDashboardPageOld extends ConsumerWidget {
  const WeightTrendDashboardPageOld({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardHeroData = ref.watch(heroDashboardProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: const Text('Weight Trend Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Weight Section
              SizedBox(
                height: 380,
                child: WeightMetricsPage(heroDashboardData: dashboardHeroData.value?.data),
              ),
              //const SizedBox(height: 10),

              // BMI Dashboard
              const SizedBox(
                height: 500,
                child: WeightDashboardScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class WeightMetricsWidget extends StatelessWidget {
  const WeightMetricsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(  // <-- Wrap in Stack
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Weight Metrics – Current 200 lbs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Obesity',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Silhouettes + Labels
              SizedBox(
                height: 200, // Fixed height for consistency
                child: Column(
                  children: [
                    // Silhouettes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Image.asset('lib/assets/bmi_d1.png', height: 60),
                        Image.asset('lib/assets/bmi_d2.png', height: 60),
                        Image.asset('lib/assets/bmi_d3.png', height: 60),
                        Image.asset('lib/assets/bmi_d4.png', height: 60),
                        Image.asset('lib/assets/bmi_d5.png', height: 60),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategoryItem('50–90 lbs', 'Underweight', Colors.blue[200]!),
                        _buildCategoryItem('91–120 lbs', 'Normal', Colors.green[400]!),
                        _buildCategoryItem('121–170 lbs', 'Overweight', Colors.yellow[600]!),
                        _buildCategoryItem('171–220 lbs', 'Obesity', Colors.orange[400]!),
                        _buildCategoryItem('221–350 lbs', 'Extreme', Colors.red[400]!),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40), // Space for bubble
            ],
          ),

          // Orange Callout Bubble (now inside Stack)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[400],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Sad', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        "You're in a high-risk zone!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Take action!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String range, String label, Color color) {
    bool isObesity = label == 'Obesity';
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(range, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isObesity ? Colors.orange[700] : Colors.black87,
              ),
            ),
          ],
        ),
        if (isObesity)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: CustomPaint(size: const Size(8, 8), painter: TrianglePainter()),
          ),
      ],
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange[400]!
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}







class WeightMetricsPage extends StatelessWidget {
  //final double weight;
  final HeroDashboardData? heroDashboardData;

  const WeightMetricsPage({super.key, required this.heroDashboardData});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints:  BoxConstraints(maxWidth: deviceWidth(context)>830?800:400), // cap width for consistency
        child: buildWeightMetricsTable(heroDashboardData!.bmiValue!,context),
      ),
    );
  }

  Widget buildWeightMetricsTable(double bmiValue,BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {'range': '< 18.5', 'label': 'Underweight', 'color': Colors.green},
      {'range': '18.5–24.9', 'label': 'Normal', 'color': Colors.lightGreen},
      {'range': '25.0–29.9', 'label': 'Overweight', 'color': Colors.yellow[600]},
      {'range': '30.0–39.9', 'label': 'Obesity', 'color': Colors.orange[400]},
      {'range': '> 40.0', 'label': 'Extreme', 'color': Colors.red[400]},
    ];

    int activeIndex = 0;
    if (bmiValue < 18.5) {
      activeIndex = 0;
    } else if (bmiValue <= 24.9) {
      activeIndex = 1;
    } else if (bmiValue <= 29.9) {
      activeIndex = 2;
    } else if (bmiValue <= 39.9) {
      activeIndex = 3;
    } else {
      activeIndex = 4;
    }

    String? message;
    Color msgColor;
    IconData icon;
    switch (activeIndex) {
      case 0:
        message = 'lib/assets/bmi_status_banner_1.png';
        msgColor = Colors.green;
        break;
      case 1:
        message = 'lib/assets/bmi_status_banner_2.png';
        msgColor = Colors.lightGreen;
        break;
      case 2:
        message = 'lib/assets/bmi_status_banner_3.png';
        msgColor = Colors.yellow[700]!;
        break;
      case 3:
        message = 'lib/assets/bmi_status_banner_4.png';
        msgColor = Colors.orange[400]!;
        break;
      default:
        message = 'lib/assets/bmi_status_banner_5.png';
        msgColor = Colors.red[400]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.white, style: BorderStyle.solid, width: 3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${heroDashboardData?.bmiStatus} - BMI ${heroDashboardData?.bmiValue} | Current Weight ${heroDashboardData?.weight}',
            style: deviceWidth(context)>830? AppTheme.title20 : AppTheme.title16,
          ),
          const SizedBox(height: 6),

          // Row 1: Silhouettes
          Row(
            children: List.generate(5, (i) {
              return Expanded(
                child: Image.asset(
                  'lib/assets/bmi_d${i + 1}.png',
                  height: deviceWidth(context)>830? 150 :100,
                  // color: i == activeIndex ? Colors.black : Colors.grey[400],
                ),
              );
            }),
          ),
          const SizedBox(height: 6),

          // Row 2: Weight ranges
          Row(
            children: categories.map((c) {
              return Expanded(
                child: Container(
                  height: deviceWidth(context)> 830? 40:30,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: c['color'] as Color,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      c['range'] as String,
                      style:  TextStyle(color: Colors.white, fontSize: deviceWidth(context)> 830? 18:12,fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),

          // Row 3: Category labels
          Row(
            children: categories.map((c) {
              return Expanded(
                child: Container(
                  height: deviceWidth(context)> 830? 40:30,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: c['color'] as Color,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      c['label'] as String,
                      style:  TextStyle(color: Colors.white, fontSize: deviceWidth(context)> 830? 18:12,fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 1),

          // Row 4: Arrow indicator
          Row(
            children: List.generate(5, (i) {
              return Expanded(
                child: Center(
                  child: i == activeIndex
                      ? Icon(Icons.arrow_drop_up, color: msgColor, size: deviceWidth(context)>830?45:35) // Reduce size if needed
                      : const SizedBox(height: 20),
                ),
              );
            }),
          ),
          // <--- decrease spacing here also
          // Row 5: Message Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Image.asset(message),
          ),

        ],
      ),
    );
  }
}



