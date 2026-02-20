import 'dart:convert';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/models/userdetails.dart';
import 'package:heart_thrive/providers/token_provider.dart';
import 'package:heart_thrive/providers/user/user_details_provider.dart';
import 'package:heart_thrive/utils/secure_storage_utils.dart';
import 'package:http/http.dart' as http;
import '../../components/action_menu.dart';
import '../../core/api_endpoints.dart';
import '../../models/symptoms/symptoms_model.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import 'custom_symptoms_widget.dart';

class AddSymptomsScreen extends ConsumerStatefulWidget {
  final SymptomModel? symptomModel;
  final bool? isEdit;
  final bool? isHome;

  const AddSymptomsScreen({super.key, this.symptomModel, this.isEdit, this.isHome});

  @override
  ConsumerState<AddSymptomsScreen> createState() => _AddSymptomsScreenState();
}

class _AddSymptomsScreenState extends ConsumerState<AddSymptomsScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _customSymptomFocus = FocusNode();

  final TextEditingController symptomController = TextEditingController();
  String? swellingToLegs;
  String? shortOfBreathWithActivity;
  String? shortOfBreathWhenLyingFlat;
  String? wakingUpAtNightShortOfBreath;

  String? swellingToLegsError;
  String? shortOfBreathWithActivityError;
  String? shortOfBreathWhenLyingFlatError;
  String? wakingUpAtNightShortOfBreathError;

  bool isLoading = false;
  bool isKeyBoardOpen = false;
  String? customSymptomError;

  final List<String> options = const ["Mild", "Moderate", "Severe"];

  @override
  void initState() {
    super.initState();

    _customSymptomFocus.addListener(() {
      if (_customSymptomFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 250), _scrollToField);
      }
    });

    prefillData();

    WidgetsBinding.instance.addObserver(this);
  }

  void _scrollToField() {
    if (_customSymptomFocus.context != null) {
      Scrollable.ensureVisible(
        _customSymptomFocus.context!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.4, // slightly above center
      );
    }
  }

  void prefillData() {
    if (widget.isEdit == true) {
      setState(() {
        swellingToLegs = widget.symptomModel?.swellingToLegs;
        shortOfBreathWithActivity = widget.symptomModel?.shortOfBreathWithActivity;
        shortOfBreathWhenLyingFlat = widget.symptomModel?.shortOfBreathWhenLyingFlat;
        wakingUpAtNightShortOfBreath = widget.symptomModel?.wakingUpAtNightShortOfBreath;
        symptomController.text = widget.symptomModel?.customSymptom ?? '';
      });
    }
  }

  void _validateAndSubmit() async {
    final customText = symptomController.text.trim();

    /// 🔥 Reset all errors first
    setState(() {
      swellingToLegsError = null;
      shortOfBreathWithActivityError = null;
      shortOfBreathWhenLyingFlatError = null;
      wakingUpAtNightShortOfBreathError = null;
      customSymptomError = null;
    });

    /// --------------------------------------------------
    /// ✅ Custom symptom validation
    /// --------------------------------------------------
    if (customText.isNotEmpty && customText.length < 3) {
      setState(() {
        customSymptomError = "Minimum 3 characters required";
      });
      return; // 🚫 STOP SAVE
    }

    /// --------------------------------------------------
    /// ✅ At least one symptom required
    /// --------------------------------------------------
    final hasDropdownSymptom =
        swellingToLegs != null ||
            shortOfBreathWithActivity != null ||
            shortOfBreathWhenLyingFlat != null ||
            wakingUpAtNightShortOfBreath != null;

    if (!hasDropdownSymptom && customText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one symptom or enter a custom symptom."),
          backgroundColor: Colors.red,
        ),
      );
      return; // 🚫 STOP SAVE
    }

    /// --------------------------------------------------
    /// ✅ Start loading only after validation passes
    /// --------------------------------------------------
    setState(() => isLoading = true);

    final token = await SecureStorageUtils().read(StorageKeys.accessToken);
    UserDetails? userDetails = ref.read(userDetailsDataProvider).value;

    final payload = {
      "patientId": userDetails?.id,
      "swellingToLegs": swellingToLegs,
      "shortOfBreathWithActivity": shortOfBreathWithActivity,
      "shortOfBreathWhenLyingFlat": shortOfBreathWhenLyingFlat,
      "wakingUpAtNightShortOfBreath": wakingUpAtNightShortOfBreath,
      "customSymptoms": customText,
    };

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http
          .post(
        Uri.parse(ApiEndpoints.createPatientSymptoms),
        body: jsonEncode(payload),
        headers: headers,
      )
          .timeout(const Duration(seconds: 30));

      setState(() => isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessMsgPopup(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Something went wrong: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearAll() {
    setState(() {
      swellingToLegs = null;
      shortOfBreathWithActivity = null;
      shortOfBreathWhenLyingFlat = null;
      wakingUpAtNightShortOfBreath = null;

      swellingToLegsError = null;
      shortOfBreathWithActivityError = null;
      shortOfBreathWhenLyingFlatError = null;
      wakingUpAtNightShortOfBreathError = null;

      symptomController.clear();
    });
  }

  void _showSuccessMsgPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 80, height: 80, child: Image.asset('lib/assets/Check Mark.png')),
              const SizedBox(height: 24),
              const Text(
                'Symptoms added successfully',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6F6C90)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 100,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if(widget.isHome?? true) {
                      AppRouter.replaceWithHome(context);
                    }else{
                      Navigator.pop(context);
                      AppRouter.replaceWithHeartRiskDashboard(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK', style: AppTheme.whiteTitle14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _backTap(BuildContext context) {
    if(widget.isHome?? true) {
      AppRouter.replaceWithHome(context);
    }else{
      Navigator.pop(context);
    }
  }

  @override
  void didChangeMetrics() {
    final viewInsets = MediaQueryData.fromView(View.of(context)).viewInsets;
    print("viewInsets @@ $viewInsets");
    final newIsOpen = viewInsets.bottom > 0;
    if (newIsOpen != isKeyBoardOpen) {
      setState(() {
        isKeyBoardOpen = newIsOpen;
      });

      if (newIsOpen) {
        Future.delayed(const Duration(milliseconds: 150), () {
          _scrollToField();
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _customSymptomFocus.dispose();
    symptomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQueryData.fromView(View.of(context)).viewInsets.bottom;
    print("keyboardHeight @@ $keyboardHeight");
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (FocusScope.of(context).hasFocus) {
          FocusScope.of(context).unfocus();
          return;
        }

        _backTap(context);
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                title: Center(child: Text("${widget.isEdit == true ? 'Edit' : 'Add'} Symptoms")),
                backgroundColor: const Color(0xFF8C1B1A),
                foregroundColor: Colors.white,
                leading: GestureDetector(
                  onTap: () => _backTap(context),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset("lib/assets/Frame.png"),
                  ),
                ),
                actions: [actionMenuItem(context)],
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Today's Symptoms", style: AppTheme.title18),
                      const SizedBox(height: 20),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDropdown(
                                label: "Swelling to legs",
                                value: swellingToLegs,
                                onChanged: (v) => setState(() {
                                  swellingToLegs = v;
                                  swellingToLegsError = null;
                                }),
                                errorText: swellingToLegsError,
                              ),
                              _buildDropdown(
                                label: "Short of breath with activity",
                                value: shortOfBreathWithActivity,
                                onChanged: (v) => setState(() {
                                  shortOfBreathWithActivity = v;
                                  shortOfBreathWithActivityError = null;
                                }),
                                errorText: shortOfBreathWithActivityError,
                              ),
                              _buildDropdown(
                                label: "Short of breath when lying flat",
                                value: shortOfBreathWhenLyingFlat,
                                onChanged: (v) => setState(() {
                                  shortOfBreathWhenLyingFlat = v;
                                  shortOfBreathWhenLyingFlatError = null;
                                }),
                                errorText: shortOfBreathWhenLyingFlatError,
                              ),
                              _buildDropdown(
                                label: "Waking up at night short of breath",
                                value: wakingUpAtNightShortOfBreath,
                                onChanged: (v) => setState(() {
                                  wakingUpAtNightShortOfBreath = v;
                                  wakingUpAtNightShortOfBreathError = null;
                                }),
                                errorText: wakingUpAtNightShortOfBreathError,
                              ),

                              Padding(
                                padding: const EdgeInsets.all(0.0),
                                child: CustomSymptomInput(
                                  controller: symptomController,
                                  maxLength: 150,
                                  focusNode: _customSymptomFocus,
                                  errorText: customSymptomError,
                                  onChanged: (val) {
                                    final text = val.trim();

                                    if (text.isNotEmpty && text.length < 3) {
                                      setState(() => customSymptomError = "Minimum 3 characters required");
                                    } else {
                                      setState(() => customSymptomError = null);
                                    }
                                  },
                                ),
                              ),

                              const SizedBox(height: 30),

                              LayoutBuilder(
                                builder: (context, constraints) {
                                  double buttonWidth = (constraints.maxWidth - 12) / 2;
                                  buttonWidth = buttonWidth.clamp(120.0, 300.0);
                                  double fontSize = (buttonWidth / 20).clamp(12.0, 16.0);

                                  return Row(
                                    children: [
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: buttonWidth,
                                          maxWidth: buttonWidth,
                                        ),
                                        child: OutlinedButton(
                                          onPressed: _clearAll,
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFF8C1B1A),
                                            side: const BorderSide(color: Color(0xFF8C1B1A)),
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: Text(
                                            "Clear All",
                                            style: AppTheme.title16.copyWith(fontSize: fontSize),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: buttonWidth,
                                          maxWidth: buttonWidth,
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _validateAndSubmit,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primaryColor,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "${widget.isEdit == true ? 'Edit' : 'Add'} Symptoms",
                                                style: AppTheme.title16.copyWith(
                                                  color: Colors.white,
                                                  fontSize: fontSize,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.add_circle, color: Colors.white, size: 16),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),

                      // ← This is the key part: automatically expands with keyboard
                      SizedBox(height: isKeyBoardOpen ? keyboardHeight + 280 : 10),
                    ],
                  ),
                ),
              ),
            ),

            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.title14.copyWith(fontWeight: FontWeight.normal),
        ),
        const SizedBox(height: 8),

        DropdownButtonHideUnderline(
          child: DropdownButton2<String>(
            isExpanded: true,
            hint: Text(
              "Select",
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
            ),
            value: value,
            items: options.map((item) {
              final isSelected = value == item;
              return DropdownMenuItem<String>(
                value: item,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            selectedItemBuilder: (context) => options.map((item) {
              return Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text(
                  value ?? "Select",
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              );
            }).toList(),
            buttonStyleData: ButtonStyleData(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: errorText != null ? Colors.red : Colors.transparent,
                  width: 1.5,
                ),
              ),
            ),
            iconStyleData: const IconStyleData(
              icon: Icon(Icons.keyboard_arrow_down),
              iconSize: 28,
              iconEnabledColor: Colors.grey,
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
            ),
            menuItemStyleData: const MenuItemStyleData(
              padding: EdgeInsets.zero,
              height: 56,
            ),
          ),
        ),

        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}