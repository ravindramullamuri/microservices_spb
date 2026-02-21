import 'package:flutter/material.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import 'package:heart_thrive/pages/verification_page.dart';

import '../components/back_button.dart';
import '../components/custom_button.dart';
import '../components/custom_text_field.dart';
import '../components/user_type_selector.dart';
import '../routes/app_router.dart';
import '../theme/app_theme.dart';
import '../services/forgot_password_service.dart';
import '../utils/storage_helper.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  UserType _selectedUserType = UserType.patient;
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  String? errorMessage;
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Function to call Forgot Password API
  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ForgotPasswordService.sendForgotPasswordRequest(email);
      await StorageHelper.saveEmail(email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset link sent to your email")),
      );

      // Navigate to verification page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationPage(email: email),
        ),
      );
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      Future.delayed(const Duration(seconds: 8),(){
        setState(() {
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Image.asset(
                    'lib/assets/back_button.png', // ✅ your back button image
                    width: 30, // adjust size
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                ),

                SizedBox(height: deviceHeight(context) > 640 ? 150: 50),
                // Title
                const Text(
                  'Forgot your password?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'Enter your email address, we will send you confirmation code',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 1,
                  width: MediaQuery.of(context).size.width * 0.9,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 24),

                // User Type Selector
                UserTypeSelector(
                  selectedType: _selectedUserType,
                  onTypeSelected: (type) {
                    setState(() {
                      _selectedUserType = type;
                      debugPrint("_selectedUserType $_selectedUserType");
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Email/Phone Field
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      errorMessage == null ? SizedBox(height: 0,width: 0,)
                          :Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(errorMessage!,style: TextStyle(color: Colors.red),),
                      ),
                      CustomTextField(
                        controller: _emailController,
                        hintText: 'Enter your email address*',
                        keyboardType: TextInputType.emailAddress,
                        autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ validate while typing
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is required';
                          }
                          // Basic email regex
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Reset Password Button

                      CustomButton2(
                        backgroundColor: _selectedUserType == UserType.doctor
                            ? Colors.grey
                            : AppTheme.primaryColor,
                        text: _isLoading ? 'Sending...' : 'Reset Password',
                        onPressed: (_selectedUserType == UserType.doctor || _isLoading)
                            ? null
                            : () {
                          if (_formKey.currentState!.validate()) {
                            _forgotPassword();
                          }
                        },
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
