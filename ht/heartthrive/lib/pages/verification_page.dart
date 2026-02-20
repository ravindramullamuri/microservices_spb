import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:heart_thrive/core/api_endpoints.dart';
import 'package:heart_thrive/pages/create_new_password_page.dart';
import 'package:http/http.dart' as http;
import '../components/custom_button.dart';
import '../components/custom_text_field.dart';
import '../constants/service_constants.dart';
import '../routes/app_router.dart';
import '../services/forgot_password_service.dart';
import '../theme/app_theme.dart';


class VerificationPage extends StatefulWidget {
  final String email; // ✅ accept email from previous screen

  const VerificationPage({Key? key, required this.email}) : super(key: key);

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
        (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
        (index) => FocusNode(),
  );

  bool _isVerifying = false;
  String? otp;

  int _secondsRemaining = 0;
  Timer? _timer;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _startResendCooldown(); // start countdown immediately
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    setState(() {
      _secondsRemaining = 60; // 1 min cooldown
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _onOtpDigitChanged(String value, int index) {
    if (value.isNotEmpty) {
      // Move to next box
      if (index < _focusNodes.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        FocusScope.of(context).unfocus(); // Last box, close keyboard
      }
    } else {
      // If backspace pressed (field became empty), move back
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  void _showSuccessPopup2(BuildContext context, String otp) {
    showDialog(
      context: context,
      barrierDismissible: false, // prevent dismiss on outside tap
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ Green Tick
                Container(
                  width: 80,
                  height: 80,
                  child: Image.asset(
                    'lib/assets/Check Mark.png',
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ Title
                const Text(
                  "Verification successful",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                const Text(
                  "Your email has been verified successfully.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6F6C90),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // close popup
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateNewPasswordPage(
                          email: widget.email,
                          otp: otp,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _verifyOtp(BuildContext parentContext) async {
    otp = _otpControllers.map((c) => c.text).join();

    if (otp?.length != 6) {
      setState(() {
        errorMessage = "Please enter the 6-digit code";
      });
      Future.delayed(Duration(seconds: 4),(){
        setState(() {
          errorMessage = null;
        });
      });
      /*
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the 6-digit OTP")),
      ); */
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final uri = Uri.parse(ApiEndpoints.passwordValidateOtp);
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
          "otp": otp,
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSuccessPopup2(parentContext, otp.toString());

          // Navigate after a short delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateNewPasswordPage(
                    email: widget.email,
                    otp: otp ?? "0000",
                  ),
                ),
              );            }
          });
        });
      } else {
        final Map<String, dynamic> responseJson = json.decode(response.body);
        final String errorMessageLocal = responseJson['message'] ?? "Something went wrong";
        setState(() {
          errorMessage = 'Verification failed $errorMessageLocal';
        });
        Future.delayed(Duration(seconds: 4),(){
          setState(() {
            errorMessage = null;
          });
        });
        /*
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification failed: $errorMessage")),
        ); */
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
      Future.delayed(Duration(seconds: 4),(){
        setState(() {
          errorMessage = null;
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendOtp() async {
    try {
      await ForgotPasswordService.sendForgotPasswordRequest(widget.email);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP resent to your email")),
      );

      _startResendCooldown(); // restart 1 min timer
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to resend OTP: $e")),
      );
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
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Image.asset(
                    'lib/assets/back_button.png', // ✅ your back button image
                    width: 30, // adjust size
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 150),

                 Text(
                  'Enter Verification Code',
                  style: AppTheme.title20.copyWith(
                    color: Colors.black
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Enter the 6-digit code we sent to \n${widget.email}',
                  style: AppTheme.title12.copyWith(
                    color: Colors.black54
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade300, height: 1),
                const SizedBox(height: 16),

                // Error message
                errorMessage != null? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ) :const SizedBox(height: 0,width: 0,),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    6,
                        (index) => SizedBox(
                      width: 50,
                      height: 60,
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        onChanged: (value) => _onOtpDigitChanged(value, index),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                CustomButton(
                  text: "Verify",
                  onPressed: _isVerifying
                      ? null
                      : () async {
                    await _verifyOtp(context); // 👈 call your async function here
                  },
                ),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Didn't receive the code? ",
                  style: AppTheme.title12,
                ),
                TextButton(
                  onPressed: _secondsRemaining == 0 ? _resendOtp : null,
                  child: Text(
                    _secondsRemaining == 0
                        ? 'Resend '
                        : 'Resend in $_secondsRemaining s',
                    style: TextStyle(
                      color: _secondsRemaining == 0
                          ? AppTheme.primaryColor
                          : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

