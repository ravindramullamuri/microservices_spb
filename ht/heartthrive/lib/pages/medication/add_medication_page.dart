import 'dart:convert';
import 'dart:ui';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/components/action_menu.dart';
import 'package:heart_thrive/components/time_12h_formatter.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import 'package:heart_thrive/core/api_endpoints.dart';
import 'package:heart_thrive/routes/app_router.dart';
import 'package:heart_thrive/services/home/risk_meter_service.dart';
import 'package:heart_thrive/services/medication_services.dart';
import 'package:heart_thrive/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../components/dob_calendar.dart';
import '../../models/medication/medication_model.dart';
import '../../providers/bmi/notification_provider.dart';
import '../../providers/medication/medication_provider.dart';
import '../../utils/component_utils.dart';

class AddMedicationPage extends StatefulWidget {
  final bool isEditMode;
  final bool myMedicationEditMode;
  final MedicationModel? medicationData;
  final bool customMode;
  final int medPeriod;

  const AddMedicationPage({
    Key? key,
    this.medPeriod = 0,
    this.isEditMode = false,
    this.medicationData,
    this.myMedicationEditMode = false,
    this.customMode = false,
  }) : super(key: key);

  @override
  State<AddMedicationPage> createState() => _AddMedicationPageState();
}

class _AddMedicationPageState extends State<AddMedicationPage> {
  // Form controllers
  final TextEditingController _medicationNameController =
      TextEditingController();
  final TextEditingController _medicationBrandController =
      TextEditingController();
  final TextEditingController _doseController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  // Selected days
  List<bool> selectedDays = [false, false, false, false, false, false, false];
  bool _addToMedicationList = true;
  bool _updateToMedicationList = true;

  // Medication period checkboxes
  bool _morningSelected = false;
  bool _afternoonSelected = false;
  bool _eveningSelected = false;
  bool _selectAllSelected = false;
  bool _previewVisibility = true;
  String? _currentPeriodLabel;
  bool? _isLoading = false;
  bool _isSaving = false; // show blur + loader while saving
  final _formKey = GlobalKey<FormState>();

  // Dropdown values
  String _selectedIntake = '';
  String _selectedFrequency = '';
  int _maxDaysAllowed = 7;

  Duration? _morningTime;
  Duration? _afternoonTime;
  Duration? _eveningTime;

  void _setPeriodSelection() {
    _morningSelected = widget.medPeriod == 1;
    _afternoonSelected = widget.medPeriod == 2;
    _eveningSelected = widget.medPeriod == 3;
  }

  @override
  void initState() {
    super.initState();
    _setPeriodSelection();
    // BackButtonInterceptor.add(_addMedicationBackHandler);
    // If editing / viewing existing schedule, load details
    if (widget.isEditMode && widget.medicationData?.scheduleUuid != null) {
      _loadMedicationDetails(widget.medicationData!.scheduleUuid!);
    } else if (widget.medicationData?.scheduleUuid != null &&
        widget.isEditMode == false) {
      // If medicationData passed but not in edit mode (your original condition)
      _loadSearchData();
    }

    // If myMedicationEditMode, prefill fields from medicationData quickly
    if (widget.myMedicationEditMode && widget.medicationData != null) {
      _prefillFromMedication(widget.medicationData!);
    } else {
      // Defaults for new medication (only when fields empty)
      final today = DateTime.now();
      if (_startDateController.text.isEmpty) {
        _startDateController.text =
            "${today.month.toString().padLeft(2, '0')}/${today.day.toString().padLeft(2, '0')}/${today.year}";
      }
      final after30 = today.add(const Duration(days: 30));
      if (_endDateController.text.isEmpty) {
        _endDateController.text =
            "${today.month.toString().padLeft(2, '0')}/${today.day.toString().padLeft(2, '0')}/${today.year}";
      }
      //if (_selectedFrequency.isEmpty) _selectedFrequency = 'Daily';
      //if (_selectedIntake.isEmpty) _selectedIntake = 'Before meal';
    }
  }


  void _prefillFromMedication(MedicationModel med) {
    // Batch updates with a single setState where possible
    setState(() {
      _medicationNameController.text = med.medicationName ?? '';
      _medicationBrandController.text = med.medicationBrand ?? '';
      _doseController.text = med.doseDescription ?? '';
      _startDateController.text = med.startDate != null
          ? formatMonthApiDateToDisplay(med.startDate!)
          : '';
      _endDateController.text = med.endDate != null
          ? formatMonthApiDateToDisplay(med.endDate!)
          : '';
      _selectedFrequency = med.dosageFrequency ?? '';
      _selectedIntake = (med.isAfterMeal ?? false)
          ? 'After meal'
          : 'Before meal';

      _morningSelected = med.isMorning ?? false;
      _afternoonSelected = med.isAfterNoon ?? false;
      _eveningSelected = med.isEvening ?? false;

      debugPrint(
        '115 @@ M :$_morningSelected A :$_afternoonSelected E: $_eveningSelected',
      );

      if (med.daysOfWeek != null) {
        const dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        final daysFromData = (med.daysOfWeek as List)
            .map((e) => e.toString().toLowerCase())
            .toList();
        selectedDays = List.generate(
          7,
          (i) => daysFromData.contains(dayNames[i].toLowerCase()),
        );
      }

      if (med.morningTime != null) {
        final t = med.morningTime!.split(':');
        final h = int.parse(t[0]);

        final m = int.parse(t[1]);

        final s = t.length > 2 ? int.parse(t[2]) : 0;

        _morningTime = Duration(hours: h, minutes: m, seconds: s);
      }
      if (med.afternoonTime != null) {
        final t = med.afternoonTime!.split(':');
        final h = int.parse(t[0]);

        final m = int.parse(t[1]);

        final s = t.length > 2 ? int.parse(t[2]) : 0;

        _afternoonTime = Duration(hours: h, minutes: m, seconds: s);
      }
      if (med.eveningTime != null) {
        final t = med.eveningTime!.split(':');
        final h = int.parse(t[0]);

        final m = int.parse(t[1]);

        final s = t.length > 2 ? int.parse(t[2]) : 0;

        _eveningTime = Duration(hours: h, minutes: m, seconds: s);
      }

      _selectAllSelected =
          _morningSelected && _afternoonSelected && _eveningSelected;
    });
  }

