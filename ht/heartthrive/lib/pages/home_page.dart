import 'dart:async';
import 'dart:convert';

import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/components/connection_unavailable.dart';
import 'package:heart_thrive/constants/heart_thrive_strings_constants.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import 'package:heart_thrive/pages/meal-sodium/user_today_food.dart';
import 'package:heart_thrive/pages/medication/all_medication_page.dart';
import 'package:heart_thrive/pages/riskmeter/risk_meter_dashboard.dart';
import 'package:heart_thrive/pages/subscription/subscription_overlay.dart';
import 'package:heart_thrive/pages/weight_bmi/add_body_mass_index_page.dart';
import 'package:heart_thrive/providers/token_provider.dart';
import 'package:heart_thrive/providers/user/user_details_provider.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:intl/intl.dart';

import '../components/animated_section.dart';
import '../components/editable_bottomsheet_card.dart';
import '../components/profile_avatar.dart';
import '../components/ui_components.dart';
import '../main.dart';
import '../models/bmi/weight_height_model.dart';
import '../providers/bmi/bmi_provider.dart';
import '../providers/bmi/notification_provider.dart';
import '../providers/internet_provider.dart';
import '../providers/meal/meal_sodium_provider.dart';
import '../providers/medication/medication_provider.dart';
import '../routes/app_router.dart';
import '../services/home/risk_meter_service.dart';
import '../services/home/weight_height_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../utils/component_utils.dart';
import '../utils/secure_storage_utils.dart';
import 'meal-sodium/sodium_home_page_summary.dart';
import 'medication/medication_home_card.dart';
import 'notification_badgeicon_widget.dart';

class MainPage extends ConsumerStatefulWidget {
  int? selectedIndex = 0;
  MainPage({ this.selectedIndex});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  late int _selectedIndex = widget.selectedIndex ?? 0;
  int _homeRefreshKey = 0;
  DateTime? _lastBackPress;
  bool? subscriptionIsExpire = false;

  List<Widget> get _pages => [
    HomePage(key: ValueKey(_homeRefreshKey)),
    const MealLogsPage(isHome: true,),
    const SizedBox(),
    const AllMedicationPage(navFromPage: "home",isHome: true,),
    const AddBodyMassIndexPage(isHome:true),
  ];

  final List<String> _quickNavKeysOld = [
    "home",
    "education",
    "",
    // center add → handled separately
    "recipe",
    "profile",
  ];
  final List<String> _quickNavKeys = [
    "home",
    "logsodium",
    "",
    // center add → handled separately
    "medication",
    "weight",
  ];

