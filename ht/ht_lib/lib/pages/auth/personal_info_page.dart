import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_intl_phone_field/flutter_intl_phone_field.dart';
import 'package:flutter_intl_phone_field/phone_number.dart';
import 'package:heart_thrive/components/privacy_policy_widget.dart';
import 'package:heart_thrive/core/api_endpoints.dart';
import 'package:heart_thrive/models/api_response.dart';
import 'package:heart_thrive/utils/user_utils.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../../components/dob_calendar.dart';
import '../../components/gender_selector.dart' show GenderSelector, GenderCardSelector;
import '../../components/input_formator.dart';
import '../../components/otp_sender.dart';
import '../../constants/ui_constants.dart';
import '../../theme/app_theme.dart';
import '../../components/custom_text_field.dart';
import '../../components/custom_button.dart';
import '../../routes/app_router.dart';
import '../../components/success_popup.dart';
import '../../services/auth_service.dart';
import 'package:flutter_toggle_tab/flutter_toggle_tab.dart';


class PersonalInfoPage extends StatefulWidget {
  final String userType; // 'patient' or 'doctor'

  const PersonalInfoPage({Key? key, required this.userType}) : super(key: key);

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _medicalHistoryController = TextEditingController();
  String? selectedCompleteNumber;
  String? selectedCountryCode;
  PhoneNumber? selectedNumberObject;
  bool? isTouchedGender = false;

  List<bool> weightUnitSelected = [true, false];
  String weightUnit = "LB";
  int selectedWeightIndex =1;
  int selectedHeightIndex =0;

  List<bool> heightUnitSelected = [true, false];
  String heightUnit = "CM";


  String _selectedGender = 'Select Your Gender';
  bool _provideHealthInfo = false;
  bool _connectWithDoctor = false;
  bool _isSubmitting = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _agreeToTerms = false;
  bool _isAgreed = false;
  bool _hasReadTerms = false;
  final _formKey = GlobalKey<FormState>();


  // 🔹 Add roles and selectedRoleId
  List<dynamic> roles = [];
  int? selectedRoleId;

  @override
  void initState() {
    super.initState();
    setState(() {
      selectedCountryCode = 'US';
    });
    fetchRoles();
  }


  String? validatePassword(String value) {
    // Rule 1: At least 6 characters
    if (value.length < 6) {
      return "Password must be at least 6 characters long.";
    }

    // Rule 2: At least 1 uppercase
    if (!RegExp(r'^(?=.*[A-Z])').hasMatch(value)) {
      return "Password must contain at least 1 uppercase letter.";
    }

    // Rule 3: At least 1 lowercase
    if (!RegExp(r'^(?=.*[a-z])').hasMatch(value)) {
      return "Password must contain at least 1 lowercase letter.";
    }

    // Rule 4: At least 1 number
    if (!RegExp(r'^(?=.*\d)').hasMatch(value)) {
      return "Password must contain at least 1 number.";
    }

    // Rule 5: At least 1 special character
    if (!RegExp(r'^(?=.*[@$!%*?&^#~\-_=+])').hasMatch(value)) {
      return "Password must contain at least 1 special character.";
    }

    return null; // ✅ Valid password
  }

