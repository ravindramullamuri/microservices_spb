import 'dart:async';

import 'package:flutter/material.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:heart_thrive/components/action_menu.dart';
import 'package:heart_thrive/components/decimal_formatter.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import 'package:heart_thrive/models/meal/edit_meal_model.dart';
import 'package:heart_thrive/models/meal/meal_logs_response.dart';

import 'package:heart_thrive/models/meal/food_item_with_nutrients_response.dart';
import 'package:heart_thrive/models/meal/patient_meal_menus_models.dart';
import '../../constants/heart_thrive_strings_constants.dart';
import '../../models/meal/meal_log_model.dart';
import 'package:heart_thrive/models/meal/nutrient.dart' as Nut;             // canonical Nutrient
import 'package:heart_thrive/models/meal/nutrient_response.dart' as Resp;  // response Nutrient
import '../../services/meal_services.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class AllMealIntakePage extends StatefulWidget {
  final int? initialTabIndex;
  final String? navFromPage;

  const AllMealIntakePage({Key? key, this.initialTabIndex,this.navFromPage}) : super(key: key);

  @override
  State<AllMealIntakePage> createState() => _AllMealIntakePageState();
}

class _AllMealIntakePageState extends State<AllMealIntakePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _initialLoadCompleted = false;
  bool _showFoodList = false;
  bool _showMealMenuPicker = false;
  bool _isBrowseFoodSelected = true; // Browse Food is selected by default
  bool _showCustomItemUI = false; // Flag to show custom item UI
  bool _showMoreInfo = false; // Flag to show/hide macronutrient details
  bool _showContextMenu = false; // Flag to show/hide context menu for All Meal tab
  final TextEditingController _searchController = TextEditingController();
  final formatter = NumberFormat('#,###');
  double _sodiumConsumed = 0.0;
  double _sodiumTarget = 2500.0;
  bool _isLoadingSodiumData = false;
  bool _hasSodiumError = false;

  List<FoodItemWithNutrientsItem> _allMeals = [];      // all meals from API
  List<FoodItemWithNutrientsItem> _filteredMeals = []; // meals shown in UI
  bool _isLoadingMeals = false;
  String _searchQuery = '';
  Timer? _debounce;
  bool _isSearchMode = false;
  Timer? _searchDebounce;

  final ScrollController _scrollController = ScrollController();

  List<FoodItemWithNutrientsItem> _foodItems = [];

  int _currentPage = 0;
  final int _pageSize = 20;

  bool _isLoading = false;
  bool _hasMoreData = true;

  int _searchRequestId = 0;

  // Meal Menu Picker state variables
  List<PatientMealMenuModel> _mealMenuPickerData = [];
  PatientMealMenuModel? processedItem;
  bool _isLoadingMealMenuPicker = false;
  bool _hasMealMenuPickerError = false;
  double? sodiumLeft;
  double? progressValue;
  bool _showMealIntakeStats = true;

  // API data for meal tabs (for browsing items)
  Map<String, List<MealLogModel>> _mealLogsData = {};


  // User-added meals (meals actually added to meal plan)
  Map<String, List<MealLogModel>> _userAddedMeals = {};
  Map<String, List<FoodItemWithNutrientsItem>> _userAddedMealsMap = {};

  Map<String, List<MealLogModel>> _userAddedMealLogs = {
    'All Meal': [],
    'Breakfast': [],
    'Lunch': [],
    'Snacks': [],
    'Dinner': [],
  };

  Map<String, List<PatientMealMenuModel>> _userAddedMealMenuItems = {
    'All Meal': [],
    'Breakfast': [],
    'Lunch': [],
    'Snacks': [],
    'Dinner': [],
  };

  Map<String, bool> _isLoadingMealLogs = {
    'All Meal': false,
    'Breakfast': false,
    'Lunch': false,
    'Snacks': false,
    'Dinner': false,
  };
  Map<String, bool> _hasError = {
    'All Meal': false,
    'Breakfast': false,
    'Lunch': false,
    'Snacks': false,
    'Dinner': false,
  };




  // Flag to show added items for different meal types
  Map<String, bool> _showAddedItems = {
    'All Meal': false,
    'Breakfast': true,
    'Lunch': false,
    'Snacks': false,
    'Dinner': false,
  };

  // Meal type names for dynamic content
  final List<String> _mealTypes = ['All Meal', 'Breakfast', 'Lunch', 'Snacks', 'Dinner'];

  // Map meal types to their respective IDs
  final Map<String, int> _mealTypeIds = {
    'All Meal': 20,  // We'll handle this specially
    'Breakfast': 21,
    'Lunch': 22,
    'Snacks': 23,
    'Dinner': 24,
  };
  List<Resp.Nutrient> _nutrients = [];
  double calorieNutrientConsumed = 0.0;
  double calorieNutrientTargeted = 0.0;
  double _carbsNutrientConsumed = 0.0;
  double _carbsNutrientTargeted = 0.0;
  double _proteinNutrientConsumed = 0.0;
  double _proteinNutrientTargeted = 0.0;
  double _fatsNutrientConsumed = 0.0;
  double _fatsNutrientTargeted = 0.0;



  @override
  void initState() {
    super.initState();
    //BackButtonInterceptor.add(_onBackPressed);
    _tabController = TabController(length: 5, vsync: this);
    if(widget.initialTabIndex != null){
      _tabController.index = widget.initialTabIndex!;
    }else{
      _tabController.index = 0;
    }


    // _tabController.addListener(() {
    //   _fetchMealsByType(_getCurrentMealType());
    //
    //   if (_showMealMenuPicker) {
    //     _fetchMealMenuPickerData();
    //   }
    //
    //   if (_showContextMenu) {
    //     setState(() {
    //       _showContextMenu = false;
    //     });
    //   }
    //
    //   setState(() {});
    // });

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;

      if (_isSearchMode) return;

      _loadMeals(isNewSearch: true);
    });

    _initialLoad();

    _loadMeals(isNewSearch: true);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 120 &&
          !_isLoading &&
          _hasMoreData
      ) {
        _loadMeals();
      }
    });

  }




  bool _onBackPressed(bool stopDefaultButtonEvent, RouteInfo info) {
    AppRouter.replaceWithHome(context);

    return true;
    // IMPORTANT: Returning true consumes the back event
    // and prevents Flutter from popping the current screen.
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoadingMeals = true;
      _isLoadingSodiumData = true;
      _isLoadingMealMenuPicker = true;
      _searchController.clear();
    });

    // reload API data only
    await _initialLoad();
    await _fetchMealsByType(_getCurrentMealType());

    setState(() {
      _isLoadingMeals = false;
      _isLoadingSodiumData = false;
      _isLoadingMealMenuPicker = false;
    });
  }

  Future<void> _initialLoad() async {
    setState(() => _initialLoadCompleted = false);

    // Start API calls in parallel
    await Future.wait([
      _loadSodiumData(),
      _fetchAllMealTypes(),
    ]);

    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() => _initialLoadCompleted = true);
  }


  Future<void> _loadMeals({bool isNewSearch = false}) async {
    if (isNewSearch) {
      _currentPage = 0;
      _foodItems.clear();
      _hasMoreData = true;
    }

    // 🔑 Increment request ID
    final int requestId = ++_searchRequestId;

    setState(() => _isLoading = true);

    final response = await MealService.fetchAllMealLogs(
      mealTypeName: _getCurrentMealType(),
      foodItemName: _isSearchMode ? _searchQuery : '',
      page: _currentPage,
      size: _pageSize,
    );

    // ❌ Ignore outdated responses
    if (requestId != _searchRequestId) {
      return;
    }

    if (response != null) {
      setState(() {
        if (_currentPage == 0) {
          _foodItems = response.content;
        } else {
          _foodItems.addAll(response.content);
        }

        _currentPage++;

        if (_currentPage >= response.totalPages) {
          _hasMoreData = false;
        }
      });
    }

    setState(() => _isLoading = false);
  }

  String cleanSearch(String search){
    return search.replaceAll(RegExp(r'\s+'), ' ').trim();
  }


  // Fetch meal logs data for all meal types
  Future<void> _fetchAllMealTypes() async {
    if (kDebugMode) {
      debugPrint('🔄 Fetching meal logs data for all meal types...');
    }

    // Fetch data for each meal type
    for (String mealType in _mealTypes) {
      if (mealType != 'All Meal') { // Skip 'All Meal' as it's handled differently
        _fetchMealsByType(mealType);
      }
    }

    // For 'All Meal', we'll use fetchMealLogs which gets all food items
    _fetchMealsByType('All Meal');
  }

  // Fetch meal logs data for a specific meal type