  @override
  void initState() {
    super.initState();

    // Add lifecycle observer to detect app resume

    // Initial setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).loadFirstPageNew();
      ref.read(riskMetricsFutureProvider);
    });

    // Add back button interceptor
    BackButtonInterceptor.add(myInterceptor);
  }

  @override
  void dispose() {
    // Clean up: remove observer and interceptor

    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    // Let the PopScope handle it via _handleBack()
    return false;
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      final key = _quickNavKeys[_selectedIndex];
      showQuickNavigationBottomSheet(context, key);
      return;
    }

    // If switching TO Home from another tab → refresh
    if (index == 0 && _selectedIndex != 0) {
      _refreshHome();
    }

    // If already on the same tab and it's Home → optional scroll-to-top or manual refresh
    if (_selectedIndex == index && index == 0) {
      // You can trigger a manual refresh here if desired
      // _refreshHome();
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  void _refreshHome() {
    ref.invalidate(riskMetricsFutureProvider);
    ref.invalidate(heroDashboardProvider);
    // Add other providers if needed
    setState(() {
      _homeRefreshKey++;
    });
    debugPrint("HomePage refreshed - key: $_homeRefreshKey");
  }

  void _handleBack() {
    if (_selectedIndex != 0) {
      // Coming back to Home from another tab → SELECT HOME + REFRESH
      setState(() => _selectedIndex = 0);
      _refreshHome(); // ← Critical: ensures fresh data on back navigation
      return;
    }

    // Already on Home → double press to exit
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Exit app
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Stack(
        children: [
          Scaffold(
            body: IndexedStack(index: _selectedIndex, children: _pages),
            bottomNavigationBar: _buildBottomNav(),
          ),
          if(subscriptionIsExpire!)
           const SubscriptionExpiredOverlay(),
        ],
      ),
    );
  }

  Widget _buildBottomNavOld() {
    return SafeArea(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            height: 85,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedFontSize: deviceWidth(context) > 830 ? 18 : 12,
              unselectedFontSize: deviceWidth(context) > 830 ? 18 : 12,
              onTap: _onItemTapped,
              items: [
                BottomNavigationBarItem(
                  icon: Image.asset(
                    _selectedIndex == 0
                        ? 'lib/assets/home_active.png'
                        : 'lib/assets/home_not_active.png',
                    width: deviceWidth(context) > 830 ? 40 : 28,
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Image.asset(
                    _selectedIndex == 1
                        ? 'lib/assets/nb_1.png'
                        : 'lib/assets/nb_2.png',
                    width: deviceWidth(context) > 830 ? 40 : 28,
                  ),
                  label: 'Education',
                ),
                const BottomNavigationBarItem(
                  icon: SizedBox.shrink(),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Image.asset(
                    _selectedIndex == 3
                        ? 'lib/assets/nb_7.png'
                        : 'lib/assets/nb_8.png',
                    width: deviceWidth(context) > 830 ? 40 : 28,
                  ),
                  label: 'Recipe',
                ),
                BottomNavigationBarItem(
                  icon: Image.asset(
                    _selectedIndex == 4
                        ? 'lib/assets/nb_5.png'
                        : 'lib/assets/nb_6.png',
                    width: deviceWidth(context) > 830 ? 40 : 28,
                  ),
                  label: 'Profile',
                ),
              ],
            ),
          ),

          // Floating Add Button
          Positioned(
            top: 6,
            child: GestureDetector(
              onTap: () {
                final key = _quickNavKeys[_selectedIndex];
                showQuickNavigationBottomSheet(context, key);
              },
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, size: 35, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            height: 85,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedFontSize: deviceWidth(context) > 830 ? 18 : 12,
              unselectedFontSize: deviceWidth(context) > 830 ? 18 : 12,
              onTap: _onItemTapped,
              items: [
                BottomNavigationBarItem(
                  icon: Image.asset(
                    _selectedIndex == 0
                        ? 'lib/assets/home/home_active.png'
                        : 'lib/assets/home/home_not_active.png',
                    width: deviceWidth(context) > 830 ? 40 : 28,
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Image.asset(
                    _selectedIndex == 1
                        ? 'lib/assets/home/log-sodium-active.png'
                        : 'lib/assets/home/log-sodium-not-active.png',
                    width: deviceWidth(context) > 830 ? 40 : 28,
                  ),
                  label: 'Log Sodium',
                ),
                const BottomNavigationBarItem(
                  icon: SizedBox.shrink(),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Image.asset(
                    _selectedIndex == 3
                        ? 'lib/assets/home/medication-active.png'
                        : 'lib/assets/home/medication-not-active.png',
                    width: deviceWidth(context) > 830 ? 40 : 28,
                  ),
                  label: 'Medication',
                ),
                BottomNavigationBarItem(
                  icon: Image.asset(
                    _selectedIndex == 4
                        ? 'lib/assets/home/scale-active.png'
                        : 'lib/assets/home/scale-not-active.png',
                    width: deviceWidth(context) > 830 ? 40 : 28,
                  ),
                  label: 'Weight',
                ),
              ],
            ),
          ),

          // Floating Add Button
          Positioned(
            top: 6,
            child: GestureDetector(
              onTap: () {
                final key = _quickNavKeys[_selectedIndex];
                showQuickNavigationBottomSheet(context, key);
              },
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, size: 35, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // ---------------------------------------------------------
  //  STATE VARIABLES (CLEANED + OPTIMIZED)
  // ---------------------------------------------------------

  bool _isLoadingMedicationData = false;
  DateTime? _lastBackPressed;

  // Sodium
  final formatter = NumberFormat('#,###');
  bool _isLoadingSodiumData = false;

  // Risk Metrics

  // Weight / BMI
  bool _isLoadingWeightData = false;
  double _weightChange24h = 0.0;
  double _weightChange48h = 0.0;
  String? _bmiStatusLabel;


  // Navbar Index
  int _selectedIndex = 0;

  // ---------------------------------------------------------
  //  INIT
  // ---------------------------------------------------------
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).loadFirstPage();
      ref.read(riskMetricsFutureProvider);
      ref.read(todayNutrientProvider);
      ref.read(nutrientSummaryByMealTypeProvider);
    });
    _loadUserData();

    debugPrint("HomePage initialized for user: ${UserService.userFirstName}");
    //initFCMForeGroundNotifications();
  }

  Future<void> _refresh() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).loadFirstPage();
    });
    // Load all async sections
    // Risk Meter
    ref.invalidate(riskMetricsFutureProvider);
    // Sodium
    ref.invalidate(todayNutrientProvider);
    ref.invalidate(nutrientSummaryByMealTypeProvider);
    // Medication
    ref.invalidate(intakeMedicationSummaryProvider);
    ref.invalidate(medicationScheduleOverviewProvider);
    // Weight
    ref.invalidate(heroDashboardProvider);
    ref.invalidate(currentAndPastProvider);
    ref.invalidate(mealLogsProvider);

    _loadUserData();

    debugPrint("HomePage initialized for user: ${UserService.userFirstName}");
  }

  bool _isPageLoading(AsyncValue riskAsync) {
    return (
        _isLoadingSodiumData ||
            _isLoadingMedicationData ||
            riskAsync.isLoading
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Risk Meter
    ref.invalidate(riskMetricsFutureProvider);
    // Sodium
    ref.invalidate(todayNutrientProvider);
    ref.invalidate(nutrientSummaryByMealTypeProvider);
    // Medication
    ref.invalidate(intakeMedicationSummaryProvider);
    ref.invalidate(medicationScheduleOverviewProvider);
    // Weight
    ref.invalidate(heroDashboardProvider);
  }

  // ---------------------------------------------------------
  //  LOAD USER
  // ---------------------------------------------------------
  Future<void> _loadUserData() async {
    await UserService.initializeUser();
    setState(() {});
  }

  // ---------------------------------------------------------
  //  LOAD WEIGHT & BMI
  // ---------------------------------------------------------


  // Function to get the correct MessageFrame image based on score

  // ---------------------------------------------------------
  //  BUILD UI
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final userDetailsAsync = ref.watch(userDetailsDataProvider);
    final riskAsync = ref.watch(riskMetricsFutureProvider);
    final hero = ref.watch(heroDashboardProvider);
    return userDetailsAsync.when(
      data: (user) {
        return WillPopScope(
          onWillPop: () async {
            final now = DateTime.now();
            if (_lastBackPressed == null ||
                now.difference(_lastBackPressed!) >
                    const Duration(seconds: 2)) {
              _lastBackPressed = now;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Press back again to exit'),
                  duration: Duration(seconds: 2),
                ),
              );
              return false;
            }
            // SECOND TAP -> EXIT APP
            SystemNavigator.pop();
            return true;
          },
          child: Scaffold(
            backgroundColor: Colors.grey.shade100,
            appBar: AppBar(
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              leading: InkWell(
                onTap: () async {
                  final result = await AppRouter.navigateToProfile(context);

                  if (result == true) {
                    ref.invalidate(riskMetricsFutureProvider);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 15, top: 8, bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: user?.profileImage == null
                        ? Image.asset(
                      'lib/assets/default_profile_img.png',
                      gaplessPlayback: true,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    )
                        : Image.memory(
                      base64Decode(user!.profileImage!),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      width: 36,
                      height: 36,
                      errorBuilder: (context, error, stack) =>
                      const Icon(Icons.account_circle, color: Colors.white),
                    ),
                  ),
                ),
              ),
              title: Container(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.firstname?.isEmpty ?? true
                          ? "Hi User! 👋"
                          : "Hi, ${user!.firstname} ${user!.lastname}! 👋",
                      style: AppTheme.title18.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: NotificationBadgeIcon(),
                ),
              ],
            ),

            // ---------------------------------------------------------
            //  BODY SCROLL
            // ---------------------------------------------------------
            body: RefreshIndicator(
              onRefresh: () => _refresh(),
              child: _isPageLoading(riskAsync)
                  ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              )
                  : SafeArea(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 5,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // -----------------------------------------------
                              //  RISK METRIC CARD
                              // -----------------------------------------------
                              AnimatedSection(
                                delay: 100,
                                child: RiskDashboard(),
                              ),
                              const SizedBox(height: 12),

                              // -----------------------------------------------
                              //  SODIUM INTAKE CARD
                              // -----------------------------------------------
                              AnimatedSection(
                                delay: 130,
                                child: SodiumHomePageSummary(),
                              ),
                              const SizedBox(height: 12),
                              // -----------------------------------------------
                              //  MEDICATION CARD
                              // -----------------------------------------------
                              AnimatedSection(
                                delay: 160,
                                child: MedicationHomeCard(),
                              ),

                              const SizedBox(height: 12),

                              // -----------------------------------------------
                              //  WEIGHT & BMI CARD
                              // -----------------------------------------------
                              AnimatedSection(
                                delay: 200,
                                child: _buildBMICard(context, hero),
                              ),

                              const SizedBox(height: 20),

                            ],
                          ),
                        ),
                      ),
                    ),
            ),

            // ---------------------------------------------------------
            //  BOTTOM NAVIGATION
            // ---------------------------------------------------------
          ),
        );
      },
      error: (e, st) => _buildErrorUI(e, st),
      loading: () => WillPopScope(
        onWillPop: () async {
          final now = DateTime.now();
          if (_lastBackPressed == null ||
              now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
            _lastBackPressed = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Press back again to exit'),
                duration: Duration(seconds: 2),
              ),
            );
            return false;
          }
          return true;
        },
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  // ---------------------------------------------------------
  //  HELPER : Greeting Text
  // ---------------------------------------------------------
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "Good Morning!";
    if (hour >= 12 && hour < 17) return "Good Afternoon!";
    if (hour >= 17 && hour < 21) return "Good Evening!";
    return "Good Night!";
  }

  // ---------------------------------------------------------
  //  BMI & WEIGHT CARD
  // ---------------------------------------------------------
  Widget _buildBMICard(BuildContext context, hero) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildWrapperInkWell(context,
              (){
                AppRouter.navigateToAddBodyMassIndex(context);
              },
            Container(
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardHeader(
                    title: "Weight & Body Mass Index",
                    onAdd: () => AppRouter.navigateToAddBodyMassIndex(context),
                  ),

                  const SizedBox(height: 10),
                  _buildBMIContent(hero),
                ],
              ),
            )
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Spacer(),
              buildDashboardButton(context, () {
                AppRouter.navigateToWeightTrendDashboard(context);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBMIContent(hero) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final data = hero?.value?.data;
    if (data == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(2),
        },
        children: [
          TableRow(
            children: [
              Center(
                child: Text(
                  deviceWidth > 370 ? 'Current Weight' : 'Current\nWeight',
                  textAlign: TextAlign.center,
                  style: deviceWidth > 830 ? AppTheme.body16 : AppTheme.body14,
                ),
              ),
              Center(
                child: Text(
                  deviceWidth > 830 ? 'Last 24H' : 'Last\n 24H',
                  textAlign: TextAlign.center,
                  style: deviceWidth > 830 ? AppTheme.body16 : AppTheme.body14,
                ),
              ),
              Center(
                child: Text(
                  deviceWidth > 830 ? 'Last 48H' : 'Last\n 48H',
                  textAlign: TextAlign.center,
                  style: deviceWidth > 830 ? AppTheme.body16 : AppTheme.body14,
                ),
              ),
              Center(
                child: Text(
                  'BMI',
                  textAlign: TextAlign.center,
                  style: deviceWidth > 830 ? AppTheme.body16 : AppTheme.body14,
                ),
              ),
            ],
          ),
          TableRow(
            children: [
              Center(
                child: Text(
                  data.weight ?? "0",
                  style: AppTheme.title14.copyWith(
                    fontSize: deviceWidth > 830 ? 16 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              Center(child: changeIndicator(data.last24Hours)),
              Center(child: changeIndicator(data.last48Hours)),
              Center(
                child: Column(
                  children: [
                    Text(
                      data.bmiValue?.toStringAsFixed(2) ?? "0.0",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _bmiStatusTag(data.bmiValue),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bmiStatusTag(double? bmi) {
    if (bmi == null) return const SizedBox();
    final category = getBMICategory(bmi);
    final color = getCategoryColor(category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        category.toString(),
        style: TextStyle(
          fontSize: deviceWidth(context) > 830 ? 14 : 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  //  COMMON CARD DECORATION
  // ---------------------------------------------------------
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(.15),
          spreadRadius: 1,
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  //  ERROR UI
  // ---------------------------------------------------------
  Widget _buildErrorUI(e, st) {
    debugPrint("Error 1370 @@ $e");
    debugPrint("Error 1370 @@@ $st");
    final isOnline = ref.watch(isOnlineProvider);

    return !isOnline
        ? ConnectionUnavailable(
            title: HeartThriveStrings.offlineTitle,
            description: HeartThriveStrings.offlineMessage,
            buttonText: "Retry",
            onRetry: () async {
              final token = await SecureStorageUtils().read(
                StorageKeys.accessToken,
              );
              ref.invalidate(tokenProvider);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => MyApp(initialToken: token),
                ),
                (route) => false,
              );
            },
          )
        : ConnectionUnavailable(
            title: HeartThriveStrings.userServerIssueTitle,
            description: HeartThriveStrings.userServerIssueDescription,
            buttonText: "Retry",
            onRetry: () async {
              final token = await SecureStorageUtils().read(
                StorageKeys.accessToken,
              );
              ref.invalidate(tokenProvider);
              ref.invalidate(currentAndPastProvider);
              ref.invalidate(mealLogsProvider);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyApp(initialToken: token),
                ),
              );
            },
          );
  }

  Future<bool> isOnline() async {
    final bool isConnected = await InternetConnection().hasInternetAccess;
    return isConnected;
  }

  // ---------------------------------------------------------
  //  CARD HEADER (Title + Add)
  // ---------------------------------------------------------
  Widget _cardHeader({required String title, required VoidCallback onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        headerTitle(context, "Weight & Body Mass Index"),
        buildAddNewButton(context, onAdd),
      ],
    );
  }

  // ---------------------------------------------------------
  //  CHANGE INDICATOR (UP/DOWN ARROW)
  // ---------------------------------------------------------
  Widget changeIndicator(ChangeInfo? info) {
    if (info == null) return const SizedBox();

    final increased = info.changeType == ChangeType.increased;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          info.value ?? "-",
          style: AppTheme.title14.copyWith(
            fontWeight: FontWeight.bold,
            color: increased ? Colors.red : Colors.green,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(width: 4),
        Icon(
          increased ? Icons.arrow_upward : Icons.arrow_downward,
          size: 16,
          color: increased ? Colors.red : Colors.green,
        ),
      ],
    );
  }
}
