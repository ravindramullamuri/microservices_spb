import 'package:flutter/material.dart';
import '../routes/app_router.dart';
import '../theme/app_theme.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Terms & Conditions - Heart Thrive',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Effective Date: 21/07/2025',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'By using Heart Thrive, you agree to the following terms and conditions for healthcare professionals:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              _buildSection(
                '1. Purpose Of Use',
                'Heart Thrive is designed to assist healthcare professionals in monitoring patients\' health data, including sodium intake, BMI, and medication adherence, with patient consent. It is not a replacement for clinical judgment or direct medical intervention.',
              ),
              _buildSection(
                '2. Professional Responsibility',
                'Doctors must use the app responsibly and in accordance with all applicable healthcare regulations and ethical standards.\n\n'
                'All patient data and interpretations of health data must comply with your medical training and best practices.',
              ),
              _buildSection(
                '3. Data Privacy And Access',
                'Access to patient information is granted only with explicit patient consent.\n\n'
                'You must handle all patient data with strict confidentiality and ensure it is not shared through the app.\n\n'
                'Doctors must handle patient data with strict confidentiality and ensure it is not shared or disclosed to unauthorized parties.',
              ),
              _buildSection(
                '4. Account Use And Termination',
                'Doctors are responsible for maintaining the integrity of their account.\n\n'
                'We reserve the right to terminate accounts that violate these terms.',
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
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

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