// ---------- Updated _fetchMealsByType (use model API, convert to Map for UI) ----------
  Future<void> _fetchMealsByType(String mealType) async {
    if (kDebugMode) {
      debugPrint('🔄 Fetching meal logs data for $mealType...');
    }

    // Skip if already loading
    if (_isLoadingMealLogs[mealType] == true) return;

    setState(() {
      _isLoadingMealLogs[mealType] = true;
      _hasError[mealType] = false;
    });

    try {
      List<MealLogModel> mealLogs = [];

      if (mealType == 'All Meal') {
        // If this method is still returning Map, update it later
        final maps = await MealService.fetchMealLogsForAllMeals(mealType);
        mealLogs = maps.map((m) => MealLogModel.fromJson(m)).toList();
      } else {
        // NEW MODEL-BASED RESPONSE
        final MealLogsResponse? response = await MealService.fetchMealLogs(mealType);

        if (response != null) {
          mealLogs = response.content; // DIRECT MODEL LIST
        } else {
          mealLogs = [];
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Received ${mealLogs.length} meal logs for $mealType');
      }

      setState(() {
        _mealLogsData[mealType] = mealLogs;
        _userAddedMeals[mealType] = List.from(mealLogs); // keep separate copy
        _showAddedItems[mealType] = mealLogs.isNotEmpty;
        _isLoadingMealLogs[mealType] = false;
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching meal logs for $mealType: $e');
        //debugPrint(st);
      }
      setState(() {
        _isLoadingMealLogs[mealType] = false;
        _hasError[mealType] = true;
      });
    }
  }

  Future<void> _loadSodiumData() async {
    setState(() {
      _isLoadingSodiumData = true;
      _hasSodiumError = false;
    });

    try {
      // Get current date for today's sodium data
      final now = DateTime.now();
      final fromDate = DateTime(now.year, now.month, now.day, 0, 0);
      final toDate   = DateTime(now.year, now.month, now.day, 23, 59);

      debugPrint('🔄 Loading sodium data for In ALL MEAL INTAKE: $fromDate to $toDate');

      // ✅ Pass DateTime instead of String
      Resp.NutrientResponse? nutrientData = await MealService.fetchNutrientSummary(fromDate, toDate);

      if (nutrientData != null && nutrientData.nutrients != null ) {
        final nutrients = nutrientData.nutrients;

        // Find sodium nutrient
        for (Resp.Nutrient nutrient in nutrients) {
          if (nutrient.name == 'Sodium') {
            setState(() {
              _sodiumConsumed = (nutrient.amount ?? 0).toDouble();
              _sodiumTarget   = (nutrient.maxValue ?? 2500).toDouble();
              _isLoadingSodiumData = false;
            });
            debugPrint('✅ Sodium data loaded: ${_sodiumConsumed}mg consumed, ${_sodiumTarget}mg target');
            return;
          }
          if(nutrient.name == "Calories"){
            calorieNutrientConsumed = (nutrient.amount ?? 0).toDouble();
            calorieNutrientTargeted = (nutrient.maxValue ?? 2500).toDouble();
          }
          if(nutrient.name == "Carbohydrates"){
            _carbsNutrientConsumed = (nutrient.amount ?? 0).toDouble();
            _carbsNutrientTargeted = (nutrient.maxValue ?? 2500).toDouble();
          }
          if(nutrient.name == "Protein"){
            _proteinNutrientConsumed = (nutrient.amount ?? 0).toDouble();
            _proteinNutrientTargeted = (nutrient.maxValue ?? 2500).toDouble();
          }
          if(nutrient.name == "Fat"){
            _fatsNutrientConsumed = (nutrient.amount ?? 0).toDouble();
            _fatsNutrientTargeted = (nutrient.maxValue ?? 2500).toDouble();
          }
        }


        setState(() {
          _nutrients = nutrientData.nutrients;
        });

        // Sodium not found
        setState(() {
          _isLoadingSodiumData = false;
        });
        debugPrint('⚠️ Sodium nutrient not found in API response');
      } else {
        setState(() {
          _isLoadingSodiumData = false;
        });
        debugPrint('⚠️ No nutrient data received from API');
      }
    } catch (e) {
      debugPrint('❌ Error loading sodium data: $e');
      setState(() {
        _isLoadingSodiumData = false;
        _hasSodiumError = true;
      });
    }
  }


  // Fetch meal menu picker data using the new API
  Future<void> _fetchMealMenuPickerData() async {
    if (kDebugMode) {
      debugPrint('🔄 Fetching meal menu picker data...');
    }

    // Skip if already loading
    if (_isLoadingMealMenuPicker) {
      return;
    }

    setState(() {
      _isLoadingMealMenuPicker = true;
      _hasMealMenuPickerError = false;
    });

    try {
      // Get current meal type ID
      String currentMealType = _getCurrentMealType();
      int mealTypeId = _mealTypeIds[currentMealType] ?? 13;

      // Create date range (today only)
      DateTime now = DateTime.now();
      String fromDateStr =
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
      String toDateStr = fromDateStr;

      if (kDebugMode) {
        debugPrint(
            '🍽️ Fetching meal menu picker data for mealTypeId: $mealTypeId, fromDate: $fromDateStr, toDate: $toDateStr');
      }

      // CALL API → MODEL RESPONSE
      final response = await MealService.fetchPatientMealMenusWithNutrients(
        fromDate: fromDateStr,
        toDate: toDateStr,
        mealTypeId: mealTypeId,
      );

      if (response == null) {
        throw Exception("Null API response");
      }

      // Extract list of menu items from model
      List<PatientMealMenuModel> mealMenuData = response.content;

      if (kDebugMode) {
        debugPrint('✅ Received ${mealMenuData.length} meal menu items for $currentMealType');
      }

      // Optional: Filtering (if needed)
      List<PatientMealMenuModel> filteredData = mealMenuData;

      setState(() {
        _mealMenuPickerData = filteredData;   // <-- MODEL LIST, NOT MAP
        _isLoadingMealMenuPicker = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching meal menu picker data: $e');
      }

      setState(() {
        _isLoadingMealMenuPicker = false;
        _hasMealMenuPickerError = true;
      });
    }
  }


  @override
  void dispose() {
    //BackButtonInterceptor.remove(_onBackPressed);
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _showContextMenuSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Go To Home'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  AppRouter.navigateToHome(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getPageTitle() {
    switch (_tabController.index) {
      case 0:
        return 'All Meal Intake';
      case 1:
        return 'Breakfast Intake';
      case 2:
        return 'Lunch Intake';
      case 3:
        return 'Snacks Intake';
      case 4:
        return 'Dinner Intake';
      default:
        return 'All Meal Intake';
    }
  }

  String _getQuickSearchImg() {
    switch (_tabController.index) {
      case 0:
        return 'lib/assets/ss-removebg-preview 1.png';
      case 1:
        return 'lib/assets/default_breakfast.png';
      case 2:
        return 'lib/assets/default_lunch_bg.png';
      case 3:
        return 'lib/assets/default_snacks.png';
      case 4:
        return 'lib/assets/default_dinner.png';
      default:
        return 'lib/assets/ss-removebg-preview 1.png';
    }

  }

  String _getQuickSearchText() {
    switch (_tabController.index) {
      case 0:
        return 'Find your favorite food with a quick search!';
      case 1:
        return 'Find your favorite breakfast food with a quick search!';
      case 2:
        return 'Find your favorite lunch food with a quick search!';
      case 3:
        return 'Find your favorite snacks with a quick search!';
      case 4:
        return 'Find your favorite dinner food with a quick search!';
      default:
        return 'Find your favorite food with a quick search!';
    }

  }

  String _getCurrentMealType() {
    return _mealTypes[_tabController.index];
  }

  List<MealLogModel> _getCurrentFoodItems() {
    final String mealType = _getCurrentMealType();

    final list = _mealLogsData[mealType];
    if (list == null || list.isEmpty) {
      return [];
    }

    if (kDebugMode) {
      debugPrint('🍽️ Processing ${list.length} meal logs for $mealType');
    }

    return list; // ← simply return model list (no Map conversion)
  }

  bool _hasAddedItems() {
    String mealType = _getCurrentMealType();

    debugPrint('Checking items for: $mealType');
    debugPrint('_userAddedMeals: $_userAddedMeals');
    debugPrint('_showAddedItems: $_showAddedItems');
    // Check if there are user-added meals for this meal type
    if (_userAddedMeals[mealType]?.isNotEmpty == true) {
      return true;
    }

    // Fallback to the static flag
    return true;
  }

  // Get user-added meals for the current meal type
  List<MealLogModel> _getUserAddedMeals() {
    String mealType = _getCurrentMealType();

    // Case 1: single tab → return directly
    if (mealType != "All Meal") {
      return _userAddedMeals[mealType] ?? [];
    }

    // Case 2: All Meal → merge all lists in correct order
    final merged = <MealLogModel>[];

    // Add in FIXED order
    final orderedKeys = ["Breakfast", "Lunch", "Snacks", "Dinner"];

    for (var key in orderedKeys) {
      if (_userAddedMeals[key] != null) {
        merged.addAll(_userAddedMeals[key]!);
      }
    }

    return merged;
  }

  // Build context menu for All Meal tab
  Widget _buildContextMenu() {
    if (!_showContextMenu) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Select All option
          GestureDetector(
            onTap: () {
              // Handle Select All action
              setState(() {
                _showContextMenu = false;
              });
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 2.0),
              child: Text(
                'Select All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const Divider(),

          // Meal type options
          GestureDetector(
            onTap: () {
              // Handle Breakfast filter
              setState(() {
                _showContextMenu = false;
              });
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 2.0),
              child: Text(
                'Breakfast',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const Divider(),

          GestureDetector(
            onTap: () {
              // Handle Lunch filter
              setState(() {
                _showContextMenu = false;
              });
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 2.0),
              child: Text(
                'Lunch',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const Divider(),

          GestureDetector(
            onTap: () {
              // Handle Snacks filter
              setState(() {
                _showContextMenu = false;
              });
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 2.0),
              child: Text(
                'Snacks',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const Divider(),

          GestureDetector(
            onTap: () {
              // Handle Dinner filter
              setState(() {
                _showContextMenu = false;
              });
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 2.0),
              child: Text(
                'Dinner',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    debugPrint("All Meal Intake Page ${widget.navFromPage }");
    double sodiumLeft = _sodiumTarget - _sodiumConsumed;
    String formattedSodiumleft = formatter.format(sodiumLeft);
    String formattedSodiumTarget = formatter.format(_sodiumTarget);
    double progressValue = _sodiumTarget > 0 ? (_sodiumConsumed / _sodiumTarget).clamp(0.0, 1.0) : 0.0;
    String currentMealType = _getCurrentMealType();
    if(currentMealType == "All Meal") {
      currentMealType = "Daily";
    };

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.appBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: Center(child: Text(_getPageTitle(),style: AppTheme.whiteTitle23,)),
        leading: GestureDetector(
          onTap: () {
            debugPrint("widget.navFromPage : ${widget.navFromPage}" );
            //debugPrint("Result ${widget.navFromPage == NavPageType.profile.name}");
            if(widget.navFromPage == NavPageType.home.name || widget.navFromPage == null){
              AppRouter.replaceWithHome(context);
            }else{
              Navigator.pop(context);
            }

          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset("lib/assets/Frame.png"),
          ),
        ),

        actions: [
          // Add refresh button to manually refresh meal logs data
          actionMenuItem(context)
        ],
      ),
      body:  RefreshIndicator(
        onRefresh: () => _refresh(),
        child: SafeArea(
          child:Column(
            children: [
              // Combined Card Section (Daily Meal Intake + Tabs + More Info)
              _isLoadingSodiumData?

              Container(
                color: Colors.white,
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 20),
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                ),
              ):
              Visibility(
                visible: _showMealIntakeStats,
                child: Container(
                  margin: const EdgeInsets.all(16.0),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 5),
                  decoration:  BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0), // rounded corners
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300, // shadow color
                        spreadRadius: 1, // spread
                        blurRadius: 6,   // softness of shadow
                        offset: const Offset(0, 3), // position of shadow (x, y)
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Total Calories Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$currentMealType Meal Intake',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            '${formatNumberWithCommas(calorieNutrientConsumed)} kcal',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Progress Bar Section
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Consumed
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${formatNumberWithCommas(_sodiumConsumed)} mg',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Text(
                                  "Consumed",
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),

                            // Progress bar with "Left" label centered
                            Expanded(
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progressValue,
                                      backgroundColor: Colors.grey.shade400,
                                      color: AppTheme.primaryColor,
                                      minHeight: 5,
                                    ),
                                  ),
                                  SizedBox(height: 2,),
                                  Text(
                                    _sodiumConsumed > 2500
                                        ? "${formatNumberWithCommas((_sodiumConsumed - _sodiumTarget))} mg limit exceeded"
                                        : "${formatNumberWithCommas(sodiumLeft)} mg left",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Target
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${formattedSodiumTarget} mg',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Text(
                                  "Target",
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // More Info / Less Info Toggle Section
                      Column(
                        children: [
                          // Toggle Button
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showMoreInfo = !_showMoreInfo;
                              });
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF95020A),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _showMoreInfo ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _showMoreInfo ? 'Less Info' : 'More Info',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF95020A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Macronutrient Progress Bars (shown when expanded)
                          if (_showMoreInfo) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Carbs Section
                                  Expanded(
                                    child: _buildMacronutrientSection(
                                      'Carbs',
                                      _carbsNutrientConsumed,   // ✅ from API
                                      250,   // ✅ dynamic target
                                      Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Proteins Section
                                  Expanded(
                                    child: _buildMacronutrientSection(
                                        'Proteins',
                                        _proteinNutrientConsumed,   // ✅ from API
                                        75,
                                        const Color(0xFF3F51B5)
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Fats Section
                                  Expanded(
                                    child: _buildMacronutrientSection(
                                      'Fats',
                                      _fatsNutrientConsumed,   // ✅ from API
                                      60,
                                      Colors.yellow,
                                    ),
                                  ),
                                ],
                              ),

                            ),
                          ],
                        ],
                      ),

                      // Meal Type Tabs with Icons
                      Container(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: SizedBox(
                          height: 95, // 👈 give enough vertical space for icon + label
                          child: TabBar(
                            controller: _tabController,
                            labelColor: AppTheme.primaryColor,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Colors.transparent,
                            isScrollable: false,
                            labelPadding: const EdgeInsets.symmetric(vertical: 4),
                            tabs: List.generate(5, (index) {
                              final tabsData = [
                                {'icon': 'lib/assets/All Meal.png', 'title': 'All Meal'},
                                {'icon': 'lib/assets/breakfast.png', 'title': 'Breakfast'},
                                {'icon': 'lib/assets/Lunch.png', 'title': 'Lunch'},
                                {'icon': 'lib/assets/snacks.png', 'title': 'Snacks'},
                                {'icon': 'lib/assets/dinner.png', 'title': 'Dinner'},
                              ];

                              final isSelected = _tabController.index == index;

                              return Tab(
                                height: 90,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // 🔴 Outer container for shadow
                                    Container(
                                      clipBehavior: Clip.none, // allows shadow to spread
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: isSelected
                                            ? [] :[
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08), // 👈 very light shadow
                                            blurRadius: 4, // 👈 smaller blur for soft edge
                                            spreadRadius: 0.5, // 👈 minimal spread
                                            offset: const Offset(0, 2), // 👈 gentle downward shadow
                                          ),
                                        ],
                                      ),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                                            width: 1,
                                          ),
                                          color: Colors.white, // background helps make shadow clear
                                        ),
                                        child: Image.asset(
                                          tabsData[index]['icon']!,
                                          color: AppTheme.primaryColor,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    Container(
                                      width: 80,
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          tabsData[index]['title']!,
                                          style: TextStyle(
                                            fontSize: 10,
                                            overflow: TextOverflow.ellipsis,
                                            color: isSelected ? Colors.white : Colors.black,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );


                            }),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ),

              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0,vertical: 10),
                  padding: const EdgeInsets.all(5.0),
                  decoration:  BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0), // rounded corners
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300, // shadow color
                        spreadRadius: 1, // spread
                        blurRadius: 6,   // softness of shadow
                        offset: const Offset(0, 3), // position of shadow (x, y)
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Browse Food and Meal Menu Picker Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isBrowseFoodSelected = true;
                                    _showMealMenuPicker = false;
                                    _showFoodList = false;
                                    _showMealIntakeStats = true;
                                  });
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(vertical: 10), // similar to button height
                                  decoration: BoxDecoration(
                                    color: _isBrowseFoodSelected ? AppTheme.primaryColor : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Text(
                                    'Browse Food',
                                    style: TextStyle(
                                      color: _isBrowseFoodSelected ? Colors.white : Colors.grey,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    softWrap: false,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isBrowseFoodSelected = false;
                                    _showMealMenuPicker = true;
                                    _showFoodList = false;
                                    _showMealIntakeStats = false;
                                  });
                                  // Call the new API to fetch meal menu picker data
                                  _fetchMealMenuPickerData();
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !_isBrowseFoodSelected ? AppTheme.primaryColor : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Text(
                                    'Meal Menu Picker',
                                    style: TextStyle(
                                      color: !_isBrowseFoodSelected ? Colors.white : Colors.grey,
                                      fontWeight: FontWeight.w600,
                                      overflow: TextOverflow.ellipsis,
                                      fontSize: 14,
                                    ),
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),

                          ],
                        ),
                      ),
                      // Context menu for All Meal tab
                      if (_showContextMenu && _tabController.index == 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: _buildContextMenu(),
                        ),

                      // Expanded content area - either food list, meal menu picker, custom item UI, or quick search
                      Expanded(
                        child: _showCustomItemUI
                            ? _buildCustomItemUI(context, false)
                            : _showMealMenuPicker
                            ? _buildMealMenuPicker(context)
                            : _showFoodList
                            ? _buildFoodList()
                            : _hasAddedItems()
                            ? _buildAddedMealItems()
                            : _buildQuickSearch(),
                      ),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildQuickSearch() {
    debugPrint("test1");
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: _isLoadingMeals
                ? const Center(child: CircularProgressIndicator())
                : _filteredMeals.isEmpty
                ? const Center(child: Text("No meals found"))
                : ListView.builder(
              itemCount: _filteredMeals.length,
              itemBuilder: (context, index) {
                final meal = _filteredMeals[index];
                return _buildMealItemCard2(meal); // your existing card
              },
            ),
          ),
        ],
      ),
    );
  }


  // Build the custom item UI when user taps on Custom button
  Widget _buildCustomItemUI(BuildContext context,bool isFromSearch) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            isFromSearch
                ? Container()
                : Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showCustomItemUI = false;
                  });
                },
                child: Image.asset(
                  "lib/assets/back_button.png",
                  height: 20,
                  width: 20,
                ),
              ),
            ),

            const Text(
              'No food items found.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your own custom food item.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () {
                AppRouter.navigateToAddMeal(context);
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Create Custom Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF95020A),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Image.asset(
              'lib/assets/ss-removebg-preview 1.png',
              width:deviceWidth(context) > 390?230: deviceWidth(context) > 360?165:150,
              // height: 180,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodList() {
    final currentMealType = _getCurrentMealType();

    // Loading
    if (_isLoadingMealLogs[currentMealType] == true) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    // Error
    if (_hasError[currentMealType] == true) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Failed to load meal data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchMealsByType(currentMealType),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Get model list
    final List<MealLogModel> items = _getCurrentFoodItems();

    // Empty state
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No meal data available',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchMealsByType(currentMealType),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final MealLogModel item = items[index];

        // 🍎 FOOD NAME
        final String foodName =
        item.foodItemWithNutrients.description.isNotEmpty
            ? item.foodItemWithNutrients.description
            : "Unknown Food";

        // 🥗 EXTRACT NUTRIENTS
        double calories = 0;
        double sodium = 0;
        double carbs = 0;
        double protein = 0;
        double fats = 0;
        String sodiumUnit = "mg";

        for (var nut in item.actualNutrientIntakes) {
          final name = nut.nutrientName.toLowerCase();

          if (name == "calories") calories = nut.quantity;
          if (name == "sodium") {
            sodium = nut.quantity;
            sodiumUnit = nut.unitType;
          }
          if (name == "carbohydrates") carbs = nut.quantity;
          if (name == "protein") protein = nut.quantity;
          if (name == "fat") fats = nut.quantity;
        }

        final mealTypeId = item.mealType.id;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: ListTile(
            tileColor: Colors.grey[100],

            // 🔹 FOOD NAME
            title: Text(
              foodName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 20,
              ),
            ),

            // 🔹 SUBTITLE / Nutrients
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatNumberWithCommas(calories)} kcal',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'Contains ${sodium.toInt()} $sodiumUnit sodium',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),

            // ➕ ADD BUTTON
            trailing: IconButton(
              icon: const Icon(
                Icons.add_circle,
                color: Color(0xFF95020A),
                size: 30,
              ),
              onPressed: () async {
                final result = await AppRouter.navigateToAddMeal(
                  context,
                  editData: MealEditData(
                    id: item.id,
                    name: foodName,
                    quantity: item.quantity.toString(),
                    servingUnit: item.foodItemWithNutrients.servingUnit,
                    calories: calories,
                    sodium: sodium,
                    carbs: carbs,
                    protein: protein,
                    fats: fats,
                    mealTypeId: mealTypeId,
                  ),
                );

                if (result == true) {
                  _userAddedMealLogs[currentMealType] ??= [];
                  _userAddedMealLogs[currentMealType]!.add(item);
                  setState(() {});
                }
              },
            ),
          ),
        );
      },
    );
  }



  Widget _buildAddedMealItems() {
    String currentMealType = _getCurrentMealType();
    List<MealLogModel> currentFoodItems = _getUserAddedMeals();

    debugPrint('🧠 Current meal type: $currentMealType');
    debugPrint('📦 Current food items: ${currentFoodItems.length}');
    debugPrint('🧂 Sodium consumed: $_sodiumConsumed');

    // If meal logs are loading → show progress first
    if (_isLoadingMealLogs[currentMealType] == true) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF95020A),
          ),
        ),
      );
    }

    // Calculate total calories for the meal type
    // double totalCalories = currentFoodItems.fold(
    //   0.0,
    //       (sum, item) => sum + (item['calories'] ?? 0.0),
    // );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔍 SEARCH FIELD
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              style: AppTheme.title14.copyWith(fontWeight: FontWeight.normal),
              decoration: InputDecoration(
                hintText: 'Search Food or Meal',
                filled: true,
                fillColor: Colors.grey.shade100,
                hintStyle: AppTheme.title14.copyWith(fontWeight: FontWeight.normal),
                prefixIcon: const Icon(Icons.search, size: 26, color: Colors.black54),
                contentPadding:
                const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_showCustomItemUI)
                      GestureDetector(
                        onTap: () {
                          AppRouter.navigateToAddMeal(context,
                            editData: MealEditData(
                              id: 0,
                              name: '',
                              quantity: '',
                              servingUnit: '',
                              calories: 0.0,
                              sodium: 0.0,
                              carbs: 0.0,
                              protein: 0.0,
                              fats: 0.0,
                              mealTypeId: _mealTypeIds[_getCurrentMealType()],
                            ),
                          );
                        },
                        child: Container(
                          height: 25,
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          margin: const EdgeInsets.only(right: 8.0),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: const Center(
                            child: Text(
                              'Custom +',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 5),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40.0),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40.0),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(40.0)),
                  borderSide: BorderSide(color: AppTheme.primaryColor),
                ),
              ),
              onChanged: (value) {
                final query = value.trim();

                if (_debounce?.isActive ?? false) _debounce!.cancel();

                _debounce = Timer(const Duration(milliseconds: 300), () {
                  _searchQuery = query;
                  _isSearchMode = query.isNotEmpty;

                  _loadMeals(isNewSearch: true);
                });
              },
            ),
          ),

          SizedBox(height: 10),

          /// 🔹 Sodium indicator + Meal type header
          _sodiumConsumed != 0
              ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currentMealType,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Sodium ${_sodiumConsumed?.toDouble() ?? 0.0} mg / 2500 mg',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
              : Container(),

          const SizedBox(height: 5),

          /// 🌟 MAIN LIST VIEW / RESULTS
          Expanded(
            child: _isLoadingMeals? const Center(child: CircularProgressIndicator())
                : _searchController.text.isEmpty
                ? (currentFoodItems.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _getQuickSearchText(),
                      style: AppTheme.title16,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Image.asset(
                    _getQuickSearchImg(),
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            )
                : ListView.builder(
              itemCount: currentFoodItems.length,
              itemBuilder: (context, index) {
                final meal = currentFoodItems[index];
                return _buildMealItemCard(meal);
              },
            ))
                : (!_isLoading && _foodItems.isEmpty
                ? _buildCustomItemUI(context, true)
                : ListView.builder(
              controller: _scrollController,
              itemCount: _foodItems.length + (_hasMoreData ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _foodItems.length) {
                  return _buildMealItemCard2(_foodItems[index]);
                }

                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            )),
          ),
        ],
      ),
    );
  }



  Widget _buildMealItemCard(MealLogModel item) {
    final int id = item.id;
    final String foodName = item.foodItemWithNutrients.description ?? 'Unknown Food';

    // Build display quantity: prefer servingSize + servingUnit, else item.quantity
    String _buildQuantity() {
      try {
        final servingSizeStr = item.quantity; // this is String
        final servingUnit = item.actualNutrientIntakes[0].unitType ?? '';

        // Convert to double safely
        final servingSize = double.tryParse(servingSizeStr.replaceAll(RegExp(r'[^0-9.]'), ''));

        if (servingSize != null && servingSize > 0) {
          // remove trailing .0 for integers
          final ss = servingSize.toString().replaceAll(RegExp(r'\.0+$'), '');
          return servingUnit.isNotEmpty ? '$ss $servingUnit' : ss;
        }
      }
      catch (_) {}
      // fallback
      return (item.quantity ?? '').toString();
    }

    final String quantity = _buildQuantity();
    final String servingUnit = item.foodItemWithNutrients.servingUnit;
    String normalizeServingUnit(String? unit) {
      if (unit == null) return "";

      final u = unit.trim().toLowerCase();

      if (u == "mlt") return "MLT";
      if (u == "grm") return "GRM";

      return unit; // return unchanged for all other units
    }

    final int mealTypeId = item.mealType?.id ?? 0;

    // Helper to extract nutrient quantity by name from actualNutrientIntakes
    double _getNutrientAmount(String key) {
      final found = item.actualNutrientIntakes.firstWhere(
            (n) => (n.nutrientName ?? '').toString().toLowerCase() == key.toLowerCase(),
      );
      if (found != null) {
        return (found.quantity ?? 0).toDouble();
      }
      return 0.0;
    }

    // Helper to extract unitType from actualNutrientIntakes
    String _getNutrientUnit(String key) {
      final found = item.actualNutrientIntakes.firstWhere(
            (n) => (n.nutrientName ?? '').toString().toLowerCase() == key.toLowerCase(),
      );
      if (found != null) {
        return (found.unitType ?? '').toString();
      }
      return '';
    }

    final double calories = _getNutrientAmount('calories');
    final double sodium = _getNutrientAmount('sodium');
    final double protein = _getNutrientAmount('protein');
    final double carbs = _getNutrientAmount('carbohydrates');
    final double fats = _getNutrientAmount('fat');

    final String caloriesUnit = _getNutrientUnit('calories');
    final String sodiumUnit = _getNutrientUnit('sodium');
    final String proteinUnit = _getNutrientUnit('protein');
    final String carbsUnit = _getNutrientUnit('carbohydrates');
    final String fatsUnit = _getNutrientUnit('fat');

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            (quantity.isNotEmpty) ? "$foodName ($quantity)" : foodName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        if (mealTypeId != 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Image.asset(
                              _getMealTypeLogo(mealTypeId),
                              height: 30,
                              width: 30,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${formatNumberWithCommas(calories)} ${caloriesUnit.isNotEmpty ? caloriesUnit : ''}",
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ],
                ),
              ),

              // Edit + Delete buttons
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF95020A), size: 24),
                    onPressed: () async {
                      final editData = MealEditData(
                        id: id,
                        name: foodName,
                        quantity: quantity,
                        servingUnit: normalizeServingUnit(servingUnit),
                        calories: calories,
                        sodium: sodium,
                        carbs: carbs,
                        protein: protein,
                        fats: fats,
                        mealTypeId: mealTypeId,
                      );

                      debugPrint("➡️ Passing to AddMealPage:");
                      debugPrint(editData.name); // 👈 This debugPrints clean JSON-like output

                      final result = await AppRouter.navigateToAddMeal(
                        context,
                        editData: editData,
                        isEditMode: true,
                      );

                      if (result == true) {
                        setState(() {});
                      }
                    },
                  ),

                  GestureDetector(
                    onTap: () {
                      _showDeleteMealLogDialog(context, id, foodName);
                    },
                    child: Image.asset(
                      'lib/assets/TrashCan.png',
                      color: const Color(0xFF95020A),
                      height: 25,
                      width: 25,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 5),
          Divider(color: Colors.grey.shade300, height: 1),
          SizedBox(height: 5),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNutrientIndicator("Sodium (${formatNumberWithCommas(sodium)}${sodiumUnit.isNotEmpty ? sodiumUnit : ''})", AppTheme.primaryColor),
                  const SizedBox(height: 5),
                  _buildNutrientIndicator("Proteins (${formatNumberWithCommas(protein)}${proteinUnit.isNotEmpty ? proteinUnit : ''})", const Color(0xFF3F51B5)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNutrientIndicator("Carbs (${formatNumberWithCommas(carbs)}${carbsUnit.isNotEmpty ? carbsUnit : ''})", Colors.orange),
                  const SizedBox(height: 5),
                  _buildNutrientIndicator("Fats (${formatNumberWithCommas(fats)}${fatsUnit.isNotEmpty ? fatsUnit : ''})", Colors.yellow),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildMealItemCard2(FoodItemWithNutrientsItem item) {
    // ✅ Use 'description' as the food name
    final foodName = item.description;

    final quantity = item.servingSize.toString();
    final servingUnit = item.servingUnit;

    debugPrint("#########quantity $quantity ########$servingUnit");
    // ✅ Extract nutrients from 'nutrients' array
    final nutrientsList = item.nutrients;

    double getNutrient(String key) {
      final nutrient = nutrientsList.firstWhere(
            (n) => n.name.toLowerCase() == key.toLowerCase(),
        orElse: () => Resp.Nutrient(name: '', amount: 0, minValue: 0, maxValue: 0, unitName: ''),
      );
      return nutrient.amount;
    }

    String getUnit(String key) {
      final nutrient = nutrientsList.firstWhere(
            (n) => n.name.toLowerCase() == key.toLowerCase(),
        orElse: () => Resp.Nutrient(name: '', amount: 0, minValue: 0, maxValue: 0, unitName: ''),
      );
      return nutrient.unitName;
    }

    // ✅ Extract nutrient values
    final calories = getNutrient("Calories");
    final sodium = getNutrient("Sodium");
    final protein = getNutrient("Protein");
    final carbs = getNutrient("Carbohydrates");
    final fats = getNutrient("Fat");

    // ✅ Extract units
    final caloriesUnit = getUnit("Calories");
    final sodiumUnit = getUnit("Sodium");
    final proteinUnit = getUnit("Protein");
    final carbsUnit = getUnit("Carbohydrates");
    final fatsUnit = getUnit("Fat");

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        color: const Color(0xFFF6F6F8),
        width: double.infinity,
        child: ListTile(
          tileColor: Colors.grey[100],
          title: Text(
            '$foodName ($quantity $servingUnit)' ,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 14,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.brandName != null && item.brandName!.isNotEmpty)
                Text(
                  'Brand: ${item.brandName}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              Text(
                '${formatNumberWithCommas(calories)} $caloriesUnit',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 8),
              Text(
                'Contains ${formatNumberWithCommas(sodium)}$sodiumUnit Sodium',
                style: const TextStyle(fontSize:12),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(
              Icons.add_circle,
              color: Color(0xFF95020A),
              size: 30,
            ),
            onPressed: () async {
              // ✅ Prepare item data for Add Meal form
              Map<String, dynamic> itemData = {
                'name': foodName,
                'quantity': '', // No serving size/unit in API response
                'calories': calories.toInt(),
                'sodium': sodium.toInt(),
                'carbs': carbs.toInt(),
                'protein': protein.toInt(),
                'fats': fats.toInt(),
                'mealTypeId': _mealTypeIds[_getCurrentMealType()],
              };



              debugPrint("🍽️ Sending Item data : $itemData");

              // ✅ Navigate to Add Meal page
              final result =
              await AppRouter.navigateToAddMeal(context,
                editData: MealEditData(
                  id: item.id,
                  name: foodName,
                  quantity: quantity,
                  servingUnit: servingUnit,
                  calories: calories,
                  sodium: sodium,
                  carbs: carbs,
                  protein: protein,
                  fats: fats,
                  mealTypeId: _mealTypeIds[_getCurrentMealType()],
                ),);

              if (result == true) {
                if (kDebugMode) {
                  debugPrint('✅ Meal added successfully, updating list...');
                }

                String currentMealType = _getCurrentMealType();
                _userAddedMealsMap[currentMealType] ??= [];
                _userAddedMealsMap[currentMealType]!.add(
                  FoodItemWithNutrientsItem(
                    id: item.id,
                    uuid: item.uuid,
                    fdcId: item.fdcId,
                    description: item.description,
                    brandName: item.brandName,
                    servingSize: item.servingSize,
                    servingUnit: item.servingUnit,
                    nutrients: item.nutrients, // or clone
                  ),
                );




                setState(() {});
              }
            },
          ),
        ),
      ),
    );
  }





  Widget _buildNutrientIndicator(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
              fontSize: 10,
              color: Colors.black,
              fontWeight: FontWeight.w500
          ),
        ),
      ],
    );
  }

  Widget _buildMacronutrientSection(
      String name,
      double consumed,
      double target,
      Color color,
      ) {
    double progress = (consumed / target).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),

        Text(
          '${formatNumberWithCommas(consumed)}g / ${formatNumberWithCommas(target)}g',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }



  void _showDeleteMealMenuDialog(
      BuildContext context,
      int mealMenuId,
      String mealName,
      ) {
    showDialog(
      context: context,
      barrierDismissible: false, // prevent closing while loading
      builder: (BuildContext dialogContext) {
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: AppTheme.primaryColor,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Are you sure you want to delete "$mealName"?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.primaryColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 🔥 DELETE BUTTON WITH LOADER
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isDeleting
                                ? null
                                : () async {
                              setState(() => isDeleting = true);

                              bool success = await MealService.deleteMealMenu(mealMenuId);

                              if (success) {
                                Navigator.pop(context); // close dialog
                                _handleSuccessfulMealMenuDelete(mealMenuId, mealName);
                              } else {
                                setState(() => isDeleting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to delete meal.')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: isDeleting
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleSuccessfulMealMenuDelete(int mealMenuId, String mealName) {
    setState(() {
      _mealMenuPickerData.removeWhere((m) => m.id == mealMenuId);

      if (processedItem != null && processedItem!.id == mealMenuId) {
        processedItem = null;
      }

      _userAddedMeals.forEach((mealType, mealsList) {
        mealsList.removeWhere((meal) => meal.id == mealMenuId);
      });
    });

    _showMealMennuDeletedSuccess(context, mealName);
  }

  void _showMealMennuDeletedSuccess(BuildContext context, String mealName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  child: Image.asset(
                    'lib/assets/Check Mark.png',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '"$mealName" deleted successfully!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6F6C90)
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('OK',style: AppTheme.whiteTitle14,),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteMealLogDialog(
      BuildContext context,
      int mealLogId,
      String mealName,
      ) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing while deleting
      builder: (BuildContext dialogContext) {
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: AppTheme.primaryColor,
                        size: 30,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Are you sure you want to delete "$mealName"?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        // ❌ Cancel button
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                            isDeleting ? null : () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.primaryColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // 🔥 DELETE BUTTON WITH PROGRESS INDICATOR
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isDeleting
                                ? null
                                : () async {
                              setState(() => isDeleting = true);

                              final success =
                              await MealService.deleteMealLog(mealLogId);

                              if (success) {
                                Navigator.pop(dialogContext); // Close dialog

                                // Update lists ⬇⬇⬇
                                setState(() {
                                  _mealMenuPickerData
                                      .removeWhere((m) => m.id == mealLogId);

                                  if (processedItem != null &&
                                      processedItem!.id == mealLogId) {
                                    processedItem = null;
                                  }

                                  _userAddedMeals.forEach((key, mealsList) {
                                    mealsList.removeWhere(
                                            (meal) => meal.id == mealLogId);
                                  });
                                });

                                _showMealDeletedSuccess(context, mealName);
                              } else {
                                setState(() => isDeleting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to delete meal.'),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: isDeleting
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMealDeletedSuccess(BuildContext context, String mealName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  child: Image.asset(
                    'lib/assets/Check Mark.png',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '"$mealName" deleted successfully!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6F6C90)
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      AppRouter.replaceWithAllMealIntake(context,0,"addMeal");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('OK',style: AppTheme.whiteTitle14,),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  Widget _buildMealMenuPicker(BuildContext context) {

    if (_isLoadingMealMenuPicker) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_hasMealMenuPickerError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Failed to load meal menu data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchMealMenuPickerData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 🔍 Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Food or Meal',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(40.0)),
                borderSide: BorderSide(color: AppTheme.primaryColor),
              ),
            ),
            onChanged: (query) {
              setState(() {
                _searchQuery = query.toLowerCase();
              });
            },
          ),
        ),

        // 📋 Meal list
        // inside _buildMealMenuPicker() where you create ListView.builder:

        Expanded(
          child: _filteredMealMenuList().isEmpty
              ? _buildCustomItemUI(context, true)
              : ListView.builder(
            itemCount: _filteredMealMenuList().length,
            itemBuilder: (context, index) {
              final PatientMealMenuModel item = _filteredMealMenuList()[index];

              // Extract nutrients from item.latestFoodItemWithNutrients
              final nutrients = item.latestFoodItemWithNutrients.nutrients;

              double getNutrient(String name) {
                final nut = nutrients.firstWhere(
                      (n) => n.name.toLowerCase() == name.toLowerCase(),
                  orElse: () => Nut.Nutrient(name: '', amount: 0, minValue: 0, maxValue: 0, unitName: ''),
                );
                return nut.amount;
              }

              String getUnit(String name) {
                final nut = nutrients.firstWhere(
                      (n) => n.name.toLowerCase() == name.toLowerCase(),
                  orElse: () => Nut.Nutrient(name: '', amount: 0, minValue: 0, maxValue: 0, unitName: ''),
                );
                return nut.unitName;
              }

              final calories = getNutrient("Calories");
              final sodium   = getNutrient("Sodium");
              final carbs    = getNutrient("Carbohydrates");
              final protein  = getNutrient("Protein");
              final fats     = getNutrient("Fat");

              final sodiumUnit   = getUnit("Sodium");
              final caloriesUnit = getUnit("Calories");
              final carbsUnit    = getUnit("Carbohydrates");
              final proteinUnit  = getUnit("Protein");
              final fatsUnit     = getUnit("Fat");

              String? servingUnit = item.latestFoodItemWithNutrients.servingUnit;
              String normalizeServingUnit(String? unit) {
                if (unit == null) return "";

                final u = unit.trim().toLowerCase();

                if (u == "mlt") return "MLT";
                if (u == "grm") return "GRM";

                return unit; // return unchanged for all other units
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// HEADER: name + mealType + actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // NAME + QUANTITY + MEAL TYPE ICON
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.name} (${item.latestQuantity})',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Image.asset(
                                  _getMealTypeLogo(item.mealType.id),
                                  height: 30,
                                  width: 30,
                                )
                              ],
                            ),
                          ),

                          /// ➕ ADD BUTTON
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: Color(0xFF95020A),
                              size: 26,
                            ),
                            onPressed: () async {
                              // Build the itemData Map ONLY because your AddMeal page expects Map



                              final result = await AppRouter.navigateToAddMeal(
                                context,
                                editData: MealEditData(
                                  id: item.id,
                                  name:  item.name,
                                  quantity: item.latestQuantity,
                                  servingUnit: normalizeServingUnit(servingUnit),
                                  calories: calories,
                                  sodium: sodium,
                                  carbs: carbs,
                                  protein: protein,
                                  fats: fats,
                                  mealTypeId: item.mealType.id,
                                ),
                                mealMenuMode: true,
                              );

                              if (result == true) {
                                String currentMealType = _getCurrentMealType();
                                _userAddedMealMenuItems[currentMealType] ??= [];
                                _userAddedMealMenuItems[currentMealType]!.add(item);
                                setState(() {});
                              }
                            },
                          ),

                          /// DELETE BUTTON
                          GestureDetector(
                            child: Image.asset(
                              'lib/assets/TrashCan.png',
                              color: const Color(0xFF95020A),
                              height: 25,
                              width: 25,
                            ),
                            onTap: () {
                              _showDeleteMealMenuDialog(
                                context,
                                item.id,
                                item.name,
                              );
                            },
                          ),
                        ],
                      ),
                      /// SODIUM TEXT
                      Text(
                        'Sodium ${sodium.toStringAsFixed(2)}$sodiumUnit',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),

                      SizedBox(height: 5),
                      Divider(color: Colors.grey.shade300, height: 1),
                      SizedBox(height: 5),

                      /// Nutrient indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildNutrientIndicator(
                              'Carbs ${formatNumberWithCommas(carbs)}$carbsUnit', Colors.orange),
                          _buildNutrientIndicator(
                              'Proteins ${formatNumberWithCommas(protein)}$proteinUnit', Colors.blue),
                          _buildNutrientIndicator(
                              'Fats ${formatNumberWithCommas(fats)}$fatsUnit', Colors.yellow),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        )

      ],
    );
  }

  // ✅ Helper: Filtered list
  List<PatientMealMenuModel> _filteredMealMenuList() {
    if (_searchQuery == null || _searchQuery!.isEmpty) {
      return _mealMenuPickerData;
    }

    final query = _searchQuery!.toLowerCase();

    return _mealMenuPickerData.where((item) {
      return item.name.toLowerCase().contains(query) ||
          item.latestQuantity.toLowerCase().contains(query) ||
          item.latestFoodItemWithNutrients.description.toLowerCase().contains(query) ||
          item.mealType.name.toLowerCase().contains(query);
    }).toList();
  }


  // Process meal menu picker item data to match expected UI format
  Map<String, dynamic> _processMealMenuPickerItem(Map<String, dynamic> item) {
    // Extract food name
    String foodName = item['name'] ?? 'Unknown Food';

    // Extract quantity from latestQuantity
    String quantity = item['latestQuantity']?.toString() ?? 'Unknown quantity';

    // Extract meal type ID (and optionally name)
    int? mealTypeId = item['mealType']?['id'];
    String? mealTypeName = item['mealType']?['name'];

    // Extract nutrients from latestFoodItemWithNutrients.nutrients
    Map<String, dynamic> nutrients = {};
    List<dynamic> nutrientList =
    (item['latestFoodItemWithNutrients']?['nutrients'] ?? []) as List<dynamic>;

    if (kDebugMode) {
      debugPrint('🍽️ Processing ${nutrientList.length} nutrients for $foodName from latestFoodItemWithNutrients');
      debugPrint('🍽️ Nutrient data: $nutrientList');
    }

    if (nutrientList.isNotEmpty) {
      for (var nutrient in nutrientList) {
        String nutrientName = (nutrient['name'] ?? '').toString().toLowerCase();
        double amount = (nutrient['amount'] ?? 0).toDouble();

        if (kDebugMode) {
          debugPrint('🍽️ Nutrient: $nutrientName = $amount');
        }

        switch (nutrientName) {
          case 'calories':
            nutrients['calories'] = amount;
            break;
          case 'sodium':
            nutrients['sodium'] = amount;
            break;
          case 'carbohydrates':
            nutrients['carbs'] = amount;
            break;
          case 'protein':
            nutrients['protein'] = amount;
            break;
          case 'fat':
            nutrients['fats'] = amount;
            break;
        }
      }
    }

    Map<String, dynamic> processedItem = {
      'name': foodName,
      'quantity': quantity,
      'calories': nutrients['calories']?.toInt() ?? 0,
      'sodium': nutrients['sodium']?.toInt() ?? 0,
      'carbs': nutrients['carbs']?.toInt() ?? 0,
      'protein': nutrients['protein']?.toInt() ?? 0,
      'fats': nutrients['fats']?.toInt() ?? 0,
      'id': item['id'],
      'uuid': item['uuid'],
      'mealTypeId': mealTypeId, // 👈 added mealTypeId
      'mealTypeName': mealTypeName,
    };

    if (kDebugMode) {
      debugPrint('🍽️ Processed meal menu item: $processedItem');
    }

    return processedItem;
  }


  String _getMealTypeLogo(int mealTypeId) {
    switch (mealTypeId) {
      case 21: // Breakfast
        return 'lib/assets/breakfast_rounded_border.png';
      case 22: // Lunch
        return 'lib/assets/lunch_rounded_border.png';
      case 23: // Snacks
        return 'lib/assets/snacks_rounded_border.png';
      case 24: // Dinner
        return 'lib/assets/dinner_rounded_border.png';
      default:
        return 'lib/assets/all_meal_rounded_border.png';
    }
  }
}