import 'dart:async';
import 'dart:ui';

import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:heart_thrive/components/profile_avatar.dart';
import 'package:heart_thrive/components/time_12h_formatter.dart';
import 'package:heart_thrive/constants/heart_thrive_strings_constants.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import 'package:heart_thrive/models/medication/medication_schedule_list_model.dart';
import 'package:heart_thrive/providers/bmi/notification_provider.dart';
import 'package:heart_thrive/routes/app_router.dart';
import 'package:intl/intl.dart';

import '../../components/action_menu.dart';
import '../../components/pop_up_dialog_ui.dart';
import '../../main.dart';
import '../../models/medication/medication_intake_summary.dart';
import '../../models/medication/medication_model.dart';
import '../../providers/medication/medication_provider.dart';
import '../../services/home/risk_meter_service.dart';
import '../../services/medication_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../utils/secure_storage_utils.dart';
import '../notification_badgeicon_widget.dart';
import 'add_medication_page.dart';
import 'medication_dose_banner.dart';

class AllMedicationPage extends StatefulWidget {
  final String? navFromPage;
  final bool isViewFullMode;
  final bool? isHome;
  const AllMedicationPage({
    Key? key,
    this.isViewFullMode = false,
    this.navFromPage,
    this.isHome = false
  }) : super(key: key);
  @override
  State<AllMedicationPage> createState() => _AllMedicationPageState();
}

class _AllMedicationPageState extends State<AllMedicationPage> with RouteAware {
  bool _skipNextPopRefresh = false;
  // View Medication Info
  late bool _isViewFullMode;
  int _selectedTabIndex = 0;
  bool _showSearchBox = false;
  bool _showBrowseSearchBox = false;
  bool _showCustomFilter = true;
  bool _showMedicationList = false;
  bool _showCustomContent = false;
  final FocusNode _searchFocusNode = FocusNode();

  MedicationScheduleResponse? _medications;
  List<MedicationModel> _myMedications = [];
  bool _isLoading = false;
  String _searchQuery = '';
  bool _hasError = false;
  bool? _isMorningFilter;
  bool? _isAfternoonFilter;
  bool? _isEveningFilter;
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce;
  int _totalTaken = 0;
  int _totalScheduled = 0;
  int _totalMissed = 0;
  int _dosesLeft = 0;
  bool _isLoadingStats = true;

  int toggleSelector = 0;

  // Intake Medication Data
  IntakeMedicationSummary? _intakeMedicationSummary;
  bool _isUpdatingIntake = false;
  final ScrollController _browseScrollController = ScrollController();

  List<Map<String, dynamic>> _browseResults = [];

  int _browsePage = 0;
  final int _browsePageSize = 20;
  bool _isBrowseLoading = false;
  bool _hasMoreBrowseData = true;
  List<MedicationModel> _filteredMedications = []; // search result

  // async search safety
  int _browseRequestId = 0;
  String _browseQuery = '';

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _browseScrollController.dispose();
    _searchFocusNode.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    //BackButtonInterceptor.remove(_allMedicationBackHandler);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _isViewFullMode = widget.isViewFullMode;
    _fetchMyMedications();
    _fetchIntakeStats();
    _searchController.addListener(() {
      _onBrowseSearchChanged(_searchController.text);
    });

    _loadBrowseMedications();
    _browseScrollController.addListener(() {
      if (_browseScrollController.position.pixels >=
          _browseScrollController.position.maxScrollExtent - 120 &&
          !_isBrowseLoading &&
          _hasMoreBrowseData) {
        _loadBrowseMedications();
      }
    });
    _filteredMedications = List.from(_myMedications);
    _searchController.addListener(_onSearchChanged);
    //BackButtonInterceptor.add(_allMedicationBackHandler);
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

