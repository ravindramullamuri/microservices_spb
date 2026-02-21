import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import 'package:heart_thrive/pages/notification_badgeicon_widget.dart';
import '../routes/app_router.dart';
import '../theme/app_theme.dart';
import 'package:heart_thrive/providers/user/user_details_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PatientTermsConditionsPage extends ConsumerStatefulWidget {
  const PatientTermsConditionsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PatientTermsConditionsPage> createState() => _PatientTermsConditionsPageState();

  static Widget _buildSectionRich(
      BuildContext context,
      String title,
      List<TextSpan> contentSpans,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: deviceWidth(context) > 750 ? 30 :16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),

        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: deviceWidth(context) > 750 ? 20 :14,
              color: Colors.black87,
              height: 1.5,
            ),
            children: contentSpans,
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }




  static Widget _buildSection(String title, String content, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:  TextStyle(
            fontSize: deviceWidth(context) > 750 ? 30 :16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: deviceWidth(context) > 750 ? 20 :14,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  static Widget _buildSection2Rich(
      BuildContext context,
      String title,
      String? content,
      List<List<TextSpan>> bulletSpans, {
        String? footerText,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: deviceWidth(context) > 750 ? 30 :16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),

        if (content?.isNotEmpty == true)
          Text(
            content!,
            style:  TextStyle(
              fontSize: deviceWidth(context) > 750 ? 20 :14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),

        const SizedBox(height: 6),

        // 🔹 Rich bullet points
        ...bulletSpans.map(
              (spans) => Padding(
            padding: const EdgeInsets.only(left: 22, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("• ", style: TextStyle(fontSize: deviceWidth(context) > 750 ? 20 :16, height: 1.5)),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: deviceWidth(context) > 750 ? 20 :14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                      children: spans,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 🔹 Footer text
        if (footerText != null && footerText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              footerText,
              style:  TextStyle(
                fontSize: deviceWidth(context) > 750 ? 20 :14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),

        const SizedBox(height: 20),
      ],
    );
  }


  static Widget _buildSection2(
      BuildContext context,
      String title,
      String? content,
      List<String> bulletPoints, {
        String? footerText, // 👈 non-bullet text
      })
  {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:  TextStyle(
            fontSize: deviceWidth(context) > 750 ? 30 :16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),

        if (content?.isNotEmpty == true)
          Text(
            content!,
            style: TextStyle(
              fontSize: deviceWidth(context) > 750 ? 20 :14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),

        const SizedBox(height: 6),

        // 🔹 Bulleted points
        ...bulletPoints.map(
              (point) => Padding(
            padding: const EdgeInsets.only(left: 22,bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("•", style: TextStyle(fontSize: deviceWidth(context) > 750 ? 20 :16, height: 1.5)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    point,
                    style:  TextStyle(
                      fontSize: deviceWidth(context) > 750 ? 20 :14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 🔹 Footer text (NO BULLET)
        if (footerText != null && footerText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              footerText,
              style:  TextStyle(
                fontSize:deviceWidth(context) > 750 ? 20 : 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),

        const SizedBox(height: 20),
      ],
    );
  }

  static Widget _buildSection6(String title, String content, BuildContext context) {
    // Split content by double line breaks
    final parts = content.split('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:  TextStyle(
            fontSize: deviceWidth(context) > 750 ? 30 :16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),

        RichText(
          text: TextSpan(
            style:  TextStyle(
              fontSize: deviceWidth(context) > 750 ? 20 : 14,
              color: Colors.black87,
              height: 1.5,
            ),
            children: [
              // Normal paragraphs
              for (int i = 0; i < parts.length; i++) ...[
                TextSpan(
                  text: parts[i],
                  style: TextStyle(
                    fontWeight:
                    i == parts.length - 1 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (i != parts.length - 1)
                  const TextSpan(text: '\n\n'),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}

class _PatientTermsConditionsPageState extends ConsumerState<PatientTermsConditionsPage> {
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
            'Terms & Conditions',
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
          padding: const EdgeInsets.all(16),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            shadowColor: Colors.black26,
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                  Text(
                    'Terms & Conditions (Terms of Use)',
                    style: TextStyle(
                      fontSize: deviceWidth(context) > 750 ? 30 :16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: October 24, 2025',
                    style: TextStyle(
                      fontSize: deviceWidth(context) > 750 ? 20 :14,
                      color: AppTheme.primaryColor, // softer grey instead of primary
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome to Heart Thrive (“we,” “our,” or “us”). These Terms & Conditions (“Terms”) govern your use of the Heart Thrive mobile application (the “App”) and related services. By downloading or using Heart Thrive, you agree to these Terms. If you do not agree, please stop using the App immediately.',
                    style: TextStyle(
                      fontSize: deviceWidth(context) > 750 ? 20 :14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  PatientTermsConditionsPage._buildSectionRich(
                    context,
                    '1. Eligibility',
                    [
                      const TextSpan(text: 'Heart Thrive is intended for individuals '),
                      const TextSpan(
                        text: '18 years of age or older',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text: '. By using the App, you confirm that you meet this requirement.',
                      ),
                    ],
                  ),


                  PatientTermsConditionsPage._buildSectionRich(
                    context,
                    '2. Purpose of the App',
                    [
                      const TextSpan(text: 'Heart Thrive is a '),
                      const TextSpan(
                        text: 'health support and tracking',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text:
                        ' tool designed for individuals with heart failure or those managing heart health.\n\n',
                      ),

                      const TextSpan(text: 'The App '),
                      const TextSpan(
                        text:
                        'does NOT provide medical advice and does NOT diagnose, treat, or cure medical conditions.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const TextSpan(
                        text:
                        '\n\nAll health decisions should be made in consultation with a qualified healthcare provider.',
                      ),
                    ],
                  ),

                  PatientTermsConditionsPage._buildSection2(
                    context,
                    '3. User Responsibilities',
                    'By using Heart Thrive, you agree to:',
                    [
                      'Provide accurate and truthful information when entering health data.',
                      'Use the App only for lawful purposes and not misuse or interfere with its functionality.',
                      'Understand that the App’s outputs (risk awareness gauge, insights, trends) are informational only.',
                      'Contact a medical professional if you experience symptoms, emergencies, or worsening conditions — the App does not monitor medical emergencies.',
                    ],
                  ),
                  PatientTermsConditionsPage._buildSection2(
                      context,
                      '4. Data Collection & Privacy',
                      'Your use of Heart Thrive is also governed by our Privacy Policy, which explains:',
                      [
                        'What data we collect',
                        'How the data is used',
                        'How data is stored and protected',
                        'When data may be shared (including optional clinician access)',
                      ],
                      footerText: 'By using the App, you agree to the practices described in our Privacy Policy.'
                  ),
                  PatientTermsConditionsPage._buildSection2(
                    context,
                    '5. Sharing Data With Clinicians ',
                    'If you choose to share your data with a clinician using the Heart Thrive Clinician Portal:',
                    [
                      'You grant us permission to securely transmit your selected health data to them.',
                      'Clinician access can be revoked by you at any time in the App settings.',
                      'We are not responsible for how clinicians use or interpret the data they receive. ',
                    ],
                  ),
                  PatientTermsConditionsPage._buildSection2Rich(
                    context,
                    '6. Not Medical Advice (Important Disclaimer)',
                    'You acknowledge and agree that:',
                    [
                      [
                        const TextSpan(text: 'Heart Thrive is '),
                        const TextSpan(
                          text: 'not a medical device.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                      [
                        const TextSpan(text: 'The App’s content, features, and feedback are for '),
                        const TextSpan(
                          text: 'educational and self-management purposes only.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                      [
                        const TextSpan(
                          text:
                          'The App should not be used to make medical decisions or replace professional healthcare.',
                        ),
                      ],
                      [
                        const TextSpan(
                          text:
                          'The App does not predict emergencies or health events and should not be relied upon for urgent situations.',
                        ),
                      ],
                    ],
                    footerText: 'Always consult your healthcare provider for medical questions.',
                  ),

                  PatientTermsConditionsPage._buildSection2(
                    context,
                    '7. Subscription & Payments',
                    'Some features of Heart Thrive may require a paid subscription or in-app purchase.',
                    [
                      'Prices and features are listed within the App Store.',
                      'Payments are processed through Apple’s in-app purchase system.',
                      'Subscriptions automatically renew unless canceled through your App Store settings.',
                    ],
                    footerText: 'We do not manage billing directly.',
                  ),
                  PatientTermsConditionsPage._buildSection(
                    '8. Intellectual Property',
                    'All content in the App — including logos, images, graphics, text, features, and software — '
                        'is the property of Heart Thrive or its licensors.\n\n'
                        'You may not copy, modify, distribute, reverse engineer, or reuse any part of the App '
                        'without written permission.',
                    context,
                  ),
                  PatientTermsConditionsPage._buildSection2(
                    context,
                    '9. Acceptable Use',
                    'You agree NOT to:',
                    [
                      'Attempt to hack, disrupt, or damage the App or its servers.',
                      'Upload harmful, illegal, or offensive content.',
                      'Use the App for commercial purposes without permission.',
                      'Attempt to access accounts or data that do not belong to you.',
                    ],
                    footerText:
                    'Violations may result in account suspension or termination.',
                  ),
                  PatientTermsConditionsPage._buildSection2(
                    context,
                    '10. Service Availability',
                    'We strive for reliable service, but we do not guarantee:',
                    [
                      'Uninterrupted access.',
                      'Error-free performance.',
                      'Perfect accuracy or real-time data processing.',
                    ],
                    footerText:
                    'We may update, pause, or discontinue features at any time.',
                  ),
                  PatientTermsConditionsPage._buildSection2(
                    context,
                    '11. Limitation of Liability',
                    'To the maximum extent permitted by law:',
                    [
                      'Heart Thrive is not liable for damages arising from use or inability to use the App.',
                      'We are not responsible for decisions made based on App data or insights.',
                      'We are not liable for the actions or interpretations of clinicians who access your data.',
                      'The App is provided “as is” and “as available.”',
                    ],
                    footerText:
                    'If you do not accept these limitations, you may not use the App.',
                  ),


                  PatientTermsConditionsPage._buildSection(
                    '12. Third-Party Services',
                    'Heart Thrive may link to or integrate with third-party services '
                        '(e.g., data storage providers, analytics systems). '
                        'We are not responsible for the policies or actions of third-party providers.',
                    context,
                  ),
                  PatientTermsConditionsPage._buildSection2(
                    context,
                    '13. Account Deletion & Data Removal',
                    'Users may delete their account at any time through the App.\n\n'
                        'Upon deletion:'
                    ,
                    [
                      'Your identifiable data will be removed from our servers within 30 days, except as required by law.',
                      'Revoked clinician access takes effect immediately.',
                    ],
                  ),
                  PatientTermsConditionsPage._buildSection(
                    '14. Changes to These Terms',
                    'We may update these Terms periodically. '
                        'The “Last Updated” date above indicates the most recent revision.\n\n'
                        'Continued use of the App after updates means you accept the revised Terms.',
                    context,
                  ),
                  PatientTermsConditionsPage._buildSection6(
                    '15. Contact Information',
                    'For questions about these Terms or our services, contact:\n\n'
                        'support@heartthrivellc.com',
                    context,
                  ),
                  Text(
                    'By using Heart Thrive, you confirm that you have read, understood, '
                        'and agree to these Terms & Conditions.',
                    style: TextStyle(
                      fontSize: deviceWidth(context) > 750 ? 20 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
