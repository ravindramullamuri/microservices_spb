import 'package:flutter/material.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import 'package:heart_thrive/theme/app_theme.dart';

class PrivacyPolicyContent extends StatelessWidget {
  const PrivacyPolicyContent({super.key});

  static Widget _buildSection2Rich(
      BuildContext context,
      String title,
      List<TextSpan>? contentSpans, // 👈 rich content line
      List<List<TextSpan>> bulletSpans, {
        List<TextSpan>? footerSpans, // 👈 rich footer
      }) {
    final baseTextStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontSize: deviceWidth(context) > 750 ? 20 : 14,
      color: Colors.black87,
      height: 1.5,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 Title
        Text(
          title,
          style: TextStyle(
            fontSize: deviceWidth(context) > 750 ? 30 : 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),

        // 🔹 Rich content line (partial bold support)
        if (contentSpans != null)
          RichText(
            text: TextSpan(style: baseTextStyle, children: contentSpans),
          ),

        if (contentSpans != null) const SizedBox(height: 6),

        // 🔹 Rich bullet points
        ...bulletSpans.map(
              (spans) => Padding(
            padding: const EdgeInsets.only(left: 22, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("• ", style: TextStyle(fontSize:deviceWidth(context) > 750 ? 20 : 16, height: 1.5)),
                Expanded(
                  child: RichText(
                    text: TextSpan(style: baseTextStyle, children: spans),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 🔹 Rich footer text (no bullet, left aligned)
        if (footerSpans != null) ...[
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(style: baseTextStyle, children: footerSpans),
          ),
        ],

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionAge(BuildContext context, String title) {
    final baseStyle = DefaultTextStyle.of(
      context,
    ).style.copyWith(fontSize: deviceWidth(context) > 750 ? 20 :14, color: Colors.black87, height: 1.5);

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
            style: baseStyle,
            children: const [
              TextSpan(text: 'Heart Thrive is intended for adults '),
              TextSpan(
                text: '18 years of age and older.\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                'We do not knowingly collect or process personal data from individuals under 18. '
                    'If you are under 18, please do not use this App or provide any personal information.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  static Widget buildSection(String title, String content, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: deviceWidth(context) > 750 ? 30 : 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor, // brand color
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: deviceWidth(context) > 750 ? 20 : 14,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  static Widget buildSection2(
      BuildContext context,
      String title,
      String? content,
      List<String> bulletPoints, {
        String? footerText, // 👈 non-bullet text
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
              fontSize:deviceWidth(context) > 750 ? 20 : 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),

        const SizedBox(height: 6),

        // 🔹 Bulleted points
        ...bulletPoints.map(
              (point) => Padding(
            padding: const EdgeInsets.only(left: 22, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("•", style: TextStyle(fontSize: deviceWidth(context) > 750 ? 20 : 16, height: 1.5)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    point,
                    style: TextStyle(
                      fontSize: deviceWidth(context) > 750 ? 20 : 14,
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
              style: TextStyle(
                fontSize: deviceWidth(context) > 750 ? 20 : 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),

        const SizedBox(height: 20),
      ],
    );
  }

  static Widget buildSection3(
      String title,
      String? content,
      String content2,
      String content3,
      BuildContext context
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: deviceWidth(context) > 750 ? 30 :16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor, // brand color
          ),
        ),
        const SizedBox(height: 8),
        content?.isNotEmpty == true
            ? Text(
          content ?? '',
          style: TextStyle(
            fontSize:deviceWidth(context) > 750 ? 20 : 14,
            color: Colors.black87,
            height: 1.5,
          ),
        )
            : SizedBox(),
        Text(
          content2,
          style: TextStyle(
            fontSize:deviceWidth(context) > 750 ? 20 : 14,
            color: Colors.black,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
        ),
        Text(
          content3,
          style: TextStyle(
            fontSize:deviceWidth(context) > 750 ? 20 : 14,
            color: Colors.black87,
            height: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  static Widget buildSection4(
      BuildContext context,
      String title,
      String? content,
      String content2,
      String content3,
      String content4,
      String content5,
      String content6,
      String content7,
      String content8,
      ) {
    Widget buildRichText(String text) {
      if (text.trim().isEmpty) return const SizedBox();

      final regex = RegExp(r'^•\s*([^:]+:)(.*)$');
      final match = regex.firstMatch(text.trim());

      if (match != null) {
        final boldPart = match.group(1)!; // e.g., "Access:"
        final normalPart = match.group(2)!; // e.g., " Request a copy..."

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: TextStyle(
                  fontSize: deviceWidth(context) > 750 ? 20 :14,
                  color: Colors.black,
                  height: 1.5,
                ),
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style:  TextStyle(
                      fontSize: deviceWidth(context) > 750 ? 20 :14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(
                        text: boldPart.trim(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: normalPart),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            text,
            style: TextStyle(
              fontSize:deviceWidth(context) > 750 ? 20 : 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          title,
          style: TextStyle(
            fontSize: deviceWidth(context) > 750 ? 30 :16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF95020A), // Same red as in screenshot
          ),
        ),
        const SizedBox(height: 8),

        // Introductory paragraph
        if (content?.isNotEmpty == true)
          Text(
            content!,
            style: TextStyle(
              fontSize:deviceWidth(context) > 750 ? 20 : 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),

        const SizedBox(height: 8),

        // Bullet list
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildRichText(content2),
              buildRichText(content3),
              buildRichText(content4),
              buildRichText(content5),
              buildRichText(content6),
              buildRichText(content7),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Footer bold line
        RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(
              context,
            ).style.copyWith(fontSize:deviceWidth(context) > 750 ? 20 : 14, color: Colors.black87, height: 1.5),
            children: const [
              TextSpan(text: 'To exercise these rights, contact us\n at '),
              TextSpan(
                text: 'support@heartthrivellc.com',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  static Widget buildSection5(
      BuildContext context,
      String title,
      String content,
      String content2,
      ) {
    Widget buildRichText(BuildContext context, String text) {
      final lines = text
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      final baseStyle = DefaultTextStyle.of(
        context,
      ).style.copyWith(fontSize:deviceWidth(context) > 750 ? 20 : 14, color: Colors.black87, height: 1.5);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) {
          final regex = RegExp(r'^•\s*([^:]+:)(.*)$');
          final match = regex.firstMatch(line.trim());

          if (match != null) {
            final boldPart = match.group(1)!;
            final normalPart = match.group(2)!;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("• ", style: baseStyle.copyWith(fontSize: deviceWidth(context) > 750 ? 20 : 16)),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: baseStyle,
                        children: [
                          TextSpan(
                            text: boldPart.trim(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: normalPart),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Normal (non-bullet) line
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(line, style: baseStyle),
          );
        }).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize:deviceWidth(context) > 750 ? 30 : 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF95020A),
          ),
        ),
        const SizedBox(height: 8),

        /// 🔹 UPDATED PART (bold GDPR only)
        RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(
              context,
            ).style.copyWith(fontSize:deviceWidth(context) > 750 ? 20 : 14, color: Colors.black87, height: 1.5),
            children: const [
              TextSpan(text: 'Under the '),
              TextSpan(
                text: 'General Data Protection Regulation (GDPR),',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                ' the legal basis for collecting and processing your information includes:\n',
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: buildRichText(context, content2),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  static Widget buildSubSection(
      BuildContext context,
      String title, {
        List<String>? bulletPoints,
        String? paragraph,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize:deviceWidth(context) > 750 ? 20 : 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),

        // 🔹 Bullet points
        if (bulletPoints != null)
          ...bulletPoints.map(
                (point) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("•", style: TextStyle(fontSize:deviceWidth(context) > 750 ? 20 : 16, height: 1.5)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        fontSize:deviceWidth(context) > 750 ? 20 : 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 🔹 Non-bullet paragraph
        if (paragraph != null && paragraph.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 22, top: 4),
            child: Text(
              paragraph,
              style: TextStyle(
                fontSize: deviceWidth(context) > 750 ? 20 : 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),

        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy Policy - Heart Thrive',
          style: TextStyle(
            fontSize:deviceWidth(context) > 750 ? 30 : 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor, // brand color
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Last updated: October 24, 2025',
          style: TextStyle(fontSize:deviceWidth(context) > 750 ? 20 : 14, color: AppTheme.primaryColor),
        ),
        const SizedBox(height: 20),
        Text(
          'Thank you for choosing Heart Thrive. Your privacy is very important to us. This Privacy Policy explains how we collect, use, store, and share your information when you use the Heart Thrive mobile application (the “App”) and related services.',
          style: TextStyle(fontSize: deviceWidth(context) > 750 ? 20 :14, color: Colors.black87, height: 1.5),
        ),
        Text(
          'By using Heart Thrive, you agree to the terms outlined in this policy. If you do not agree, please discontinue use of the App.',
          style: TextStyle(fontSize:deviceWidth(context) > 750 ? 20 : 14, color: Colors.black87, height: 1.5),
        ),
        const SizedBox(height: 20),
        buildSection(
          '1. Information We Collect',
          'Heart Thrive collects the following types of information:',
          context,
        ),
        buildSubSection(
          context,
          'A. Personal Information (Entered By You):',
          bulletPoints: [
            'Name, age, gender, and contact information (if you create an account).',
            'Health-related inputs such as weight, daily sodium intake, medication adherence, and symptoms.',
            'Optional notes or journal entries related to your condition.',
          ],
        ),

        buildSubSection(
          context,
          'B. Automatically Collected Information:',
          bulletPoints: [
            'Device information (model, operating system, unique device identifiers).',
            'Usage data (frequency of use, app performance, crash logs).',
          ],
        ),

        buildSubSection(
          context,
          'C. Clinician Data (Optional):',
          bulletPoints: [
            'If you consent, your inputted health data may be shared securely with clinicians who use Heart, Thrive for the assistance in your condition.',
          ],
        ),

        _buildSection2Rich(
          context,
          '2. Purpose of Data Use',
          const [TextSpan(text: 'We collect and use your data to:')],
          [
            [
              TextSpan(
                text:
                'Provide personalized insights and track your health metrics.',
              ),
            ],
            [
              TextSpan(
                text:
                'Generate risk scores and trend reports to help you manage heart failure.',
              ),
            ],
            [
              TextSpan(
                text:
                'Allow your clinician (if you consent) to view your data for monitoring and assisting with the optimization of your condition.',
              ),
            ],
            [
              TextSpan(
                text:
                'Improve the performance, features, and user experience of the App.',
              ),
            ],
            [
              TextSpan(
                text:
                'Comply with applicable legal and regulatory obligations.',
              ),
            ],
          ],
          footerSpans: const [
            TextSpan(text: 'We '),
            TextSpan(
              text: 'do not sell, rent, or share',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: ' your data with third parties for advertising purposes.',
            ),
          ],
        ),

        _buildSection2Rich(
          context,
          '3. Data Sharing and Consent',
          const [
            TextSpan(text: 'Data is shared '),
            TextSpan(
              text: 'only with your explicit consent:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
          [
            [
              const TextSpan(
                text:
                'You may choose to link your data with a clinician using the Heart Thrive Clinician Portal.',
              ),
            ],
            [
              const TextSpan(
                text:
                'Data is transmitted using industry-standard encryption and stored in a HIPAA-compliant manner.',
              ),
            ],
            [
              const TextSpan(
                text:
                'You may withdraw consent for clinician access at any time via your in-app settings.',
              ),
            ],
          ],
          footerSpans: const [
            TextSpan(
              text:
              'Without your consent, no identifiable health data is shared externally.',
              style: TextStyle(color: Colors.black87),
            ),
          ],
        ),

        buildSection5(
          context,
          '4. Legal Basis for Processing (GDPR Compliance)',
          'Under the General Data Protection Regulation (GDPR), the legal basis for collecting and processing your information includes:\n',
          '• Consent: You have given clear consent for processing your personal and health data.\n\n'
              '• Contractual necessity: Data is processed to deliver the services you request through the App.\n\n'
              '• Legitimate interests: To improve our product and ensure app security and functionality.\n\n'
              '• Legal obligations: To comply with applicable laws and data protection regulations.',
        ),
        _buildSectionAge(context, '5. Age Requirement'),
        buildSection2(context,
            '6. Data Storage and Security', null, [
              'All personal and health data are encrypted during transmission and storage.',
              'Data is stored securely on HIPAA- and GDPR-compliant servers.',
              'We implement administrative, physical, and technical safeguards to prevent unauthorized access, loss, or misuse.',
            ]),
        buildSection4(
          context,
          '7. User Rights',
          'Depending on your location, you may have the following rights regarding your data:\n',
          '• Access: Request a copy of the data we hold about you.\n\n',
          '• Correction: Request correction of inaccurate or incomplete data.\n\n',
          '• Deletion: Request deletion of your data (“right to be forgotten”).\n\n',
          '• Restriction: Request restriction of how we process your data.\n\n',
          '• Portability: Request a copy of your data in a structured, machine-readable format.\n\n',
          '• Withdraw Consent: You may withdraw consent at any time without affecting prior lawful processing.\n\n',
          'To exercise these rights, contact us at support@heartthrivellc.com',
        ),

        buildSection(
          '8. Data Retention',
          'We retain your data only as long as necessary for the purposes described above or as required by law.\n\n'
              'If you delete your account, your identifiable information will be permanently removed within 30 days, except as legally required.',
          context,
        ),
        buildSection(
          '9. International Data Transfers',
          'If you are located outside the United States, your information may be transferred to and processed in the United States or other jurisdictions that may not provide the same level of protection. We take appropriate safeguards to ensure your data remains protected under applicable laws.',
          context,
        ),
        buildSection(
          '10. Updates to This Policy',
          'We may update this Privacy Policy periodically. The “Last updated” date will reflect the most recent revision.\n\n'
              'We encourage you to review this page regularly. Continued use of the App constitutes acceptance of any changes.',
          context,
        ),
        buildSection3(
          '11. Contact Us',
          'If you have questions or concerns about this Privacy Policy or our data practices, please contact:\n',
          'Heart Thrive Privacy Team Email: support@heartthrivellc.com Address: 2720 steeplechase road\n'
              'Gastonia NX 28056\n',
          'By using Heart Thrive, you acknowledge that you have read and understood this Privacy Policy and consent to the processing of your information as described.',
          context,
        ),
      ],
    );
  }
}
