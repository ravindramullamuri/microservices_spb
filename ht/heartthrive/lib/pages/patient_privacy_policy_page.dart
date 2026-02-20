import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:heart_thrive/components/privacy_policy_widget.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import 'package:heart_thrive/pages/notification_badgeicon_widget.dart';
import '../routes/app_router.dart';
import '../theme/app_theme.dart';
import 'package:heart_thrive/providers/user/user_details_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PatientPrivacyPolicyPage extends ConsumerStatefulWidget {
  const PatientPrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PatientPrivacyPolicyPage> createState() => _PatientPrivacyPolicyPageState();


}

class _PatientPrivacyPolicyPageState extends ConsumerState<PatientPrivacyPolicyPage> {
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
            'Privacy Policy',
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
              padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      // AppRouter.replaceWithHome(context);
                      Navigator.pop(context);
                    },
                    child: Image.asset("lib/assets/back_button.png", height: deviceWidth(context) > 750 ? 35 :25, width:deviceWidth(context) > 750 ? 35 : 25,),
                  ),
                  SizedBox(height: 20),
                  Column(
                    children: [
                      PrivacyPolicyContent()
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
