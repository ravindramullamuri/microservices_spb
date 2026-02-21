import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../components/custom_text_field.dart';
import '../components/custom_button.dart';
import '../components/back_button.dart';
import '../routes/app_router.dart';
import '../components/success_popup.dart';

class RegisterAsDoctorPage extends StatefulWidget {
  const RegisterAsDoctorPage({Key? key}) : super(key: key);

  @override
  State<RegisterAsDoctorPage> createState() => _RegisterAsDoctorPageState();
}

class _RegisterAsDoctorPageState extends State<RegisterAsDoctorPage> {
  final TextEditingController _npiController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  final TextEditingController _hospitalNameController = TextEditingController();
  final TextEditingController _hospitalCityController = TextEditingController();
  
  String _selectedState = 'Select State of License';
  bool _agreeToTerms = true;

  @override
  void dispose() {
    _npiController.dispose();
    _licenseNumberController.dispose();
    _hospitalNameController.dispose();
    _hospitalCityController.dispose();
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
            AppRouter.navigateToSignInWithUserType(context, 'doctor');
          },
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                CustomBackButton(
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 24),
                
                // Title
                const Text(
                  'Register as Doctor',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Subtitle
                const Text(
                  'Help us verify your identity and connect with patients',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Progress Indicator
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // NPI Number Field
                CustomTextField(
                  controller: _npiController,
                  hintText: 'Enter your NPI number*',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                
                // State of License Dropdown
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedState,
                      isExpanded: true,
                      items: [
                        'Select State of License',
                        'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California',
                        'Colorado', 'Connecticut', 'Delaware', 'Florida', 'Georgia',
                        'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa',
                        'Kansas', 'Kentucky', 'Louisiana', 'Maine', 'Maryland',
                        'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi', 'Missouri',
                        'Montana', 'Nebraska', 'Nevada', 'New Hampshire', 'New Jersey',
                        'New Mexico', 'New York', 'North Carolina', 'North Dakota', 'Ohio',
                        'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island', 'South Carolina',
                        'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont',
                        'Virginia', 'Washington', 'West Virginia', 'Wisconsin', 'Wyoming'
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(
                              color: value == 'Select State of License' 
                                  ? Colors.grey.shade600 
                                  : Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedState = newValue!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // License Number Field
                CustomTextField(
                  controller: _licenseNumberController,
                  hintText: 'Enter your license number*',
                ),
                const SizedBox(height: 16),
                
                // Hospital/Clinic Name Field
                CustomTextField(
                  controller: _hospitalNameController,
                  hintText: 'Enter your hospital or clinic name*',
                ),
                const SizedBox(height: 16),
                
                // Hospital/Clinic City Field
                CustomTextField(
                  controller: _hospitalCityController,
                  hintText: 'Enter your hospital or clinic city',
                ),
                const SizedBox(height: 24),
                
                // Terms and Conditions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (bool? value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    const Expanded(
                      child: Text(
                        'I agree to the health thrive Terms of Service and Privacy Policy',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Sign Up Button
                CustomButton(
                  text: 'Sign Up',
                  onPressed: () {
                    _showSuccessPopup();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
