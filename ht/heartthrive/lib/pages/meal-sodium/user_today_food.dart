import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/components/profile_avatar.dart';
import 'package:heart_thrive/services/home/risk_meter_service.dart';

import '../../components/action_menu.dart';
import '../../components/ui_components.dart';
import '../../constants/heart_thrive_strings_constants.dart';
import '../../constants/ui_constants.dart';
import '../../main.dart';
import '../../models/meal/edit_meal_model.dart';
import '../../models/meal/food/food_response_model.dart';
import '../../models/meal/food/nutrients_model.dart';
import '../../providers/bmi/notification_provider.dart';
import '../../providers/internet_provider.dart';
import '../../providers/meal/meal_sodium_provider.dart';
import '../../routes/app_router.dart';
import '../../services/meal_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/error_response.dart';
import '../medication/medication_home_card.dart';
import '../notification_badgeicon_widget.dart';
import 'browse_food_page.dart';

// =======================
// MEAL LOGS PAGE - NOW CONSUMER WIDGET
// =======================
// Refresh screen
bool _skipNextPopRefresh = false;

class MealLogsPage extends ConsumerStatefulWidget {
  final int? initialIndex;
  final String? pageType;
  final bool? isHome;

  const MealLogsPage({
    super.key,
    this.initialIndex,
    this.pageType,
    this.isHome = false,
  });

  @override
  ConsumerState<MealLogsPage> createState() => _MealLogsPageState();
}

class _MealLogsPageState extends ConsumerState<MealLogsPage> with RouteAware {
  final ScrollController _controller = ScrollController();

  ///  Selected meal index (0 = All)
  int _selectedMealIndex = 0;

  ///  Meal tabs
  final List<Map<String, dynamic>> _mealTabs = [
    {"title": "All Meal", "icon": 'lib/assets/All Meal.png'},
    {"title": "Breakfast", "icon": 'lib/assets/breakfast.png'},
    {"title": "Lunch", "icon": 'lib/assets/Lunch.png'},
    {"title": "Snacks", "icon": 'lib/assets/snacks.png'},
    {"title": "Dinner", "icon": 'lib/assets/dinner.png'},
  ];

