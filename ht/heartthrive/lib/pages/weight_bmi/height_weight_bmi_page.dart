import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import 'package:heart_thrive/providers/user/user_details_provider.dart';
import 'dart:convert';

import 'package:heart_thrive/theme/app_theme.dart';
import 'package:heart_thrive/utils/secure_storage_utils.dart';

import '../../models/bmi/weight_height_model.dart';
import '../../providers/bmi/notification_provider.dart';
import '../../providers/bmi/bmi_provider.dart';
import '../../utils/component_utils.dart';


class BMICalculatorScreen extends ConsumerWidget {
  const BMICalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(currentAndPastProvider);

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text("Error loading BMI"),
      data: (data) {
        final record = data.currentRecord;
        final bmiValue = record?.bmiValue ?? 0.0;
        final bmiCategory = getBMICategory(bmiValue);

        return _BMIContent(
          currentAndPastData: data,
          bmiValue: bmiValue,
          bmiCategory: bmiCategory,
        );
      },
    );
  }
}


class _BMIContent extends ConsumerStatefulWidget {
  final CurrentAndPastData? currentAndPastData;
  final double bmiValue;
  final String? bmiCategory;

  const _BMIContent({
    required this.currentAndPastData,
    required this.bmiValue,
    required this.bmiCategory,
  });

  @override
  ConsumerState<_BMIContent> createState() => _BMIContentState();
}

class _BMIContentState extends ConsumerState<_BMIContent> {
  late double weight;
  late double height;
  late bool isKg;
  late bool isCm;

  final weightController = TextEditingController();
  final heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialValues();
  }


  void _loadInitialValues() {
    //final record =ref.watch(currentAndPastProvider).value?.currentRecord;
    final record = widget.currentAndPastData?.currentRecord;
    if (record != null) {
      weight = parseMeasurement(record.weight)['value'];
      height = parseMeasurement(record.height)['value'];
      isKg = parseMeasurement(record.weight)['unit'] == 'kg';
      isCm = parseMeasurement(record.height)['unit'] == 'cm';
    } else {
      weight = 85.0;
      height = 165.0;
      isKg = true;
      isCm = true;
    }

    weightController.text = weight.toStringAsFixed(2);
    heightController.text = height.toStringAsFixed(2);
  }

  void _openEditDialog() {
    // Always use latest data from provider when opening dialog
    final currentData = ref.watch(currentAndPastProvider).value;

    final record = currentData?.currentRecord;
    double dialogWeight = record != null
        ? parseMeasurement(record.weight)['value']
        : 85.0;
    double dialogHeight = record != null
        ? parseMeasurement(record.height)['value']
        : 165.0;
    bool dialogIsKg = record != null
        ? parseMeasurement(record.weight)['unit'] == 'kg'
        : true;
    bool dialogIsCm = record != null
        ? parseMeasurement(record.height)['unit'] == 'cm'
        : true;

    // Reset controllers to current saved values
    weightController.text = dialogWeight.toStringAsFixed(2);
    heightController.text = dialogHeight.toStringAsFixed(2);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BMIDialogContent(
        weightController: weightController,
        heightController: heightController,
        initialIsKg: dialogIsKg,
        initialIsCm: dialogIsCm,
        onSave: (newKg, newCm, newWeight, newHeight) {
          setState(() {
            isKg = newKg;
            isCm = newCm;
            weight = newWeight;
            height = newHeight;
          });
        },
      ),
    );
  }

  Widget getBMIUI(double bmiValue, String? bmiCategory) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Edit button
          Container(
            alignment: Alignment.centerRight,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Body Mass Index",
                  style: deviceWidth > 750 ? AppTheme.title20 :deviceWidth > 360 ? AppTheme.title16 : AppTheme.title14,
                ),
                TextButton(
                  onPressed: _openEditDialog,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Edit',
                        style: deviceWidth > 750 ? AppTheme.buttonTextStyle20:deviceWidth > 360
                            ? AppTheme.buttonTextStyle
                            : AppTheme.buttonTextStyle12,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.edit,
                        color: AppTheme.primaryColor,
                        size: deviceWidth > 750 ? 22: deviceWidth > 360 ? 18 : 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          deviceHeight(context) > 640
              ? const SizedBox(height: 20)
              : const SizedBox(height: 5),

          // Weight Card
          _DisplayCard(
            title: "Weight",
            value: "$weight ${isKg ? "kg" : "lb"}",
            icon: 'lib/assets/Scale.png',
          ),
          deviceHeight(context) > 640
              ? const SizedBox(height: 16)
              : const SizedBox(height: 5),

          // Height Card
          _DisplayCard(
            title: "Height",
            value: "$height ${isCm ? "cm" : "in"}",
            icon: 'lib/assets/sewing_tape_measure.png',
          ),
          deviceHeight(context) > 640
              ? const SizedBox(height: 10)
              : const SizedBox(height: 5),

          // BMI Result
          Row(
            children: [
              Container(
                margin: const EdgeInsets.only(left: 12.0),
                padding: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryColor, width: 2),
                ),
                child: Image.asset(
                  'lib/assets/Heartbeat2.png',
                  width: deviceWidth > 750 ? 40: deviceWidth > 360 ? 30 : 20,
                ),
              ),
              const SizedBox(width: 10.0),
              Text(
                'Body Mass Index',
                style: deviceWidth > 750 ? AppTheme.title20: deviceWidth > 360 ? AppTheme.title18 : AppTheme.title16,
              ),
            ],
          ),
          SizedBox(height: deviceWidth > 750 ? 20:8.0),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: deviceWidth > 750 ? 20:deviceHeight(context) > 640 ? 8 : 4,
              horizontal: 12,
            ),
            decoration: BoxDecoration(
              color: getCategoryColor(bmiCategory).withOpacity(0.3),
              borderRadius: BorderRadius.circular(8.0),
              border: Border(
                left: BorderSide(
                  color: getCategoryColor(bmiCategory),
                  width: 3,
                ),
              ),
            ),
            child: Text(
              'Your BMI is ${bmiValue.toStringAsFixed(2)} ($bmiCategory)',
              style: deviceWidth > 750 ? AppTheme.title20:deviceWidth > 360
                  ? AppTheme.title18
                  : deviceHeight(context) > 640
                  ? AppTheme.title16
                  : AppTheme.title10,
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.visible,
            ),
          )
          ,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.currentAndPastData?.currentRecord;

     weight = record != null
        ? parseMeasurement(record.weight)['value']
        : 0.0;

     height = record != null
        ? parseMeasurement(record.height)['value']
        : 0.0;
    isKg = record!= null?parseMeasurement(record.weight)['unit'] == 'kg':false;
    isCm = record!= null?parseMeasurement(record.height)['unit'] == 'cm':false;

    return Column(
      children: [
        getBMIUI(widget.bmiValue, widget.bmiCategory),
      ],
    );
  }

  @override
  void dispose() {
    weightController.dispose();
    heightController.dispose();
    super.dispose();
  }
}

