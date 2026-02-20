import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:heart_thrive/core/api_endpoints.dart';
import 'package:http/http.dart' as http;
import '../components/custom_button.dart';
import '../constants/service_constants.dart';
import '../constants/service_constants.dart';
import '../theme/app_theme.dart';
import '../routes/app_router.dart';
import '../services/auth_service.dart'; // ✅ for baseUrl

class CreateNewPasswordPage extends StatefulWidget {
  final String email;
  final String otp;

  const CreateNewPasswordPage({
    Key? key,
    required this.email,
    required this.otp,
  }) : super(key: key);

  @override
  State<CreateNewPasswordPage> createState() => _CreateNewPasswordPageState();
}

class _CreateNewPasswordPageState extends State<CreateNewPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
   String? errorMessage;
  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      final uri = Uri.parse(ApiEndpoints.resetPassword);
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
          "otp": widget.otp,
          "newPassword": password,
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        _showSuccessModal();
      } else {
        final Map<String, dynamic> responseJson = json.decode(response.body);
        final String errorMessageLocal = responseJson['message'] ?? response.body;
         setState(() {
           errorMessage = errorMessageLocal;
         });
         Future.delayed(Duration(seconds: 10),(){
           setState(() {
             errorMessage = null;
           });
         });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: $errorMessage")),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
      Future.delayed(Duration(seconds: 10),(){
        setState(() {
          errorMessage = null;
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  child: Image.asset(
                    'lib/assets/Check Mark.png',
                  ),
                ),
                const SizedBox(height: 16),
                 Text(
                  'You have successfully \nreset your password.',
                  textAlign: TextAlign.center,
                  style: AppTheme.title14.copyWith(
                    color: Color(0xFF6F6C90)
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Sign In',
                  onPressed: () {
                    // Show snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Redirecting to sign in page'),
                        duration: Duration(seconds: 2),
                      ),
                    );

                    // Delay navigation slightly so snackbar is visible
                    Future.delayed(const Duration(milliseconds: 500), () {
                      Navigator.of(context).pop();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRouter.signIn,
                            (route) => false,
                      );
                    });
                  },
                ),

              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      'lib/assets/back_button.png', // ✅ your back button image
                      width: 30,
                      height: 30,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 150),
                   Text(
                    'Create New Password',
                    style: AppTheme.title20,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your new password to sign in',
                    style: AppTheme.body14,
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade300, height: 1),
                  const SizedBox(height: 16),
                  errorMessage == null ? SizedBox(height: 0,width: 0,)
                  :Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(errorMessage!,style: TextStyle(color: Colors.red),),
                  ),
                  // 🔑 Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      hintText: 'Create your password *',
                      hintStyle: AppTheme.body14,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.grey), // default border
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.grey), // when not focused
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2), // when focused
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      if (!RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d).+$')
                          .hasMatch(value)) {
                        return 'Must contain upper, lower, and a number';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // 🔑 Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      hintText: 'Confirm your password *',
                      hintStyle: AppTheme.body14,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.grey), // default border
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.grey), // when not focused
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2), // when focused
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirm Password is required';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  CustomButton(
                    text: _isSubmitting ? 'Submitting...' : 'Create Password',
                    onPressed: _isSubmitting
                        ? null
                        : () {
                      if (_formKey.currentState!.validate()) {
                        _resetPassword();
                      }
                    },
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
