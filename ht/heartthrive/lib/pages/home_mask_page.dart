import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/custom_button.dart';
import '../components/profile_image_uploader.dart';
import '../providers/user/user_details_provider.dart';
import '../routes/app_router.dart';
import '../theme/app_theme.dart';
import '../services/user_service.dart';
import '../utils/date_utils.dart';

class HomeMaskPage extends ConsumerStatefulWidget {
  const HomeMaskPage({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeMaskPage> createState() => _HomeMaskPageState();
}

class _HomeMaskPageState extends ConsumerState<HomeMaskPage> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userDetailsDataProvider);
    return PopScope(
      canPop: false, // prevent default back navigation

      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: SizedBox(),
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          title: const Text('Heart Thrive'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {},
            ),
          ],
        ),
        body: userAsync.when(
            data: (user){
              if(user == null){
      
              }
              return  Stack(
                children: [
                  // Background content (Home page content)
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User greeting section
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: user?.profileImage == null? Image.asset(
                                  'lib/assets/image (2).png',
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                ):Image.memory(
                                  base64Decode(user!.profileImage!),
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_circle)
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hi, ${user?.firstname} ${user?.lastname}!',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Good  ${DateFormatUtil.getTimePeriod()}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
      
                          const SizedBox(height: 16),
      
                          // Good job section
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Good job!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Your heart risk is very low. Keep up the healthy lifestyle!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
      
                          const SizedBox(height: 16),
      
                          // Today's Heart Risk Metrics
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Today\'s Heart Risk Metrics',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Row(
                                children: [
                                  Image.asset(
                                    'lib/assets/Laptop Metrics.png',
                                    width: 16,
                                    height: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Dashboard',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
      
                          const SizedBox(height: 16),
      
                          // Risk meter
                          Center(
                            child: Image.asset(
                              'lib/assets/Meter Base.png',
                              height: 120,
                              fit: BoxFit.contain,
                            ),
                          ),
      
                          const SizedBox(height: 8),
      
                          // Risk legend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildRiskLegendItem('1-2 (Very Low)', Colors.green),
                              const SizedBox(width: 8),
                              _buildRiskLegendItem('3-4 (Low)', Colors.lightGreen),
                              const SizedBox(width: 8),
                              _buildRiskLegendItem('5-6 (Moderate)', Colors.amber),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildRiskLegendItem('7-8 (High)', Colors.orange),
                              const SizedBox(width: 8),
                              _buildRiskLegendItem('9-10 (Critical)', Colors.red),
                            ],
                          ),
      
                          const SizedBox(height: 16),
      
                          // Medication section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Medication',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Row(
                                children: const [
                                  Text(
                                    'Add New',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  Icon(
                                    Icons.add_circle,
                                    color: AppTheme.primaryColor,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ],
                          ),
      
                          const SizedBox(height: 8),
      
                          // Medication progress
                          Row(
                            children: [
                              const Text(
                                'Consumed:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '1',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                '6 Target',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
      
                          const SizedBox(height: 4),
      
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: 1/6,
                              backgroundColor: Colors.grey.shade200,
                              color: AppTheme.primaryColor,
                              minHeight: 8,
                            ),
                          ),
      
                          const SizedBox(height: 8),
      
                          // Missed doses
                          Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '2 Missed Doses',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.amber,
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                'Doses Left',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
      
                          const SizedBox(height: 16),
      
                          // Next dose
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'Next Dose: 8:00 pm-Aspirin',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
      
                          const SizedBox(height: 100), // Space for the overlay
                        ],
                      ),
                    ),
                  ),
      
                  // Overlay mask
                /*  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Welcome to HeartThrive!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Complete your profile to help doctors recognize you better — upload a photo.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    text: 'Skip Now',
                                    isOutlined: true,
                                    onPressed: () {
                                      // Navigate to home page without mask
                                      AppRouter.navigateToHome(context);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
      
                                Expanded(
                                  child: CustomButton(
                                    text: 'Upload Profile Photo',
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.transparent,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                        ),
                                        builder: (context) => Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                          ),
                                          height: 300,
                                          child: Column(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 4,
                                                margin: const EdgeInsets.only(bottom: 12),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[400],
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                              const Expanded(
                                                child: ProfileImageUploader(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
      
      
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),*/
                ],
              );
            },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text("Error: $err")),),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: 0,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            onTap: (index) {
              switch (index) {
                case 0:
                // Already on home page
                  break;
                case 1:
                  // AppRouter.navigateToEducation(context);
                  break;
                case 2:
                // Show quick navigation popup
                    // Handle add action
                  break;
                case 3:
                  // AppRouter.navigateToRecipe(context);
                  break;
                case 4:
                  AppRouter.navigateToProfile(context);
                  break;
              }
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.school),
                label: 'Education',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  decoration: const BoxDecoration(
                  ),
                  child: Image.asset(
                    'lib/assets/Add.png', // Adjust path if needed
                    width: 50,
                    height: 50,
      
                  ),
                ),
                label: '',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_menu),
                label: 'Recipe',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
