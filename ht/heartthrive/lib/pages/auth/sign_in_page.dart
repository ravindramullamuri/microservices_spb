import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import 'package:heart_thrive/utils/user_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../components/custom_button.dart';
import '../../components/custom_text_field.dart';
import '../../components/user_type_selector.dart';
import '../../providers/token_provider.dart';
import '../../providers/user/user_details_provider.dart';
import '../../routes/app_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/secure_storage_utils.dart';

class SignInPage extends ConsumerStatefulWidget {
  final String? initialUserType; // 'patient' or 'doctor'

  const SignInPage({Key? key, this.initialUserType}) : super(key: key);

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  UserType _selectedUserType = UserType.patient;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _passwordVisible = false;
  String? errorMessage;
  bool isValidCredentials = false;

  Future<void> _signIn({bool rememberMe = false}) async {
    final identifier = _emailController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      _showError("Please enter email and password");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Login
      final token = await AuthService.authenticate(
        username: identifier,
        password: password,
        rememberMe: rememberMe,
      ).timeout(const Duration(seconds: 20));

      if (token == null || token.trim().isEmpty) {
        throw Exception("Wrong email or password");
      }

      // 2. Save Token
      final storage = SecureStorageUtils();
      await storage.write("auth_token", token);
      ref.read(tokenProvider.notifier).setToken(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("auth_token", token);
      // await prefs.setString("userId", ""); // will be filled next

      // 3. Update Riverpod immediately (critical!)
      // ref.read(tokenProvider.notifier).state = token;
      // Reload future provider

      // 4. Fetch user details (one call only)
      //final userDetails = await AuthService.fetchUserDetails(token: token).timeout(timeoutDuration);

      /*if (userDetails == null || userDetails.id == null) {
        throw Exception("Failed to load your profile");
      }*/

      // 5. Save user info
      //await prefs.setString('userId', userDetails.id.toString());

      // 6. Load into Riverpod provider
      ref.read(userDetailsDataProvider.notifier).loadUser(token: token);

      // 7. Go home
      if (!mounted) return;
      AppRouter.replaceWithHome(context);
    } on TimeoutException catch (_) {
      _showError("Slow internet or server down. Try again.");
    } catch (e) {
      String msg = e.toString().replaceAll("Exception: ", "");

      if (msg.contains("SocketException") || msg.contains("Failed host")) {
        msg = "No internet connection";
      } else if (msg.contains("Wrong email")) {
        msg = "Incorrect email or password";
      }

      _showError(msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    setState(() => errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );

    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) setState(() => errorMessage = null);
    });
  }

  @override
  void initState() {
    super.initState();
    // Set initial user type if provided
    if (widget.initialUserType == 'doctor') {
      _selectedUserType = UserType.doctor;
    } else {
      _selectedUserType = UserType.patient;
    }
  }

  String get _emailHintText => _selectedUserType == UserType.patient
      ? 'Enter your email address *'
      : 'Enter your email, phone number, or NPI number*';

  String get _passwordHintText => 'Enter your password*';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // ← Prevents unwanted resizing/flicker on Android
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 150, // ← Key: generous padding (try 120–200)
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            Future.delayed(const Duration(milliseconds: 100), () {
                              AppRouter.replaceWithLanding(context);
                            });
                          },
                          child: Image.asset(
                            'lib/assets/back_button.png',
                            width: 30,
                            height: 30,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(
                          height: deviceWidth(context) > 750
                              ? 200
                              : deviceHeight(context) > 640
                              ? 100
                              : 50,
                        ),

                        Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: deviceWidth(context) > 750 ? 40 : 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          'Enter your credentials to proceed.',
                          style: TextStyle(
                            fontSize: deviceWidth(context) > 750 ? 20 : 16,
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

                        UserTypeSelector(
                          selectedType: _selectedUserType,
                          onTypeSelected: (type) {
                            setState(() => _selectedUserType = type);
                          },
                        ),
                        const SizedBox(height: 24),

                        if (errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),

                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              CustomTextField(
                                controller: _emailController,
                                hintText: _emailHintText,
                                keyboardType: TextInputType.emailAddress,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Email is required';
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    isValidCredentials = UserUtils.isValidEmail(value) &&
                                        _passwordController.text.trim().length > 6;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),

                              CustomTextField(
                                controller: _passwordController,
                                hintText: _passwordHintText,
                                obscureText: !_passwordVisible,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Password is required';
                                  if (value.length < 6) return 'Password must be at least 6 characters';
                                  return null;
                                },
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    isValidCredentials = UserUtils.isValidEmail(_emailController.text.trim()) &&
                                        value.trim().length > 6;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => AppRouter.navigateToForgotPassword(context),
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                fontSize: deviceWidth(context) > 750 ? 20 : 14,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else
                          CustomButton2(
                            text: 'Sign In',
                            onPressed: _selectedUserType == UserType.doctor
                                ? () {
                              // your banner code here...
                            }
                                : () {
                              if (_formKey.currentState!.validate()) {
                                _signIn();
                              }
                            },
                            backgroundColor: _selectedUserType == UserType.doctor
                                ? Colors.grey
                                : isValidCredentials
                                ? AppTheme.primaryColor
                                : Colors.grey,
                          ),

                        const SizedBox(height: 16),

                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account yet? ",
                                style: TextStyle(
                                  fontSize: deviceWidth(context) > 750 ? 20 : 14,
                                  color: Colors.black54,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => AppRouter.navigateToRegister(context),
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize: deviceWidth(context) > 750 ? 20 : 14,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 100), // Extra breathing room
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