  bool _isTodaySelected = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    _selectedMealIndex = widget.initialIndex ?? 0;
  }

  void _onScroll() {
    final state = ref.read(mealLogsProvider);
    if (state.isLoading) return;

    if (_controller.position.pixels >=
        _controller.position.maxScrollExtent - 200) {
      ref.read(mealLogsProvider.notifier).loadMoreLogs();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    if (_skipNextPopRefresh) {
      _skipNextPopRefresh = false; // reset immediately
      return;
    }

    _refreshMealData(); // ✅ single refresh only
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _controller.removeListener(_onScroll);
    _controller.dispose();
    //ref.read(mealLogsProvider.notifier).dispose();
    //ref.read(todayNutrientProvider.future);
    super.dispose();
  }

  List<FoodLogEntry> getFilteredLogs(List<FoodLogEntry> logs) {
    if (_selectedMealIndex == 0) return logs;

    final selectedMeal = _mealTabs[_selectedMealIndex]["title"]
        .toString()
        .toLowerCase();

    return logs.where((e) {
      final mealName = e.mealType?.name?.toLowerCase() ?? '';
      return mealName == selectedMeal;
    }).toList();
  }

  Widget _buildMealTabs() {
    return SizedBox(
      height: deviceWidth(context) > 830 ? 150 : 110,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_mealTabs.length, (index) {
          final tab = _mealTabs[index];
          final bool isSelected = _selectedMealIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedMealIndex = index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: deviceWidth(context) > 830
                        ? 70
                        : deviceWidth(context) > 390
                        ? 56
                        : deviceWidth(context) > 360
                        ? 40
                        : 40,
                    height: deviceWidth(context) > 830
                        ? 70
                        : deviceWidth(context) > 390
                        ? 56
                        : deviceWidth(context) > 360
                        ? 40
                        : 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: AppTheme.primaryColor, width: 1)
                          : null,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        tab["icon"],
                        width: deviceWidth(context) > 830
                            ? 36
                            : deviceWidth(context) > 390
                            ? 26
                            : deviceWidth(context) > 360
                            ? 20
                            : 20,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  isSelected
                      ? Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: deviceWidth(context) > 360 ? 10 : 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            tab["title"],
                            style: AppTheme.title12.copyWith(
                              fontSize: deviceWidth(context) > 830
                                  ? 16
                                  : deviceWidth(context) > 420
                                  ? 11
                                  : deviceWidth(context) > 395
                                  ? 10
                                  : 10,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          tab["title"],
                          style: AppTheme.title12.copyWith(
                            fontSize: deviceWidth(context) > 830
                                ? 16
                                : deviceWidth(context) > 390
                                ? 12
                                : 10,
                            color: Colors.black87,
                          ),
                        ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Future<void> _onPullToRefresh() async {
    // Small delay so indicator is visible
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // Refresh all related providers
    ref.invalidate(mealLogsProvider);
    ref.invalidate(todayNutrientProvider);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('UI start : ${DateTime.now()}');
    final nutrientAsync = ref.watch(todayNutrientProvider);
    final logsAsync = ref.watch(mealLogsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        print("DEmoTeST123");
        debugPrint("widget.navFromPage : ${widget.pageType}");
        //debugPrint("Result ${widget.navFromPage == NavPageType.profile.name}");
        if (widget.pageType == NavPageType.home.name ||
            widget.pageType == null) {
          AppRouter.replaceWithHome(context);
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Center(child: const Text('Today Meal Logs')),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(widget.isHome! ? 24 : 0),
            ),
          ),
          leading: widget.isHome!
              ? ProfileAvatar()
              : GestureDetector(
                  onTap: () {
                    print("DEmoTeST123");
                    debugPrint("widget.navFromPage : ${widget.pageType}");
                    //debugPrint("Result ${widget.navFromPage == NavPageType.profile.name}");
                    if (widget.pageType == NavPageType.home.name ||
                        widget.pageType == null) {
                      AppRouter.replaceWithHome(context);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset("lib/assets/Frame.png"),
                  ),
                ),
          actions: [
            widget.isHome!?Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: NotificationBadgeIcon(),
            ):actionMenuItemResponse(
              context,
              onOpened: () {
                _skipNextPopRefresh = true;
                debugPrint('Menu opened');
              },
              onCanceled: () {
                _skipNextPopRefresh = true;
                debugPrint('Menu dismissed (outside tap)');
                // ❗ stop API calls here if needed
              },
              onSelected: (result) {
                debugPrint('Selected: $result');
                if (result == ActionMenuResult.goHome) {
                  AppRouter.navigateToHome(context);
                }
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _onPullToRefresh,
          child: Column(
            children: [
              // Daily Intake Card
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 10,
                ),
                padding: const EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: nutrientAsync.when(
                  loading: () => const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => DailyMealIntakeCard(nutrients: []),
                  data: (nutrients) => DailyMealIntakeCard(
                    key: ValueKey(nutrients.hashCode + DateTime.now().day),
                    nutrients: nutrients,
                  ),
                ),
              ),

              // Logs Section
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 10,
                  ),
                  padding: const EdgeInsets.all(5.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildFoodToggle(),
                      _buildMealTabs(),
                      Expanded(
                        child: logsAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => noDataUI(mapException(e).message),
                          data: (logs) {
                            debugPrint('UI End : ${DateTime.now()}');
                            final filteredLogs = getFilteredLogs(logs);

                            if (filteredLogs.isEmpty) {
                              return _buildEmptyUI(
                                index: _selectedMealIndex == 0
                                    ? null
                                    : _selectedMealIndex,
                              );
                            }

                            return ListView.builder(
                              key: ValueKey(logs.length),
                              controller: _controller,
                              itemCount:
                                  filteredLogs.length +
                                  (logsAsync.isLoading ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= filteredLogs.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: FoodNutrientsCard(
                                    foodLogEntry: filteredLogs[index],
                                  ),
                                );
                              },
                            );
                          },
                        ),
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

  // Error Information
  Widget noDataUI(String? message) {
    final isOnline = ref.watch(isOnlineProvider);
    return SizedBox(
      width: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Text(
                  !isOnline
                      ? HeartThriveStrings.noInternet
                      : message ?? HeartThriveStrings.noSodiumDashBoardTitle,
                  textAlign: TextAlign.center,
                  style: AppTheme.title16.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  !isOnline
                      ? HeartThriveStrings.noInternetDescription
                      : HeartThriveStrings.noSodiumDashBoardDescription,
                  textAlign: TextAlign.center,
                  style: AppTheme.body14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFoodToggle() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // "Today's Food" – always selected
          Expanded(
            child: _toggleButton(
              title: "Today's Food",
              isSelected: true, // Always true
              onTap: () {}, // No action needed
            ),
          ),
          const SizedBox(width: 8), // "Browse Food" – action button
          Expanded(
            child: _toggleButton(
              title: "Browse Food",
              isSelected: false,
              onTap: _onBrowseFoodTap,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onBrowseFoodTapOld() async {
    final bool? added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const MealMenuPage()),
    );

    if (!mounted) return;

    if (added == true) {
      // 🔑 THIS IS THE MISSING PIECE
      setState(() {
        _selectedMealIndex = _selectedMealIndex; // Reset to "All Meal"
      });

      _refreshMealData();
    }
  }

  Future<void> _onBrowseFoodTap() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MealMenuPage()),
    );
  }

  void _refreshMealData() {
    // Safe refresh – no risk of conflicting with local state
    ref.invalidate(mealLogsProvider);
    ref.invalidate(todayNutrientProvider);
  }

  Widget _toggleButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: deviceWidth(context) > 830 ? 60 : 44,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: AppTheme.responsiveButtonFontSize(context),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyUI({int? index}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getMessageOfMealType(index: index),
                textAlign: TextAlign.center,
                style: AppTheme.title16.copyWith(
                  fontSize: deviceWidth(context) > 830 ? 20 : 16,
                ),
              ),
              const SizedBox(height: 10),
              Image.asset(
                _getImageOfMealType(index: index),
                width: deviceWidth(context) > 830 ? 300 : 200,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMessageOfMealType({int? index}) {
    switch (index) {
      case 1:
        return HeartThriveStrings.noMealBreakFastSectionMsg;
      case 2:
        return HeartThriveStrings.noMealLunchSectionMsg;
      case 3:
        return HeartThriveStrings.noMealSnacksSectionMsg;
      case 4:
        return HeartThriveStrings.noMealDinnerSectionMsg;
      default:
        return HeartThriveStrings.noMealAllSectionMsg;
    }
  }

  String _getImageOfMealType({int? index}) {
    switch (index) {
      case 1:
        return "lib/assets/default_breakfast.png";
      case 2:
        return "lib/assets/default_lunch_bg.png";
      case 3:
        return "lib/assets/default_snacks.png";
      case 4:
        return "lib/assets/default_dinner.png";
      default:
        return "lib/assets/ss-removebg-preview 1.png";
    }
  }
}

//DailyMealIntakeCard
class DailyMealIntakeCard extends ConsumerWidget {
  final List<Nutrients>? nutrients;

  const DailyMealIntakeCard({super.key, this.nutrients});

  String getAmountWithUnit(List<Nutrients> nutrients, String name) {
    final n = nutrients.firstWhere(
      (e) => e.name?.toLowerCase() == name.toLowerCase(),
      orElse: () => Nutrients(
        name: name,
        amount: 0,
        minValue: 0,
        maxValue: 0,
        unitName: '',
      ),
    );
    return '${n.amount?.toStringAsFixed(2)} ${n.unitName}';
  }

  String getAmount(List<Nutrients> nutrients, String name) {
    final n = nutrients.firstWhere(
      (e) => e.name?.toLowerCase() == name.toLowerCase(),
      orElse: () => Nutrients(
        name: name,
        amount: 0,
        minValue: 0,
        maxValue: 0,
        unitName: '',
      ),
    );
    return '${n.amount?.toStringAsFixed(2)}';
  }

  String sodiumStatus(double consumedSodium) {
    const double limit = 2500;
    if (consumedSodium > limit) {
      final exceeded = consumedSodium - limit;
      return "${exceeded.toStringAsFixed(2)} mg limit\nexceeded";
    } else {
      final left = limit - consumedSodium;
      return "${left.toStringAsFixed(2)} mg left";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showMoreInfo = ref.watch(showMoreInfoProvider);
    void toggleMoreInfo() {
      ref.read(showMoreInfoProvider.notifier).state = !showMoreInfo;
    }

    if (nutrients == null || nutrients!.isEmpty) {
      return const SizedBox.shrink(); // or loading/empty state
    }

    final String calories = getAmountWithUnit(nutrients!, 'Calories');
    final String sodium = getAmountWithUnit(nutrients!, 'Sodium');
    final String carbs = getAmount(nutrients!, 'Carbohydrates');
    final String fat = getAmount(nutrients!, 'Fat');
    final String protein = getAmount(nutrients!, 'Protein');
    final String sodiumConsumed = getAmount(nutrients!, 'Sodium');

    final double consumedSodium = double.tryParse(sodiumConsumed) ?? 0;
    final double consumedCarbs = double.tryParse(carbs) ?? 0;
    final double consumedFat = double.tryParse(fat) ?? 0;
    final double consumedProtein = double.tryParse(protein) ?? 0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 300,
          maxWidth: deviceWidth(context) > 830 ? 800 : 600,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Daily Meal Intake",
                    style: TextStyle(
                      fontSize: deviceWidth(context) > 830 ? 20 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    calories,
                    style: TextStyle(
                      fontSize: deviceWidth(context) > 830 ? 18 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Sodium Progress Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoColumn(value: sodium, label: "Consumed"),
                  Column(
                    children: [
                      SizedBox(
                        width: deviceWidth(context) > 830 ? 350 : 140,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: consumedSodium / 2500,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: const AlwaysStoppedAnimation(
                              AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _InfoColumn(
                        value: sodiumStatus(consumedSodium),
                        label: "",
                        valueColor: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                  const _InfoColumn(value: "2,500 mg", label: "Target"),
                ],
              ),

              const SizedBox(height: 16),

              // Reusable More/Less Button
              buildLessAndMoreInfoButton(
                context,
                showMoreInfo: showMoreInfo,
                onTap: toggleMoreInfo,
              ),

              // Expanded Nutrient Bars
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (showMoreInfo) ...[
                    const SizedBox(height: 16),

                    /// Nutrients
                    _NutrientBar(
                      title: "Carbs",
                      value: "$carbs / 250g",
                      consumedValue: consumedCarbs,
                      targetedValue: 250,
                      color: Colors.orange,
                      progress: 0.9,
                    ),
                    const SizedBox(height: 10),
                    _NutrientBar(
                      title: "Proteins",
                      value: "$protein / 75g",
                      consumedValue: consumedProtein,
                      targetedValue: 75,
                      color: Colors.indigo,
                      progress: 0.85,
                    ),
                    const SizedBox(height: 10),
                    _NutrientBar(
                      title: "Fats",
                      value: "$fat / 60g",
                      consumedValue: consumedFat,
                      targetedValue: 60,
                      color: Colors.yellow.shade700,
                      progress: 0.95,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Info column widget
class _InfoColumn extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const _InfoColumn({
    required this.value,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: deviceWidth(context) > 830 ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black,
          ),
        ),
        if (label.isNotEmpty)
          Text(
            label,
            style: TextStyle(
              fontSize: deviceWidth(context) > 830 ? 16 : 12,
              color: Colors.grey.shade600,
            ),
          ),
      ],
    );
  }
}

/// Nutrient progress bar widget
class _NutrientBar extends StatelessWidget {
  final String title;
  final double consumedValue;
  final double targetedValue;
  final String value;
  final Color color;
  final double progress;

  const _NutrientBar({
    required this.title,
    required this.consumedValue,
    required this.targetedValue,
    required this.value,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final double progressValue = consumedValue / targetedValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          title,
          style: TextStyle(
            fontSize: deviceWidth(context) > 830 ? 18 : 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        // Progress bar
        SizedBox(
          width: deviceWidth(context) > 830
              ? 200
              : deviceWidth(context) > 410
              ? 120
              : deviceWidth(context) > 390
              ? 100
              : 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progressValue,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Value
        Text(
          value,
          style: TextStyle(
            fontSize: deviceWidth(context) > 830 ? 18 : 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

// user food card

class FoodNutrientsCard extends StatelessWidget {
  FoodLogEntry? foodLogEntry;
  FoodNutrientsCard({super.key, this.foodLogEntry});

  @override
  Widget build(BuildContext context) {
    List<ActualNutrientIntake> actualNutrientIntakes =
        foodLogEntry!.actualNutrientIntakes;
    String? calories = actualNutrientIntakes.valueOf("Calories");
    String? sodium = actualNutrientIntakes.valueOf("Sodium");
    String? carbs = actualNutrientIntakes.valueOf("Carbohydrates");
    String? fat = actualNutrientIntakes.valueOf("Fat");
    String? protein = actualNutrientIntakes.valueOf("Protein");
    double? dcalories = actualNutrientIntakes.valueOfQuantity("Calories");
    double? dsodium = actualNutrientIntakes.valueOfQuantity("Sodium");
    double? dcarbs = actualNutrientIntakes.valueOfQuantity("Carbohydrates");
    double? dfat = actualNutrientIntakes.valueOfQuantity("Fat");
    double? dprotein = actualNutrientIntakes.valueOfQuantity("Protein");
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 300 ? 300.0 : constraints.maxWidth;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: 300, maxWidth: width),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    /// 🔹 Top Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 8,
                                    child: Text(
                                      foodLogEntry!
                                          .foodItemWithNutrients!
                                          .description!,
                                      style: AppTheme.title20.copyWith(
                                        fontSize:
                                            AppTheme.responsiveTitleFontSize(
                                              context,
                                            ),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      width: deviceWidth(context) > 830
                                          ? 40
                                          : 25,
                                      height: deviceWidth(context) > 830
                                          ? 40
                                          : 25,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTheme.primaryColor,
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Image.asset(
                                          _getImageOfMealType(
                                            index: foodLogEntry!.mealType!.id,
                                          ),
                                          height: deviceWidth(context) > 830
                                              ? 30
                                              : 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                calories,
                                style: AppTheme.title12.copyWith(
                                  fontSize: AppTheme.responsiveTitle2FontSize(
                                    context,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        //Image.asset(_getImageOfMealType(index: foodLogEntry!.mealType!.id),height: 30,),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () async {
                            final editData = MealEditData(
                              id: foodLogEntry!.id!,
                              name: foodLogEntry!
                                  .foodItemWithNutrients!
                                  .description!,
                              quantity: foodLogEntry!.quantity!,
                              servingUnit: foodLogEntry!
                                  .foodItemWithNutrients!
                                  .servingUnit,
                              calories: dcalories,
                              sodium: dsodium,
                              carbs: dcarbs,
                              protein: dprotein,
                              fats: dfat,
                              mealTypeId: foodLogEntry!.mealType!.id!,
                            );

                            debugPrint("➡️ Passing to AddMealPage:");
                            debugPrint(
                              editData.name,
                            ); // 👈 This debugPrints clean JSON-like output

                            final result = await AppRouter.navigateToAddMeal(
                              context,
                              editData: editData,
                              isEditMode: true,
                            );
                          },
                          icon: Icon(
                            Icons.edit,
                            size: deviceWidth(context) > 830 ? 40 : 25,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),

                        Consumer(
                          builder: (context, ref, _) {
                            return IconButton(
                              icon: Icon(
                                Icons.delete,
                                size: deviceWidth(context) > 830 ? 40 : 25,
                                color: AppTheme.primaryColor,
                              ),
                              onPressed: () {
                                _showDeleteMealLogDialog(
                                  context,
                                  foodLogEntry!.id!,
                                  foodLogEntry!
                                      .foodItemWithNutrients!
                                      .description!,
                                  ref,
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    const Divider(color: Colors.black12, thickness: 1),

                    /// 🔹 Nutrients Grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _NutrientItem(
                            color: AppTheme.primaryColor,
                            label: "Sodium ($sodium)",
                          ),
                        ),
                        // Spacer(),
                        Expanded(
                          child: _NutrientItem(
                            color: Colors.orange,
                            label: "Carbs ($carbs)",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _NutrientItem(
                            color: Colors.blueAccent,
                            label: "Proteins ($protein)",
                          ),
                        ),
                        //Spacer(),
                        Expanded(
                          child: _NutrientItem(
                            color: Colors.yellow,
                            label: "Fats ($fat)",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _iconCircle(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.redAccent),
      ),
      child: Icon(icon, size: 16, color: Colors.redAccent),
    );
  }

  String _getImageOfMealType({int? index}) {
    switch (index) {
      case 21:
        return "lib/assets/breakfast.png";
      case 22:
        return "lib/assets/Lunch.png";
      case 23:
        return "lib/assets/snacks.png";
      case 24:
        return "lib/assets/dinner.png";
      default:
        return "lib/assets/All Meal.png";
    }
  }

  // Delete Today Meal
  void _showDeleteMealLogDialog(
    BuildContext context,
    int mealLogId,
    String mealName,
    ref,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
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
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isDeleting
                                ? null
                                : () => Navigator.pop(dialogContext),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isDeleting
                                ? null
                                : () async {
                                    setState(() => isDeleting = true);

                                    final success =
                                        await MealService.deleteMealLog(
                                          mealLogId,
                                        );

                                    if (success) {
                                      Navigator.pop(dialogContext);
                                      _skipNextPopRefresh =
                                          true; // 🔴 IMPORTANT
                                      // ✅ RIVERPOD REFRESH (THIS IS THE FIX)
                                      _refreshMealRelatedProviders(ref);
                                      _showMealDeletedSuccess(
                                        context,
                                        mealName,
                                        ref,
                                      );
                                    } else {
                                      setState(() => isDeleting = false);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Failed to delete meal.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
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
                                : const Text('Delete'),
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

  // Delete Success Message
  void _showMealDeletedSuccess(BuildContext context, String mealName, ref) {
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
                  child: Image.asset('lib/assets/Check Mark.png'),
                ),
                const SizedBox(height: 16),
                Text(
                  '"$mealName" deleted successfully!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6F6C90),
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
                    child: const Text('OK', style: AppTheme.whiteTitle14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _refreshMealRelatedProviders(ref) {
    ref.invalidate(riskMetricsFutureProvider);

    ref.invalidate(nutrientSummaryProvider);
    ref.invalidate(nutrientSummaryByMealTypeProvider);

    ref.invalidate(notificationProvider);
    ref.read(notificationProvider.notifier).loadFirstPage();
  }
}

class _NutrientItem extends StatelessWidget {
  final Color color;
  final String label;

  const _NutrientItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: deviceWidth(context) > 830 ? 16 : 10,
          height: deviceWidth(context) > 830 ? 16 : 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: deviceWidth(context) > 830
                ? AppTheme.title18
                : deviceWidth(context) > 390
                ? AppTheme.title12
                : AppTheme.title10,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// Utility
extension NutrientUtils on List<ActualNutrientIntake> {
  String valueOf(String name) {
    final item = firstWhere(
      (e) => (e.nutrientName ?? '').toLowerCase() == name.toLowerCase(),
      orElse: () => ActualNutrientIntake(quantity: 0, unitType: ''),
    );

    return "${(item.quantity ?? 0).toStringAsFixed(2)} ${item.unitType ?? ''}";
  }
}

extension NutrientUtilsDouble on List<ActualNutrientIntake> {
  double valueOfQuantity(String name) {
    final item = firstWhere(
      (e) => (e.nutrientName ?? '').toLowerCase() == name.toLowerCase(),
      orElse: () => ActualNutrientIntake(quantity: 0),
    );

    return item.quantity ?? 0.0;
  }
}
