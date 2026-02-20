import 'dart:ui';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/models/meal/edit_meal_model.dart';
import 'package:heart_thrive/providers/bmi/notification_provider.dart';
import 'package:heart_thrive/routes/app_router.dart';
import '../../components/action_menu.dart';
import '../../providers/meal/meal_sodium_provider.dart';
import '../../services/home/risk_meter_service.dart';
import '../../services/meal_services.dart';
import '../../theme/app_theme.dart';

class AddMealPage extends ConsumerStatefulWidget {
  final MealEditData? editData;
  final bool isEditMode;
  final bool mealMenuMode;

  const AddMealPage({
    Key? key,
    this.editData,
    this.isEditMode = false,
    this.mealMenuMode = false,
  }) : super(key: key);

  @override
  ConsumerState<AddMealPage> createState() => _AddMealPageState();
}

class _AddMealPageState extends ConsumerState<AddMealPage> {
  // --- Controllers ---
  final TextEditingController _foodItemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _sodiumController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _fatsController = TextEditingController();

  // --- Local state ---
  int? selectedMealTypeId;
  String _selectedMeal = 'Select Meals';
  bool _isLoading = false;
  bool _isLoadingMealTypes = false;
  bool _addToMealMenu = false;
  bool _touchedQuantity = false;

  // Meal types
  List<Map<String, dynamic>> _mealTypes = [];
  List<String> _mealOptions = ['Select Meals'];

  // Original nutrients / quantity
  Map<String, double> _originalNutrients = {};
  double _originalQuantity = 0.0;

  // Validation
  String _quantityError = '';
  String _foodItemError = '';
  String _sodiumError = '';
  String _caloriesError = '';
  String _carbsError = '';
  String _proteinError = '';
  String _fatsError = '';

  bool _isQuantityValid = false;
  bool _isFoodItemValid = false;
  bool _isSodiumValid = false;
  bool _isCaloriesValid = false;
  bool _isCarbsValid = false;
  bool _isProteinValid = false;
  bool _isFatsValid = false;

  bool get _isFormValid {
    return _selectedMeal != 'Select Meals' &&
        _isFoodItemValid &&
        _quantityController.text.trim().isNotEmpty &&
        _isQuantityValid &&
        _isSodiumValid &&
        _isCaloriesValid &&
        _isCarbsValid &&
        _isProteinValid &&
        _isFatsValid;
  }

  @override
  void initState() {
    super.initState();
    if (kDebugMode) MealService.testBaseUrl();
    _attachValidators();
    _prefillFormData();
    _loadMealTypes();
  }

