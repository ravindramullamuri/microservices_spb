import 'package:flutter/material.dart';
import '../components/disconnect_confirmation_dialog.dart';
import '../theme/app_theme.dart';

class MyDoctorPage extends StatefulWidget {
  const MyDoctorPage({Key? key}) : super(key: key);

  @override
  State<MyDoctorPage> createState() => _MyDoctorPageState();
}

class _MyDoctorPageState extends State<MyDoctorPage> {
  bool isConnected = true;
  Map<int, bool> expandedCards = {}; // Track expanded state for each card

  void _showDisconnectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return DisconnectConfirmationDialog(
          doctorName: 'Dr. James Howard',
          onCancel: () {
            Navigator.of(context).pop();
          },
          onConfirm: () {
            setState(() {
              isConnected = false;
            });
            Navigator.of(context).pop();
            // Show success message or navigate to another page
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Successfully disconnected from Dr. James Howard'),
                backgroundColor: Colors.green,
              ),
            );
          },
        );
      },
    );
  }

  void _toggleCardExpansion(int cardIndex) {
    setState(() {
      expandedCards[cardIndex] = !(expandedCards[cardIndex] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB71C1C),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    children: [
                      // Profile Avatar
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'lib/assets/image (2).png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Profile Text
                      const Expanded(
                        child: Text(
                          'Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Notification Icons
                      Container(
                        width: 35,
                        height: 35,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFFB71C1C),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 35,
                        height: 35,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications,
                          color: Color(0xFFB71C1C),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // My Doctor Title
                        const Text(
                          'My Clinician',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Doctor Profile Card
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Doctor Avatar
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'lib/assets/Doctor-Img.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              // Doctor Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Dr. James Howard',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        if (isConnected)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Text(
                                              'Connected',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    const Text(
                                      'james.howard@gmail.com',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    if (isConnected)
                                      SizedBox(
                                        width: 100,
                                        height: 30,
                                        child: ElevatedButton(
                                          onPressed: _showDisconnectDialog,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFB71C1C),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: const Text(
                                            'Disconnect',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      SizedBox(
                                        width: 100,
                                        height: 30,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              isConnected = true;
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: const Text(
                                            'Connect',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Doctor Advice Section
                        const Text(
                          'Clinician advice',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Date Range Selector
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  // Handle previous date range
                                },
                                child: const Icon(
                                  Icons.chevron_left,
                                  color: Colors.grey,
                                ),
                              ),
                              Column(
                                children: [
                                  const Text(
                                    'Custom View',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const Text(
                                    'May 20 - July 25',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  // Handle next date range
                                },
                                child: const Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Advice Cards
                        Expanded(
                          child: ListView(
                            children: [
                              _buildAdviceCard(
                                0,
                                'May 31, 2020  10:28 AM',
                                'Health Risk Alert',
                                'Sodium intake exceeds limits. Irregular meals noted. Risk of BP elevation. It is recommended to reduce sodium intake to less than 2300mg per day and maintain regular meal times to prevent blood pressure spikes.',
                              ),
                              const SizedBox(height: 15),
                              _buildAdviceCard(
                                1,
                                'May 31, 2020  10:30 AM',
                                'Health Risk Alert',
                                'Sodium intake exceeds limits. Irregular meals noted. Risk of BP elevation. Please monitor your daily sodium consumption and try to eat at consistent times throughout the day.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
      ),
    );
  }

  Widget _buildAdviceCard(int cardIndex, String date, String title, String description) {
    bool isExpanded = expandedCards[cardIndex] ?? false;
    String displayText = description;

    // Truncate text if not expanded (show first 60 characters)
    if (!isExpanded && description.length > 60) {
      displayText = '${description.substring(0, 60)}...';
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB71C1C), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Doctor Avatar
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'lib/assets/Doctor-Img.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dr. Howard',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _toggleCardExpansion(cardIndex),
                child: Text(
                  isExpanded ? 'See less' : 'See more',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB71C1C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                height: 30,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle download report
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Downloading report...'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'Download Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
