import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_intl_phone_field/countries.dart';
import 'package:flutter_intl_phone_field/country_picker_dialog.dart';
import 'package:flutter_intl_phone_field/flutter_intl_phone_field.dart';
import 'package:flutter_intl_phone_field/phone_number.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import 'package:heart_thrive/models/api_response.dart';
import 'package:heart_thrive/models/userdetails.dart';
import 'package:heart_thrive/pages/notification_badgeicon_widget.dart';
import 'package:heart_thrive/providers/user/user_details_provider.dart';
import 'package:heart_thrive/routes/app_router.dart';
import 'package:heart_thrive/services/user_service.dart';
import 'package:heart_thrive/utils/date_utils.dart';
import 'package:heart_thrive/utils/user_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/dob_calendar.dart';
import '../components/gender_selector.dart';
import '../theme/app_theme.dart';
import '../utils/secure_storage_utils.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  final UserDetails? userDetails;
  const EditProfilePage({Key? key, this.userDetails}) : super(key: key);

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  String fullName = "John Doe";
  String gender = "Male";
  String dob = "01 Jan 2000";
  String email = "john@example.com";
  String phone = "+91 9876543210";
  bool _isLoading = false;
  Map<String, dynamic>? _profileData;
  String _selectedGender = 'Select Your Gender';
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _initialCountryCode = 'US';
  String? _selectedCountryCode;
  late FocusNode _phoneFocus;
  String? _selectedCompletePhoneNumber;
  PhoneNumber? selectedPhoneNumber;
  bool? isModified = false;
  @override
  void initState() {

    super.initState();
    _phoneFocus = FocusNode();
    _loadProfileData();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _phoneFocus.dispose();

  }

  Future<void> saveLastCountryCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_country_code', code);
  }

  Future<String> getLastCountryCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_country_code') ?? 'IN'; // default India
  }

  Future<void> _loadProfileData() async {
    try {
      if (!mounted || widget.userDetails == null) return;

      // Default fallback
      final rawPhone = widget.userDetails?.phone ?? '+919876543210';

      String countryCode = 'IN'; // default
      String numberOnly = '';

// Extract country and number
      if (rawPhone.startsWith('+')) {
        final matchedCountry = countries.firstWhere(
              (c) => rawPhone.startsWith(c.dialCode),
          orElse: () => countries.firstWhere((c) => c.code == 'IN'),
        );

        countryCode = matchedCountry.code;
        _selectedCountryCode = countryCode;
        numberOnly = rawPhone.substring(matchedCountry.dialCode.length);
      } else {
        numberOnly = rawPhone; // just local number
      }

      // _phoneController.text = numberOnly;
      //_initialCountryCode = countryCode;


      setState(() {
        fullName =
            '${widget.userDetails?.firstname ?? ''} ${widget.userDetails?.lastname ?? ''}'
                .trim();
        gender = widget.userDetails?.gender ?? 'Male';
        dob = DateFormatUtil.fromCustomToDisplay(widget.userDetails!.dateOfBirth!) ?? '01 Jan 2000';
        _dobController.text = dob;

        email = widget.userDetails?.email ?? 'john@example.com';
        //phone = numberOnly; // full number with +
        //_phoneController.text = numberOnly; // only the local number
        //_initialCountryCode = countryCode; // ISO code like "IN"
        _initialCountryCode = widget.userDetails!.countryCode!;
        selectedPhoneNumber = PhoneNumber(countryCode: countryCode, number: numberOnly, countryISOCode: '');
      });
      _parseNumber(widget.userDetails!.phone!);
      _selectedCompletePhoneNumber = widget.userDetails!.phone!;
      debugPrint("rawPhone: $rawPhone");
      debugPrint("Matched country: $countryCode");
      debugPrint("numberOnly: $numberOnly");
      debugPrint("appears : ${_phoneController.text}");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }


  }

  // Parse the number
  Future<void> _parseNumber(String fullNumber) async {
    final parsed = PhoneNumber.fromCompleteNumber(completeNumber: fullNumber);
    //final parsed = await FlutterLibphonenumber().parse(fullNumber);
    // parsed = { "type": "mobile", "e164": "+19493267194", "national": "9493267194", "country_code": "1", "region_code": "US" }



    debugPrint("Country Code: $parsed");
    setState(() {
      //_initialCountryCode = parsed.countryISOCode;
      _initialCountryCode = widget.userDetails!.countryCode!;
      debugPrint("Country Code ${widget.userDetails!.countryCode!}");
      _phoneController.text = parsed.countryCode+parsed.number;

    });
    debugPrint("Country Code: ${_phoneController.text}");
  }


  // Fixed: Safe _saveProfile with mounted checks
  Future<void> _saveProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final nameParts = fullName.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      debugPrint("_initialCountryCode @@ $_initialCountryCode");
      final profileData = {
        'id': widget.userDetails?.id,
        'firstName': firstName,
        'lastName': lastName,
        'gender': {"name": gender},
        'dateOfBirth': DateFormatUtil.toApiFormat(dob),
        'phoneNumber': _selectedCompletePhoneNumber?.isNotEmpty == true
            ? _selectedCompletePhoneNumber
            : widget.userDetails?.phone,
        'countryCode': _initialCountryCode,
      };

      ApiResponse apiResponse = await UserService().updateUser(widget.userDetails!.id!, profileData);

      if (apiResponse.status == 200 && apiResponse.success == true && mounted) {
        // Show SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );

        // Refresh user data
        final storage = SecureStorageUtils();
        final token = await storage.read("auth_token");
        ref.read(userDetailsDataProvider.notifier).loadUser(token: token);

        // Wait for SnackBar to finish
        await Future.delayed(const Duration(seconds: 2));

        // Only pop if still mounted
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  void _editGender(String title) {
    String tempGender = gender; // 👈 Store the original gender temporarily

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: StatefulBuilder( // 👈 Important: local state inside dialog
            builder: (context, setDialogState) {
              return Container(
                width: MediaQuery.of(context).size.width * 0.95,
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Edit $title", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.50,
                      ),
                      child: SingleChildScrollView(
                        child: GenderCardSelector(
                          selectedValue: tempGender, // 👈 Use temporary value
                          onChanged: (localGender) {
                            setDialogState(() {
                              tempGender = localGender; // 👈 Only update local temporary value
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        // ❌ Cancel → discard changes
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context), // No update to main state
                            child: const Text("Cancel"),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // ✅ Save → apply selected tempGender
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                gender = tempGender;
                                _selectedGender = tempGender.toLowerCase();
                                isModified = true;
                              });

                              Navigator.pop(context);
                            },
                            child: const Text("Save"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }




  String? _dobErrorMsg; // <-- add this as a field in your State class
  DateTime _parseDobString(String dobStr) {
    // expecting DD/MM/YYYY
    final parts = dobStr.split('/');
    if (parts.length != 3) {
      throw FormatException("Invalid DOB format. Expected DD/MM/YYYY");
    }

    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);

    return DateTime(year, month, day);
  }
  void _editDateOfBirth(String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(
                "Edit $title",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.92,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DOBField(
                      hintText: "Enter your DOB (MM/DD/YYYY)",
                      controller: _dobController,
                      onChanged: (val) {
                        // clear inline error when user types
                        setDialogState(() {
                          _dobErrorMsg = null;
                        });
                      },
                    ),

                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _dobController.text = dob;
                          _dobErrorMsg = null;
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          backgroundColor: Colors.white,
                        ),
                        child: const Text("Cancel", style: TextStyle(color: Colors.black)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // 1. basic format validation using your existing util
                          if (!UserUtils.validateDob(_dobController.text)) {
                            setDialogState(() {
                              _dobErrorMsg = "Please enter a valid date";
                            });
                            return;
                          }

                          // 2. age validation (must be >= 18)
                          late DateTime dobDate;
                          try {
                            dobDate = _parseDobString(_dobController.text);
                          } catch (_) {
                            setDialogState(() {
                              _dobErrorMsg = "Please enter date in DD/MM/YYYY format";
                            });
                            return;
                          }

                          final today = DateTime.now();
                          int age = today.year - dobDate.year;
                          if (today.month < dobDate.month ||
                              (today.month == dobDate.month && today.day < dobDate.day)) {
                            age--;
                          }

                          if (age < 18) {
                            setDialogState(() {
                              _dobErrorMsg = "Age must be 18 or above";
                            });
                            return;
                          }

                          // 3. save if valid
                          setState(() {
                            dob = _dobController.text;
                            isModified = true;
                            _dobErrorMsg = null;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: const Text("Save"),
                      ),
                    )
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }




  void _editField(String title, String currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 10), // 🔥 Wider space
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

          title: Text(
            "Edit $title",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.92,   // 🔥 increase width (92%)
            child: Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                autovalidateMode: AutovalidateMode.onUserInteraction,

                decoration: InputDecoration(
                  hintText: "Enter $title",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.all(14),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.primaryColor),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.primaryColor),
                  ),
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'This field is required';
                  if (value.trim().length < 3) return 'Minimum 3 characters required';

                  // 🚫 Emoji Restriction
                  if (RegExp(
                      r'[\u{1F600}-\u{1F64F}'
                      r'\u{1F300}-\u{1F5FF}'
                      r'\u{1F680}-\u{1F6FF}'
                      r'\u{2600}-\u{26FF}'
                      r'\u{2700}-\u{27BF}]', unicode: true)
                      .hasMatch(value)) return 'Emojis are not allowed';

                  // ✔ allow only alphanumeric + space
                  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9 ]*$').hasMatch(value)) {
                    return 'Only alphabets, numbers & spaces allowed';
                  }
                  return null;
                },
              ),
            ),
          ),

          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text("Cancel", style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        onSave(controller.text.trim());
                        setState(() => isModified = true);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Save"),
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }


  Widget _buildEditOption(String title, String value, Function(String) onSave) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            title,
            style: TextStyle(fontSize: deviceWidth(context) > 750 ? 25 :  16, color: Colors.black87),
          ),
          subtitle: Text(
            value,
            style: TextStyle(color: Colors.grey, fontSize: deviceWidth(context) > 750 ? 18 :14),
          ),
          trailing: title == "Email" ? const SizedBox(height: 0,width: 0,): Icon(Icons.arrow_forward_ios,
              color: AppTheme.primaryColor, size: deviceWidth(context) > 750 ? 25 :18),
          onTap: () {
            if(title == "Email"){
              return;
            }
            if(title == "Gender"){
              return _editGender(title);
            }
            if(title == "Date of birth"){
              return _editDateOfBirth(title);
            }
            return  _editField(title, value, onSave);
          },
        ),
        Divider(color: Colors.grey.shade300, height: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userDetailsAsync = ref.watch(userDetailsDataProvider);
    final user = userDetailsAsync.asData?.value;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
              'Edit Profile',
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: Colors.black26,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // AppRouter.replaceWithHome(context);
                        Navigator.pop(context);
                      },
                      child: Image.asset("lib/assets/back_button.png", height: deviceWidth(context) > 750 ? 35 :25, width: deviceWidth(context) > 750 ? 35 :25,),
                    ),
                    SizedBox(height: 10),
                    Text("Personal Info",
                        style: TextStyle(
                            fontSize: deviceWidth(context) > 750 ? 30 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    const SizedBox(height: 16),
                    _buildEditOption("Full name", fullName, (val) {
                      setState(() => fullName = val);
                    }),
                    _buildEditOption("Gender", gender, (val) {
                      setState(() => gender = val);
                    }),
                    _buildEditOption("Date of birth", dob, (val) {
                      setState(() => dob = val);
                    }),
                    _buildEditOption("Email", email, (val) {
                      setState(() => email = val);
                    }),
                    const SizedBox(height: 10),
                    Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: IntlPhoneField(
                        autofocus: false,
                        controller: _phoneController,
                        focusNode: _phoneFocus,
                        initialCountryCode: _initialCountryCode,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        // ✅ SELECTED COUNTRY (FLAG + CODE) FONT SIZE
                        dropdownTextStyle: TextStyle(
                          fontSize: deviceWidth(context) > 750 ? 22 : 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),

                        // ✅ DROPDOWN ICON SIZE
                        dropdownIcon: Icon(
                          Icons.arrow_drop_down,
                          size: deviceWidth(context) > 750 ? 34 : 26,
                        ),
                        dropdownIconPosition: IconPosition.trailing,

                        // ✅ COUNTRY PICKER LIST FONT SIZE (THIS FIXES YOUR ISSUE)
                        pickerDialogStyle: PickerDialogStyle(
                          searchFieldInputDecoration: InputDecoration(
                            hintText: 'Search country',
                            hintStyle: TextStyle(
                              fontSize: deviceWidth(context) > 750 ? 20 : 14,
                            ),
                            suffixIcon: Icon(
                              Icons.search, // 🔍 SEARCH ICON
                              size: deviceWidth(context) > 750 ? 28 : 22,
                              color: Colors.grey,
                            ),
                          ),
                          countryNameStyle: TextStyle(
                            fontSize: deviceWidth(context) > 750 ? 20 : 14,
                          ),
                          countryCodeStyle: TextStyle(
                            fontSize: deviceWidth(context) > 750 ? 18 : 13,
                            color: Colors.grey,
                          ),
                        ),
                        decoration: InputDecoration(
                          hintText: "Enter your phone number",
                          hintStyle: TextStyle(fontSize: deviceWidth(context) > 750 ? 20 : 15, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          isDense: true,
                          //suffixIcon: Icon(Icons.phone, color: Colors.grey),
                        ),
                        // dropdownIcon: const Icon(Icons.arrow_drop_down),
                        // dropdownIconPosition: IconPosition.trailing,
                        validator: (phoneNumber) {
                          debugPrint('${phoneNumber!.isValidNumber()}');
                          if (phoneNumber == null || phoneNumber.number.isEmpty) {
                            return 'Phone number is required';
                          }
                          if (_selectedCountryCode == null || _selectedCountryCode!.isEmpty) {
                            return 'Please select a country code';
                          }
                          if (!phoneNumber!.isValidNumber()) {
                            return 'Please enter correct number';
                          }

                          return null;
                        },
                        onChanged: (phoneNumber) {
                          debugPrint("${phoneNumber!.isValidNumber()}");
                          setState(() {
                            phone = phoneNumber.number;
                            _selectedCountryCode = phoneNumber.countryCode;
                            _selectedCompletePhoneNumber = phoneNumber.completeNumber;
                            selectedPhoneNumber = phoneNumber;
                          });
                        },
                        onCountryChanged: (country) {
                          debugPrint("country 663 @@ code ${country.code} rc ${country.regionCode}"
                              "name ${country.name}");
                          setState(() {
                            _selectedCountryCode = "+${country.dialCode}";
                            _initialCountryCode = country.code;
                            _selectedCompletePhoneNumber =
                                _selectedCountryCode! + _phoneController.text;
                          });
                        },
                        onSaved: (details) {
                          debugPrint("On Saved ${details?.completeNumber}");
                        },
                        onSubmitted: (_) => _phoneFocus.unfocus(),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                          // debugPrint("Edited valid phone ${selectedPhoneNumber!.isValidNumber()} isModified ${isModified}");
                          if ((selectedPhoneNumber == null || !selectedPhoneNumber!.isValidNumber()) &&
                              (isModified == null || !isModified!)) {
                            return;
                          }

                          // 🔑 Run form validation before saving
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            _saveProfile();
                          } else {
                            // Optional: show a red snackbar if you want extra feedback
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fix the errors before saving')),
                            );
                          }
                        },
                        style: ((selectedPhoneNumber?.isValidNumber() ?? false) || (isModified ?? false)) ?
                        ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ):
                        ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )

                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
