import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({Key? key}) : super(key: key);

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  int? expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'FAQ',
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
            children: [
              const SizedBox(height: 20),
              ...faqItems.asMap().entries.map((entry) {
                int index = entry.key;
                FAQItem item = entry.value;
                return _buildFAQItem(item, index);
              }).toList(),
            ],
          ),
        ),
      ),

    );
  }

  Widget _buildFAQItem(FAQItem item, int index) {
    bool isExpanded = expandedIndex == index;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          ListTile(
            title: Text(
              '$index) ${item.question}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.grey,
            ),
            onTap: () {
              setState(() {
                expandedIndex = isExpanded ? null : index;
              });
            },
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                item.answer,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static final List<FAQItem> faqItems = [
    FAQItem(
      question: '1) How does Heart Thrive help me monitor patients?',
      answer: 'Heart Thrive provides a real-time dashboard of connected patients showing key trends like sodium intake, BMI, and medication compliance. You\'ll also receive alerts for any critical changes.',
    ),
    FAQItem(
      question: '2) How do I see my patients?',
      answer: 'Navigate to the Patients tab in the bottom navigation to view all your connected patients. You can see their health metrics, send alerts, and monitor their progress.',
    ),
    FAQItem(
      question: '3) Can I search for a patient?',
      answer: 'Yes, you can use the search functionality in the Patients section to quickly find specific patients by name or other criteria.',
    ),
    FAQItem(
      question: '4) How do I know if a patient\'s health is getting worse?',
      answer: 'The app automatically analyzes patient data and sends you alerts when critical thresholds are exceeded. High-risk patients are highlighted on your dashboard.',
    ),
    FAQItem(
      question: '5) Is patient data private and secure?',
      answer: 'Yes, all patient data is encrypted and stored securely. We comply with HIPAA regulations and healthcare privacy standards to protect sensitive information.',
    ),
    FAQItem(
      question: '6) Is the app compliant with healthcare regulations?',
      answer: 'Yes, Heart Thrive is designed to meet healthcare compliance standards including HIPAA for data privacy and security in medical applications.',
    ),
  ];
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}