  bool _containsEmoji(String input) {
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}'     // Emoticons
      r'\u{1F300}-\u{1F5FF}'      // Misc Symbols and Pictographs
      r'\u{1F680}-\u{1F6FF}'      // Transport and Map
      r'\u{2600}-\u{26FF}'        // Misc symbols
      r'\u{2700}-\u{27BF}'        // Dingbats
      r'\u{1F900}-\u{1F9FF}'      // Supplemental Symbols and Pictographs
      r'\u{1FA70}-\u{1FAFF}'      // Symbols and Pictographs Extended-A
      r'\u{1F1E6}-\u{1F1FF}]',    // Regional indicator symbols (flags)
      unicode: true,
    );

    return emojiRegex.hasMatch(input);
  }

  void _attachValidators() {
    // Food Item - allow letters, numbers, space, -, ', .
    _foodItemController.addListener(() {
      final value = _foodItemController.text;
      if (value.isEmpty) {
        _foodItemError = 'Please fill Food Item name.';
        _isFoodItemValid = false;
      } else if(value.trim().length < 3){
        _foodItemError = 'Foot Item name should be at least 3 characters.';
        _isFoodItemValid = false;
      }
      else if (_containsEmoji(value)) {
        _foodItemError = 'Emojis are not allowed.';
        _isFoodItemValid = false;
      }
      else {
        _foodItemError = '';
        _isFoodItemValid = true;
      }
      setState(() {});
    });

    // Quantity
    _quantityController.addListener(() {
      if (!_touchedQuantity) _touchedQuantity = true;
      _validateQuantity(_quantityController.text.trim());
      _updateNutrientsBasedOnQuantity();
      setState(() {});
    });

    // Nutrient fields
    void validateNutrient(TextEditingController controller, Function(String) setError, Function(bool) setValid) {
      controller.addListener(() {
        final text = controller.text.trim();
        if (text.isEmpty) {
          setError('Required.');
          setValid(false);
        } else if (!RegExp(r'^\d*\.?\d+$').hasMatch(text)) {
          setError('Only numbers.');
          setValid(false);
        } else if (double.tryParse(text) == null || double.parse(text) < 0) {
          setError('Invalid number.');
          setValid(false);
        } else {
          setError('');
          setValid(true);
        }
        setState(() {});
      });
    }

    validateNutrient(_sodiumController, (e) => _sodiumError = e, (v) => _isSodiumValid = v);
    validateNutrient(_caloriesController, (e) => _caloriesError = e, (v) => _isCaloriesValid = v);
    validateNutrient(_carbsController, (e) => _carbsError = e, (v) => _isCarbsValid = v);
    validateNutrient(_proteinController, (e) => _proteinError = e, (v) => _isProteinValid = v);
    validateNutrient(_fatsController, (e) => _fatsError = e, (v) => _isFatsValid = v);
  }


  void _prefillFormData() {
    final data = widget.editData;
    if (data == null) return;

    _foodItemController.text = data.name ?? "";

    // --- Extract number from quantity ---
    final numberMatch = RegExp(r'(\d+(\.\d+)?)').firstMatch(data.quantity ?? "");
    final rawNumber = numberMatch?.group(1) ?? "100";

    // --- Build formatted quantity with unit ---
    String formattedQuantity = rawNumber;

    final unit = data.servingUnit?.trim().toLowerCase();

    if (unit != null && unit.isNotEmpty && unit != "null") {
      formattedQuantity = "$rawNumber $unit";
    }

    // ⭐ IMPORTANT — normalize original quantity to base unit
    _originalQuantity = _parseQuantityInBaseUnit(formattedQuantity);

    // --- Set quantity text ---
    _quantityController.text =
    widget.editData!.isCustom! ? '' : formattedQuantity;

    // --- Store original nutrients ---
    _originalNutrients = {
      'calories': data.calories ?? 0.0,
      'sodium': data.sodium ?? 0.0,
      'carbs': data.carbs ?? 0.0,
      'protein': data.protein ?? 0.0,
      'fats': data.fats ?? 0.0,
    };

    // --- Prefill nutrient controllers ---
    _caloriesController.text =
        (data.calories ?? 0.0).toStringAsFixed(2);

    _sodiumController.text =
        (data.sodium ?? 0.0).toStringAsFixed(2);

    _carbsController.text =
        (data.carbs ?? 0.0).toStringAsFixed(2);

    _proteinController.text =
        (data.protein ?? 0.0).toStringAsFixed(2);

    _fatsController.text =
        (data.fats ?? 0.0).toStringAsFixed(2);

    selectedMealTypeId = data.mealTypeId;
  }

  Future<void> _loadMealTypes() async {
    setState(() => _isLoadingMealTypes = true);
    try {
      final mealTypesData = await MealService.fetchMealTypes();
      if (mealTypesData.isNotEmpty) {
        _mealTypes = mealTypesData.map((m) => {'id': m['id'], 'name': m['name'] == 'All' ? 'Select Meals' : m['name']}).toList();
        _mealOptions = ['Select Meals', ..._mealTypes.map((m) => m['name'].toString())].toSet().toList();

        if (widget.editData != null) {
          final matched = _mealTypes.firstWhere((m) => m['id'] == widget.editData!.mealTypeId, orElse: () => {});
          if (matched.isNotEmpty) {
            _selectedMeal = matched['name'];
            selectedMealTypeId = matched['id'];
          }
        }
      } else {
        _setDefaultMealTypes();
      }
    } catch (e) {
      _setDefaultMealTypes();
    } finally {
      setState(() => _isLoadingMealTypes = false);
    }
  }

  void _setDefaultMealTypes() {
    _mealTypes = [
      {"id": 21, "name": "Breakfast"},
      {"id": 22, "name": "Lunch"},
      {"id": 23, "name": "Snacks"},
      {"id": 24, "name": "Dinner"},
    ];
    _mealOptions = ['Select Meals', 'Breakfast', 'Lunch', 'Snacks', 'Dinner'];
    if (widget.editData != null) {
      final matched = _mealTypes.firstWhere((m) => m['id'] == widget.editData!.mealTypeId, orElse: () => {});
      if (matched.isNotEmpty) {
        _selectedMeal = matched['name'];
        selectedMealTypeId = matched['id'];
      }
    }
  }

  // 1. FIXED: Correctly extract quantity in GRAMS or ML (normalized)
  // 1. FIXED: Correctly extract quantity in GRAMS or ML (normalized)
  double _parseQuantityInBaseUnit(String input) {
    final regex = RegExp(
      r'^(\d+(\.\d+)?)\s*(kg|g|gm|grm|mg|ml|mlt|iu|mc|oz)$',
      caseSensitive: false,
    );

    final match = regex.firstMatch(input.trim());
    if (match == null) return 0.0;

    final value = double.parse(match.group(1)!);
    final unit = match.group(3)!.toLowerCase();

    switch (unit) {
      case 'kg':
        return value * 1000; // kg → g
      case 'mg':
        return value / 1000; // mg → g
      case 'oz':
        return value * 28.3495; // oz → g
      case 'g':
      case 'gm':
      case 'grm':
        return value;
      case 'ml':
      case 'mlt':
        return value; // ml treated same as g
      case 'iu':
      case 'mc':
        return value; // kept as-is (unit-based)
      default:
        return 0.0;
    }
  }