  Future<void> _loadSearchData() async {
    setState(() => _isLoading = true);
    if (widget.medicationData != null) {
      setState(() {
        _medicationNameController.text =
            widget.medicationData!.medicationName ?? '';
        _medicationBrandController.text =
            widget.medicationData!.medicationBrand ?? '';
        _doseController.text = widget.medicationData!.doseDescription ?? '';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMedicationDetails(String scheduleUuid) async {
    setState(() => _isLoading = true);

    final data = await MedicationService.fetchMedicationScheduleByUuid(
      scheduleUuid,
    );

    if (data != null) {
      _prefillFromMedication(data);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load medication details')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  bool isValidMMDDYYYY(String value) {
    try {
      // Strict regex check
      final regex = RegExp(r'^(0[1-9]|1[0-2])\/(0[1-9]|[12][0-9]|3[01])\/\d{4}$');
      if (!regex.hasMatch(value)) return false;

      // Real date validation (catches 02/30 etc.)
      final parsed = DateFormat('MM/dd/yyyy').parseStrict(value);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool get _areDatesValid {
    return isValidMMDDYYYY(_startDateController.text) &&
        isValidMMDDYYYY(_endDateController.text);
  }



  @override
  void dispose() {
    // BackButtonInterceptor.remove(_addMedicationBackHandler);
    _medicationNameController.dispose();
    _medicationBrandController.dispose();
    _doseController.dispose();
    _timeController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _editMedication(ref) async {
    // Convert selectedDays (bool list) to day names
    const dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    List<String> selectedDayNames = [
      for (int i = 0; i < selectedDays.length; i++)
        if (selectedDays[i]) dayNames[i],
    ];

    // Form validation
    if (!_formKey.currentState!.validate()) return;
    // Weekly once/twice/thrice validation
    int selectedCount = selectedDays.where((e) => e).length;
    if (_selectedFrequency != "Daily" && selectedCount > _maxDaysAllowed) {
      _showErrorDialog(
        "You can select only $_maxDaysAllowed day(s) for $_selectedFrequency",
      );
      return;
    }
    if (!_validateSelectedTimes(context)) return;
    final parsedDate = DateFormat('MM/dd/yyyy').parse(_startDateController.text.trim());
    final startDate = DateFormat('MM-dd-yyyy').format(parsedDate);
    final parsedEndDate = DateFormat('MM/dd/yyyy').parse(_endDateController.text.trim());
    final endDate = DateFormat('MM-dd-yyyy').format(parsedEndDate);

    setState(() => _isSaving = true);
    try {
      bool success = await MedicationService.updateMedicationSchedule(
        scheduleUuid: widget.medicationData!.scheduleUuid!,
        startDate: startDate,
        endDate: endDate,
        morning: _morningSelected,
        afternoon: _afternoonSelected,
        evening: _eveningSelected,
        morningTime: _morningTime,
        afternoonTime: _afternoonTime,
        eveningTime: _eveningTime,
        isAfterMeal: _selectedIntake == 'After meal',
        doseDescription: _doseController.text.trim(),
        dosageFrequency: _selectedFrequency,
        daysOfWeek: selectedDayNames,
        isUpdateToMyMedication: _updateToMedicationList,
      );

      if (success) {
        refreshMedicationData(ref);
        _showSaveMedicationPopup(context);
      } else {
        _showErrorDialog('Failed to update medication.');
      }
    } catch (e) {
      debugPrint('❌ Error updating medication: $e');
      _showErrorDialog(
        'An unexpected error occurred while updating medication.',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveMedication(
    ref, {
    bool updateInMenu = false,
    String? menuUuid,
  }) async {
    // Form validation
    if (!_formKey.currentState!.validate()) return;
    // Weekly once/twice/thrice validation
    int selectedCount = selectedDays.where((e) => e).length;
    if (_selectedFrequency != "Daily" && selectedCount > _maxDaysAllowed) {
      _showErrorDialog(
        "You can select only $_maxDaysAllowed day(s) for $_selectedFrequency",
      );
      return;
    }

    if (!_validateSelectedTimes(context)) return;

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _showErrorDialog('Authentication token not found.');
        return;
      }

      // Helper: Convert DD/MM/YYYY → YYYY-MM-DD
      String _convertToApiDate(String input) {
        try {
          final parts = input.split('/');
          if (parts.length == 3) {
            final day = parts[0].padLeft(2, '0');
            final month = parts[1].padLeft(2, '0');
            final year = parts[2];
            return '$month-$day-$year';
          }
        } catch (_) {}
        return input;
      }

      // Helper: Format TimeOfDay → HH:mm:ss
      String _formatTime(TimeOfDay time) {
        final hours = time.hour.toString().padLeft(2, '0');
        final minutes = time.minute.toString().padLeft(2, '0');
        return '$hours:$minutes:00';
      }

      // Determine flag
      Map<String, dynamic> getMedicationListFlag() {
        if (widget.myMedicationEditMode) {
          return {"isAddToMyMedication": _addToMedicationList};
        } else if (widget.isEditMode) {
          return {"isUpdateMyMedication": _updateToMedicationList};
        } else {
          return {"isAddToMyMedication": _addToMedicationList};
        }
      }

      // Prepare request body
      debugPrint("Start Date  377 @@ ${_startDateController.text}");
      final parsedDate = DateFormat('MM/dd/yyyy').parse(_startDateController.text.trim());
      final startDate = DateFormat('MM-dd-yyyy').format(parsedDate);
      final parsedEndDate = DateFormat('MM/dd/yyyy').parse(_endDateController.text.trim());
      final endDate = DateFormat('MM-dd-yyyy').format(parsedEndDate);
      final body = {
        "medicationUuid": widget.medicationData?.medicationUuid ?? '',
        "medicationName": _medicationNameController.text.trim(),
        "medicationBrand": _medicationBrandController.text.trim(),
        "startDate": startDate,
        "endDate": endDate,
        "morning": _morningSelected,
        "afternoon": _afternoonSelected,
        "evening": _eveningSelected,
        "morningTime": _morningTime != null
            ? formatDurationHMS(_morningTime!)
            : null,
        "afternoonTime": _afternoonTime != null
            ? formatDurationHMS(_afternoonTime!)
            : null,
        "eveningTime": _eveningTime != null
            ? formatDurationHMS(_eveningTime!)
            : null,
        "afterMeal": _selectedIntake.toLowerCase() == 'after meal',
        "doseDescription": _doseController.text.trim(),
        "dosageFrequency": _selectedFrequency,
        "daysOfWeek": _getSelectedDaysList(),
        ...getMedicationListFlag(),
      };

      final addUrl = Uri.parse(ApiEndpoints.medicationsAdd);
      debugPrint("321 @@@ ${jsonEncode(body)}");
      final addResponse = await http
          .post(
            addUrl,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode(body),
          )
          .timeout(timeoutDuration);

      if (addResponse.statusCode == 200 || addResponse.statusCode == 201) {
        debugPrint('addResponse @@@ ${addResponse.body}');
        refreshMedicationData(ref);
        _showSaveMedicationPopup(context);

        // Optional menu update
        if (updateInMenu && menuUuid != null) {
          final updateBody = {
            "doseDescription": _doseController.text.trim(),
            "morningTime": _morningTime != null
                ? formatDurationHMS(_morningTime!)
                : null,
            "notes": "",
          };

          final updateUrl = Uri.parse(
            ApiEndpoints.medicationMenuByUUID(menuUuid),
          );

          final updateResponse = await http
              .put(
                updateUrl,
                headers: {
                  "Content-Type": "application/json",
                  "Authorization": "Bearer $token",
                },
                body: jsonEncode(updateBody),
              )
              .timeout(timeoutDuration);

          if (updateResponse.statusCode == 200) {
            // nothing extra (already showed saved popup)
          } else {
            _showErrorDialog('Failed to update menu item. Please try again.');
          }
        }
      } else {
        final message = (addResponse.body.isNotEmpty)
            ? (json.decode(addResponse.body)['message'] ??
                  'Something went wrong')
            : 'Something went wrong';
        _showErrorDialog(
          'Failed to save medication. Please try again with a different one.',
        );
      }
    } catch (e) {
      debugPrint('❌ Error saving medication: $e');
      _showErrorDialog('Error saving medication. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // 🩺 Helper for showing error popup
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Error',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ✅ Helper for success popup
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Success',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => AppRouter.replaceWithAllMedication(context),
            child: Container(
              height: 30,
              width: 70,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Center(
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getSelectedDaysList() {
    List<String> days = [];
    const dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    for (int i = 0; i < selectedDays.length; i++) {
      if (selectedDays[i]) {
        days.add(dayNames[i]);
      }
    }
    return days;
  }

  /// Converts a date string from "YYYY-MM-DD" to "DD/MM/YYYY"
  String formatApiDateToDisplay(String apiDate) {
    try {
      final parts = apiDate.split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final month = parts[1].padLeft(2, '0');
        final day = parts[2].padLeft(2, '0');
        return '$day/$month/$year';
      }
    } catch (_) {}
    return apiDate; // fallback to original if parsing fails
  }
  String formatMonthApiDateToDisplay(String apiDate) {
    final DateTime parsedDate = DateTime.parse(apiDate);
    return DateFormat('MM/dd/yyyy').format(parsedDate);
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    DateTime initialDate = DateTime.now();
    try {
      final parts = controller.text.split('/');
      if (parts.length == 3) {
        initialDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        controller.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Widget _buildDateField(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:  TextStyle(
            fontSize:deviceWidth(context) > 750 ? 20 : 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DOBField(
          allowFutureDates: true,
          hintText: "MM/DD/YYYY",
          controller: controller,
          onChanged: (val) {},
          isMyMedList: true,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPeriodCheckbox(
    String label,
    bool value,
    Function(bool?) onChanged,
  ) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
        ),
        Text(
          label,
          style: TextStyle(fontSize:deviceWidth(context) > 750 ? 20 : 14, color: Colors.black87),
        ),
      ],
    );
  }

  Future<Duration?> _selectTime(
    BuildContext context,
    String period, {
    Duration? initial,
  }) async {
    // Convert initial Duration → 12H time + AM/PM
    int totalMinutes = (initial ?? const Duration(hours: 9)).inMinutes;
    int hour24 = totalMinutes ~/ 60;
    int minute = totalMinutes % 60;

    int hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12;

    bool isPM = hour24 >= 12;

    int selectedHour = hour12;
    int selectedMinute = minute;
    bool selectedIsPM = isPM;

    final result = await showDialog<Duration>(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$period',
                  style: TextStyle(fontSize: deviceWidth(context) > 750 ? 25 :18, fontWeight: FontWeight.w600),
                ),
                SizedBox(
                  height: 180,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Hour picker (1–12)
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 32,
                          scrollController: FixedExtentScrollController(
                            initialItem: selectedHour - 1,
                          ),
                          onSelectedItemChanged: (i) {
                            selectedHour = i + 1;
                          },
                          children: List.generate(
                            12,
                            (i) => Center(
                              child: Text(
                                "${i + 1}",
                                style:  TextStyle(fontSize:deviceWidth(context) > 750 ? 24 : 18),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Colon :
                      Text(":", style: TextStyle(fontSize: deviceWidth(context) > 750 ? 38 :28)),

                      // Minute picker (00–59)
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 32,
                          scrollController: FixedExtentScrollController(
                            initialItem: selectedMinute,
                          ),
                          onSelectedItemChanged: (i) {
                            selectedMinute = i;
                          },
                          children: List.generate(
                            60,
                            (i) => Center(
                              child: Text(
                                i.toString().padLeft(2, '0'),
                                style: TextStyle(fontSize: deviceWidth(context) > 750 ? 24 :18),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // AM/PM picker
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 32,
                          scrollController: FixedExtentScrollController(
                            initialItem: isPM ? 1 : 0,
                          ),
                          onSelectedItemChanged: (i) {
                            selectedIsPM = (i == 1);
                          },
                          children: [
                            Center(
                              child: Text("AM", style: TextStyle(fontSize: deviceWidth(context) > 750 ? 24 :18)),
                            ),
                            Center(
                              child: Text("PM", style: TextStyle(fontSize: deviceWidth(context) > 750 ? 24 :18)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: Padding(
                        padding:  EdgeInsets.symmetric(horizontal: deviceWidth(context) > 750 ? 16.0 :8.0),
                        child: Text("Cancel", style: TextStyle(fontSize: deviceWidth(context) > 750 ? 20 :14),),
                      ),
                    ),
                    ElevatedButton(
                      child: Padding(
                        padding:  EdgeInsets.symmetric(horizontal: deviceWidth(context) > 750 ? 16.0 :8.0),
                        child: Text("Save", style: TextStyle( fontSize: deviceWidth(context) > 750 ? 20 : 14),),
                      ),
                      onPressed: () {
                        // Convert 12H → 24H format
                        int finalHour = selectedHour % 12;
                        if (selectedIsPM) finalHour += 12; // PM handling
                        if (!selectedIsPM && selectedHour == 12)
                          finalHour = 0; // 12 AM = 00

                        final duration = Duration(
                          hours: finalHour,
                          minutes: selectedMinute,
                        );

                        Navigator.pop(context, duration);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    // update UI
    if (result != null) {
      _timeController.text = formatTo12Hour(result); // your 12H formatter
    }

    return result;
  }

  String get _nextPeriodLabel {
    if (_morningSelected && _morningTime == null) return 'Morning';
    if (_afternoonSelected && _afternoonTime == null) return 'Afternoon';
    if (_eveningSelected && _eveningTime == null) return 'Evening';
    return 'Period';
  }

  bool _validateSelectedTimes(BuildContext context) {
    List<String> missingTimes = [];

    if (_morningSelected && _morningTime == null) missingTimes.add('Morning');
    if (_afternoonSelected && _afternoonTime == null)
      missingTimes.add('Afternoon');
    if (_eveningSelected && _eveningTime == null) missingTimes.add('Evening');

    if (missingTimes.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Incomplete Time Selection'),
          content: Text(
            'You selected ${missingTimes.join(', ')} but haven’t set a time for ${missingTimes.length > 1 ? 'these periods' : 'this period'}. Please set the time(s) before saving.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return false;
    }

    return true;
  }

  bool _validateWeeklyDaySelection() {
    int selectedCount = selectedDays.where((e) => e).length;

    if (_selectedFrequency == "Weekly once" && selectedCount != 1) {
      _showErrorDialog("For Weekly Once, please select exactly 1 day.");
      return false;
    }
    if (_selectedFrequency == "Weekly twice" && selectedCount != 2) {
      _showErrorDialog("For Weekly Twice, please select exactly 2 days.");
      return false;
    }
    if (_selectedFrequency == "Weekly thrice" && selectedCount != 3) {
      _showErrorDialog("For Weekly Thrice, please select exactly 3 days.");
      return false;
    }

    return true; // valid
  }

  Future<void> _selectTimeForSelectedPeriodsOld(BuildContext context) async {
    final List<String> periods = ['Morning', 'Afternoon', 'Evening'];

    for (String period in periods) {
      // Skip if this period is not selected
      bool isSelected =
          (period == 'Morning' && _morningSelected) ||
          (period == 'Afternoon' && _afternoonSelected) ||
          (period == 'Evening' && _eveningSelected);

      if (!isSelected) continue;

      Duration? picked;

      while (true) {
        // Pick time
        picked = await _selectTime(
          context,
          period,
          initial: const Duration(hours: 9),
        );

        // User cancelled → stop everything
        if (picked == null) {
          setState(() {
            _currentPeriodLabel = null;
            _timeController.clear();
          });
          return;
        }

        // Validate
        if (_isValidPeriodTime(period, picked)) {
          // VALID → save & move to next period
          setState(() {
            if (period == 'Morning') _morningTime = picked;
            if (period == 'Afternoon') _afternoonTime = picked;
            if (period == 'Evening') _eveningTime = picked;

            _timeController.text = formatDurationHMS(picked!);
          });
          break; // go next period
        }

        // INVALID → Show error & repeat SAME period
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please select a valid $period time."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectTimeForSelectedPeriods(BuildContext context) async {
    // 1. Find periods that are selected but have no time yet
    final List<String> pendingPeriods = [];
    if (_morningSelected && _morningTime == null) pendingPeriods.add('Morning');
    if (_afternoonSelected && _afternoonTime == null)
      pendingPeriods.add('Afternoon');
    if (_eveningSelected && _eveningTime == null) pendingPeriods.add('Evening');

    // 2. If there are pending → ask one by one
    if (pendingPeriods.isNotEmpty) {
      for (String label in pendingPeriods) {
        await _pickTimeForPeriod(label); // This handles validation + cancel
        // If user cancels at any point → stop the flow
        if (!_morningSelected && !_afternoonSelected && !_eveningSelected)
          return;
      }
      return;
    }

    // 3. All times are set → show beautiful edit dialog
    final List<Map<String, dynamic>> editable = [];
    if (_morningSelected && _morningTime != null) {
      editable.add({'label': 'Morning', 'time': _morningTime});
    }
    if (_afternoonSelected && _afternoonTime != null) {
      editable.add({'label': 'Afternoon', 'time': _afternoonTime});
    }
    if (_eveningSelected && _eveningTime != null) {
      editable.add({'label': 'Evening', 'time': _eveningTime});
    }

    if (editable.isEmpty) return;

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: AppTheme.primaryColor,
                      size: deviceWidth(context) > 750 ? 30 :26,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Edit Medication Times",
                      style: deviceWidth(context) > 750 ? AppTheme.title20 :AppTheme.title16,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                ...editable.map((p) {
                  final String label = p['label'];
                  final Duration time = p['time'];
                  final String formatted = formatTo12Hour(time);

                  String icon;
                  Color color;
                  if (label == 'Morning') {
                    icon = "lib/assets/Sun.png";
                    color = Colors.amber.shade700;
                  } else if (label == 'Afternoon') {
                    icon = "lib/assets/Dawn.png";
                    color = Colors.lightBlue.shade600;
                  } else {
                    icon = "lib/assets/Vaporwave.png";
                    color = Colors.deepPurple.shade600;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Material(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset(icon, color: color, width: deviceWidth(context) > 750 ? 35 :30),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(label, style: deviceWidth(context) > 750 ? AppTheme.title20 :AppTheme.title16),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatted,
                                    style: AppTheme.title18.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(ctx, p);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.edit_outlined,
                                  color: AppTheme.primaryColor,
                                  size: deviceWidth(context) > 750 ? 30 :22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),
                Center(
                  child: Text(
                    "Tap any time to edit",
                    style: TextStyle(
                      fontSize: deviceWidth(context) > 750 ? 20 :13,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // User cancelled dialog
    if (selected == null) return;

    // This is the ONLY place we call _pickTimeForPeriod when editing
    await _pickTimeForPeriod(selected['label'], initialTime: selected['time']);
  }

  Future<void> _pickTimeForPeriod(String label, {Duration? initialTime}) async {
    while (true) {
      final picked = await _selectTime(
        context,
        label,
        initial: initialTime ?? _getDefaultTimeForPeriod(label),
      );

      // User cancelled → exit safely
      if (picked == null) {
        return;
      }

      // Validate time range
      if (_isValidPeriodTime(label, picked)) {
        setState(() {
          if (label == 'Morning') _morningTime = picked;
          if (label == 'Afternoon') _afternoonTime = picked;
          if (label == 'Evening') _eveningTime = picked;
          _timeController.text = formatTo12Hour(picked);
        });
        return; // Success → exit
      }

      // Invalid time → show error and ask again
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Invalid time for $label. Please choose a valid time."),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Helper: default suggested time per period
  Duration _getDefaultTimeForPeriod(String period) {
    switch (period) {
      case 'Morning':
        return const Duration(hours: 9);
      case 'Afternoon':
        return const Duration(hours: 13);
      case 'Evening':
        return const Duration(hours: 19);
      default:
        return const Duration(hours: 9);
    }
  }

  // Validate The Selected Period Time
  bool _isValidPeriodTime(String period, Duration time) {
    final totalMinutes = time.inMinutes;

    switch (period) {
      case 'Morning':
        // 6:00 AM — 11:59 AM
        return totalMinutes >= 6 * 60 && totalMinutes < 12 * 60;

      case 'Afternoon':
        // 12:00 PM — 4:59 PM
        return totalMinutes >= 12 * 60 && totalMinutes < 17 * 60;

      case 'Evening':
        // 5:00 PM — 11:30 PM
        return totalMinutes >= 17 * 60 && totalMinutes <= 22 * 60;

      default:
        return true;
    }
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return "$h:$m:00";
  }

  Widget _buildPreviewAndReset() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _previewVisibility = !_previewVisibility;
            });
          },
          child: Row(
            children: [
              Icon(
                _previewVisibility ? Icons.visibility : Icons.visibility_off,
                color: AppTheme.primaryColor,
                size: deviceWidth(context) > 750 ? 25 :20,
              ),
              const SizedBox(width: 4),
              Text(
                'Preview',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: deviceWidth(context) > 750 ? 20 :14
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        GestureDetector(
          onTap: _resetTimeSelector,
          child: Row(
            children:  [
              Icon(Icons.refresh, color: AppTheme.primaryColor, size: deviceWidth(context) > 750 ? 25 :20),
              SizedBox(width: 4),
              Text(
                'Reset',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize:deviceWidth(context) > 750 ? 20 :14
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedSlots() {
    List<Widget> slots = [];
    if (_morningSelected && _morningTime != null) {
      slots.add(Text("Morning: ${formatTo12Hour(_morningTime!)}", style: TextStyle(fontSize: deviceWidth(context) > 750 ? 18 :14),));
    }
    if (_afternoonSelected && _afternoonTime != null) {
      slots.add(Text("Afternoon: ${formatTo12Hour(_afternoonTime!)}", style: TextStyle(fontSize: deviceWidth(context) > 750 ? 18 :14)));
    }
    if (_eveningSelected && _eveningTime != null) {
      slots.add(Text("Evening: ${formatTo12Hour(_eveningTime!)}", style: TextStyle(fontSize: deviceWidth(context) > 750 ? 18 :14)));
    }

    return Visibility(
      visible: _previewVisibility,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: AppTheme.primaryColor, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected Slots and Times',
              style: TextStyle(fontWeight: FontWeight.w500,fontSize:  deviceWidth(context) > 750 ? 20 :14),
            ),
            const SizedBox(height: 4),
            if (slots.isEmpty)
               Text(
                'No times selected yet',
                style: TextStyle(color: Colors.grey, fontSize:deviceWidth(context) > 750 ? 16: 12),
              ),
            ...slots,
          ],
        ),
      ),
    );
  }

  Widget _buildIntakeDropdown() {
    final intakeOptions = {
      'Select Medication Intake': 'Select Medication Intake',
      'Before meal': 'Before Meals',
      'After meal': 'After Meals',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medication Intake',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: deviceWidth(context) > 750 ? 20 :14),
        ),
        const SizedBox(height: 8),
        FormField<String>(
          validator: (value) {
            if (_selectedIntake.isEmpty ||
                _selectedIntake == 'Select Medication Intake') {
              return 'Please select medication intake';
            }
            return null;
          },
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    border: Border.all(
                      color: state.hasError ? Colors.red : Colors.grey.shade400,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      highlightColor: AppTheme.primaryColor.withValues(
                        alpha: 0.9,
                      ),
                      hoverColor: AppTheme.primaryColor,
                      focusColor: AppTheme.primaryColor,
                      splashColor: Colors.transparent,
                      canvasColor: Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        value: _selectedIntake.isEmpty ? null : _selectedIntake,
                        hint: Padding(
                          padding: EdgeInsets.all(10),
                          child: Text(
                            'Select Medication Intake',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize:deviceWidth(context) > 750 ? 20 :18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        dropdownStyleData: DropdownStyleData(
                          elevation: 4,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          offset: const Offset(0, 4),
                        ),
                        menuItemStyleData: const MenuItemStyleData(
                          padding: EdgeInsets.zero,
                        ),
                        iconStyleData: const IconStyleData(
                          icon: Icon(
                            CupertinoIcons.chevron_down,
                            color: Colors.grey,
                            size: 18,
                          ),
                        ),
                        items: intakeOptions.entries.map((entry) {
                          final value = entry.key;
                          final label = entry.value;
                          final isSelected = _selectedIntake == value;
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null ||
                              value == 'Select Medication Intake')
                            return;
                          setState(() => _selectedIntake = value);
                        },
                        selectedItemBuilder: (context) {
                          return intakeOptions.entries.map((entry) {
                            final label = entry.value;
                            return Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                ),
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
                if (state.hasError) const SizedBox(height: 6),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Text(
                      state.errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDoseDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dose Description',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: deviceWidth(context) > 750 ? 20 :14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _doseController,
          enabled: widget.customMode ? true : false,
          decoration: _inputDecoration().copyWith(
            hintText: 'Ex:- 50 mg',
            hintStyle: TextStyle(fontSize:deviceWidth(context) > 750 ? 20 : 14),
            filled: true,
            fillColor: Colors.grey.shade100,
            enabledBorder: InputBorder.none,

            // 🔥 Required for showing error text
            errorBorder: const OutlineInputBorder(),
            focusedErrorBorder: const OutlineInputBorder(),
            errorStyle: TextStyle(color: Colors.red, fontSize: 13),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty)
              return 'Dose Description is required';
            if (value.trim().length < 3) return 'Enter at least 3 characters';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildFrequencyDropdown() {
    final frequencyOptions = {
      'Select Medication Intake': 'Select Medication Intake',
      'Daily': 'Daily',
      'Weekly once': 'Weekly Once',
      'Weekly twice': 'Weekly Twice',
      'Weekly thrice': 'Weekly Thrice',
      'Custom': 'Custom',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dosage Frequency',
          style: TextStyle(fontWeight: FontWeight.w500,fontSize: deviceWidth(context) > 750 ? 20 :14),
        ),
        const SizedBox(height: 8),
        FormField<String>(
          validator: (value) {
            if (_selectedFrequency.isEmpty ||
                _selectedFrequency == 'Select Medication Intake') {
              return 'Please select medication intake frequency';
            }
            return null;
          },
          builder: (state) {
            final bool showError =
                (state.hasError &&
                (_selectedFrequency.isEmpty ||
                    _selectedFrequency == 'Select Medication Intake'));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    border: Border.all(
                      color: showError ? Colors.red : Colors.grey.shade400,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      highlightColor: AppTheme.primaryColor.withOpacity(0.9),
                      hoverColor: AppTheme.primaryColor,
                      focusColor: AppTheme.primaryColor,
                      splashColor: Colors.transparent,
                      canvasColor: Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        value: _selectedFrequency.isEmpty
                            ? 'Select Medication Intake'
                            : _selectedFrequency,
                        dropdownStyleData: DropdownStyleData(
                          elevation: 4,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          direction: DropdownDirection.textDirection,
                          offset: const Offset(0, 4),
                        ),
                        menuItemStyleData: const MenuItemStyleData(
                          padding: EdgeInsets.zero,
                        ),
                        iconStyleData: const IconStyleData(
                          icon: Icon(
                            CupertinoIcons.chevron_down,
                            color: Colors.grey,
                            size: 18,
                          ),
                        ),
                        items: frequencyOptions.entries.map((entry) {
                          final value = entry.key;
                          final label = entry.value;
                          final isPlaceholder =
                              value == 'Select Medication Intake';
                          return DropdownMenuItem<String>(
                            value: value,
                            enabled: !isPlaceholder,
                            child: StatefulBuilder(
                              builder: (context, setInnerState) {
                                final isSelected = _selectedFrequency == value;
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    label,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: isPlaceholder
                                          ? Colors.grey
                                          : (isSelected
                                                ? Colors.white
                                                : Colors.black),
                                      fontWeight: isPlaceholder
                                          ? FontWeight.w400
                                          : FontWeight.w500,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == 'Select Medication Intake') return;
                          setState(() {
                            _selectedFrequency = value!;
                            if (value == "Daily") {
                              _maxDaysAllowed = 7;
                              // Auto-select all days
                              selectedDays = List.generate(7, (_) => true);
                            } else if (value == 'Weekly once') {
                              _maxDaysAllowed = 1;
                              selectedDays = List.generate(7, (_) => false);
                            } else if (value == 'Weekly twice') {
                              _maxDaysAllowed = 2;
                              selectedDays = List.generate(7, (_) => false);
                            } else if (value == 'Weekly thrice') {
                              _maxDaysAllowed = 3;
                              selectedDays = List.generate(7, (_) => false);
                            } else {
                              _maxDaysAllowed = 7;
                              selectedDays = List.generate(7, (_) => false);
                            }
                            ;
                          });
                        },
                        selectedItemBuilder: (context) {
                          return frequencyOptions.entries.map((entry) {
                            final value = entry.key;
                            final label = entry.value;
                            final isPlaceholder =
                                value == 'Select Medication Intake';
                            return Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: isPlaceholder
                                      ? Colors.grey
                                      : Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                ),
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
                if (showError)
                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Text(
                      state.errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    bool isAllSelected = selectedDays.every((day) => day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12, // horizontal spacing
          runSpacing: 4, // vertical spacing
          children: days.asMap().entries.map((entry) {
            int index = entry.key;
            String day = entry.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: selectedDays[index],
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      int selectedCount = selectedDays.where((e) => e).length;

                      if (value == true) {
                        // user is trying to select a day

                        // If max limit reached, stop user
                        if (_selectedFrequency != "Daily" &&
                            selectedCount >= _maxDaysAllowed) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "You can select only $_maxDaysAllowed day(s) for $_selectedFrequency",
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return; // do not update day
                        }

                        selectedDays[index] = true; // allow selection
                      } else {
                        // unselect always allowed
                        selectedDays[index] = false;
                      }
                    });
                  },
                ),
                Text(
                  day,
                  style: TextStyle(
                    fontSize: deviceWidth(context) > 750 ? 20 :16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        _selectedFrequency == 'Custom' || _selectedFrequency == 'Daily'
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: isAllSelected,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (value) {
                      if (_selectedFrequency == "Custom" ||
                          _selectedFrequency == "Daily") {
                        int selectedCount = selectedDays.where((e) => e).length;
                        if (_selectedFrequency != "Daily" &&
                            selectedCount > _maxDaysAllowed) {
                          _showErrorDialog(
                            "You can select only $_maxDaysAllowed day(s) for $_selectedFrequency",
                          );
                          return;
                        }
                        setState(() {
                          for (int i = 0; i < selectedDays.length; i++) {
                            selectedDays[i] = value ?? false;
                          }
                        });
                      } else {
                        return;
                      }
                    },
                  ),
                  Text(
                    'Select All',
                    style: TextStyle(fontSize: deviceWidth(context) > 750 ? 20 :16, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : SizedBox(),
      ],
    );
  }

  Widget _buildAddToListCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: widget.myMedicationEditMode
              ? _updateToMedicationList
              : _addToMedicationList,
          onChanged: (value) => setState(() {
            if (widget.myMedicationEditMode)
              _updateToMedicationList = value ?? false;
            else
              _addToMedicationList = value ?? false;
          }),
          activeColor: AppTheme.primaryColor,
        ),
        Text(
          widget.myMedicationEditMode
              ? 'Update to My Medication'
              : 'Add to My Medication List',
          style: TextStyle(fontSize: deviceWidth(context) > 750 ? 20 : 16),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _clearAllFields,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Clear All',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: deviceWidth(context) > 750 ? 20 :14
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Consumer(
            builder: (context, ref, _) {
              return ElevatedButton(
                onPressed: () async {
                   if(!_areDatesValid){
                     return;
                   }
                  if (_formKey.currentState!.validate() &&
                      _validateSelectedTimes(context)) {
                    if (!_validateWeeklyDaySelection()) return;
                    if (widget.isEditMode) {
                      await _editMedication(ref);
                    } else {
                      await _saveMedication(ref);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.isEditMode ? 'Edit' : 'Save'} Medication',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: deviceWidth(context) > 750 ? 20 : 14
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.add_circle, color: Colors.white),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _resetTimeSelector() {
    setState(() {
      _morningSelected = false;
      _afternoonSelected = false;
      _eveningSelected = false;
      _selectAllSelected = false;
      _morningTime = null;
      _afternoonTime = null;
      _eveningTime = null;
      _currentPeriodLabel = null;
      _timeController.clear();
    });
  }

  void _clearAllFields() {
    setState(() {
      _medicationNameController.clear();
      _medicationBrandController.clear();
      _doseController.clear();
      _timeController.clear();
      _startDateController.clear();
      _endDateController.clear();
      _selectedIntake = 'Before meal';
      _selectedFrequency = 'Daily';
      selectedDays = [false, false, false, false, false, false, false];
      _morningSelected = false;
      _afternoonSelected = false;
      _eveningSelected = false;
      _selectAllSelected = false;
      _addToMedicationList = false;
    });
  }

  void _showSaveMedicationPopup(BuildContext context) {
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
              SizedBox(
                width: 80,
                height: 80,
                child: Image.asset('lib/assets/Check Mark.png'),
              ),
              const SizedBox(height: 24),
              Text(
                widget.isEditMode ? 'Medication Updated' : 'Medication Saved!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.isEditMode
                    ? 'Your medication details have been updated successfully.'
                    : 'Your medication details have been saved successfully.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6F6C90)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 100,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).pop();
                    AppRouter.replaceWithAllMedication(
                      context,
                      pageType: 'addMedication',
                    );
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

  refreshMedicationData(ref) {
    ref.invalidate(medicationScheduleOverviewProvider);
    ref.invalidate(intakeMedicationSummaryProvider);
    ref.invalidate(riskMetricsFutureProvider);
    ref.invalidate(notificationProvider);
    ref.invalidate(notificationProvider);
    ref.read(notificationProvider.notifier).loadFirstPage();
  }

  @override
  Widget build(BuildContext context) {
    // Layout: keep content centered and constrained to look good on ≥350px
    final screenWidth = MediaQuery.of(context).size.width;
    final double contentWidth = screenWidth < 350
        ? screenWidth * 0.98
        : (screenWidth > 700 ? 700 : screenWidth * 0.95);

    return WillPopScope(
      onWillPop: () async {
        AppRouter.replaceWithAllMedication(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          title: Center(
            child: Text(
              widget.isEditMode ? 'Edit Medication' : 'Add Medication',
            ),
          ),
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image.asset("lib/assets/Frame.png", height: 40),
            ),
          ),
          actions: [actionMenuItem(context)],
        ),
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Medication Name',
                            style: TextStyle(
                              fontSize: deviceWidth(context) > 750 ? 20 :14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _medicationNameController,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r"[a-zA-Z0-9 ]"),
                              ),
                            ],
                            style: TextStyle(
                              fontSize: deviceWidth(context) > 750 ? 20 : 14,
                            ),
                            decoration: _inputDecoration().copyWith(
                              hintText: 'Enter Medication name',
                              hintStyle: TextStyle(color: Colors.grey,fontSize: deviceWidth(context) > 750 ? 20 :14),
                              enabledBorder: InputBorder.none,
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              errorStyle: TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                            enabled: widget.customMode ? true : false,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty)
                                return 'Medication name is required';
                              if (value.trim().length < 3)
                                return 'Enter at least 3 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Medication Brand',
                            style: TextStyle(
                              fontSize: deviceWidth(context) > 750 ? 20 :14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _medicationBrandController,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r"[a-zA-Z0-9 ]"),
                              ),
                            ],
                            style: TextStyle(
                              fontSize: deviceWidth(context) > 750 ? 20 : 14,
                            ),
                            decoration: _inputDecoration().copyWith(
                              hintText: 'Enter Medication brand',
                              hintStyle:  TextStyle(color: Colors.grey,fontSize: deviceWidth(context) > 750 ? 20 :14),
                              enabledBorder: InputBorder.none,
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              errorStyle: TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                            enabled: widget.customMode ? true : false,
                            textAlign: TextAlign.left,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty)
                                return 'Medication brand is required';
                              if (value.trim().length < 3)
                                return 'Enter at least 3 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 110,
                                      child: _buildDateField(
                                        'Start Date',
                                        _startDateController,
                                        validator: (value) {
                                          if (value == null || value.isEmpty)
                                            return 'Start Date is required';
                                          // update End Date validation
                                          if (!isValidMMDDYYYY(value)) {
                                            return 'Invalid date format (MM/DD/YYYY)';
                                          }
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                                _formKey.currentState
                                                    ?.validate();
                                              });
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 110,
                                      child: _buildDateField(
                                        'End Date',
                                        _endDateController,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'End Date is required';
                                          }

                                          if (!isValidMMDDYYYY(value)) {
                                            return 'Please enter valid date format (MM/DD/YYYY)';
                                          }
                                          try {
                                            final startParts =
                                                _startDateController.text.split(
                                                  '/',
                                                );
                                            final endParts = value.split('/');
                                            if (startParts.length == 3 &&
                                                endParts.length == 3) {
                                              final startDate = DateTime(
                                                int.parse(startParts[2]),
                                                int.parse(startParts[1]),
                                                int.parse(startParts[0]),
                                              );
                                              final endDate = DateTime(
                                                int.parse(endParts[2]),
                                                int.parse(endParts[1]),
                                                int.parse(endParts[0]),
                                              );
                                              if (endDate.isBefore(startDate))
                                                return 'End Date cannot be before Start Date';
                                            }
                                          } catch (e) {
                                            return 'Invalid date';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Medication Period',
                            style: TextStyle(
                              fontSize: deviceWidth(context) > 750 ? 20 :14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FormField<bool>(
                            initialValue:
                                _morningSelected ||
                                _afternoonSelected ||
                                _eveningSelected,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (!(_morningSelected ||
                                  _afternoonSelected ||
                                  _eveningSelected))
                                return 'Please select at least one period';
                              return null;
                            },
                            builder: (field) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildPeriodCheckbox(
                                            'Morning',
                                            _morningSelected,
                                            (value) => setState(() {
                                              _morningSelected = value ?? false;
                                              _selectAllSelected =
                                                  _morningSelected &&
                                                  _afternoonSelected &&
                                                  _eveningSelected;
                                            }),
                                          ),
                                          _buildPeriodCheckbox(
                                            'Afternoon',
                                            _afternoonSelected,
                                            (value) => setState(() {
                                              _afternoonSelected =
                                                  value ?? false;
                                              _selectAllSelected =
                                                  _morningSelected &&
                                                  _afternoonSelected &&
                                                  _eveningSelected;
                                            }),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildPeriodCheckbox(
                                            'Evening',
                                            _eveningSelected,
                                            (value) => setState(() {
                                              _eveningSelected = value ?? false;
                                              _selectAllSelected =
                                                  _morningSelected &&
                                                  _afternoonSelected &&
                                                  _eveningSelected;
                                            }),
                                          ),
                                          _buildPeriodCheckbox(
                                            'Select All',
                                            _selectAllSelected,
                                            (value) => setState(() {
                                              _selectAllSelected =
                                                  value ?? false;
                                              _morningSelected =
                                                  _selectAllSelected;
                                              _afternoonSelected =
                                                  _selectAllSelected;
                                              _eveningSelected =
                                                  _selectAllSelected;
                                            }),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 40),
                                    ],
                                  ),
                                  if (field.hasError)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 15),
                                      child: Text(
                                        field.errorText ?? '',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          if (_morningSelected ||
                              _afternoonSelected ||
                              _eveningSelected) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Select time for ${_nextPeriodLabel.isNotEmpty ? _nextPeriodLabel : 'Period'}',
                                    style:  TextStyle(
                                      fontSize: deviceWidth(context) > 750 ? 25 :20,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 1),
                                Expanded(
                                  child: Container(
                                    width: 150,
                                    height: 60,
                                    padding: const EdgeInsets.all(6.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey[200],
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _timeController,
                                            readOnly: true,
                                            // NOTE: we intentionally don't block form submission here.
                                            decoration: InputDecoration(
                                              hintText:
                                                  (_nextPeriodLabel == 'Period')
                                                  ? 'Tap clock to set time'
                                                  : 'Select time for $_nextPeriodLabel',
                                              hintStyle: TextStyle(fontSize: deviceWidth(context) > 750 ? 20 : 16),
                                              filled: true,
                                              fillColor: Colors.white,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide.none,
                                              ),
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 8,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () =>
                                              _selectTimeForSelectedPeriods(
                                                context,
                                              ),
                                          child: Icon(
                                            Icons.access_time_filled_outlined,
                                            color: AppTheme.primaryColor,
                                            size: deviceWidth(context) > 750 ? 35 :24,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          _buildPreviewAndReset(),
                          const SizedBox(height: 16),
                          _buildSelectedSlots(),
                          const SizedBox(height: 16),
                          _buildIntakeDropdown(),
                          const SizedBox(height: 16),
                          _buildDoseDescription(),
                          const SizedBox(height: 16),
                          _buildFrequencyDropdown(),
                          const SizedBox(height: 16),
                          _buildDaySelector(),
                          const SizedBox(height: 16),
                          _buildAddToListCheckbox(),
                          const SizedBox(height: 24),
                          _buildBottomButtons(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Loading overlay for long operations like save/update
            if ((_isLoading ?? false) || _isSaving)
              Positioned.fill(
                child: AbsorbPointer(
                  absorbing: true,
                  child: Container(
                    alignment: Alignment.center,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.25),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _isSaving
                                    ? 'Saving medication...'
                                    : 'Loading...',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
