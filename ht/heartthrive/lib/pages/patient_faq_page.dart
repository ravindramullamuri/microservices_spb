import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import 'package:heart_thrive/pages/notification_badgeicon_widget.dart';
import '../theme/app_theme.dart';
import 'package:heart_thrive/providers/user/user_details_provider.dart';

class PatientFAQPage extends ConsumerStatefulWidget {
  const PatientFAQPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PatientFAQPage> createState() => _PatientFAQPageState();
}

class _PatientFAQPageState extends ConsumerState<PatientFAQPage> {
  int? expandedIndex;

  @override
  Widget build(BuildContext context) {
    final userDetailsAsync = ref.watch(userDetailsDataProvider);
    final user = userDetailsAsync.asData?.value;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppTheme.appBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24), // 👈 Adjust the roundness
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 15,top: 8,bottom: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6), // round shape
            child: user?.profileImage == null
                ? Image.asset(
              'lib/assets/default_profile_img.png',
              fit: BoxFit.cover,
              gaplessPlayback: true,
              width: 40,
              height: 40,
            )
                : Image.memory(
              base64Decode(user!.profileImage!),
              gaplessPlayback: true,
              fit: BoxFit.cover,
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.account_circle, color: Colors.white),
            ),
          ),
        ),
        title: const Center(
          child:  Text(
            'FAQ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: NotificationBadgeIcon(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 10),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            shadowColor: Colors.black26,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      // AppRouter.replaceWithHome(context);
                      Navigator.pop(context);
                    },
                    child: Image.asset("lib/assets/back_button.png", height: deviceWidth(context) > 750 ? 35 :25, width: deviceWidth(context) > 750 ? 35 :25,),
                  ),
                  SizedBox(height: 20),
                  ...patientFaqItems.asMap().entries.map((entry) {
                    int index = entry.key;
                    FAQItem item = entry.value;
                    return _buildFAQItem(item, index);
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(FAQItem item, int index) {
    bool isExpanded = expandedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(vertical: deviceWidth(context) > 750 ? 15 : 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300, // ✅ Light border instead of shadow
        ),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              '${index+1}) ${item.question}',
              style: TextStyle(
                fontSize: deviceWidth(context) > 750 ? 25 :16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.all(6), // controls the inner space around the icon
              decoration: BoxDecoration(
                color: AppTheme.primaryColor, // background color of the circle
                shape: BoxShape.circle,
              ),
              child: Icon(
                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.white, // icon color
                size: deviceWidth(context) > 750 ? 30 : 24,
              ),
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
                style: TextStyle(
                  fontSize: deviceWidth(context) > 750 ? 22 : 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static final List<FAQItem> patientFaqItems = [
    FAQItem(
      question: 'What is Heart Thrive?',
      answer:
      'Heart Thrive is a daily health companion app designed for people living with heart failure. It helps you track your weight, sodium intake, symptoms, and medications — and displays a simple “Risk Awareness Gauge” to show how your numbers are trending.',
    ),
    FAQItem(
      question: 'Who can use Heart Thrive?',
      answer:
      'Heart Thrive is intended for adults 18 years and older who have heart failure or want to better manage their heart health. It can be used by patients at home and by clinicians who monitor patient progress through the companion clinician portal.',
    ),
    FAQItem(
      question: 'What information does Heart Thrive collect?',
      answer:
      'The app collects only the information you enter, such as your daily weight, sodium intake, medication compliance, and symptom notes. Basic device data (like app performance and version) may also be collected to keep Heart Thrive running smoothly.',
    ),
    FAQItem(
      question: 'Is my health data secure?',
      answer:
      'Yes. All health data is encrypted and stored securely in compliance with HIPAA and GDPR standards. Your data is never sold or shared without your consent.',
    ),
    FAQItem(
      question: 'Can my clinician see my data?',
      answer:
      'Yes, but only if you choose to share it. You can securely connect with your clinician so they can view your trends and help manage your care more effectively. You can stop sharing at any time through the app settings.',
    ),
    FAQItem(
      question: 'How does the “Risk Awareness Gauge” work?',
      answer:
      'The Risk Awareness Gauge uses your daily entries — like weight changes, symptoms, and sodium intake — to calculate your personalized risk level. The meter gives you a visual cue based off your own actions, to assist in healthier choices',
    ),
    FAQItem(
      question: 'Does Heart Thrive replace my doctor?',
      answer:
      'No. Heart Thrive is a support tool, not a medical device or diagnostic app. It’s designed to help you and your healthcare team track and manage your condition, not replace professional care or medical advice.',
    ),
    FAQItem(
      question: 'Is there a cost to use heart Thrive?',
      answer:
      'TBD on pricing',
    ),
    FAQItem(
      question: 'Can I delete my account and data?',
      answer:
      'Yes. You can delete your account and all associated data at any time in the app settings. Once deleted, your data is permanently removed from our servers within 30 days.',
    ),
    FAQItem(
      question: 'Who do I contact for support?',
      answer:
      'You can reach the HeartThrive support team at support@heartthrivellc.com for technical help or account questions.',
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