// 2. FIXED: Validate quantity (allow up to 1000g/ml OR 1kg/1L)
  void _validateQuantity(String value) {
    if (value.trim().isEmpty) {
      _quantityError = 'Quantity is required';
      _isQuantityValid = false;
      setState(() {});
      return;
    }

    final baseQty = _parseQuantityInBaseUnit(value);

    if (baseQty <= 0) {
      _quantityError = 'Invalid quantity';
      _isQuantityValid = false;
    } else if (baseQty > 1000) {
      _quantityError = 'Maximum allowed is 1000g/ml or 1kg/1L';
      _isQuantityValid = false;
    } else {
      _quantityError = '';
      _isQuantityValid = true;
    }

    setState(() {});
  }

// 3. FIXED: Nutrient scaling – CORRECT factor calculation
  void _updateNutrientsBasedOnQuantity() {
    if (_originalQuantity <= 0) return;

    final currentBaseQty = _parseQuantityInBaseUnit(_quantityController.text);
    //if (currentBaseQty <= 0) return;

    // Correct ratio: current / original (both in grams or ml)
    final factor = currentBaseQty / _originalQuantity;

    void update(String key, TextEditingController controller) {
      final originalValue = _originalNutrients[key] ?? 0.0;
      final newValue = (originalValue * factor).toStringAsFixed(2);

      // Prevent unnecessary rebuilds
      if (controller.text != newValue) {
        controller.text = newValue;
      }
    }

    update('calories', _caloriesController);
    update('sodium', _sodiumController);
    update('carbs', _carbsController);
    update('protein', _proteinController);
    update('fats', _fatsController);
  }

  Map<String, String> _parseQuantityAndUnit(String raw) {
    final match = RegExp(
      r'^(\d+(\.\d+)?)\s*(kg|g|gm|grm|mg|ml|mlt|iu|mc|oz)$',
      caseSensitive: false,
    ).firstMatch(raw.trim());

    return {
      'quantity': match?.group(1) ?? '',
      'unit': match?.group(3)?.toLowerCase() ?? '',
    };
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Image.asset(
                'lib/assets/Check Mark.png',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.isEditMode ? 'Updated $_selectedMeal' : 'Added to $_selectedMeal',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6F6C90)),
            ),
            const SizedBox(height: 8),
            const Text('Successfully', textAlign: TextAlign.center,style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6F6C90))),
            const SizedBox(height: 24),
            SizedBox(
              width: 100,
              child: ElevatedButton(
                onPressed: () {
                  if(widget.isEditMode){
                    Navigator.pop(context);
                    Navigator.pop(context);
                    AppRouter.replaceWithAllMealIntakeIndex(context,0);
                  }else{
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pop(context);
                    // Always refresh providers BEFORE popping
                    _refreshAllMealProviders();

                    // Pop everything back to MealLogsPage with success flag
                    AppRouter.replaceWithAllMealIntakeIndex(context,0);
                  }


                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                child: const Text('OK',style: AppTheme.whiteTitle14,),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 60,
              height: 60,
              decoration:
              const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.error, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Error',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: const Text('OK'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // Refresh the riverpod
  void _refreshAllMealProviders() {
    Future.microtask((){
      ref.invalidate(riskMetricsFutureProvider);
      // Meal logs list
      ref.invalidate(mealLogsProvider);
      // Meal menu list
      ref.invalidate(mealsProvider);
      // Nutrient summary (today)
      ref.invalidate(todayNutrientProvider);
      // Generic nutrient summary (family provider)
      ref.invalidate(nutrientSummaryProvider);
      ref.invalidate(nutrientSummaryByMealTypeProvider);

      //ref.invalidate(notificationProvider);
      ref.invalidate(notificationProvider);
      ref.read(notificationProvider.notifier).loadFirstPage();
    });
  }


  // --- API calls (Add / Update variants) ---
  Future<void> _handleAddMeal() async {
    if (!_checkAllFieldsBeforeSubmit()) return;

    setState(() => _isLoading = true);
    try {
      debugPrint("Sodium ${_sodiumController.text}");
      double toTwoDecimals(String? value) {
        final parsed = double.tryParse(value?.trim() ?? '');
        if (parsed == null) return 0.0;       // if null, empty, or invalid → 0.0
        return double.parse(parsed.toStringAsFixed(2));
      }

      final parsed = _parseQuantityAndUnit(_quantityController.text.trim());
      final sodium   = toTwoDecimals(_sodiumController.text);
      final calories = toTwoDecimals(_caloriesController.text);
      final carbs    = toTwoDecimals(_carbsController.text);
      final protein  = toTwoDecimals(_proteinController.text);
      final fats     = toTwoDecimals(_fatsController.text);


      final success = await MealService.createMealLog(
        mealType: _selectedMeal,
        quantity: parsed['quantity'] ?? '',
        unitType: parsed['unit'] ?? '',
        logDate: DateTime.now(),
        foodItemName: _foodItemController.text.trim(),
        brandName: 'Custom',
        foodCategoryId: 0,
        foodTypeId: 0,
        sodiumAmount: sodium,
        caloriesAmount: calories,
        carbsAmount: carbs,
        proteinAmount: protein,
        fatsAmount: fats,
        addToMealMenu: _addToMealMenu,
      );

      if (success) {
        _showSuccessModal();
      } else {
        _showErrorDialog('Failed to add meal. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEditMealLog() async {
    if (!_checkAllFieldsBeforeSubmit()) return;

    setState(() => _isLoading = true);
    try {
      final parsed = _parseQuantityAndUnit(_quantityController.text.trim());
      final sodium = double.tryParse(_sodiumController.text.trim()) ?? 0.0;
      final calories = double.tryParse(_caloriesController.text.trim()) ?? 0.0;
      final carbs = double.tryParse(_carbsController.text.trim()) ?? 0.0;
      final protein = double.tryParse(_proteinController.text.trim()) ?? 0.0;
      final fats = double.tryParse(_fatsController.text.trim()) ?? 0.0;

      final success = await MealService.updateMealLog(
        mealId: widget.editData!.id!,
        mealType: _selectedMeal,
        quantity: parsed['quantity'] ?? '',
        unitType: parsed['unit'] ?? '',
        logDate: DateTime.now(),
        foodItemName: _foodItemController.text.trim(),
        brandName: 'Custom',
        foodCategoryId: 0,
        foodTypeId: 0,
        sodiumAmount: sodium,
        caloriesAmount: calories,
        carbsAmount: carbs,
        proteinAmount: protein,
        fatsAmount: fats,
        addToMealMenu: _addToMealMenu,
      );

      if (success) {
        _showSuccessModal();
      } else {
        _showErrorDialog('Failed to update meal. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEditMealMenu() async {
    if (!_checkAllFieldsBeforeSubmit()) return;

    setState(() => _isLoading = true);
    try {
      final parsed = _parseQuantityAndUnit(_quantityController.text.trim());
      final sodium = double.tryParse(_sodiumController.text.trim()) ?? 0.0;
      final calories = double.tryParse(_caloriesController.text.trim()) ?? 0.0;
      final carbs = double.tryParse(_carbsController.text.trim()) ?? 0.0;
      final protein = double.tryParse(_proteinController.text.trim()) ?? 0.0;
      final fats = double.tryParse(_fatsController.text.trim()) ?? 0.0;

      final successUpdate = await MealService.updateMealMenu(
        mealId: widget.editData!.id!,
        mealType: _selectedMeal,
        quantity: parsed['quantity'] ?? '',
        unitType: parsed['unit'] ?? '',
        logDate: DateTime.now(),
        foodItemName: _foodItemController.text.trim(),
        brandName: 'Custom',
        foodCategoryId: 0,
        foodTypeId: 0,
        sodiumAmount: sodium,
        caloriesAmount: calories,
        carbsAmount: carbs,
        proteinAmount: protein,
        fatsAmount: fats,
        addToMealMenu: _addToMealMenu,
      );

      final successCreate = await MealService.createMealLog(
        mealType: _selectedMeal,
        quantity: parsed['quantity'] ?? '',
        unitType: parsed['unit'] ?? '',
        logDate: DateTime.now(),
        foodItemName: _foodItemController.text.trim(),
        brandName: 'Custom',
        foodCategoryId: 0,
        foodTypeId: 0,
        sodiumAmount: sodium,
        caloriesAmount: calories,
        carbsAmount: carbs,
        proteinAmount: protein,
        fatsAmount: fats,
        addToMealMenu: _addToMealMenu,
      );

      if (successUpdate && successCreate) {
        _showSuccessModal();
      } else {
        _showErrorDialog('Failed to update meal. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _checkAllFieldsBeforeSubmit() {
    if (!_isFormValid) {
      _showErrorDialog('Please fill all fields correctly');
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: Center(child: Text(widget.isEditMode ? 'Edit Meal' : 'Add Meal')),
        leading: GestureDetector(onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image.asset("lib/assets/Frame.png"),
            )),
        actions: [
          actionMenuItem(context),

        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.grey.shade300, spreadRadius: 1, blurRadius: 6, offset: const Offset(0, 3))],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Meals', style: AppTheme.title16),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration( borderRadius: BorderRadius.circular(8),color: Colors.grey.shade100),
                    child: _isLoadingMealTypes
                        ? const Padding(padding: EdgeInsets.all(12), child: Text('Loading...'))
                        : DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        value: _selectedMeal,

                        dropdownStyleData: DropdownStyleData(
                          width: MediaQuery.of(context).size.width*0.83, // FULL WIDTH
                          padding: EdgeInsets.zero,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                        ),

                        menuItemStyleData: const MenuItemStyleData(
                          padding: EdgeInsets.zero, // IMPORTANT
                        ),

                        items: _mealOptions.map((v) {
                          final selected = v == _selectedMeal;

                          return DropdownMenuItem<String>(
                            value: v,
                            child: Container(
                              width: double.infinity, // NOW IT FILLS FULL WIDTH
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              decoration: BoxDecoration(
                                color: selected ?  AppTheme.primaryColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                v,
                                style: TextStyle(
                                  color: selected ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),

                        onChanged: (val) {
                          setState(() => _selectedMeal = val!);
                        },

                        selectedItemBuilder: (_) {
                          return _mealOptions.map(
                                (v) => Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(v),
                            ),
                          ).toList();
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text('Food Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _foodItemController,
                    enabled: !widget.isEditMode,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r"[a-zA-Z0-9 .,'’\-–&]"),
                      )
                    ],
                    decoration: InputDecoration(
                      hintText: 'Enter food item',
                      errorText: _foodItemError.isEmpty ? null : _foodItemError,
                      hintStyle: const TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.grey.shade100,

                      // No border normally
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,

                      // Focus border (only when no error)
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),

                      // Error border (red)
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),

                      // Error border when field is focused
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),

                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),


                  const SizedBox(height: 16),
                  const Text('Quantity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      hintText: 'e.g., 100g, 500ml, 1kg',
                      errorText: _touchedQuantity && _quantityError.isNotEmpty ? _quantityError : null,
                      hintStyle: TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      enabledBorder: InputBorder.none,
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.primaryColor)),),
                    keyboardType: TextInputType.text,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z\.\s]'))],

                  ),

                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: _buildNutrientField('Sodium (mg)', _sodiumController, 'mg', _sodiumError)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildNutrientField('Calories (kcal)', _caloriesController, 'kcal', _caloriesError)),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _buildNutrientField('Carbs (g)', _carbsController, 'g', _carbsError)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildNutrientField('Proteins (g)', _proteinController, 'g', _proteinError)),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _buildNutrientField('Fats (g)', _fatsController, 'g', _fatsError)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: widget.isEditMode? Spacer():Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Checkbox(value: _addToMealMenu, activeColor: AppTheme.primaryColor, onChanged: (v) => setState(() => _addToMealMenu = v ?? true)),
                        Flexible(child: Text(widget.mealMenuMode ? 'Update in Meal Menu' : 'Add to Meal Menu', style: const TextStyle(fontWeight: FontWeight.bold))),
                      ]),
                    ),
                  ]),

                  const SizedBox(height: 30),
                  Row(children: [
                    Expanded(child: OutlinedButton(onPressed: () {
                      _foodItemController.clear();
                      _quantityController.clear();
                      _sodiumController.clear();
                      _caloriesController.clear();
                      _carbsController.clear();
                      _proteinController.clear();
                      _fatsController.clear();
                      setState(() {
                        _selectedMeal = 'Select Meals';
                        _addToMealMenu = false;
                      });
                    }, child: const Text('Clear All'))),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading || !_isFormValid
                            ? null
                            : widget.isEditMode
                            ? (widget.mealMenuMode && _addToMealMenu ? _handleEditMealMenu : _handleEditMealLog)
                            : _handleAddMeal,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(widget.isEditMode ? "Update Meal" : "Add Meal"),
                          const SizedBox(width: 5),
                          const Icon(Icons.add_circle, color: Colors.white, size: 25)
                        ]),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
          if (_isLoading) ...[
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
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const CircularProgressIndicator(color: AppTheme.primaryColor),
                          const SizedBox(height: 12),
                          Text(_isLoading ? 'Saving meal...' : 'Loading...', style: const TextStyle(color: Colors.white)),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ],
      ),
    );
  }

  Widget _buildNutrientField(
      String label,
      TextEditingController controller,
      String suffix,
      String error,
      ) {
    // STEP 1: Set max digits before decimal
    int maxDigits = 4;

    switch (label.toLowerCase()) {
      case "sodium (mg)":
        maxDigits = 4;
        break;
      case "calories (kcal)":
        maxDigits = 3;
        break;
      case "fats (g)":
      case "proteins (g)":
      case "carbs (g)":
        maxDigits = 2;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.title16),
        const SizedBox(height: 6),

        Container(
          padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.shade100,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: TextField(
                  controller: controller,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),

                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),

                    // 🔥 MAX DIGITS BEFORE & AFTER DECIMAL
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final text = newValue.text;

                      if (text.isEmpty) return newValue;

                      // Prevent multiple decimals
                      if ('.'.allMatches(text).length > 1) return oldValue;

                      final parts = text.split('.');

                      final before = parts[0];
                      final after = parts.length > 1 ? parts[1] : "";

                      // Max digits before decimal
                      if (before.length > maxDigits) return oldValue;

                      // Max 2 digits after decimal
                      if (after.length > 2) return oldValue;

                      return newValue;
                    }),
                  ],

                  decoration: InputDecoration(
                    hintText: 'e.g., 50',
                    errorText: error.isEmpty ? null : error,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryColor, width: 2),
                    ),

                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(color: Colors.red, width: 2),
                    ),

                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),
              Text(suffix),
            ],
          ),
        ),
      ],
    );
  }


  @override
  void dispose() {
    _foodItemController.dispose();
    _quantityController.dispose();
    _sodiumController.dispose();
    _caloriesController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatsController.dispose();
    super.dispose();
  }
}