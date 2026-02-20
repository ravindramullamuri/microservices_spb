import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/constants/heart_thrive_strings_constants.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import 'package:heart_thrive/pages/notification_badgeicon_widget.dart';
import 'package:heart_thrive/providers/user/user_details_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

class PatientContactUsPage extends ConsumerStatefulWidget {
  const PatientContactUsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PatientContactUsPage> createState() =>
      _PatientContactUsPageState();
}

class _PatientContactUsPageState extends ConsumerState<PatientContactUsPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userDetailsAsync = ref.watch(userDetailsDataProvider);
    final user = userDetailsAsync.asData?.value;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24), // 👈 Adjust the roundness
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 15, top: 8, bottom: 8),
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
          child: Text(
            'Contact Us',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      // AppRouter.replaceWithHome(context);
                      Navigator.pop(context);
                    },
                    child: Image.asset(
                      "lib/assets/back_button.png",
                      height: deviceWidth(context) > 750 ? 35 :25,
                      width: deviceWidth(context) > 750 ? 35 :25,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Email Us',
                    style: TextStyle(
                      fontSize: deviceWidth(context) > 750 ? 35 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: deviceWidth(context) > 750 ? 12 :8),
                  Text(
                    'Tell us about your problem',
                    style: TextStyle(
                      fontSize: deviceWidth(context) > 750 ? 25 :16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6F6C90),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Give us as much detail as you can',
                    style: TextStyle(fontSize: deviceWidth(context) > 750 ? 22 :14, color: Color(0xFF6F6C90)),
                  ),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: 'Type your message here...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: deviceWidth(context) > 750 ? 20 :16),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: deviceWidth(context) > 750 ? 60 :40,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        'Send Message',
                        style: TextStyle(
                          fontSize: deviceWidth(context) > 750 ? 25 :16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    margin: EdgeInsets.only(left: 5),
                    child: Text(
                      'Need More Help?',
                      style: TextStyle(
                        fontSize: deviceWidth(context) > 750 ? 22 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      clipBehavior: Clip.none,
                      width: MediaQuery.of(context).size.width * 0.9,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: deviceWidth(context) > 750 ? 50 :30,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF95020A).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Email us at:',
                              style: TextStyle(
                                fontSize: deviceWidth(context) > 750 ? 25 :16,
                                color: Color(0xFF95020A),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'support@heartthrivellc.com',
                              style: TextStyle(
                                fontSize: deviceWidth(context) > 750 ? 25 : 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF95020A),
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Support Hours:',
                              style: TextStyle(
                                fontSize: deviceWidth(context) > 750 ? 25 : 16,
                                color: Color(0xFF95020A),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Mon - Fri, 8:00 AM - 17:00 PM',
                              style: TextStyle(
                                fontSize: deviceWidth(context) > 750 ? 25 : 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF95020A),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  void _showSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                child: Image.asset('lib/assets/Check Mark.png'),
              ),
              const SizedBox(height: 16),
              Text(
                'Message sent to support@heartthrivellc.com',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6F6C90),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Successfully',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6F6C90),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 100,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('OK', style: AppTheme.whiteTitle14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    bool launched = await sendSupportEmail(_messageController.text);

    setState(() => _isLoading = false);

    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email app found. Unable to send.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Email app opened → now ask user to confirm
    //_showEmailConfirmationDialog();
    Navigator.pop(context); // close this dialog
    _messageController.clear();
    //_showSuccessModal(); // show your success popup
  }

  Future<bool> sendSupportEmail(String body) async {
    final String subject = Uri.encodeComponent('Support Request');
    final String encodedBody = Uri.encodeComponent(body);

    final Uri emailUri = Uri.parse(
      'mailto:${HeartThriveStrings.supportEmail}?subject=$subject&body=$encodedBody',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      return true;
    } else {
      return false;
    }
  }

  void _showEmailConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Email Sent"),
        content: const Text(
          "After sending the message in your email app, tap Confirm.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // close dialog
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // close this dialog
              _messageController.clear();
              _showSuccessModal(); // show your success popup
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}