  void _showPasswordInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            "Password Requirements",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Your password must:\n\n"
                "• Be at least 6 characters long\n"
                "• Contain at least 1 uppercase letter\n"
                "• Contain at least 1 lowercase letter\n"
                "• Contain at least 1 number\n"
                "• Contain at least 1 special character",
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Got it"),
            ),
          ],
        );
      },
    );
  }


  Future<void> fetchRoles() async {
    try {
      final ioc = HttpClient()
        ..badCertificateCallback = (cert, host, port) => true;
      final client = IOClient(ioc);

      final url = Uri.parse(ApiEndpoints.userRoles);
      final response = await client.get(url); // ✅ use client
      debugPrint("response 151 @@@ ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          roles = data; // assuming API returns list of roles
          if (roles.isNotEmpty) {
            final userRole =
            roles.firstWhere((role) => role['name'] == 'Patient', orElse: () => {});
            if (userRole.isNotEmpty) {
              selectedRoleId = userRole['id'];
              final selectedRoleName  = userRole['name'];
              debugPrint("***RoleID*** : $selectedRoleId");
              debugPrint("***RoleName*** : $selectedRoleName");
              setState(() {
                selectedRoleId = userRole['id'];
              });
            }


          }
        });
      } else {
        debugPrint("Failed to load roles: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching roles: $e");
    }
  }


  Future<void> _submitSignUp(BuildContext parentContext) async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        isTouchedGender = true;
      });
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final gender = widget.userType == 'patient' ? _selectedGender : null;
    final dob = widget.userType == 'patient' ? _dobController.text.trim() : null;

    // ✅ Validation
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Please fill all required fields.');
      return;
    }
    if (!_isValidEmail(email)) {
      _showMessage('Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters long.');
      return;
    }
    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }
    if (widget.userType == 'patient' && (dob == null || dob.isEmpty)) {
      _showMessage('Please select your Date of Birth.');
      return;
    }
    // 👇 Add gender validation here
    if (widget.userType == 'patient' && (gender == null || gender.isEmpty)) {
      _showMessage('Please select your Gender.');
      return;
    }
    if (!_isAgreed) {
      _showMessage('Please agree to the Terms to continue.');
      return;
    }
    if (selectedRoleId == null) {
      _showMessage('Unable to determine role. Please try again.');
      return;
    }

    setState(() => _isSubmitting = true);

    debugPrint("Demo debugPrint 2");
    _sendOtp(
      parentContext,
      _nameController.text.trim(),
      _emailController.text.trim(),
    );
  }


  /// ✅ Helper to show snackbars consistently
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    debugPrint('Test123');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    });
  }

  /// ✅ Helper to validate email format
  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return regex.hasMatch(email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _medicalHistoryController.dispose();
    super.dispose();
  }


  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SuccessPopup(
          onSignInPressed: () {
            Navigator.of(context).pop(); // Close popup
            if (widget.userType == 'patient') {
              AppRouter.navigateToSignInWithUserType(context, 'patient');
            } else {
              AppRouter.navigateToSignInWithUserType(context, 'doctor');
            }
          },
        );
      },
    );
  }
  List<bool> isSelected = [true, false];
  String selectedUnit = "KG";

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // transparent or any color
      statusBarIconBrightness: Brightness.light, // 👈 white icons
      statusBarBrightness: Brightness.dark, // for iOS
    ));

    return Scaffold(
      // backgroundColor: AppTheme.primaryColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(20),
        child: AppBar(
         leading: SizedBox(),
        ),
      ),
      body: Ink(
        //color: AppTheme.primaryColor,
        child: SafeArea(
          child: Container(
            color: Colors.white,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () => AppRouter.replaceWithRegister(context),
                        child: Image.asset(
                          'lib/assets/back_button.png', // ✅ your back button image
                          width: deviceWidth(context)>750?40:30, // adjust size
                          height: deviceWidth(context)>750?40:30,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Title
                      Text(
                        'Personal Info',
                        style: TextStyle(
                          fontSize: deviceWidth(context)>750?32:deviceWidth(context) > 360 ? 30:20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                       Text(
                        'Let\'s start with your basic details.',
                        style: TextStyle(
                          fontSize: deviceWidth(context)>750?20:16,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Full Name Field
                      CustomTextField(
                        controller: _nameController,
                        hintText: 'Enter your full name*',
                        // suffixIcon: const Icon(Icons.person, color: Colors.grey),
                        inputFormatters: [
                          FirstLetterAlphaAlnumFormatter(),          // ✅ allows spaces now
                          LengthLimitingTextInputFormatter(30),      // ✅ limit to 30 chars
                        ],
                        validator: (value) {
                          value = value?.trim() ?? "";

                          // Required
                          if (value.isEmpty) return 'Name is required.';

                          // Split into words and check the first actual word
                          final words = value.split(' ').where((w) => w.isNotEmpty).toList();
                          if (words.isNotEmpty) {
                            final firstWord = words.first;
                            if (firstWord.length < 3) {
                              return 'Name must be between 3 and 75 characters.';
                            }
                          }

                          // Full length check (backend rule)
                          if (value.length < 3 || value.length > 75) {
                            return 'Name must be between 3 and 75 characters.';
                          }

                          // Emoji block
                          final emojiRegex = RegExp(
                            r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
                            unicode: true,
                          );
                          if (emojiRegex.hasMatch(value)) return 'Emojis are not allowed.';

                          // Allowed characters: A–Z, 0–9, space
                          if (!RegExp(r'^[A-Za-z0-9 ]+$').hasMatch(value)) {
                            return 'Only alphabets, numbers and spaces allowed.';
                          }

                          return null;
                        },

                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),


                      const SizedBox(height: 16),
                      FormField<String>(
                        validator: (value) {
                          debugPrint("Gender Value $value");

                          if (widget.userType == 'patient' && (_selectedGender == null || _selectedGender!.isEmpty)) {
                            return 'Please select your Gender.';
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        builder: (FormFieldState<String> state) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GenderCardSelector(
                                onChanged: (gender) {
                                  debugPrint("onChanged 388 $gender ${deviceWidth(context)}");
                                  setState(() {
                                    _selectedGender = gender.toLowerCase();
                                    state.didChange(_selectedGender);
                                    // 👇 validate only this field
                                    state.validate();// 👈 updates form field state
                                  });
                                },
                              ),
                              if (state.hasError && isTouchedGender!)
                                Padding(
                                  padding: const EdgeInsets.only(top: 5, left: 10),
                                  child: Text(
                                    state.errorText!,
                                    style:  TextStyle(color: Color(0xffD3303F), fontSize: deviceWidth(context) > 750? 18:12),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 16),
                      // Date of Birth Field
                      if (widget.userType == "patient")
                        DOBField(
                          hintText: "Enter your DOB (MM/DD/YYYY)",
                          controller: _dobController,
                          onChanged: (val) {
                            debugPrint("DOB Entered: $val");
                          },
                        ),

                      const SizedBox(height: 16),
                      // ],
                      // Email Field
                      CustomTextField(
                        controller: _emailController,
                        hintText: 'Enter your email address*',
                        keyboardType: TextInputType.emailAddress,
                        //suffixIcon: const Icon(Icons.email, color: Colors.grey),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')),
                          LengthLimitingTextInputFormatter(50), // ✅ optional length limit
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is required.';
                          }
                          // ✅ basic email regex
                          if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(value)) {
                            return 'Enter a valid email address.';
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ show instantly

                      ),

                      SizedBox(height: 16,),
                      // Phone Field
                      FormField<String>(
                        builder: (state) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: double.infinity, // ✅ take full width
                                child: IntlPhoneField(
                                  autofocus: false,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  controller: _phoneController,
                                  initialCountryCode: 'US',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: TextStyle(
                                    fontSize: deviceWidth(context)>750? 20.0:15.0,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Enter your phone number",
                                    hintStyle:  TextStyle(fontSize: deviceWidth(context)>750? 20.0:15.0, color: Colors.grey),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.0),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: const BorderSide(color: Colors.red, width: 1.0),
                                    ),
                                      errorStyle: TextStyle(
                                          fontSize: deviceWidth(context)>750?18:12
                                      ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: const BorderSide(color: Colors.red, width: 1.0),
                                    ),
                                    //suffixIcon: const Icon(Icons.phone, color: Colors.grey),
                                  ),
                                  dropdownIcon: const Icon(Icons.arrow_drop_down),
                                  dropdownTextStyle: TextStyle(
                                    fontSize: deviceWidth(context)>750? 20.0:15.0,
                                    color: Colors.black87,
                                  ),
                                  dropdownIconPosition: IconPosition.trailing,
                                  onChanged: (phone) {
                                    setState(() {
                                      selectedCompleteNumber = phone.completeNumber;
                                    });
                                  },
                                  onCountryChanged: (country) {
                                    debugPrint('Country changed to: ${country.name} ${country.code}');
                                    setState(() {
                                      selectedCountryCode = country.code;
                                    });
                                  },
                                  validator: (phone) {
                                    if (phone == null || phone.number.isEmpty) {
                                      return "Phone number is required.";
                                    }
                                    if (!phone.isValidNumber()) {
                                      return "Please enter a valid phone number.";
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              if (state.hasError)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2, left: 10),
                                  child: Text(
                                    state.errorText!,
                                    style: const TextStyle(color: Color(0xffD3303F), fontSize: 12),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),




                      const SizedBox(height: 16),

                      // Password Field
                      // Password Field
                      CustomTextField(
                        controller: _passwordController,
                        hintText: 'Create your password*',
                        obscureText: !_passwordVisible,
                        validator: (value) => validatePassword(value ?? ""),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        onChanged: (value) {
                          setState(() {}); // to re-check password validity
                        },
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Toggle visibility button
                            // IconButton(
                            //   icon: const Icon(Icons.info_outline, color: Colors.grey),
                            //   onPressed: () {
                            //     _showPasswordInfoDialog(context);
                            //   },
                            // ),
                            IconButton(
                              icon: Icon(
                                _passwordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Confirm Password Field
                      CustomTextField(
                        controller: _confirmPasswordController,
                        hintText: 'Confirm your password*',
                        obscureText: !_confirmPasswordVisible,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please confirm your password.";
                          }
                          if (value != _passwordController.text) {
                            return "Passwords do not match.";
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _confirmPasswordVisible = !_confirmPasswordVisible;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Additional Options (only for patients)
                      if (widget.userType == 'patient') ...[
                         Text(
                          'Would you like to:',
                          style: TextStyle(
                            fontSize: deviceWidth(context)>750?20:16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Provide Health Info Checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _provideHealthInfo,
                              onChanged: (bool? value) {
                                setState(() {
                                  _provideHealthInfo = value ?? false;
                                });
                              },
                              activeColor: AppTheme.primaryColor,
                            ),
                             Expanded(
                              child: Text(
                                'Provide Health Info',
                                style: TextStyle(
                                  fontSize: deviceWidth(context)>750?18:14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // 🔽 Show Health Info Section when checkbox is checked
                        if (_provideHealthInfo) ...[
                          const SizedBox(height: 12),
                           Text(
                            'Health Info',
                            style: TextStyle(
                              fontSize: deviceWidth(context)>750?20:16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                           Text(
                            "This helps us assess your heart risk.",
                            style: TextStyle(
                              fontSize: deviceWidth(context)>750?18:14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Weight Input
                          // Weight Input
                          CustomTextField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d{0,5}(\.\d{0,2})?$'),
                              ),
                              DecimalTextInputFormatter(
                                maxDigitsBeforeDecimal: 5,
                                maxDigitsAfterDecimal: 2,
                              ),
                            ],
                            hintText: "Enter your weight",
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 8.0, top: 8, bottom: 8),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.black, // ✅ Border color same as your toggle tab
                                    width: 1,             // ✅ Border width
                                  ),
                                  borderRadius: BorderRadius.circular(40), // ✅ Rounded pill shape
                                ),
                                child: FlutterToggleTab(
                                  width: 22,
                                  borderRadius: 40,
                                  height: 15,
                                  selectedIndex: selectedWeightIndex,
                                  selectedBackgroundColors: [AppTheme.primaryColor],
                                  unSelectedBackgroundColors: [Colors.white],
                                  isScroll: true,
                                  selectedTextStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  unSelectedTextStyle: const TextStyle(
                                    color: Colors.black87,
                                  ),
                                  dataTabs: <DataTab>[
                                    DataTab(title: "KG"),
                                    DataTab(title: "LB"),
                                  ],
                                  selectedLabelIndex: (index) {
                                    if (selectedWeightIndex == index) return;

                                    setState(() {
                                      for (int i = 0; i < weightUnitSelected.length; i++) {
                                        weightUnitSelected[i] = i == index;
                                      }
                                      selectedWeightIndex = index;
                                      weightUnit = index == 0 ? "KG" : "LB";

                                      if (weightUnit == "KG") {
                                        double kg = double.tryParse(_weightController.text ?? "0") ?? 0;
                                        _weightController.text = UserUtils.lbsToKg(kg).toString();
                                      } else {
                                        double lbs = double.tryParse(_weightController.text ?? "0") ?? 0;
                                        _weightController.text = UserUtils.kgToLbs(lbs).toString();
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return "Please enter weight";

                              double number = double.tryParse(val) ?? -1;
                              if (number < 0) return "Enter a valid number";


                              if (weightUnit.toLowerCase().trim() == "kg" && number > 500) return "Weight cannot exceed 500 kg";
                              if (weightUnit.toLowerCase().trim() == "lb" && number > 1103) return "Weight cannot exceed 1103 lbs";


                              return null;
                            },
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                          ),

                          const SizedBox(height: 16),

                          // Height Input
                          CustomTextField(
                            controller: _heightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d{0,5}(\.\d{0,2})?$'),
                              ),
                              DecimalTextInputFormatter(
                                maxDigitsBeforeDecimal: 5,
                                maxDigitsAfterDecimal: 2,
                              ),
                            ],
                            hintText: "Enter your height",
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 8.0, top: 8,bottom: 8),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.black, // ✅ Border color
                                    width: 1, // ✅ Border width
                                  ),
                                  borderRadius: BorderRadius.circular(40), // ✅ Match your toggle's radius
                                ),
                                child: FlutterToggleTab(
                                  width: 22,
                                  borderRadius: 40,
                                  height: 15,
                                  selectedIndex: selectedHeightIndex,
                                  selectedBackgroundColors: [AppTheme.primaryColor],
                                  unSelectedBackgroundColors: [Colors.white],
                                  isScroll: true,
                                  selectedTextStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  unSelectedTextStyle: const TextStyle(
                                    color: Colors.black87,
                                  ),
                                  dataTabs: <DataTab>[
                                    DataTab(title: "CM"),
                                    DataTab(title: "IN"),
                                  ],
                                  selectedLabelIndex: (index) {
                                    if (selectedHeightIndex == index) return;

                                    setState(() {
                                      selectedHeightIndex = index;
                                      heightUnit = index == 0 ? "CM" : "IN";

                                      if (heightUnit == "CM") {
                                        double cm = double.tryParse(_heightController.text.isEmpty ? "0" : _heightController.text) ?? 0;
                                        _heightController.text = UserUtils.inchToCm(cm).toString();
                                      } else {
                                        double inch = double.tryParse(_heightController.text.isEmpty ? "0" : _heightController.text) ?? 0;
                                        _heightController.text = UserUtils.cmToInch(inch).toString();
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                            validator: (val) {
                              debugPrint(val);
                              if (val == null || val.isEmpty) return "Please enter height";

                              double number = double.tryParse(val) ?? -1;
                              if (number < 0) return "Enter a valid number";

                              if (heightUnit.toLowerCase().trim() == "cm" && number > 274) return "Height cannot exceed 9 feet (274 cm)";
                              if (heightUnit.toLowerCase().trim() == "in" && number > 108) return "Height cannot exceed 9 feet (108 inches)";

                              return null;
                            },
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                          ),

                          const SizedBox(height: 16),

                          // Medical History Input
                          CustomTextField(
                            controller: _medicalHistoryController,
                            hintText: "Enter your medical history (if any)",
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z\s.,-]'), // ✅ allows letters, spaces, dot, comma, hyphen
                              ),
                            ],
                          ),
                        ],

                        // Connect with Doctor Checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _connectWithDoctor,
                              onChanged: (bool? value) {
                                setState(() {
                                  _connectWithDoctor = value ?? false;
                                });
                              },
                              activeColor: AppTheme.primaryColor,
                            ),
                             Expanded(
                              child: Text(
                                'Connect with a Clinician',
                                style: TextStyle(
                                  fontSize: deviceWidth(context)>750?18:14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // 🔽 Show Connect with Doctor Section when checkbox is checked
                        if (_connectWithDoctor) ...[
                          const SizedBox(height: 12),

                          // 🚧 Under Construction Banner
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.construction, color: Colors.orange),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "This feature is under construction. Please check back later.",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),],

                      ],

                      // Terms and Conditions
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: _isAgreed,
                            activeColor: AppTheme.primaryColor,
                            onChanged: (val) {
                              setState(() {
                                _isAgreed = val ?? false;
                              });
                            },
                          ),
                          Expanded( // ✅ fixes "RenderBox was not laid out"
                            child: RichText(
                              text: TextSpan(
                                style:  TextStyle(
                                  fontSize: deviceWidth(context)>750?18:14,
                                  color: Colors.black,
                                ),
                                children: [
                                   TextSpan(
                                    text: 'I agree to the heart thrive ',
                                    style: TextStyle(
                                      fontSize: deviceWidth(context)>750?18:14,
                                    )
                                  ),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style:  TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = ()  async {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: true,
                                          builder: (context) => AlertDialog(
                                            insetPadding: const EdgeInsets.all(16),
                                            contentPadding: const EdgeInsets.all(16),
                                            content: SizedBox(
                                              width: double.maxFinite,
                                              child: SingleChildScrollView(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                     Text(
                                                      'Terms & Conditions (Terms of Use)',
                                                      style: TextStyle(
                                                        fontSize: deviceWidth(context)>750?20:16,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppTheme.primaryColor,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    const Text(
                                                      'Last updated: October 24, 2025',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: AppTheme.primaryColor,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 20),
                                                    const Text(
                                                      'Welcome to Heart Thrive (“we,” “our,” or “us”). These Terms & Conditions (“Terms”) govern your use of the Heart Thrive mobile application (the “App”) and related services. By downloading or using Heart Thrive, you agree to these Terms. If you do not agree, please stop using the App immediately.',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black87,
                                                        height: 1.5,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 20),
                                                    /// 1. Eligibility
                                                    _buildSectionRich(
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


                                                    _buildSectionRich(
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

                                                    _buildSection2(
                                                      '3. User Responsibilities',
                                                      'By using Heart Thrive, you agree to:',
                                                      [
                                                        'Provide accurate and truthful information when entering health data.',
                                                        'Use the App only for lawful purposes and not misuse or interfere with its functionality.',
                                                        'Understand that the App’s outputs (risk awareness gauge, insights, trends) are informational only.',
                                                        'Contact a medical professional if you experience symptoms, emergencies, or worsening conditions — the App does not monitor medical emergencies.',
                                                      ],
                                                    ),
                                                    _buildSection2(
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
                                                    _buildSection2(
                                                      '5. Sharing Data With Clinicians ',
                                                      'If you choose to share your data with a clinician using the Heart Thrive Clinician Portal:',
                                                      [
                                                        'You grant us permission to securely transmit your selected health data to them.',
                                                        'Clinician access can be revoked by you at any time in the App settings.',
                                                        'We are not responsible for how clinicians use or interpret the data they receive. ',
                                                      ],
                                                    ),
                                                    _buildSection2Rich(
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

                                                    _buildSection2(
                                                      '7. Subscription & Payments',
                                                      'Some features of Heart Thrive may require a paid subscription or in-app purchase.',
                                                      [
                                                        'Prices and features are listed within the App Store.',
                                                        'Payments are processed through Apple’s in-app purchase system.',
                                                        'Subscriptions automatically renew unless canceled through your App Store settings.',
                                                      ],
                                                      footerText: 'We do not manage billing directly.',
                                                    ),
                                                    _buildSection(
                                                      '8. Intellectual Property',
                                                      'All content in the App — including logos, images, graphics, text, features, and software — '
                                                          'is the property of Heart Thrive or its licensors.\n\n'
                                                          'You may not copy, modify, distribute, reverse engineer, or reuse any part of the App '
                                                          'without written permission.',
                                                    ),
                                                    _buildSection2(
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
                                                    _buildSection2(
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
                                                    _buildSection2(
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


                                                    _buildSection(
                                                      '12. Third-Party Services',
                                                      'Heart Thrive may link to or integrate with third-party services '
                                                          '(e.g., data storage providers, analytics systems). '
                                                          'We are not responsible for the policies or actions of third-party providers.',
                                                    ),

                                                    /// 13. Account Deletion & Data Removal
                                                    _buildSection2(
                                                      '13. Account Deletion & Data Removal',
                                                      'Users may delete their account at any time through the App.\n\n'
                                                          'Upon deletion:'
                                                      ,
                                                      [
                                                        'Your identifiable data will be removed from our servers within 30 days, except as required by law.',
                                                        'Revoked clinician access takes effect immediately.',
                                                      ],
                                                    ),
                                                    _buildSection(
                                                      '14. Changes to These Terms',
                                                      'We may update these Terms periodically. '
                                                          'The “Last Updated” date above indicates the most recent revision.\n\n'
                                                          'Continued use of the App after updates means you accept the revised Terms.',
                                                    ),
                                                    _buildSection6(
                                                      '15. Contact Information',
                                                      'For questions about these Terms or our services, contact:\n\n'
                                                          'support@heartthrivellc.com',
                                                    ),

                                                    const Text(
                                                      'By using Heart Thrive, you confirm that you have read, understood, '
                                                          'and agree to these Terms & Conditions.',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                        height: 1.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Close'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },

                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () async {
                                        await showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            insetPadding: const EdgeInsets.all(16),
                                            contentPadding: const EdgeInsets.all(16),
                                            content: SizedBox(
                                              width: double.maxFinite,
                                              child: SingleChildScrollView(
                                                  child: PrivacyPolicyContent()
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text("Close"),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),


                      const SizedBox(height: 24),

                      // Action Button
                      _isSubmitting
                          ? const Center(child: CircularProgressIndicator())
                          : CustomButton2(
                        backgroundColor: AppTheme.primaryColor,
                        text: widget.userType == 'patient' ? 'Sign Up' : 'Next',
                        onPressed: () {
                          if (widget.userType == 'patient') {
                            debugPrint("User is patient !!!!");
                            _submitSignUp(context);
                          } else {
                            AppRouter.navigateToRegisterAsDoctor(context);
                          }
                        },
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),

        RichText(
          text: TextSpan(
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(height: 1.5),
            children: contentSpans,
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
  static Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),

        if (content?.isNotEmpty == true)
          Text(
            content!,
            style: const TextStyle(
              fontSize: 14,
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
                const Text("• ", style: TextStyle(fontSize: 16, height: 1.5)),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 14,
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
              style: const TextStyle(
                fontSize: 14,
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),

        if (content?.isNotEmpty == true)
          Text(
            content!,
            style: const TextStyle(
              fontSize: 14,
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
                const Text("•", style: TextStyle(fontSize: 16, height: 1.5)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    point,
                    style: const TextStyle(
                      fontSize: 14,
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
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),

        const SizedBox(height: 20),
      ],
    );
  }

  static Widget _buildSection6(String title, String content) {
    // Split content by double line breaks
    final parts = content.split('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),

        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
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

  void _sendOtpAndShowDialog(BuildContext context, String name, String email) {
    // Close previous OTP dialog if any
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    // Send OTP
    _sendOtp(context, name, email);

  }


  Future<void> _sendOtp(BuildContext context, String name, String email) async {
    debugPrint("debugPrinting Name:$name Email:$email");
    final ioc = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;

    final url = Uri.parse(ApiEndpoints.emailVerificationSendOTP);

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "email": email}),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        // ✅ OTP Sent Successfully
        _showOtpDialog(context, email);
        setState(() => _isSubmitting = false);
      } else {
        final body = jsonDecode(response.body);
        final errorMessage = body['message'] ?? 'Something went wrong';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send OTP: $errorMessage")),
        );
        debugPrint('!!!!!!!!!!!!!!!!!456');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _isSubmitting = false);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }




  void _showOtpDialog(BuildContext parentContext, String email) {
    List<TextEditingController> otpControllers =
    List.generate(6, (_) => TextEditingController());
    List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (context) {
        bool isLoading = false; // local state for loader
        String?  errorMessage; // local state for loader
        return StatefulBuilder(
          builder: (context, setState) {
            return Stack(
              children: [
                AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  contentPadding: const EdgeInsets.all(20),
                  insetPadding: const EdgeInsets.symmetric(horizontal: 40),
                  title: const Text(
                    "Enter Verification Code",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Enter the 6-digit code we sent to "
                            "$email",
                        textAlign: TextAlign.center,
                        style: AppTheme.title12.copyWith(
                            fontWeight: FontWeight.normal
                        ),
                      ),
                      const SizedBox(height: 20),
                      errorMessage == null ?
                      const SizedBox(height: 0,width: 0,)
                          : Text(
                        errorMessage!,style: const TextStyle(
                          color: Colors.red
                      ),),
                      // OTP Fields
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          6,
                              (index) => SizedBox(
                            width: 30,
                            child: TextField(
                              controller: otpControllers[index],
                              focusNode: focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              decoration: InputDecoration(
                                counterText: '',
                                contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty && index < 5) {
                                  FocusScope.of(context)
                                      .requestFocus(focusNodes[index + 1]);
                                }
                                if (value.isEmpty && index > 0) {
                                  FocusScope.of(context)
                                      .requestFocus(focusNodes[index - 1]);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                  actionsAlignment: MainAxisAlignment.center,
                  actions: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppTheme.primaryColor),
                              ),
                            ),
                            child:  Text(
                              "Cancel",
                              style:  TextStyle(
                                fontSize: deviceWidth(context) > 390 ? 16 : deviceWidth(context) > 360 ?
                                14:12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8,),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(150, 48),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: isLoading
                                ? null
                                : () async {
                              String otp =
                              otpControllers.map((c) => c.text).join();
                              if (otp.length == 6) {
                                setState(() => isLoading = true);

                                ApiResponse apiResponse = await _verifyOtp(parentContext, email, otp);
                                if(apiResponse.status == 200 && apiResponse.success){
                                  await createPatientAccount(parentContext);
                                  setState(() => isLoading = false);
                                  // ✅ if verification success, close dialog
                                  Navigator.pop(context);
                                }else{
                                  setState((){
                                    errorMessage = apiResponse.message;
                                    isLoading = false;
                                  });
                                  Future.delayed(const Duration(seconds: 8),(){
                                    setState((){
                                      errorMessage = null;
                                    });
                                  });
                                }

                              } else {
                                setState((){
                                  errorMessage = "Please enter all 6 digits";
                                });
                                Future.delayed(const Duration(seconds: 8),(){
                                  setState((){
                                    errorMessage = null;
                                  });
                                });
                                ScaffoldMessenger.of(parentContext)
                                    .showSnackBar(
                                  const SnackBar(
                                      content:
                                      Text("Please enter all 6 digits")),
                                );
                              }
                            },
                            child:  Text(
                              "Verify & Sign Up",
                              style: AppTheme.title16.copyWith(
                                  fontSize: deviceWidth(context) > 390 ? 16 : deviceWidth(context) > 360 ?
                                  14:12,
                                  color: Colors.white
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    OtpResendRow(
                      sendOtpCallback: () {
                        _sendOtp(
                            parentContext, _nameController.text.trim(), email.trim());
                      },
                    ),
                  ],
                ),

                // ✅ Loading overlay
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }



  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // prevent closing
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Future<ApiResponse> _verifyOtp(BuildContext parentContext, String email, String otp) async {
    final ioc = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    final client = IOClient(ioc);

    final url = Uri.parse(ApiEndpoints.emailVerificationVerifyOtp);

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "otp": otp}),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return ApiResponse(
            status: response.statusCode,
            success: true,
            message: response.body
        );
      } else {
        // ✅ Use parentContext instead of dialog context
        //_showErrorPopup(parentContext, "Invalid OTP. Please try again.");
        return ApiResponse(
            status: response.statusCode,
            success: false,
            message: "Invalid OTP. Please try again."
        );
      }
    } catch (e) {
      //_showErrorPopup(parentContext, "Error: $e");
      return ApiResponse(
          status: 400,
          success: false,
          message: "Invalid OTP. Please try again."
      );
    }
  }

  Future<void> createPatientAccount(BuildContext parentContext) async {
    debugPrint("Demo debugPrint 3");

    if (selectedRoleId == null) {
      _showMessage("Please select a role before continuing.");
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = selectedCompleteNumber;
    final countryCode = selectedNumberObject?.countryISOCode;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final gender = widget.userType == 'patient' ? _selectedGender : null;
    final dob = widget.userType == 'patient' ? _dobController.text.trim() : null;

    try {
      await AuthService.createUser(
        name: name,
        email: email,
        password: password,
        countryCode: selectedCountryCode,
        phone: phone,
        genderName: gender,
        dobDdMmYyyy: dob,
        userType: widget.userType,
        agreedToTerms: _agreeToTerms,
        roleId: selectedRoleId!,   // ✅ now guaranteed not null
        weight: double.tryParse(_weightController.text) ?? 0,
        weightUnitType: weightUnit.toLowerCase().trim(),
        height: double.tryParse(_heightController.text) ?? 0,
        heightUnitType: heightUnit.toLowerCase().trim(),
      );

      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSuccessPopup2(parentContext);

        // Navigate after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(parentContext, AppRouter.signIn);
          }
        });
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// 🔴 Error Popup
  void _showErrorPopup(BuildContext context, String message) {
    if (!mounted) return; // avoid calling if widget disposed

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }




  void _showSuccessPopup2(BuildContext context) {
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

                // ✅ Subtitle
                const Text(
                  "Your email has been verified and your account has been created.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6F6C90),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // ✅ Continue button
                // ElevatedButton(
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: AppTheme.primaryColor,
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 24,
                //       vertical: 12,
                //     ),
                //   ),
                //   onPressed: () {
                //     Navigator.pop(context); // close popup
                //     Navigator.pushReplacementNamed(
                //         context, AppRouter.signIn); // go to sign in
                //   },
                //   child: const Text(
                //     "Continue",
                //     style: TextStyle(
                //       fontSize: 16,
                //       fontWeight: FontWeight.w600,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

}


