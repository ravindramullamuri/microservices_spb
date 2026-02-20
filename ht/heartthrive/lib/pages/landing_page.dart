import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/custom_button.dart';
import '../constants/ui_constants.dart';
import '../routes/app_router.dart';
import '../theme/app_theme.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const Spacer(flex: 1),
                    // Heart Image
                    Image.asset(
                      'lib/assets/heartSplash.png',
                      width: 2800,
                       height: 280,
                    ),
                    const SizedBox(height: 32),
                    // Welcome Text
                     Text(
                      'Welcome to',
                      style: GoogleFonts.poppins(
                        fontSize: deviceWidth(context) > 750 ? 60:deviceWidth(context) > 360 ? 32: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                     Text(
                      'Heart Thrive',
                      style: GoogleFonts.poppins(
                        fontSize: deviceWidth(context) > 750 ? 60: deviceWidth(context) > 360 ? 32:20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 250,
                      child: Text(
                        'A User-friendly app to your\nhealthier journey!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: deviceWidth(context) > 750 ? 18:deviceWidth(context) > 360 ?16:14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                  // Get Started Button with Box Shadow
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: deviceHeight(context) > 640 ?60:40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFED1D28),
                          blurRadius: 14,
                          spreadRadius: -2,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        AppRouter.replaceWithRegister(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent, // we’re using our own shadow
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF95020A), // top-left
                              Color(0xFFED1D28), // bottom-right
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child:  Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: deviceWidth(context) > 750 ? 30:deviceWidth(context) > 360 ? 20.0:18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                    // Sign In Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontSize: deviceWidth(context) > 750 ? 18:deviceWidth(context) > 360 ? 16:14,
                            color: Colors.black,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            AppRouter.navigateToSignIn(context);
                          },
                          child:  Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: deviceWidth(context) > 750 ? 18:deviceWidth(context) > 360 ? 16:14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(flex: 1),
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