// ==================== DIALOG CONTENT (SMOOTH & SAFE) ====================
class BMIDialogContent extends ConsumerStatefulWidget {
  final TextEditingController weightController;
  final TextEditingController heightController;
  final bool initialIsKg;
  final bool initialIsCm;
  final Function(bool isKg, bool isCm, double weight, double height) onSave;

  const BMIDialogContent({
    super.key,
    required this.weightController,
    required this.heightController,
    required this.initialIsKg,
    required this.initialIsCm,
    required this.onSave,
  });

  @override
  ConsumerState<BMIDialogContent> createState() => _BMIDialogContentState();
}

class _BMIDialogContentState extends ConsumerState<BMIDialogContent> {
  late bool isKg;
  late bool isCm;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    isKg = widget.initialIsKg;
    isCm = widget.initialIsCm;
    widget.weightController.addListener(_clearError);
    widget.heightController.addListener(_clearError);
  }

  void _clearError() => setState(() => _errorMessage = null);

  bool _validateInputs() {
    final weightText = widget.weightController.text.trim();
    final heightText = widget.heightController.text.trim();

    final weight = double.tryParse(weightText);
    final height = double.tryParse(heightText);

    if (weight == null || weight <= 0) {
      setState(() => _errorMessage = "Please enter a valid weight");
      return false;
    }
    if (height == null || height <= 0) {
      setState(() => _errorMessage = "Please enter a valid height");
      return false;
    }

    final weightInKg = isKg ? weight : weight / 2.20462;
    final heightInCm = isCm ? height : height * 2.54;

    const minKg = 20.0, maxKg = 500.0;
    const minCm = 100.0, maxCm = 274.0;

    final minWeightDisplay = isKg ? minKg : minKg * 2.20462;
    final maxWeightDisplay = isKg ? maxKg : maxKg * 2.20462;
    final minHeightDisplay = isCm ? minCm : minCm / 2.54;
    final maxHeightDisplay = isCm ? maxCm : maxCm / 2.54;

    if (weightInKg < minKg || weightInKg > maxKg) {
      setState(() => _errorMessage =
      "Weight must be between ${minWeightDisplay.toStringAsFixed(0)}–${maxWeightDisplay.toStringAsFixed(0)} ${isKg ? 'kg' : 'lbs'}");
      return false;
    }
    if (heightInCm < minCm || heightInCm > maxCm) {
      setState(() => _errorMessage =
      "Height must be between ${minHeightDisplay.toStringAsFixed(0)}–${maxHeightDisplay.toStringAsFixed(0)} ${isCm ? 'cm' : 'in'}");
      return false;
    }

    return true;
  }

  Future<void> _handleSaveOld() async {
    if (!_validateInputs()) return;

    setState(() => _isSaving = true);

    try {
      final currentData = ref.watch(currentAndPastProvider).value;
      final currentRecord = currentData?.currentRecord;

      final log = WeightHeightLog(
        id: currentRecord!.patientWeightHeightId,
        weight: double.parse(widget.weightController.text),
        height: double.parse(widget.heightController.text),
        weightUnitType: isKg ? 'kg' : 'lb',
        heightUnitType: isCm ? 'CM' : 'IN',
      );

      final isUpdate = currentRecord?.patientWeightHeightId != null;

      await ref
          .read(weightLogNotifierProvider.notifier)
          .createOrUpdate(log, isUpdate: isUpdate);

      // Success: Update parent immediately
      final newWeight = double.parse(widget.weightController.text);
      final newHeight = double.parse(widget.heightController.text);
      widget.onSave(isKg, isCm, newWeight, newHeight);

      if (mounted) Navigator.pop(context);

      // Background refresh — fire and forget
      Future.microtask(() async {
        ref.invalidate(userDetailsDataProvider);
        ref.invalidate(currentAndPastProvider);
        ref.invalidate(heroDashboardProvider);
       // final token = ref.watch(tokenProvider);
        final token = await SecureStorageUtils().read(StorageKeys.accessToken);
        ref.invalidate(notificationProvider);
        ref.read(notificationProvider.notifier).loadFirstPage();
        if (token != null) {
          ref.read(userDetailsDataProvider.notifier).loadUser(token: token);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  Future<void> _handleSave() async {
    if (!_validateInputs()) return;

    setState(() => _isSaving = true);

    try {
      final currentData = ref.read(currentAndPastProvider).value;
      final currentRecord = currentData?.currentRecord;

      final log = WeightHeightLog(
        id: currentRecord!.patientWeightHeightId,
        weight: double.parse(widget.weightController.text),
        height: double.parse(widget.heightController.text),
        weightUnitType: isKg ? 'kg' : 'lb',
        heightUnitType: isCm ? 'CM' : 'IN',
      );

      final isUpdate = currentRecord?.patientWeightHeightId != null;

      await ref
          .read(weightLogNotifierProvider.notifier)
          .createOrUpdate(log, isUpdate: isUpdate);

      // Success: Update parent immediately
      final newWeight = double.parse(widget.weightController.text);
      final newHeight = double.parse(widget.heightController.text);
      widget.onSave(isKg, isCm, newWeight, newHeight);

      if (mounted) Navigator.pop(context);

      // Background refresh — fire and forget
      Future.microtask(() async{
        ref.invalidate(currentAndPastProvider);
        ref.invalidate(heroDashboardProvider);
        ref.invalidate(userDetailsDataProvider);
        final token = await SecureStorageUtils().read(StorageKeys.accessToken);
        ref.invalidate(notificationProvider);
        ref.read(notificationProvider.notifier).loadFirstPage();
        if (token != null) {
          ref.read(userDetailsDataProvider.notifier).loadUser(token: token);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    widget.weightController.removeListener(_clearError);
    widget.heightController.removeListener(_clearError);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              //print(MediaQueryData.fromView(View.of(context)).viewInsets.bottom);
              return SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                //physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(
                  top: 24,
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 10)
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_errorMessage != null)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                               Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  "Enter your weight & height",
                                  style: deviceWidth(context) > 750 ? AppTheme.title25 : AppTheme.title16,
                                ),
                              ),
                              WeightInputCard(
                                controller: widget.weightController,
                                isKg: isKg,
                                onToggleUnit: () {
                                  setState(() {
                                    isKg = !isKg;
                                    final val =
                                        double.tryParse(widget.weightController.text) ??
                                            0;
                                    widget.weightController.text = isKg
                                        ? (val / 2.20462).toStringAsFixed(2)
                                        : (val * 2.20462).toStringAsFixed(2);
                                  });
                                },
                                isEditable: true,
                              ),
                              const SizedBox(height: 16),
                              HeightInputCard(
                                controller: widget.heightController,
                                isCm: isCm,
                                onToggleUnit: () {
                                  setState(() {
                                    isCm = !isCm;
                                    final val =
                                        double.tryParse(widget.heightController.text) ??
                                            0;
                                    widget.heightController.text = isCm
                                        ? (val * 2.54).toStringAsFixed(2)
                                        : (val / 2.54).toStringAsFixed(2);
                                  });
                                },
                                isEditable: true,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                                      child: Text("Cancel", style: TextStyle(fontSize: deviceWidth(context) > 750 ? 20 :14),),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton(
                                      onPressed: _isSaving ? null : _handleSave,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                      ),
                                      child: _isSaving
                                          ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                          : Text(
                                        "Save & calculate BMI",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: deviceWidth(context) > 750 ? 20 : 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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

// DisplayCard, WeightInputCard, HeightInputCard, _InputCard remain exactly as in your original code
// (They were already well-written)

class _DisplayCard extends StatelessWidget {
  final String title;
  final String value;
  final String icon;

  const _DisplayCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final parts = value.split(' ');
    final number = parts.isNotEmpty ? parts.first : '';
    final unit = parts.length > 1 ? parts.last : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryColor, width: 2),
            ),
            child: Image.asset(icon, width: deviceWidth > 750? 50 :deviceWidth > 360 ? 30 : 20),
          ),
          const SizedBox(width: 12),
          Text(title, style: deviceWidth > 750? AppTheme.title20:deviceWidth > 360 ? AppTheme.title18 : AppTheme.title16),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(number, style: deviceWidth > 750 ? AppTheme.title20:deviceWidth > 360 ? AppTheme.title18 : AppTheme.title16),
            ),
          ),
          if (unit.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(unit, style: (deviceWidth > 750 ? AppTheme.title20:deviceWidth > 360 ? AppTheme.title18 : AppTheme.title16).copyWith(fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }
}
// Input Cards remain unchanged — they are already correct
class WeightInputCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isKg;
  final VoidCallback onToggleUnit;
  final bool isEditable;

  const WeightInputCard({
    super.key,
    required this.controller,
    required this.isKg,
    required this.onToggleUnit,
    required this.isEditable,
  });

  @override
  Widget build(BuildContext context) {
    return _InputCard(
      icon: 'lib/assets/bmi_3.png',
      title: "Weight",
      controller: controller,
      firstUnit: "KG",
      secondUnit: "LB",
      isFirstSelected: isKg,
      onToggle: onToggleUnit,
      isEditable: isEditable,
    );
  }
}

class HeightInputCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isCm;
  final VoidCallback onToggleUnit;
  final bool isEditable;

  const HeightInputCard({
    super.key,
    required this.controller,
    required this.isCm,
    required this.onToggleUnit,
    required this.isEditable,
  });

  @override
  Widget build(BuildContext context) {
    return _InputCard(
      icon: 'lib/assets/bmi_2.png',
      title: "Height",
      controller: controller,
      firstUnit: "CM",
      secondUnit: "IN",
      isFirstSelected: isCm,
      onToggle: onToggleUnit,
      isEditable: isEditable,
    );
  }
}

class _InputCard extends StatelessWidget {
  final String icon;
  final String title;
  final TextEditingController controller;
  final String firstUnit;
  final String secondUnit;
  final bool isFirstSelected;
  final VoidCallback onToggle;
  final bool isEditable;

  const _InputCard({
    required this.icon,
    required this.title,
    required this.controller,
    required this.firstUnit,
    required this.secondUnit,
    required this.isFirstSelected,
    required this.onToggle,
    required this.isEditable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(icon, width: deviceWidth(context) > 750 ? 50 : 30, height: deviceWidth(context) > 750 ? 50 : 30),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: deviceWidth(context) > 750 ? 25 : 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text("Units", style:deviceWidth(context) > 750 ? AppTheme.title20: AppTheme.title16),
              const SizedBox(width: 30),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 6,
                child: TextField(
                  controller: controller,
                  style: deviceWidth(context) > 750 ? AppTheme.title20:AppTheme.title16,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  enabled: isEditable,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2),
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 100,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.black.withOpacity(0.4), width: 0.8),
                ),
                child: ToggleButtons(
                  isSelected: [isFirstSelected, !isFirstSelected],
                  onPressed: (index) {
                    if ((index == 0 && !isFirstSelected) || (index == 1 && isFirstSelected)) {
                      onToggle();
                    }
                  },
                  borderColor: Colors.transparent,
                  selectedBorderColor: Colors.transparent,
                  fillColor: Colors.transparent,
                  color: Colors.black,
                  selectedColor: Colors.white,
                  renderBorder: false,
                  constraints: const BoxConstraints(minHeight: 0, minWidth: 0),
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isFirstSelected ? AppTheme.primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        firstUnit,
                        style: deviceWidth(context) > 750 ? AppTheme.title20.copyWith(
                          color: isFirstSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600)
                              :AppTheme.title16.copyWith(
                          color: isFirstSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: !isFirstSelected ? AppTheme.primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        secondUnit,
                        style:deviceWidth(context) > 750 ? AppTheme.title20.copyWith(
                          color: !isFirstSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600 ) :  AppTheme.title16.copyWith(
                          color: !isFirstSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}