import 'package:flutter/material.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import '../components/user_type_card.dart';
import '../routes/app_router.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Image.asset('lib/assets/ht_bg.jpg',
            fit: BoxFit.fill,
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,),
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button
                    GestureDetector(
                      onTap: () => AppRouter.replaceWithLanding(context),
                      child: Image.asset(
                        'lib/assets/back_button.png', // ✅ your back button image
                        width: deviceWidth(context) > 750 ? 40:30, // adjust size
                        height: deviceWidth(context) > 750 ? 40:30,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 90),

                    // Title
                    Center(
                      child: Text(
                        'Register ',
                        style: GoogleFonts.poppins(
                          fontSize: deviceWidth(context) > 750 ? 45: deviceWidth(context) > 360? 32:20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Center(
                      child: Text(
                        'Who you are?',
                        style: TextStyle(
                            fontSize: deviceWidth(context) > 750 ? 25:deviceWidth(context) > 360? 18 :14,
                            color: Colors.black54,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // User Type Cards
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Doctor Card
                        Expanded(
                          child: UserTypeCard(
                            title: 'I\'m a Clinician',
                            imagePath: 'lib/assets/Doctor-Img.png',
                            onTap: () {
                              final messenger = ScaffoldMessenger.of(context);

                              messenger
                                ..hideCurrentMaterialBanner()
                                ..showMaterialBanner(
                                  MaterialBanner(
                                    content: const Text(
                                      'This feature is under construction.',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: AppTheme.primaryColor,
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          messenger.hideCurrentMaterialBanner();
                                        },
                                        child: const Text(
                                          'DISMISS',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                              // 🔥 Auto dismiss after 4 seconds
                              Future.delayed(const Duration(seconds: 5), () {
                                messenger.hideCurrentMaterialBanner();
                              });
                            },

                          ),
                        ),
                        const SizedBox(width: 10),
                        // Patient Card
                        Expanded(
                          child: UserTypeCard(
                            title: 'I\'m a Patient',
                            imagePath: 'lib/assets/Patient-Img.png',
                            onTap: () {
                              AppRouter.replaceWithPersonalInfo(context, 'patient');
                            },
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 14,),
                    // Sign In Link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: deviceWidth(context) > 750 ? 20:14
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              AppRouter.navigateToSignIn(context);
                            },
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: deviceWidth(context) > 750 ? 20: 14
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
