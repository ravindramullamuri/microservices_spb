import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/components/pop_up_dialog_ui.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import 'package:heart_thrive/models/api_response.dart';
import 'package:heart_thrive/models/userdetails.dart';
import 'package:heart_thrive/providers/bmi/bmi_provider.dart';
import 'package:heart_thrive/services/user_service.dart';
import 'package:heart_thrive/utils/secure_storage_utils.dart';
import 'package:heart_thrive/utils/user_utils.dart';

import '../providers/user/user_details_provider.dart';
import '../routes/app_router.dart';
import '../theme/app_theme.dart';

Widget buildStatCard(
  String title,
  String value,
  String image,
  Color color,
  BuildContext context,
  UserDetails user,
) {
  return GestureDetector(
    onTap: () {
      showEditBottomSheet(context, title, value, user);
    },
    child: LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth < 200 ? constraints.maxWidth : 180,
          // ✅ Responsive width
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  image,
                  height: deviceWidth(context) > 750 ? 60 : 40,
                  width: deviceWidth(context) > 750 ? 60 : 40,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTheme.title12.copyWith(
                  fontSize: deviceWidth(context) > 750 ? 16 : 12,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: AppTheme.title16.copyWith(
                        fontSize: deviceWidth(context) > 750 ? 20 : 16,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Image.asset(
                    'lib/assets/Icon Edit.png',
                    height: 14,
                    width: 14,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}

Widget buildStatCard2(
  String title,
  String value,
  String image,
  Color color,
  BuildContext context,
  UserDetails user,
) {
  return Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Image.asset(
            image,
            height: deviceWidth(context) > 750 ? 60 : 40,
            width: deviceWidth(context) > 750 ? 60 : 40,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: AppTheme.title12.copyWith(
            fontSize: deviceWidth(context) > 750 ? 16 : 12,
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.title16.copyWith(
            fontSize: deviceWidth(context) > 750 ? 20 : 16,
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

void showEditBottomSheetOld(
  BuildContext context,
  String field,
  String currentValue,
  UserDetails user,
) {
  // Keep a reference to the root page context to use for SnackBars safely
  final BuildContext rootContext = context;
  final TextEditingController numberController = TextEditingController();
  String selectedUnit = field == "Weight" ? "kg" : "cm";
  bool _isLoading = false;
  String? errorMessage;

  // Pre-fill if value already exists
  if (currentValue.isNotEmpty && currentValue.contains(" ")) {
    final parts = currentValue.split(" ");
    debugPrint("parts @@@@ ${parts}");
    numberController.text = parts[0]; // number part
    if (parts.length > 1) {
      selectedUnit = parts[1] == "in" || parts[1] == "IN"
          ? "inch"
          : parts[1]; // unit part
    }
  }

  showDialog(
    context: context,
    barrierDismissible: false, // tap outside to close
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Edit $field",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: numberController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                              // allow decimals
                            ],
                            decoration: InputDecoration(
                              hintText: "Enter $field",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              errorText: errorMessage,
                            ),
                            onChanged: (val) {
                              setState(() {
                                if (val.isEmpty) {
                                  errorMessage = "Please enter $field";
                                  return;
                                }

                                double number = double.tryParse(val) ?? -1;
                                if (number < 0) {
                                  errorMessage = "Enter a valid number";
                                  return;
                                }

                                if (field == "Weight") {
                                  if (selectedUnit == "kg" && number > 500) {
                                    errorMessage =
                                        "Weight cannot exceed 500 kg";
                                    return;
                                  }
                                  if (selectedUnit == "lb" && number > 1103) {
                                    errorMessage =
                                        "Weight cannot exceed 1103 lbs";
                                    return;
                                  }
                                } else if (field == "Height") {
                                  if (selectedUnit == "cm" && number > 274) {
                                    errorMessage =
                                        "Height cannot exceed 9 feet (274 cm)";
                                    return;
                                  }
                                  if (selectedUnit == "inch" && number > 108) {
                                    errorMessage =
                                        "Height cannot exceed 9 feet (108 inches)";
                                    return;
                                  }
                                }

                                errorMessage = null; // all good
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Toggle-like Chip for Weight and Height units
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.grey.shade200,
                          ),
                          child: Row(
                            children: [
                              if (field == "Weight")
                                ...["kg", "lb"].map(
                                  (unit) => GestureDetector(
                                    onTap: () {
                                      if (selectedUnit == unit)
                                        return; // ✅ Prevent re-tap conversion
                                      setState(() {
                                        selectedUnit = unit;
                                        double value =
                                            double.tryParse(
                                              numberController.text,
                                            ) ??
                                            0.0;
                                        if (unit == "kg") {
                                          numberController.text =
                                              UserUtils.lbsToKg(
                                                value,
                                              ).toStringAsFixed(1);
                                        } else {
                                          numberController.text =
                                              UserUtils.kgToLbs(
                                                value,
                                              ).toStringAsFixed(1);
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            selectedUnit.toLowerCase() == unit
                                            ? AppTheme.primaryColor
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        unit.toUpperCase(),
                                        style: TextStyle(
                                          color: selectedUnit == unit
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (field == "Height")
                                ...["cm", "inch"].map(
                                  (unit) => GestureDetector(
                                    onTap: () {
                                      if (selectedUnit == unit)
                                        return; // ✅ Prevent re-tap conversion
                                      setState(() {
                                        selectedUnit = unit;
                                        double value =
                                            double.tryParse(
                                              numberController.text,
                                            ) ??
                                            0.0;
                                        if (unit == "cm") {
                                          numberController.text =
                                              UserUtils.inchToCm(
                                                value,
                                              ).toStringAsFixed(1);
                                        } else {
                                          numberController.text =
                                              UserUtils.cmToInch(
                                                value,
                                              ).toStringAsFixed(1);
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            selectedUnit.toLowerCase() == unit
                                            ? AppTheme.primaryColor
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        unit.toUpperCase(),
                                        style: TextStyle(
                                          color:
                                              selectedUnit.toLowerCase() == unit
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: Colors.grey),
                              ),
                            ),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, _) {
                              return _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : ElevatedButton(
                                      onPressed: () async {
                                        try {
                                          if (numberController.text
                                              .trim()
                                              .isEmpty) {
                                            setState(
                                              () => errorMessage =
                                                  "Enter a valid number",
                                            );
                                            return;
                                          }

                                          final formattedValue =
                                              "${numberController.text.trim()} $selectedUnit";
                                          setState(() => _isLoading = true);

                                          await savePatientWeightOrHeight(
                                            context,
                                            field,
                                            formattedValue,
                                            user,
                                            ref,
                                          );

                                          setState(() => _isLoading = false);
                                        } catch (e) {
                                          if (rootContext.mounted) {
                                            ScaffoldMessenger.of(
                                              rootContext,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Something went wrong: $e",
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text("Save"),
                                    );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

void showEditBottomSheet(
  BuildContext context,
  String field,
  String currentValue,
  UserDetails user,
) {
  // Keep a reference to the root page context to use for SnackBars safely
  final BuildContext rootContext = context;
  final TextEditingController numberController = TextEditingController();
  String selectedUnit = field == "Weight" ? "kg" : "cm";
  bool _isLoading = false;
  String? errorMessage;

  // Pre-fill if value already exists
  if (currentValue.isNotEmpty && currentValue.contains(" ")) {
    final parts = currentValue.split(" ");
    debugPrint("parts @@@@ ${parts}");
    numberController.text = parts[0]; // number part
    if (parts.length > 1) {
      selectedUnit = parts[1] == "in" || parts[1] == "IN"
          ? "inch"
          : parts[1]; // unit part
    }
  }

  showDialog(
    context: context,
    barrierDismissible: false, // tap outside to close
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                deviceWidth(context) > 750 ? 20 : 16,
              ),
            ),
            child: Stack(
              children: [
                // 👉 MAIN CONTENT OF DIALOG
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Edit $field",
                          style: TextStyle(
                            fontSize: deviceWidth(context) > 750 ? 25 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: numberController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                  // allow decimals
                                ],
                                decoration: InputDecoration(
                                  hintText: "Enter $field",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  errorText: errorMessage,
                                  errorStyle: TextStyle(
                                    fontSize: deviceWidth(context) > 750
                                        ? 16
                                        : 12,
                                  ),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    if (val.isEmpty) {
                                      errorMessage = "Please enter $field";
                                      return;
                                    }

                                    double number = double.tryParse(val) ?? -1;
                                    if (number < 0) {
                                      errorMessage = "Enter a valid number";
                                      return;
                                    }

                                    if (field == "Weight") {
                                      if (selectedUnit == "kg" &&
                                          number > 500) {
                                        errorMessage =
                                            "Weight cannot exceed 500 kg";
                                        return;
                                      }
                                      if (selectedUnit == "lb" &&
                                          number > 1103) {
                                        errorMessage =
                                            "Weight cannot exceed 1103 lbs";
                                        return;
                                      }
                                    } else if (field == "Height") {
                                      if (selectedUnit == "cm" &&
                                          number > 274) {
                                        errorMessage =
                                            "Height cannot exceed 9 feet (274 cm)";
                                        return;
                                      }
                                      if (selectedUnit == "inch" &&
                                          number > 108) {
                                        errorMessage =
                                            "Height cannot exceed 9 feet (108 inches)";
                                        return;
                                      }
                                    }

                                    errorMessage = null; // all good
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Toggle-like Chip for Weight and Height units
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.grey.shade200,
                              ),
                              child: Row(
                                children: [
                                  if (field == "Weight")
                                    ...["kg", "lb"].map(
                                      (unit) => GestureDetector(
                                        onTap: () {
                                          if (selectedUnit == unit)
                                            return; // ✅ Prevent re-tap conversion
                                          setState(() {
                                            selectedUnit = unit;
                                            double value =
                                                double.tryParse(
                                                  numberController.text,
                                                ) ??
                                                0.0;
                                            if (unit == "kg") {
                                              numberController.text =
                                                  UserUtils.lbsToKg(
                                                    value,
                                                  ).toStringAsFixed(1);
                                            } else {
                                              numberController.text =
                                                  UserUtils.kgToLbs(
                                                    value,
                                                  ).toStringAsFixed(1);
                                            }
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                selectedUnit.toLowerCase() ==
                                                    unit
                                                ? AppTheme.primaryColor
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            unit.toUpperCase(),
                                            style: TextStyle(
                                              color: selectedUnit == unit
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (field == "Height")
                                    ...["cm", "inch"].map(
                                      (unit) => GestureDetector(
                                        onTap: () {
                                          if (selectedUnit == unit)
                                            return; // ✅ Prevent re-tap conversion
                                          setState(() {
                                            selectedUnit = unit;
                                            double value =
                                                double.tryParse(
                                                  numberController.text,
                                                ) ??
                                                0.0;
                                            if (unit == "cm") {
                                              numberController.text =
                                                  UserUtils.inchToCm(
                                                    value,
                                                  ).toStringAsFixed(1);
                                            } else {
                                              numberController.text =
                                                  UserUtils.cmToInch(
                                                    value,
                                                  ).toStringAsFixed(1);
                                            }
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                selectedUnit.toLowerCase() ==
                                                    unit
                                                ? AppTheme.primaryColor
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            unit.toUpperCase(),
                                            style: TextStyle(
                                              color:
                                                  selectedUnit.toLowerCase() ==
                                                      unit
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(color: Colors.grey),
                                  ),
                                ),
                                child: const Text("Cancel"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Consumer(
                                builder: (context, ref, _) {
                                  return _isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : ElevatedButton(
                                          onPressed: () async {
                                            try {
                                              if (numberController.text
                                                  .trim()
                                                  .isEmpty) {
                                                setState(
                                                  () => errorMessage =
                                                      "Enter a valid number",
                                                );
                                                return;
                                              }
                                              final error = validateBeforeSave(
                                                field: field,
                                                // "Weight" or "Height"
                                                selectedUnit: selectedUnit,
                                                value: numberController.text,
                                              );

                                              if (error != null) {
                                                setState(
                                                  () => errorMessage = error,
                                                );
                                                showErrorMessageDialog(
                                                  context,
                                                  errorMessage!,
                                                );
                                                return;
                                              }

                                              final formattedValue =
                                                  "${numberController.text.trim()} $selectedUnit";
                                              setState(() => _isLoading = true);

                                              await savePatientWeightOrHeight(
                                                context,
                                                field,
                                                formattedValue,
                                                user,
                                                ref,
                                              );

                                              setState(
                                                () => _isLoading = false,
                                              );
                                            } catch (e) {
                                              if (rootContext.mounted) {
                                                ScaffoldMessenger.of(
                                                  rootContext,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      "Something went wrong: $e",
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text("Save"),
                                        );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 👉 BLUR + LOADING OVERLAY
                if (_isLoading)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                        child: Container(
                          color: Colors.white.withValues(alpha: 0.65),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Edit $field",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: numberController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                              // allow decimals
                            ],
                            decoration: InputDecoration(
                              hintText: "Enter $field",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              errorText: errorMessage,
                            ),
                            onChanged: (val) {
                              setState(() {
                                if (val.isEmpty) {
                                  errorMessage = "Please enter $field";
                                  return;
                                }

                                double number = double.tryParse(val) ?? -1;
                                if (number < 0) {
                                  errorMessage = "Enter a valid number";
                                  return;
                                }

                                if (field == "Weight") {
                                  if (selectedUnit == "kg" && number > 500) {
                                    errorMessage =
                                        "Weight cannot exceed 500 kg";
                                    return;
                                  }
                                  if (selectedUnit == "lb" && number > 1103) {
                                    errorMessage =
                                        "Weight cannot exceed 1103 lbs";
                                    return;
                                  }
                                } else if (field == "Height") {
                                  if (selectedUnit == "cm" && number > 274) {
                                    errorMessage =
                                        "Height cannot exceed 9 feet (274 cm)";
                                    return;
                                  }
                                  if (selectedUnit == "inch" && number > 108) {
                                    errorMessage =
                                        "Height cannot exceed 9 feet (108 inches)";
                                    return;
                                  }
                                }

                                errorMessage = null; // all good
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Toggle-like Chip for Weight and Height units
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.grey.shade200,
                          ),
                          child: Row(
                            children: [
                              if (field == "Weight")
                                ...["kg", "lb"].map(
                                  (unit) => GestureDetector(
                                    onTap: () {
                                      if (selectedUnit == unit)
                                        return; // ✅ Prevent re-tap conversion
                                      setState(() {
                                        selectedUnit = unit;
                                        double value =
                                            double.tryParse(
                                              numberController.text,
                                            ) ??
                                            0.0;
                                        if (unit == "kg") {
                                          numberController.text =
                                              UserUtils.lbsToKg(
                                                value,
                                              ).toStringAsFixed(1);
                                        } else {
                                          numberController.text =
                                              UserUtils.kgToLbs(
                                                value,
                                              ).toStringAsFixed(1);
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            selectedUnit.toLowerCase() == unit
                                            ? AppTheme.primaryColor
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        unit.toUpperCase(),
                                        style: TextStyle(
                                          color: selectedUnit == unit
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (field == "Height")
                                ...["cm", "inch"].map(
                                  (unit) => GestureDetector(
                                    onTap: () {
                                      if (selectedUnit == unit)
                                        return; // ✅ Prevent re-tap conversion
                                      setState(() {
                                        selectedUnit = unit;
                                        double value =
                                            double.tryParse(
                                              numberController.text,
                                            ) ??
                                            0.0;
                                        if (unit == "cm") {
                                          numberController.text =
                                              UserUtils.inchToCm(
                                                value,
                                              ).toStringAsFixed(1);
                                        } else {
                                          numberController.text =
                                              UserUtils.cmToInch(
                                                value,
                                              ).toStringAsFixed(1);
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            selectedUnit.toLowerCase() == unit
                                            ? AppTheme.primaryColor
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        unit.toUpperCase(),
                                        style: TextStyle(
                                          color:
                                              selectedUnit.toLowerCase() == unit
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: Colors.grey),
                              ),
                            ),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, _) {
                              return _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : ElevatedButton(
                                      onPressed: () async {
                                        try {
                                          if (numberController.text
                                              .trim()
                                              .isEmpty) {
                                            setState(
                                              () => errorMessage =
                                                  "Enter a valid number",
                                            );
                                            return;
                                          }

                                          final formattedValue =
                                              "${numberController.text.trim()} $selectedUnit";
                                          setState(() => _isLoading = true);

                                          await savePatientWeightOrHeight(
                                            context,
                                            field,
                                            formattedValue,
                                            user,
                                            ref,
                                          );

                                          setState(() => _isLoading = false);
                                        } catch (e) {
                                          if (rootContext.mounted) {
                                            ScaffoldMessenger.of(
                                              rootContext,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Something went wrong: $e",
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text("Save"),
                                    );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

String? validateBeforeSave({
  required String field, // "Weight" or "Height"
  required String selectedUnit, // "kg", "lb", "cm", "inch"
  required String value,
}) {
  final number = double.tryParse(value.trim());

  if (number == null || number <= 0) {
    return "Please enter a valid $field";
  }

  final limits = {
    "Weight": {"kg": 500.0, "lb": 1102.0},
    "Height": {"cm": 274.0, "inch": 108.0},
  };

  final max = limits[field]?[selectedUnit];

  if (max != null && number > max) {
    return "$field cannot exceed $max $selectedUnit";
  }

  return null; // ✅ valid
}

Future<void> savePatientWeightOrHeight(
  BuildContext context,
  String title,
  String patientData,
  UserDetails user,
  WidgetRef ref,
) async {
  try {
    var requestData;

    if (title == "Weight") {
      final data = convertData(title, patientData);
      requestData = jsonEncode({
        "weight": data['data'],
        "weightUnitType": data['unitType'],
        "height": user.height == null ? 10 : user.height?.split(" ")[0],
        "heightUnitType": user.height == null
            ? 'cm'
            : user.height?.split(" ")[1],
      });
    }

    if (title == "Height") {
      final data = convertData(title, patientData);
      requestData = jsonEncode({
        "weight": user.weight == null ? 13 : user.weight?.split(" ")[0],
        "weightUnitType": user.weight == null
            ? 'kg'
            : user.weight?.split(" ")[1],
        "height": data['data'],
        "heightUnitType": data['unitType'] == 'inch' ? "in" : data['unitType'],
      });
    }

    debugPrint("requestData @@@@ $requestData");

    ApiResponse apiResponse = await UserService().createPatientWeightHeightLog(
      requestData,
    );

    if ((apiResponse.status == 200 || apiResponse.status == 201) &&
        apiResponse.success) {
      // ✅ Reload user details BEFORE closing the dialog to keep ref valid
      String? token = await SecureStorageUtils().read(StorageKeys.accessToken);
      Future.microtask(() async {
        ref.invalidate(userDetailsDataProvider);
        ref.invalidate(currentAndPastProvider);
        ref.invalidate(heroDashboardProvider);
        await ref.read(userDetailsDataProvider.notifier).loadUser(token: token);
      });

      Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title update failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e, st) {
    debugPrint("Error in savePatientWeightOrHeight: $e\n$st");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }
}

convertData(String? field, String data) {
  final regex = RegExp(r'^(\d+(?:\.\d+)?)\s*([a-zA-Z]+)$'); // ✅ allows decimal
  final match = regex.firstMatch(data.trim());

  if (match != null) {
    final patientData = double.parse(match.group(1)!); // ✅ use double
    final unitType = match.group(2)!.toLowerCase();

    // Allowed units only
    Set<String> allowedUnits;
    if (field == 'Weight') {
      allowedUnits = {'kg', 'lb'};
    } else {
      allowedUnits = {'cm', 'inch'};
    }

    if (!allowedUnits.contains(unitType)) {
      debugPrint('Invalid unit: $unitType');
      return null;
    }

    final result = {"data": patientData, "unitType": unitType};
    debugPrint(result.toString());
    return result;
  } else {
    debugPrint("Invalid input");
    return null;
  }
}

convertDataValue(String? field, String data) {
  final regex = RegExp(r'^(\d+(?:\.\d+)?)\s*([a-zA-Z]+)$'); // ✅ allows decimal
  final match = regex.firstMatch(data.trim());

  if (match != null) {
    final patientData = double.parse(match.group(1)!); // ✅ use double
    final unitType = match.group(2)!.toLowerCase();
    debugPrint("patientData ${patientData}");
    // Allowed units only
    Set<String> allowedUnits;
    if (field == 'Weight') {
      allowedUnits = {'kg', 'lb'};
    } else {
      allowedUnits = {'cm', 'inch'};
    }

    if (!allowedUnits.contains(unitType)) {
      debugPrint('Invalid unit: $unitType');
      return null;
    }

    final result = {"data": patientData, "unitType": unitType};
    debugPrint(result.toString());
    return patientData;
  } else {
    debugPrint("Invalid input");
    return null;
  }
}

// Add Quick Navigation
void showQuickNavigationBottomSheet(BuildContext context, String pageType) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: false,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- TOP ROW ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _quickNavItem(
                  "Breakfast",
                  "lib/assets/bottom_pop_menu/breakfast_icon.png",
                  Colors.transparent,
                  () {
                    Navigator.pop(context);
                    AppRouter.navigateToAllMealIntakeWithTab(
                      context,
                      1,
                      pageType,
                    );
                  },
                  context,
                ),
                _quickNavItem(
                  "Lunch",
                  "lib/assets/bottom_pop_menu/lunch_icon.png",
                  Colors.transparent,
                  () {
                    Navigator.pop(context);
                    AppRouter.navigateToAllMealIntakeWithTab(
                      context,
                      2,
                      pageType,
                    );
                  },
                  context,
                ),
                _quickNavItem(
                  "Snacks",
                  "lib/assets/bottom_pop_menu/snacks_icon.png",
                  Colors.transparent,
                  () {
                    Navigator.pop(context);
                    AppRouter.navigateToAllMealIntakeWithTab(
                      context,
                      3,
                      pageType,
                    );
                  },
                  context,
                ),
                _quickNavItem(
                  "Dinner",
                  "lib/assets/bottom_pop_menu/dinner_icon.png",
                  Colors.transparent,
                  () {
                    Navigator.pop(context);
                    AppRouter.navigateToAllMealIntakeWithTab(
                      context,
                      4,
                      pageType,
                    );
                  },
                  context,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- SECOND ROW (Center aligned) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _quickNavItem(
                  "Education",
                  "lib/assets/bottom_pop_menu/education-img.png",
                  Colors.transparent,
                      () {
                    Navigator.pop(context);
                    //AppRouter.navigateToAddBodyMassIndex(context, pageType);
                    AppRouter.navigateToEducation(context);
                  },
                  context,
                ),
                _quickNavItem(
                  "Recipe",
                  "lib/assets/bottom_pop_menu/recipe_icon.png",
                  Colors.transparent,
                      () {
                    Navigator.pop(context);
                    //AppRouter.navigateToAddBodyMassIndex(context, pageType);
                    AppRouter.navigateToRecipe(context);
                  },
                  context,
                ),

                _quickNavItem(
                  "Add Symptoms",
                  "lib/assets/bottom_pop_menu/add_symptoms_icon.png",
                  Colors.pink,
                  () {
                    Navigator.pop(context);
                    AppRouter.navigateToAddSymptoms(context);
                  },
                  context,
                ),
                _quickNavItem(
                  "Profile",
                  "lib/assets/bottom_pop_menu/profile-img.png",
                  Colors.transparent,
                      () async {
                    Navigator.pop(context);
                    AppRouter.navigateToProfile(context);
                  },
                  context,
                ),
              ],
            ),

            const SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}

Widget _quickNavItem(
  String title,
  String icon,
  Color color,
  VoidCallback onTap,
  BuildContext context,
) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Image.asset(
          icon,
          height: deviceWidth(context) > 400
              ? 70
              : deviceWidth(context) > 360
              ? 60
              : 55,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );
}

Widget _quickNavItemNew(
  String title,
  String icon,
  Color color,
  VoidCallback onTap,
) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Perfect responsive scalable icon
        Flexible(
          flex: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryColor, width: 1),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 50,
                maxWidth: 50, // prevents overflow even in small widths
                minHeight: 35,
                minWidth: 35,
              ),
              child: FittedBox(fit: BoxFit.contain, child: Image.asset(icon)),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Text that NEVER overflows
        Flexible(
          child: SizedBox(
            width: 80, // safe fixed text width
            child: Text(
              title,
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    ),
  );
}
