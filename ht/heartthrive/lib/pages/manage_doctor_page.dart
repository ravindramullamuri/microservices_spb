import 'package:flutter/material.dart';
import '../routes/app_router.dart';
import '../theme/app_theme.dart';

class ManageDoctorPage extends StatelessWidget {
  const ManageDoctorPage({Key? key}) : super(key: key);

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
          'Profile',
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
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Manage Doctor',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildMenuItem(
                    'Doctor\'s Email',
                    Icons.email,
                    () {
                      // Handle doctor's email tap
                    },
                  ),
                  _buildMenuItem(
                    'Hospital or Clinic Name',
                    Icons.local_hospital,
                    () {
                      // Handle hospital name tap
                    },
                  ),
                  _buildMenuItem(
                    'Hospital or Clinic City',
                    Icons.location_city,
                    () {
                      // Handle hospital city tap
                    },
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.white.withOpacity(0.6), // dark transparent mask
            alignment: Alignment.center,
            child: Container(
              height: 300,
              width: MediaQuery.of(context).size.width*0.9,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppTheme.primaryColor,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.construction,
                    color: Colors.white,
                    size: 60,
                  ),
                  SizedBox(height: 15),
                  Text(
                    "This feature is under construction",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

    );
  }

  Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.black26,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          color: Colors.grey.shade200,
        ),
      ],
    );
  }
}
