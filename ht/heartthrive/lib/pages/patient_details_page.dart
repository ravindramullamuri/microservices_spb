import 'package:flutter/material.dart';
import '../routes/app_router.dart';
import '../theme/app_theme.dart';

class PatientDetailsPage extends StatefulWidget {
  final String patientName;
  final String patientAge;
  final String patientGender;
  final String patientImage;

  const PatientDetailsPage({
    Key? key,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.patientImage,
  }) : super(key: key);

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  bool _showSodiumDetails = false;
  bool _showMedicationDetails = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'lib/assets/image (2).png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Hi, Ethan! 👋',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Good Evening!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Patient Info Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.asset(
                        widget.patientImage,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${widget.patientName} (${widget.patientGender}, ${widget.patientAge} yrs)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Heart Risk Metrics Card
              _buildHeartRiskCard(context),
              
              const SizedBox(height: 16),
              
              // Sodium Card
              _buildSodiumCard(context),
              
              const SizedBox(height: 16),
              
              // Medication Card
              _buildMedicationCard(context),
              
              const SizedBox(height: 16),
              
              // Weight & BMI Card
              _buildWeightBMICard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardButton({required VoidCallback onPressed}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white),
        foregroundColor: AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon without border
          Image.asset(
            'lib/assets/dash.png',
            width: 14,
            height: 14,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 6),
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRiskCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Heart Risk Metrics',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              _buildDashboardButton(
                onPressed: () {
                  AppRouter.navigateToPatientDetailsRiskMetricDashboard(
                    context,
                    widget.patientName,
                    widget.patientAge,
                    widget.patientGender,
                    widget.patientImage,
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              // Risk Chart
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'lib/assets/Meter Base.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    ),

                  ],
                ),
              ),

              const SizedBox(width: 20),
              
              // Risk Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRiskLegendItem('1-2 (Very Low)', Colors.green),
                    _buildRiskLegendItem('3-4 (Low)', Colors.yellow.shade700),
                    _buildRiskLegendItem('5-6 (Moderate)', Colors.orange),
                    _buildRiskLegendItem('7-8 (High)', Colors.red),
                    _buildRiskLegendItem('9 (Critical)', Colors.red.shade800),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Risk of developing symptoms:\nVery Low',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskLegendItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSodiumCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sodium (in mg)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('800 mg\nConsumed', style: TextStyle(fontSize: 11, color: Colors.black54)),
              Text('1700 mg Left', style: TextStyle(fontSize: 11, color: Colors.black54)),
              Text('2500 mg', style: TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
          
          const SizedBox(height: 8),
          
          LinearProgressIndicator(
            value: 0.32, // 800/2500
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            minHeight: 8,
          ),
          
          // Expandable Details Section
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _showSodiumDetails 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: _buildSodiumDetails(),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _showSodiumDetails = !_showSodiumDetails;
                  });
                },
                child: Text(
                  _showSodiumDetails ? 'Less Info' : 'More Info', 
                  style: const TextStyle(color: AppTheme.primaryColor)
                ),
              ),
              const Spacer(),
              _buildDashboardButton(
                onPressed: () {
                  AppRouter.navigateToPatientDetailsSodiumDashboard(
                    context,
                    widget.patientName,
                    widget.patientAge,
                    widget.patientGender,
                    widget.patientImage,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSodiumDetails() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          // Meal breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMealColumn('Breakfast', '200 mg', '500 mg', Colors.orange),
              _buildMealColumn('Lunch', '300 mg', '500 mg', Colors.blue),
              _buildMealColumn('Snacks', '100 mg', '400 mg', Colors.purple),
              _buildMealColumn('Dinner', '200 mg', '700 mg', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealColumn(String meal, String consumed, String limit, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
          child: Center(
            child: Text(
              consumed,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          meal,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Text(
          limit,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Medication',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('4 Target', style: TextStyle(fontSize: 11, color: Colors.black54)),
              Text('2 Missed Doses', style: TextStyle(fontSize: 11, color: Colors.black54)),
              Text('Doses Left', style: TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
          
          const SizedBox(height: 8),
          
          LinearProgressIndicator(
            value: 0.5, // 2/4 missed
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
            minHeight: 8,
          ),
          
          const SizedBox(height: 16),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.yellow.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.yellow.shade300),
            ),
            child: const Text(
              'Next Doses: 8:00 pm Aspirin',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Expandable Details Section
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _showMedicationDetails 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: _buildMedicationDetails(),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _showMedicationDetails = !_showMedicationDetails;
                  });
                },
                child: Text(
                  _showMedicationDetails ? 'Less Info' : 'More Info', 
                  style: const TextStyle(color: AppTheme.primaryColor)
                ),
              ),
              const Spacer(),
              _buildDashboardButton(
                onPressed: () {
                  AppRouter.navigateToPatientDetailsMedicationDashboard(
                    context,
                    widget.patientName,
                    widget.patientAge,
                    widget.patientGender,
                    widget.patientImage,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationDetails() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's Schedule Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Today\'s Schedule',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Next Doses',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Schedule List
          Column(
            children: [
              _buildMedicationScheduleItem('08:00 am', 'Vitamin D', true),
              _buildMedicationScheduleItem('13:00 pm', 'Ibuprofen', true),
              _buildMedicationScheduleItem('19:00 pm', 'Aspirin', false),
              _buildMedicationScheduleItem('21:00 pm', 'Aspirin', false),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Next Doses and Missed Doses
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Next Doses',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '13:00 pm - Ibuprofen',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Missed Doses',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '08:00 am - Vitamin D',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                      ),
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

  Widget _buildMedicationScheduleItem(String time, String medication, bool taken) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: taken ? Colors.green : Colors.grey.shade300,
            ),
            child: taken 
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : const Icon(Icons.close, color: Colors.red, size: 14),
          ),
          const SizedBox(width: 12),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            medication,
            style: TextStyle(
              fontSize: 12,
              color: taken ? Colors.black54 : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightBMICard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weight & Body Mass Index',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              _buildDashboardButton(
                onPressed: () {
                  AppRouter.navigateToPatientDetailsBMIDashboard(
                    context,
                    widget.patientName,
                    widget.patientAge,
                    widget.patientGender,
                    widget.patientImage,
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '200 lbs',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Current Weight',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Row(
                    children: const [
                      Text(
                        '1.2 lbs ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Icon(Icons.arrow_upward, color: Colors.red, size: 16),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Text(
                        '3.6 lbs ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Icon(Icons.arrow_downward, color: Colors.green, size: 16),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    '24.9',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    'Normal',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