    _refresh(); // ✅ runs only when coming from Add / Browse pages
  }

  bool _allMedicationBackHandler(bool stopDefaultButtonEvent, RouteInfo info) {
    AppRouter.replaceWithHome(context);

    return true;
    // IMPORTANT: Returning true consumes the back event
    // and prevents Flutter from popping the current screen.
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _isLoadingStats = true;
      _isMorningFilter = true;
      _isAfternoonFilter = true;
      _isEveningFilter = true;
      _searchController.clear();
    });

    _isViewFullMode = widget.isViewFullMode; // read the passed value
    _fetchMyMedications();

    _searchController.addListener(() {
      _onBrowseSearchChanged(_searchController.text);
    });
    _fetchIntakeStats();

    setState(() {
      _isLoading = true;
      _isLoadingStats = true;
      _isMorningFilter = true;
      _isAfternoonFilter = true;
      _isEveningFilter = true;
    });
  }

  Future<void> _fetchIntakeStats() async {
    setState(() => _isLoadingStats = true);

    try {
      final now = DateTime.now();
      final formattedDate =
          "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";

      debugPrint("Input test $formattedDate");
      final stats = await MedicationService.getMedicationIntakeStats(
        fromDate: formattedDate,
        toDate: formattedDate,
      );

      // Network Call
      String? token = await SecureStorageUtils().read("auth_token");
      String fromDate = DateFormatUtil.getStartOfDay(DateTime.now());
      String toDate = DateFormatUtil.getEndOfDay(DateTime.now());
      _intakeMedicationSummary = await MedicationService()
          .fetchIntakeCountSummary(token!, fromDate, toDate, "");

      final data = stats["data"];
      setState(() {
        _totalTaken = data["totalTaken"] ?? 0;
        _totalScheduled = data["totalScheduled"] ?? 0;
        _totalMissed = data["totalMissed"] ?? 0;
        _isLoadingStats = false;
        _dosesLeft = _totalScheduled - _totalTaken;
        debugPrint("_dosesLeft $_dosesLeft");
      });
    } catch (e) {
      debugPrint("❌ Error fetching stats: $e");
      setState(() => _isLoadingStats = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        _filteredMedications = List.from(_myMedications);
      } else {
        _filteredMedications = _myMedications.where((med) {
          final name = med.medicationName?.toLowerCase() ?? '';
          final brand = med.medicationBrand?.toLowerCase() ?? '';
          return name.contains(query) || brand.contains(query);
        }).toList();
      }
    });
  }

  void _onBrowseSearchChanged(String value) {
    final query = cleanSearch(value);
    _browseQuery = query;

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _resetAndSearchBrowse();
    });
  }

  void _resetAndSearchBrowse() {
    _browsePage = 0;
    _browseResults.clear();
    _hasMoreBrowseData = true;

    _loadBrowseMedications(isNewSearch: true);
  }

  Future<void> _loadBrowseMedications({bool isNewSearch = false}) async {
    if (_isBrowseLoading) return;

    final int requestId = ++_browseRequestId;

    setState(() => _isBrowseLoading = true);

    try {
      final results = await MedicationService.searchMedications(
        name: _browseQuery,
        page: _browsePage,
        size: _browsePageSize,
      );

      // ❌ Ignore outdated responses
      if (requestId != _browseRequestId) return;

      setState(() {
        _browseResults.addAll(results);
        _browsePage++;

        if (results.length < _browsePageSize) {
          _hasMoreBrowseData = false;
        }
      });
    } catch (e) {
      debugPrint("Browse search error: $e");
    }

    setState(() => _isBrowseLoading = false);
  }

  String cleanSearch(String search) {
    return search.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _onSearchFirstLoadUI() {
    _isLoading = true;
    setState(() {});
    debugPrint('');
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final results = await MedicationService.searchMedications(name: "");
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      } catch (e) {
        _isLoading = false;
        setState(() {});
        debugPrint("Search error: $e");
      }
    });
  }

  Future<void> _fetchMyMedications({
    bool? isMorning,
    bool? isAfternoon,
    bool? isEvening,
  }) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final meds = await MedicationService.fetchMedications(
        isMorning: isMorning,
        isAfternoon: isAfternoon,
        isEvening: isEvening,
      );
      final myMeds = await MedicationService.fetchMyMedications();
      setState(() {
        _medications = meds;
        _myMedications = myMeds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedTabIndex = index;

      // Set filter based on tab
      switch (index) {
        case 0: // All
          _isMorningFilter = true;
          _isAfternoonFilter = true;
          _isEveningFilter = true;
          break;
        case 1: // Morning
          _isMorningFilter = true;
          _isAfternoonFilter = false;
          _isEveningFilter = false;
          break;
        case 2: // Afternoon
          _isMorningFilter = false;
          _isAfternoonFilter = true;
          _isEveningFilter = false;
          break;
        case 3: // Evening
          _isMorningFilter = false;
          _isAfternoonFilter = false;
          _isEveningFilter = true;
          break;
      }
    });

    // Fetch filtered data
    _fetchMyMedications(
      isMorning: _isMorningFilter,
      isAfternoon: _isAfternoonFilter,
      isEvening: _isEveningFilter,
    );
  }

  // Refresh Home Page Data
  void refreshMedicationHomeData(ref) {
    ref.invalidate(medicationScheduleOverviewProvider);
    ref.invalidate(intakeMedicationSummaryProvider);
    ref.invalidate(riskMetricsFutureProvider);
    ref.invalidate(notificationProvider);
    ref.read(notificationProvider.notifier).loadFirstPage();
  }

  //DEmoTeST123

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        print("demoprint121");
        if (widget.navFromPage == NavPageType.home.name ||
            widget.navFromPage == NavPageType.addMedication.name) {
          AppRouter.replaceWithHome(context);
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppTheme.appBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular( widget.isHome!?24:0),
            ),
          ),
          leading:widget.isHome!? ProfileAvatar(): GestureDetector(
            onTap: () {
              print("demoprint121");
              if (widget.navFromPage == NavPageType.home.name ||
                  widget.navFromPage == NavPageType.addMedication.name) {
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
          title: Center(child: const Text('Medication')),
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
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => _refresh(),
              child: Column(
                children: [
                  // Daily Medication Intake Card - UPDATED DESIGN
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Daily Medication Intake',
                              style: deviceWidth(context) > 750 ? AppTheme.title20:AppTheme.title16,
                            ),
                            Text(
                              '${_intakeMedicationSummary?.data?.totalTaken ?? 0}/${_intakeMedicationSummary?.data?.totalScheduled ?? 0} Dose',
                              style: deviceWidth(context) > 750 ? AppTheme.title20:AppTheme.title16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Progress Bar Section
                        _buildMedicationSummary(),
                        // Tab buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildTabButton(0, 'All', 'lib/assets/Calendar.png'),
                            _buildTabButton(1, 'Morning', 'lib/assets/Sun.png'),
                            _buildTabButton(
                              2,
                              'Afternoon',
                              'lib/assets/Dawn.png',
                            ),
                            _buildTabButton(
                              3,
                              'Evening',
                              'lib/assets/Vaporwave.png',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Medication List and Browse Medication buttons
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _showBrowseSearchBox = false;
                                        _showMedicationList = false;
                                        _showCustomFilter = false;
                                        _showCustomContent = false;
                                      });
                                    },
                                    child: Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      // similar to button height
                                      decoration: BoxDecoration(
                                        color: _showBrowseSearchBox
                                            ? Colors.grey.shade200
                                            : AppTheme.primaryColor,
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                      child: Text(
                                        "Today's Medication",
                                        style: TextStyle(
                                          color: _showBrowseSearchBox
                                              ? Colors.grey
                                              : Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: deviceWidth(context) > 750 ? 20:12,
                                        ),
                                        softWrap: false,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 5),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (_searchController.text.isEmpty) {
                                        _onSearchFirstLoadUI();
                                      }
                                      setState(() {
                                        _showBrowseSearchBox = true;
                                        _showCustomFilter = true;
                                      });
                                    },
                                    child: Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      // similar to button height
                                      decoration: BoxDecoration(
                                        color: _showBrowseSearchBox
                                            ? AppTheme.primaryColor
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                      child: Text(
                                        "Browse Medication",
                                        style: TextStyle(
                                          color: _showBrowseSearchBox
                                              ? Colors.white
                                              : Colors.grey,
                                          fontWeight: FontWeight.w600,
                                          fontSize: deviceWidth(context) > 750 ? 20:12,
                                        ),
                                        softWrap: false,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_showBrowseSearchBox) ...[
                            // Add this at the top of your widget tree where you want the radio buttons
                            SizedBox(height: deviceWidth(context) > 750 ? 12:0),
                            Row(
                              mainAxisAlignment:deviceWidth(context) > 750 ? MainAxisAlignment.spaceEvenly: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Radio<bool>(
                                      value: true,
                                      groupValue: _showMedicationList,
                                      visualDensity: const VisualDensity(
                                        horizontal: -4,
                                        vertical: -4,
                                      ),
                                      // 👈 reduces spacing
                                      onChanged: (value) {
                                        setState(() {
                                          _searchFocusNode.unfocus();
                                          _showMedicationList = true;
                                          _searchController.clear();
                                          // optional, depending on your UI
                                        });
                                      },
                                    ),
                                    Text(
                                      "My Medication List",
                                      style: deviceWidth(context) > 750 ? AppTheme.title20:AppTheme.title14,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Row(
                                  children: [
                                    Radio<bool>(
                                      value: false,
                                      groupValue: _showMedicationList,
                                      visualDensity: const VisualDensity(
                                        horizontal: -4,
                                        vertical: -4,
                                      ),
                                      // 👈 reduces spacing
                                      onChanged: (value) {
                                        setState(() {
                                          _searchFocusNode.unfocus();
                                          _searchController.clear();
                                          _showMedicationList = false;
                                          _showBrowseSearchBox =
                                          true; // optional, depending on your UI
                                        });
                                      },
                                    ),
                                    Text(
                                      "Find Medications",
                                      style: deviceWidth(context) > 750 ? AppTheme.title20:AppTheme.title14,
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            SizedBox(height: deviceWidth(context) > 750 ? 12:8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,

                              ),
                              child: Container(
                                height: deviceWidth(context) > 750 ? 60:45,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  contextMenuBuilder:
                                      (context, editableTextState) {
                                    return const SizedBox.shrink();
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Search medication',
                                    hintStyle: TextStyle(
                                        fontSize: deviceWidth(context) > 750 ? 20:16
                                    ),
                                    prefixIcon:  Icon(Icons.search,size: deviceWidth(context) > 750 ? 30:24,),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    suffixIcon: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_showCustomFilter &&
                                            !_showCustomContent)
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      AddMedicationPage(
                                                        medPeriod:
                                                        _selectedTabIndex,
                                                        customMode: true,
                                                        ishome: widget.isHome ?? false,
                                                      ),
                                                ),
                                              );
                                              // AppRouter.navigateToAllMedication(context);
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.all(8),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryColor,
                                                borderRadius:
                                                BorderRadius.circular(14),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'Custom +',
                                                  style: deviceWidth(context) > 750 ? AppTheme.title18
                                                      .copyWith(
                                                    color: Colors.white,
                                                  ):AppTheme.title12
                                                      .copyWith(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),

                          // Tab content
                          Expanded(child: _buildTabContent()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isUpdatingIntake)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    color: Colors.black.withOpacity(0.1),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
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

  Widget _buildTabButton(int index, String title, String imagePath) {
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
          _onTabChanged(_selectedTabIndex);
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: deviceWidth(context) > 750 ? 60:40,
            height: deviceWidth(context) > 750 ? 60:40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6), // adjust this for image size
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    _getTabIcon(index),
                    size: 22,
                    color: AppTheme.primaryColor,
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 8),
          Container(
            width: deviceWidth(context) > 750 ? 100:70,
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
                title,
                style: TextStyle(
                  fontSize: deviceWidth(context) > 750 ? 16:10,
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
  }

  _mealTypeIconImage(int index, String imagePath) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: deviceWidth(context) > 750 ? 38 :28,
        height:deviceWidth(context) > 750 ? 38 : 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.primaryColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6), // adjust this for image size
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                _getTabIcon(index),
                size: 22,
                color: AppTheme.primaryColor,
              );
            },
          ),
        ),
      ),
    );
  }

  IconData _getTabIcon(int index) {
    switch (index) {
      case 0: // All
        return Icons.calendar_today;
      case 1: // Morning
        return Icons.wb_sunny;
      case 2: // Afternoon
        return Icons.wb_cloudy;
      case 3: // Evening
        return Icons.nights_stay;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildMedicationSummary() {
    debugPrint("_isViewFullMode @@@ 762 ${_isViewFullMode}");
    debugPrint(
      "_intakeMedicationSummary @@@@ ${_intakeMedicationSummary?.data?.upcomingMedications.length}",
    );
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    final progress = _totalScheduled == 0 ? 0.0 : _totalTaken / _totalScheduled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Row — Doses Taken and Progress Bar
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$_totalTaken', style: deviceWidth(context) > 750 ? AppTheme.title18:AppTheme.title14),
                Text(
                  'Doses \nTaken',
                  style: deviceWidth(context) > 750 ? AppTheme.title18.copyWith(color: Colors.grey):AppTheme.title14.copyWith(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_totalScheduled',
                        style: deviceWidth(context) > 750 ? AppTheme.title18.copyWith(color: AppTheme.primaryColor)
                            :AppTheme.title14.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Target',
                        style: deviceWidth(context) > 750 ? AppTheme.title18.copyWith(color: AppTheme.primaryColor):AppTheme.title14.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade300,
                      color: AppTheme.primaryColor,
                      minHeight: deviceWidth(context) > 750 ? 14:6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "•",
                        style: TextStyle(fontSize: deviceWidth(context) > 750 ? 40 :30, color: Colors.red),
                      ),
                      Text(
                        "${_totalMissed} Missed Doses",
                        style: deviceWidth(context) > 750 ? AppTheme.title18.copyWith(color: Colors.grey):AppTheme.title14.copyWith(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$_dosesLeft', style: deviceWidth(context) > 750 ? AppTheme.title18 : AppTheme.title14),
                Text(
                  'Doses \n Left',
                  style:deviceWidth(context) > 750 ? AppTheme.title18.copyWith(color: Colors.grey): AppTheme.title14.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 10),
        if (_isViewFullMode)
          _intakeMedicationSummary != null
              ? MedicationDoseBanner(intakeSummary: _intakeMedicationSummary!)
              : const SizedBox(height: 0, width: 0),
        if (_isViewFullMode)
          _intakeMedicationSummary != null
              ? MedicationDoseBanner(
            intakeSummary: _intakeMedicationSummary!,
            isMissedDose: true,
          )
              : const SizedBox(height: 0, width: 0),

        // Missed doses
      ],
    );
  }

  Widget _buildMyMedicationScheduleList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_hasError)
      return Center(child: Text('Failed to load medications.',style: TextStyle(fontSize: deviceWidth(context) > 750 ? 20:14),));

    final allSchedules = _medications?.data?.allSchedules;

    if (allSchedules == null || allSchedules.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                HeartThriveStrings.noMedicationTodayMSG,
                style: deviceWidth(context) > 750 ? AppTheme.title20.copyWith(fontWeight: FontWeight.normal) :AppTheme.title16.copyWith(fontWeight: FontWeight.normal),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Image.asset(
                'lib/assets/smartphone_1047642 1.png',
                width: deviceWidth(context) > 750 ? 250 : 200,
                height:deviceWidth(context) > 750 ? 250 : 200,
              ),
            ],
          ),
        ),
      );
    }

    // 🔍 Maintain a filtered list based on search input
    final filteredSchedules = allSchedules.where((schedule) {
      final query = _searchQuery.toLowerCase();
      return schedule.medicationName.toLowerCase().contains(query) ||
          schedule.medicationBrand.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        // 🔍 Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            contextMenuBuilder: (context, editableTextState) {
              return const SizedBox.shrink();
            },
            decoration: InputDecoration(
              hintText: 'Search medication',
              hintStyle: TextStyle(
                  fontSize: deviceWidth(context) > 750 ? 20:16
              ),
              prefixIcon: Icon(Icons.search, size: deviceWidth(context) > 750 ? 30:24,),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: deviceWidth(context) > 750 ? 12 :12,
                vertical: deviceWidth(context) > 750 ? 18 :10,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim();
              });
            },
          ),
        ),

        // 📋 List
        Expanded(
          child: filteredSchedules.isEmpty
              ? const Center(
            child: Text(
              'No matching medications found.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          )
              : ListView.builder(
            itemCount: filteredSchedules.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final schedule = filteredSchedules[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildDetailedMedicationScheduleListCard(
                  context,
                  schedule,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedMedicationScheduleListCard(
      BuildContext context,
      MedicationSchedule schedule,
      ) {
    toggleSelector = (schedule.isTaken ?? false) ? 0 : 1;

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
                    width: deviceWidth(context) > 750 ? 160 :80,
                    height: deviceWidth(context) > 750 ? 160 :80,
                    child: Image.asset('lib/assets/Check Mark.png'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '"$mealName" deleted successfully!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: deviceWidth(context) > 750 ? 25 :16,
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
                        _fetchIntakeStats();
                        _fetchMyMedications();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text('OK', style: deviceWidth(context) > 750 ? AppTheme.whiteTitle23 : AppTheme.whiteTitle14),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Medication Name & Time Slot
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.timeSlot ?? 'Unknown Medication',
                    style: TextStyle(
                      fontSize: deviceWidth(context) > 750 ? 18 :16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.notifications_active_outlined,
                    color: AppTheme.primaryColor,
                    size: deviceWidth(context) > 750 ? 22:18,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    formatTo12Hour(schedule.scheduledTime) ?? '',
                    style:  TextStyle(
                      fontSize: deviceWidth(context) > 750 ? 18 : 14,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Expanded(
                          child: Flexible(
                            child: Text(
                              schedule.medicationName,
                              style: TextStyle(
                                fontSize: deviceWidth(context) > 750 ? 20 : 14,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Flexible(
                            child: Text(
                              "(${schedule.quantity})",
                              style:  TextStyle(
                                fontSize: deviceWidth(context) > 750 ? 20:14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 5),
                        if (schedule.timeSlot?.toUpperCase() == 'MORNING')
                          _mealTypeIconImage(1, 'lib/assets/Sun.png'),
                        if (schedule.timeSlot?.toUpperCase() == 'AFTERNOON')
                          _mealTypeIconImage(1, 'lib/assets/Dawn.png'),
                        if (schedule.timeSlot?.toUpperCase() == 'EVENING')
                          _mealTypeIconImage(1, 'lib/assets/Vaporwave.png'),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          MedicationModel model = schedule.toModel();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddMedicationPage(
                                isEditMode: true,
                                medicationData: model,
                                ishome: widget.isHome ?? false,
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.edit, color: AppTheme.primaryColor, size: deviceWidth(context) > 750 ? 35 :24,),
                      ),

                      GestureDetector(
                        child: Image.asset(
                          'lib/assets/TrashCan.png',
                          color: const Color(0xFF95020A),
                          height: deviceWidth(context) > 750 ? 35 :25,
                          width: deviceWidth(context) > 750 ? 35 :25,
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext dialogContext) {
                              bool isDeleting = false;

                              return StatefulBuilder(
                                builder: (context, setDialogState) {
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
                                            width: deviceWidth(context) > 750 ? 100 :60,
                                            height: deviceWidth(context) > 750 ? 100 :60,
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(
                                                0.1,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.delete,
                                              color: AppTheme.primaryColor,
                                              size: deviceWidth(context) > 750 ? 40 :30,
                                            ),
                                          ),

                                          const SizedBox(height: 16),

                                          Text(
                                            'Are you sure you want to delete "${schedule.medicationName}"?',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: deviceWidth(context) > 750 ? 20 :16,
                                              color: Colors.black87,
                                            ),
                                          ),

                                          const SizedBox(height: 24),

                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: isDeleting
                                                      ? null
                                                      : () => Navigator.pop(
                                                    dialogContext,
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    side: const BorderSide(
                                                      color:
                                                      AppTheme.primaryColor,
                                                    ),
                                                    padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                        8,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      color:
                                                      AppTheme.primaryColor,
                                                      fontSize: deviceWidth(context) > 750 ? 20 :16,
                                                      fontWeight:
                                                      FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(width: 12),

                                              Expanded(
                                                child: Consumer(
                                                  builder: (context, ref, _) {
                                                    return ElevatedButton(
                                                      onPressed: isDeleting
                                                          ? null
                                                          : () async {
                                                        setDialogState(
                                                              () =>
                                                          isDeleting =
                                                          true,
                                                        );

                                                        final success =
                                                        await MedicationService.deleteMedicationSchedule(
                                                          schedule
                                                              .scheduleUuid
                                                              .toString(),
                                                        );

                                                        if (success) {
                                                          _skipNextPopRefresh = true;
                                                          refreshMedicationHomeData(
                                                            ref,
                                                          );
                                                          Navigator.pop(
                                                            dialogContext,
                                                          );
                                                          _showMealDeletedSuccess(
                                                            context,
                                                            schedule
                                                                .medicationName,
                                                          );
                                                        } else {
                                                          setDialogState(
                                                                () =>
                                                            isDeleting =
                                                            false,
                                                          );
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                'Failed to delete Medication.',
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                        AppTheme
                                                            .primaryColor,
                                                        foregroundColor:
                                                        Colors.white,
                                                        padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 12,
                                                        ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                        ),
                                                      ),
                                                      child: isDeleting
                                                          ? const SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                        child:
                                                        CircularProgressIndicator(
                                                          strokeWidth:
                                                          2,
                                                          color: Colors
                                                              .white,
                                                        ),
                                                      )
                                                          : Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                          fontSize: deviceWidth(context) > 750 ? 20 :16,
                                                          fontWeight:
                                                          FontWeight
                                                              .w600,
                                                        ),
                                                      ),
                                                    );
                                                  },
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
                        },
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Text(
                      schedule.medicationBrand ?? '',
                      style: TextStyle(
                        fontSize:deviceWidth(context) > 750 ? 16 : 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(
                color: Colors.grey,
                thickness: 1,
                indent: 1,
                endIndent: 1,
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildScheduleItem(
                    "${schedule.isAfterMeal! ? 'After Meal' : 'Before Meal'}",
                  ),
                  _buildScheduleItem(
                    "${schedule.dayOfWeek[0].toUpperCase()}${schedule.dayOfWeek.substring(1).toLowerCase()}",
                  ),
                  _buildScheduleItem(schedule.scheduledTime),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Intake Status:',
                style: TextStyle(fontSize: deviceWidth(context) > 750 ? 20 : 14, color: Colors.black),
              ),

              const SizedBox(width: 10),

              Container(
                padding: const EdgeInsets.all(3),
                width: deviceWidth(context) > 750 ? 200 :150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    // ---------------- TAKEN ----------------
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, _) {
                          return GestureDetector(
                            onTap: () async {
                              if(schedule.isTaken!){
                                return;
                              }
                              // ❗ Block if time already passed
                              if (canAllowTime(schedule.scheduledTime)) {
                                String msg =
                                    "Cannot mark as taken. The scheduled time (${formatTo12Hour(schedule.scheduledTime)}).";
                                showErrorMessageDialog(context, msg);
                                _skipNextPopRefresh = true;
                                return;
                              }
                              setState(() => _isUpdatingIntake = true);
                              // 👉 Update UI first
                              setState(() {
                                toggleSelector = 0;
                                schedule.isTaken = true;
                              });

                              // 👉 API call
                              final tz =
                              await FlutterTimezone.getLocalTimezone();
                              bool success =
                              await MedicationService.trackMedicationIntake(
                                scheduleUuid: schedule.scheduleUuid ?? '',
                                date: schedule.date,
                                timeSlot: schedule.timeSlot,
                                isTaken: true,
                                timezone: tz.identifier,
                              );
                              if (success) {
                                _skipNextPopRefresh = true;
                                refreshMedicationHomeData(ref);
                                await _fetchIntakeStats();
                              }
                              setState(() => _isUpdatingIntake = false);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              decoration: BoxDecoration(
                                color: toggleSelector == 0
                                    ? Colors.green
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Taken",
                                style: TextStyle(
                                  color: toggleSelector == 0
                                      ? Colors.white
                                      : Colors.black54,
                                  fontWeight: FontWeight.w600,
                                  fontSize: deviceWidth(context) > 750 ? 15 :11,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // ---------------- NOT TAKEN ----------------
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, __) {
                          return GestureDetector(
                            onTap: () async {
                              if(!schedule.isTaken!){
                                return;
                              }
                              setState(() => _isUpdatingIntake = true);
                              // 👉 Update UI first
                              setState(() {
                                toggleSelector = 1;
                                schedule.isTaken = false;
                              });

                              // 👉 API call
                              final tz =
                              await FlutterTimezone.getLocalTimezone();
                              bool success =
                              await MedicationService.trackMedicationIntake(
                                scheduleUuid: schedule.scheduleUuid ?? '',
                                date: schedule.date,
                                timeSlot: schedule.timeSlot,
                                isTaken: false,
                                timezone: tz.identifier,
                              );

                              if (success) {
                                _skipNextPopRefresh = true;
                                refreshMedicationHomeData(ref);
                                await _fetchIntakeStats();
                              }
                              setState(() => _isUpdatingIntake = false);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              decoration: BoxDecoration(
                                color: toggleSelector == 1
                                    ? Colors.red
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Not Taken",
                                style: TextStyle(
                                  color: toggleSelector == 1
                                      ? Colors.white
                                      : Colors.black54,
                                  fontWeight: FontWeight.w600,
                                  fontSize: deviceWidth(context) > 750 ? 15 :11,
                                ),
                              ),
                            ),
                          );
                        },
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

  // New Intake status
  Widget intakeToggle(bool isTaken, Function(bool) onChange) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Intake Status:",
          style: TextStyle(fontSize: 14, color: Colors.black),
        ),

        const SizedBox(width: 8),

        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 300, // your minimum width
            maxWidth: double.infinity,
          ),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                // ----- TAKEN -----
                Expanded(
                  child: GestureDetector(
                    onTap: () => onChange(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isTaken ? Colors.green : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Taken",
                        style: TextStyle(
                          color: isTaken ? Colors.white : Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                // ----- NOT TAKEN -----
                Expanded(
                  child: GestureDetector(
                    onTap: () => onChange(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !isTaken ? Colors.green : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Not Taken",
                        style: TextStyle(
                          color: !isTaken ? Colors.white : Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to reduce code duplication
  Widget _buildScheduleItem(dynamic value, {String emptyText = "Not set"}) {
    String displayText = emptyText;

    if (value == null) {
      displayText = emptyText;
    }
    // Duration → convert to 12H
    else if (value is Duration) {
      displayText = formatTo12Hour(value);
    }
    // String handling
    else if (value is String) {
      final trimmed = value.trim();

      if (trimmed.isEmpty) {
        displayText = emptyText;
      } else {
        // 🔥 Match HH:mm:ss or HH:mm
        final regexFull = RegExp(r'^\d{1,2}:\d{2}:\d{2}$');
        final regexShort = RegExp(r'^\d{1,2}:\d{2}$');

        if (regexFull.hasMatch(trimmed) || regexShort.hasMatch(trimmed)) {
          // Parse using split
          final parts = trimmed.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);

          final duration = Duration(hours: hour, minutes: minute);

          displayText = formatTo12Hour(duration);
        } else {
          displayText = trimmed;
        }
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("•", style: TextStyle(fontSize: 20, color: Colors.grey)),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Text(
            displayText,
            style: TextStyle(
              fontSize: deviceWidth(context) > 750 ? 16 :14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailChip(String label, String image) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: deviceWidth(context) > 750 ? 18 :12)),
        SizedBox(width: deviceWidth(context) > 750 ? 8 :6),
        Container(
          padding: const EdgeInsets.all(2),
          // border thickness
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryColor, width: 1),
          ),
          child: Image.asset(image, width:deviceWidth(context) > 750 ? 35 : deviceWidth(context) > 750 ? 35 :24, height: 24, fit: BoxFit.cover),
        ),
      ],
    );
  }

  Widget _buildStatusButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyMedicationsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return const Center(child: Text('Failed to load medications.'));
    }

    if (_filteredMedications.isEmpty &&
        _searchController.text.isNotEmpty &&
        _showMedicationList == true) {
      return _searchMedicationNotFound();
    }

    if (_myMedications.isEmpty) {
      return const Center(child: Text('No medications found.'));
    }

    return ListView.builder(
      itemCount: _filteredMedications.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final med = _filteredMedications[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: _buildDetailedMyMedicationCard(context, med, index),
        );
      },
    );
  }

  Map<String, bool> expandedStates = {};
  Widget _buildDetailedMyMedicationCard(
      BuildContext context,
      MedicationModel med,
      index,
      ) {
    debugPrint("med. ${med.medicationBrand} ${med.startDate!}");
    final String key =
        med.scheduleUuid ?? med.medicationName ?? index.toString();
    final bool isExpanded = expandedStates[key] ?? false;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        // padding:  EdgeInsets.only(left: 10,right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: med.active! ? Colors.green.shade600 : Colors.transparent,
              width: deviceWidth(context) > 750 ? 6:3,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Medication Name & Brand
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${med.medicationName} (${med.doseDescription})',
                                style: TextStyle(
                                  fontSize: deviceWidth(context) > 750 ? 22 :14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    med.medicationBrand!,
                                    style: TextStyle(
                                      fontSize: deviceWidth(context) > 750 ? 18:12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  med.active!
                                      ? Container(
                                    padding: EdgeInsets.only(
                                      top: 2,
                                      left: 5,
                                      right: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(
                                        20,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Active",
                                        style: TextStyle(
                                          fontSize: deviceWidth(context) > 750 ? 18 :12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                      : Container(),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Icons
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                debugPrint("daysOfWeek ${med.daysOfWeek}");
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddMedicationPage(
                                      myMedicationEditMode: true,
                                      medicationData: med,
                                      ishome: widget.isHome ?? false,
                                    ),
                                  ),
                                );
                              },
                              child: Icon(
                                Icons.add_circle,
                                size: deviceWidth(context) > 750 ? 35 :20,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              child: Image.asset(
                                'lib/assets/TrashCan.png',
                                color: const Color(0xFF95020A),
                                height: deviceWidth(context) > 750 ? 35 :25,
                                width: deviceWidth(context) > 750 ? 35 :25,
                              ),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext dialogContext) {
                                    bool isDeleting = false;

                                    return StatefulBuilder(
                                      builder: (context, setDialogState) {
                                        return Dialog(
                                          backgroundColor: Colors.transparent,
                                          child: Container(
                                            padding: const EdgeInsets.all(24),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                              BorderRadius.circular(16),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: deviceWidth(context) > 750 ? 100 :60,
                                                  height: deviceWidth(context) > 750 ? 100 :60,
                                                  decoration: BoxDecoration(
                                                    color: Colors.red
                                                        .withOpacity(0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.delete,
                                                    color:
                                                    AppTheme.primaryColor,
                                                    size:deviceWidth(context) > 750 ? 60 : 30,
                                                  ),
                                                ),

                                                SizedBox(height: deviceWidth(context) > 750 ? 20 :16),

                                                Text(
                                                  'Delete Medication?',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: deviceWidth(context) > 750 ? 25 :18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),

                                                SizedBox(height: deviceWidth(context) > 750 ? 12 :6),

                                                Text(
                                                  'Are you sure you want to delete ${med.medicationName}?',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: deviceWidth(context) > 750 ? 24 :16,
                                                    color: Colors.black87,
                                                  ),
                                                ),

                                                const SizedBox(height: 8),

                                                Text(
                                                  'Note: This action removes the medication from both My Medication List and Today\'s Medication. You can add it again using Browse Medication.',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: deviceWidth(context) > 750 ? 20 :14,
                                                    color: Colors.black38,
                                                  ),
                                                ),

                                                const SizedBox(height: 24),

                                                Row(
                                                  children: [
                                                    /// ❌ CANCEL
                                                    Expanded(
                                                      child: OutlinedButton(
                                                        onPressed: isDeleting
                                                            ? null
                                                            : () => Navigator.pop(
                                                          dialogContext,
                                                        ),
                                                        style: OutlinedButton.styleFrom(
                                                          side: const BorderSide(
                                                            color: AppTheme
                                                                .primaryColor,
                                                          ),
                                                          padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 12,
                                                          ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'Cancel',
                                                          style: TextStyle(
                                                            color: AppTheme
                                                                .primaryColor,
                                                            fontSize: deviceWidth(context) > 750 ? 20 :16,
                                                            fontWeight:
                                                            FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ),

                                                    const SizedBox(width: 12),

                                                    /// 🔥 DELETE WITH LOADER
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        onPressed: isDeleting
                                                            ? null
                                                            : () async {
                                                          setDialogState(
                                                                () =>
                                                            isDeleting =
                                                            true,
                                                          );

                                                          final success =
                                                          await MedicationService.deleteMedicationMenuItem(
                                                            menuUuid:
                                                            med.scheduleUuid!,
                                                          );

                                                          if (success) {
                                                            _skipNextPopRefresh = true;
                                                            Navigator.pop(
                                                              dialogContext,
                                                            );

                                                            setState(() {
                                                              _myMedications.removeWhere(
                                                                    (item) =>
                                                                item.scheduleUuid ==
                                                                    med.scheduleUuid,
                                                              );

                                                              _filteredMedications.removeWhere(
                                                                    (item) =>
                                                                item.scheduleUuid ==
                                                                    med.scheduleUuid,
                                                              );
                                                            });

                                                            _showMealDeletedSuccess(
                                                              context,
                                                              med.medicationName!,
                                                            );
                                                          } else {
                                                            setDialogState(
                                                                  () => isDeleting =
                                                              false,
                                                            );
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  'Failed to delete medication.',
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                          AppTheme
                                                              .primaryColor,
                                                          foregroundColor:
                                                          Colors.white,
                                                          padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 12,
                                                          ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                          ),
                                                        ),
                                                        child: isDeleting
                                                            ? SizedBox(
                                                          height: deviceWidth(context) > 750 ? 25 :20,
                                                          width: deviceWidth(context) > 750 ? 25 :20,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth:
                                                            2,
                                                            color: Colors
                                                                .white,
                                                          ),
                                                        )
                                                            : Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                            fontSize: deviceWidth(context) > 750 ? 20 :16,
                                                            fontWeight:
                                                            FontWeight
                                                                .w600,
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
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    Divider(
                      color: Colors.grey,
                      thickness: 1,
                      indent: 1,
                      endIndent: 1,
                    ),

                    // Details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      spacing: 8,
                      children: [
                        // _buildDetailChip(med.isAfterMeal ? 'After Meal' : 'Before Meal'),
                        // _buildDetailChip(med.daysOfWeek.join(', ')),
                        // if (med.morningTime != null)
                        //   _buildDetailChip(med.morningTime!),
                        // if (med.eveningTime != null)
                        //   _buildDetailChip(med.eveningTime!),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              expandedStates[key] = !isExpanded;
                            });
                          },
                          child: Row(
                            children: [
                              Container(
                                height: deviceWidth(context) > 750 ? 30 :20,
                                width: deviceWidth(context) > 750 ? 30 :20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  color: AppTheme.primaryColor,
                                ),
                                child: Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white,
                                  size: deviceWidth(context) > 750 ? 30 : 20,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isExpanded ? 'Less Info' : 'More Info',
                                style: TextStyle(
                                  fontSize: deviceWidth(context) > 750 ? 20 : 14,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              "•",
                              style: TextStyle(
                                fontSize: deviceWidth(context) > 750 ? 30 :20,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              med.isAfterMeal! ? 'After Meal' : 'Before Meal',
                              style: TextStyle(
                                fontSize: deviceWidth(context) > 750 ? 20 :14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Status Section (dummy for now)
                    isExpanded
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(width: 10),
                            if (med.morningTime != null)
                              _buildDetailChip(
                                formatTo12Hour(med.morningTime),
                                "lib/assets/Group 1361498938 (2).png",
                              ),

                            if (med.morningTime != null &&
                                (med.afternoonTime != null ||
                                    med.eveningTime != null))
                              const SizedBox(width: 15),

                            if (med.afternoonTime != null)
                              _buildDetailChip(
                                formatTo12Hour(med.afternoonTime),
                                "lib/assets/Group 1361498935 (2).png",
                              ),

                            if (med.afternoonTime != null &&
                                med.eveningTime != null)
                              const SizedBox(width: 15),

                            if (med.eveningTime != null)
                              _buildDetailChip(
                                formatTo12Hour(med.eveningTime),
                                "lib/assets/Group 1361498936 (1).png",
                              ),
                          ],
                        ),
                        SizedBox(height: 10),

                        Row(
                          children: [
                            SizedBox(width: 10),
                            Text(
                              "${med.dosageFrequency} - ${med.daysOfWeek!.join(", ")}",
                              style: TextStyle(fontSize: deviceWidth(context) > 750 ? 20 :14),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_month_sharp,
                                  color: AppTheme.primaryColor,
                                  size: deviceWidth(context) > 750 ? 35 :24,
                                ),
                                SizedBox(width: 2),
                                Text(DateFormatUtil.formatOfMonthDateYearDisplay(med.startDate!),style: TextStyle(fontSize: deviceWidth(context) > 750 ? 20 :14),),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_month_sharp,
                                  color: AppTheme.primaryColor,
                                  size: deviceWidth(context) > 750 ? 35 :24,
                                ),
                                SizedBox(width: 2),
                                Text(DateFormatUtil.formatOfMonthDateYearDisplay(med.endDate!),style: TextStyle(fontSize: deviceWidth(context) > 750 ? 20 :14),),
                              ],
                            ),
                          ],
                        ),
                      ],
                    )
                        : Container(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildBrowseMedicationCard(Map<String, dynamic> medication) {
    return InkWell(
      onTap: (){
        MedicationModel medModel = MedicationModel.fromPartialJson({
          "scheduleUuid": medication['uuid'],
          "medicationName": medication['name'],
          "medicationBrand": medication['brand'],
          "doseDescription": medication['strength'],
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddMedicationPage(
              medicationData: medModel,
              medPeriod: _selectedTabIndex,
              ishome: widget.isHome ?? false,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 2),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medication['name'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: deviceWidth(context) > 750 ? 24:16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(medication['strength'] ?? '',style: TextStyle(fontSize: deviceWidth(context) > 750 ? 20 : 14),),
                      const SizedBox(width: 8),
                      Text(medication['brand'] ?? '', style: TextStyle(fontSize: deviceWidth(context) > 750 ? 20 : 14),),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle, color: AppTheme.primaryColor, size: deviceWidth(context) > 750 ? 30 : 24,),
              onPressed: () {
                MedicationModel medModel = MedicationModel.fromPartialJson({
                  "scheduleUuid": medication['uuid'],
                  "medicationName": medication['name'],
                  "medicationBrand": medication['brand'],
                  "doseDescription": medication['strength'],
                });

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddMedicationPage(
                      medicationData: medModel,
                      medPeriod: _selectedTabIndex,
                      ishome: widget.isHome ?? false,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    // Show medication list and custom content for all tabs when filter is active
    if (_showCustomContent) {
      return _buildCustomContent();
    }
    if (_showMedicationList) {
      return _buildMyMedicationsList();
    }

    if (_showBrowseSearchBox) {
      debugPrint(
        "_showBrowseSearchBox $_showBrowseSearchBox  Med ${_browseResults.length}",
      );
      if (_browseResults.length == 0 && !_isBrowseLoading) {
        return _searchMedicationNotFound();
      }

      return ListView.builder(
        controller: _browseScrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: _browseResults.length + (_hasMoreBrowseData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _browseResults.length) {
            final medication = _browseResults[index];

            return _buildBrowseMedicationCard(medication);
          }

          // Bottom loader
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        },
      );
    }

    // Show default content based on selected tab
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedTabIndex) {
      case 0: // All
        return _buildMyMedicationScheduleList();

      case 1: // Morning
        return _medications?.data?.allSchedules?.isNotEmpty ?? false
            ? _buildMyMedicationScheduleList()
            : _buildEmptyTab(
          'Sunrise.png',
          HeartThriveStrings.noMedicationMorningMSG,
          Colors.orange,
        );

      case 2: // Afternoon
        return _medications?.data?.allSchedules?.isNotEmpty ?? false
            ? _buildMyMedicationScheduleList()
            : _buildEmptyTab(
          'afternoon 1.png',
          HeartThriveStrings.noMedicationAfterNoonMSG,
          Colors.blue,
        );

      case 3: // Evening
        return _medications?.data?.allSchedules?.isNotEmpty ?? false
            ? _buildMyMedicationScheduleList()
            : _buildEmptyTab(
          'Sunset.png',
          HeartThriveStrings.noMedicationEveningMSG,
          Colors.purple,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEmptyTab(String asset, String message, Color iconColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        //crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            message,
            style: AppTheme.title16.copyWith(fontWeight: FontWeight.normal),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Image.asset(
            'lib/assets/$asset',
            width: 200,
            height: 200,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.medical_services, size: 60, color: iconColor),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationList() {
    // Static medication data matching the reference screen
    final List<Map<String, String>> medications = [
      {
        'name': 'Metoprolol tartrate',
        'dosage': '50 mg',
        'brand': 'Brand: Lopressor',
      },
      {
        'name': 'Metoprolol Succinate',
        'dosage': '50 mg',
        'brand': 'Brand: Toprol',
      },
      {
        'name': 'Metoprolol tartrate',
        'dosage': '50 mg',
        'brand': 'Brand: Coreg',
      },
      {
        'name': 'Metoprolol tartrate',
        'dosage': '50 mg',
        'brand': 'Brand: Digitek',
      },
      {
        'name': 'Metoprolol tartrate',
        'dosage': '50 mg',
        'brand': 'Brand: Digitek',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: medications.length,
      itemBuilder: (context, index) {
        final medication = medications[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication['name']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          medication['dosage']!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          medication['brand']!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>  AddMedicationPage(ishome: widget.isHome ?? false),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            HeartThriveStrings.noMedicationFoundMSG,
            style: AppTheme.title16.copyWith(fontWeight: FontWeight.normal),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddMedicationPage(customMode: true, ishome: widget.isHome ?? false),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Create Custom Item +',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
          Image.asset("lib/assets/no_search_med_found.png", height: 160),
        ],
      ),
    );
  }

  Widget _searchMedicationNotFound() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              HeartThriveStrings.noMedicationFoundMSG,
              style: deviceWidth(context) > 750 ?AppTheme.title20.copyWith(fontWeight: FontWeight.normal) :AppTheme.title16.copyWith(fontWeight: FontWeight.normal),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddMedicationPage(customMode: true, ishome: widget.isHome ?? false,),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:  Text(
                'Create Custom Item +',
                style: TextStyle(fontSize: deviceWidth(context) > 750 ? 20 :16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            Image.asset("lib/assets/no_search_med_found.png", height:deviceWidth(context) > 750 ? 180 : 160),
          ],
        ),
      ),
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
                  width: deviceWidth(context) > 750 ? 160 : 80,
                  height: deviceWidth(context) > 750 ? 160 :80,
                  child: Image.asset('lib/assets/Check Mark.png'),
                ),
                const SizedBox(height: 16),
                Text(
                  '"$mealName" deleted successfully!',
                  textAlign: TextAlign.center,
                  style:  TextStyle(
                    fontSize: deviceWidth(context) > 750 ? 25 : 16,
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
                      _fetchIntakeStats();
                      _fetchMyMedications();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text('OK', style: deviceWidth(context) > 750 ? AppTheme.whiteTitle23:AppTheme.whiteTitle14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool canAllowTimeOld(String? scheduledTime24h) {
    debugPrint("scheduledTime24h @@ $scheduledTime24h");
    if (scheduledTime24h == null || scheduledTime24h.isEmpty)
      return true; // or false, depends on your fallback

    try {
      final now = DateTime.now();
      final parts = scheduledTime24h.split(':');
      if (parts.length < 2) return true;

      final hour = int.parse(parts[0]);
      final minute = int.parse(
        parts[1].split(' ').first,
      ); // in case of seconds like "10:53:00"

      // Create scheduled time for TODAY
      DateTime scheduled = DateTime(now.year, now.month, now.day, hour, minute);

      // If scheduled time is in the future → BLOCK marking as "Taken"
      // If scheduled time is now or in the past → ALLOW
      bool isFuture = scheduled.isAfter(now);

      debugPrint("Scheduled: $scheduled");
      debugPrint("Now: $now");
      debugPrint("Is future? $isFuture → Block = $isFuture");

      return isFuture; // Return TRUE → means "block"
    } catch (e) {
      debugPrint("Error parsing time: $e");
      return true; // or false — decide fallback
    }
  }

  bool canAllowTime(String? scheduledTime24h) {
    debugPrint("scheduledTime24h @@ $scheduledTime24h");
    if (scheduledTime24h == null || scheduledTime24h.isEmpty)
      return true; // or false, depends on your fallback

    try {
      final now = DateTime.now();
      final parts = scheduledTime24h.split(':');
      if (parts.length < 2) return true;

      final hour = int.parse(parts[0]);
      final minute = int.parse(
        parts[1].split(' ').first,
      ); // in case of seconds like "10:53:00"

      // Create scheduled time for TODAY
      DateTime scheduled = DateTime(now.year, now.month, now.day, hour, minute);

      // If scheduled time is in the future → BLOCK marking as "Taken"
      // If scheduled time is now or in the past → ALLOW
      debugPrint("Before 1 hours @@@ ${scheduled.subtract(Duration(hours: 1))}");
      bool isFuture = scheduled.subtract(Duration(hours: 1)).isAfter(now);

      debugPrint("Scheduled: $scheduled");
      debugPrint("Now: $now");
      debugPrint("Is future? $isFuture → Block = $isFuture");

      return isFuture; // Return TRUE → means "block"
    } catch (e) {
      debugPrint("Error parsing time: $e");
      return true; // or false — decide fallback
    }
  }

}
