import 'package:flutter/material.dart';
import '../routes/app_router.dart';
import '../theme/app_theme.dart';
import '../components/send_alert_popup.dart';

class PatientsListPage extends StatelessWidget {
  const PatientsListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
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
        child: Column(
          children: [
            // Page Title
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Patient\'s List',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            // Search Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search for a Patient',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune, color: AppTheme.primaryColor),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Patients List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: patients.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildPatientCard(context, patients[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              AppRouter.navigateToDoctorHome(context);
              break;
            case 1:
              AppRouter.navigateToPatientsList(context);
              break;
            case 2:
              AppRouter.navigateToDoctorEducation(context);
              break;
            case 3:
              AppRouter.navigateToDoctorRecipe(context);
              break;
            case 4:
              AppRouter.navigateToDoctorProfile(context);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Education',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Recipe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, Patient patient) {
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
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Image.asset(
                  patient.imagePath,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${patient.name} (${patient.gender}, ${patient.age} yrs)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patient.email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patient.condition,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    AppRouter.navigateToPatientDetails(
                      context,
                      patient.name,
                      patient.age.toString(),
                      patient.gender,
                      patient.imagePath,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,    // Already reduced vertically
                      horizontal: 3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _showSendAlertPopup(context, patient);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,    // Already reduced vertically
                      horizontal: 3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Send Alert'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSendAlertPopup(BuildContext context, Patient patient) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return SendAlertPopup(
          patientName: patient.name,
          patientGender: patient.gender,
          patientAge: patient.age,
          onCancel: () {
            Navigator.of(context).pop();
          },
          onSend: (String message) {
            Navigator.of(context).pop();
            // Handle send alert logic here
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Alert sent to ${patient.name}'),
                backgroundColor: Colors.green,
              ),
            );
          },
        );
      },
    );
  }

  static final List<Patient> patients = [
    Patient(
      name: 'John Smith',
      gender: 'Male',
      age: 52,
      email: 'johnsmith@gmail.com',
      condition: 'Last visit: Heart checkup on 15 Jan 24',
      imagePath: 'lib/assets/image (4).png',
    ),
    Patient(
      name: 'Emma Thomas',
      gender: 'Female',
      age: 45,
      email: 'emmathomas@gmail.com',
      condition: 'Last visit: Blood pressure check on 12 Jan 24',
      imagePath: 'lib/assets/image (5).png',
    ),
    Patient(
      name: 'David Kumar',
      gender: 'Male',
      age: 40,
      email: 'davidkumar@gmail.com',
      condition: 'Last visit: Heart checkup on 10 Jan 24',
      imagePath: 'lib/assets/image (6).png',
    ),
    Patient(
      name: 'Michael Rahman',
      gender: 'Male',
      age: 36,
      email: 'michaelrahman@gmail.com',
      condition: 'Last visit: Routine checkup on 8 Jan 24',
      imagePath: 'lib/assets/image (7).png',
    ),
  ];
}

class Patient {
  final String name;
  final String gender;
  final int age;
  final String email;
  final String condition;
  final String imagePath;

  Patient({
    required this.name,
    required this.gender,
    required this.age,
    required this.email,
    required this.condition,
    required this.imagePath,
  });
}
