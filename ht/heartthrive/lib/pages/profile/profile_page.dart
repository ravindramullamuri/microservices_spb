import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import 'package:heart_thrive/pages/landing_page.dart';
import 'package:heart_thrive/utils/fcm_util.dart';
import 'package:heart_thrive/utils/secure_storage_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../components/connection_unavailable.dart';
import '../../components/editable_bottomsheet_card.dart';
import '../../components/profile_image_uploader.dart';
import '../../constants/heart_thrive_strings_constants.dart';
import '../../main.dart';
import '../../providers/bmi/notification_provider.dart';
import '../../providers/internet_provider.dart';
import '../../providers/token_provider.dart';
import '../../providers/user/user_details_provider.dart';
import '../../routes/app_router.dart';
import '../../services/patient_profile_service.dart';
import '../../theme/app_theme.dart';
import '../edit_profile_page.dart';
import '../notification_badgeicon_widget.dart';

class ProfilePage extends ConsumerStatefulWidget {
  final String? navFromPage;
  const ProfilePage({super.key,this.navFromPage});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String _errorMessage = '';
  int _selectedIndex = 4;

  @override
  void initState() {
    super.initState();
    // IMPORTANT: Load notifications before badge icon renders
    //BackButtonInterceptor.add(_onBackPressed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).loadFirstPage();
    });
    _loadProfileData();
  }

  bool _onBackPressed(bool stopDefaultButtonEvent, RouteInfo info) {
    debugPrint('Global back intercepted on Profile');
    AppRouter.replaceWithHome(context);
    return true; // 🔥 stops Navigator.pop
  }

  @override
  void dispose() {
    //BackButtonInterceptor.remove(_onBackPressed);
    super.dispose();
  }

  Future<void> _refresh() async {
    // turn on loader BEFORE refresh indicator completes
    setState(() {
      _isLoading = true;
    });

    // await your async calls
    await ref.read(notificationProvider.notifier).loadFirstPage();
    await _loadProfileData();

    // turn off loader
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final profileData = await PatientProfileService.fetchPatientProfile();
      if (mounted) {
        setState(() {
          _profileData = profileData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _getProfileValue(String key, String defaultValue) {
    if (_profileData == null) return defaultValue;
    return _profileData![key]?.toString() ?? defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    final userDetailsAsync = ref.watch(userDetailsDataProvider);
    final user = userDetailsAsync.asData?.value;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24), // 👈 Adjust the roundness
          ),
        ),
        leading: GestureDetector(
          onTap: () {
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
        title: const Center(
          child: Text(
            'Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: NotificationBadgeIcon(),
          ),
        ],
      ),
      body: Stack(
        children: [
          userDetailsAsync.when(
            data: (user) {
              if (user == null) {
                final isOnline = ref.watch(isOnlineProvider);

                return !isOnline
                    ? ConnectionUnavailable(
                        title: HeartThriveStrings.offlineTitle,
                        description: HeartThriveStrings.offlineMessage,
                        buttonText: "Retry",
                        onRetry: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MyApp(initialToken: ref.watch(tokenProvider)),
                            ),
                          );
                        },
                      )
                    : ConnectionUnavailable(
                        title: HeartThriveStrings.userServerIssueTitle,
                        description:
                            HeartThriveStrings.userServerIssueDescription,
                        buttonText: "Retry",
                        onRetry: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MyApp(initialToken: ref.watch(tokenProvider)),
                            ),
                          );
                        },
                      );
              }
              return RefreshIndicator(
                onRefresh: () => _refresh(),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // Profile Section
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            // Profile Image
                            GestureDetector(
                              onTap: () async {
                                if (Platform.isIOS) {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: true,
                                    builder: (context) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          height: deviceWidth(context) > 750
                                              ? 400
                                              : 300,
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: ProfileImageUploader(
                                                  userId: user.id,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                } else {
                                  /* bool allowed = await _checkPhotoPermission();  // <-- permission check
                                    if (!allowed) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Permission required to access photos")),
                                      );
                                      return;
                                    }*/

                                  showDialog(
                                    context: context,
                                    barrierDismissible: true,
                                    builder: (context) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          height: deviceWidth(context) > 750
                                              ? 400
                                              : 300,
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: ProfileImageUploader(
                                                  userId: user.id,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }
                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Profile Circle
                                  Container(
                                    width: deviceWidth(context) > 750
                                        ? 200
                                        : 100,
                                    height: deviceWidth(context) > 750
                                        ? 200
                                        : 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.primaryColor.withValues(
                                          alpha: 0.4,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: user.profileImage == null
                                          ? Image.asset(
                                              'lib/assets/default_profile_image_rounded.png',
                                              fit: BoxFit.cover,
                                              width: deviceWidth(context) > 750
                                                  ? 200
                                                  : 100,
                                              height: deviceWidth(context) > 750
                                                  ? 200
                                                  : 100,
                                            )
                                          : Image.memory(
                                              base64Decode(user.profileImage!),
                                              gaplessPlayback: true,
                                              width: deviceWidth(context) > 750
                                                  ? 200
                                                  : 100,
                                              height: deviceWidth(context) > 750
                                                  ? 200
                                                  : 100,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Icon(
                                                    Icons.account_circle,
                                                    size:
                                                        deviceWidth(context) >
                                                            750
                                                        ? 120
                                                        : 80,
                                                  ),
                                            ),
                                    ),
                                  ),

                                  // Edit Icon at bottom-right
                                  /*Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child:  Image.asset(
                                         "lib/assets/Edit_Profile.png"
                                        ),
                                      ),
                                    )*/
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: deviceWidth(context) > 750
                                          ? 55
                                          : 32,
                                      height: deviceWidth(context) > 750
                                          ? 55
                                          : 32,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: deviceWidth(context) > 750
                                            ? 35
                                            : 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16), // Name
                            Text(
                              '${user.firstname} ${user.lastname}',
                              style: deviceWidth(context) > 750
                                  ? AppTheme.title30
                                  : AppTheme.title20,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),

                            const SizedBox(height: 4),

                            // Email
                            Text(
                              user.email!,
                              style: TextStyle(
                                fontSize: deviceWidth(context) > 750 ? 20 : 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Stats Cards
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  buildStatCard(
                                    'Weight',
                                    _getProfileValue(
                                      'weight',
                                      user.weight ?? "0",
                                    ),
                                    'lib/assets/Scale.png',
                                    Colors.white,
                                    context,
                                    user,
                                  ),
                                  // Right-side shorter border line
                                  Positioned(
                                    top: 30,
                                    right: 0,
                                    child: Container(
                                      width: deviceWidth(context) > 750 ? 2 : 1,
                                      // thickness of the line
                                      height: deviceWidth(context) > 750
                                          ? 120
                                          : 80,
                                      // adjust height here
                                      color: Colors.grey, // border color
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: deviceWidth(context) > 750 ? 20 : 0,
                            ),
                            Expanded(
                              child: Stack(
                                children: [
                                  buildStatCard(
                                    'Height',
                                    _getProfileValue(
                                      'height',
                                      user.height ?? "0",
                                    ),
                                    'lib/assets/sewing_tape_measure.png',
                                    Colors.white,
                                    context,
                                    user,
                                  ),
                                  Positioned(
                                    top: 30,
                                    right: 0,
                                    child: Container(
                                      width: deviceWidth(context) > 750 ? 2 : 1,
                                      // thickness of the line
                                      height: deviceWidth(context) > 750
                                          ? 120
                                          : 80,
                                      // adjust height here
                                      color: Colors.grey, // border color
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: buildStatCard2(
                                'BMI',
                                _getProfileValue('bmi', '${user.bmi ?? 0}'),
                                'lib/assets/Heartbeat2.png',
                                Colors.white,
                                context,
                                user,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Menu Items
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            _buildMenuItem(
                              'Edit Profile',
                              'lib/assets/ht2.png',
                              AppTheme.primaryColor,
                              () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditProfilePage(userDetails: user),
                                  ),
                                );
                                // Refresh profile data if edit was successful
                                if (result == true) {
                                  _loadProfileData();
                                }
                              },
                            ),
                            _buildMenuItem(
                              'My Clinician',
                              'lib/assets/ht4.png',
                              Colors.blue,
                              () {
                                AppRouter.navigateTomyDoctor(context);
                              },
                            ),
                            _buildMenuItem(
                              'Manage Clinician Connection',
                              'lib/assets/ht5.png',
                              Colors.green,
                              () {
                                AppRouter.navigateToManageDoctor(context);
                              },
                            ),
                            _buildMenuItem(
                              'FAQ',
                              'lib/assets/ht6.png',
                              Colors.orange,
                              () {
                                AppRouter.navigateToPatientFAQ(context);
                              },
                            ),
                            _buildMenuItem(
                              'Contact Us',
                              'lib/assets/ht7.png',
                              Colors.purple,
                              () {
                                AppRouter.navigateToPatientContactUs(context);
                              },
                            ),
                            _buildMenuItem(
                              'Privacy Policy',
                              'lib/assets/ht8.png',
                              Colors.teal,
                              () {
                                AppRouter.navigateToPatientPrivacyPolicy(
                                  context,
                                );
                              },
                            ),
                            _buildMenuItem(
                              'Terms & Conditions',
                              'lib/assets/ht9.png',
                              Colors.indigo,
                              () {
                                AppRouter.navigateToPatientTermsConditions(
                                  context,
                                );
                              },
                            ),
                            _buildMenuItem(
                              'Logout',
                              'lib/assets/ht10.png',
                              Colors.red,
                              () => _showLogoutDialog(context),
                              isLast: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
            error: (e, st) {
              final isOnline = ref.watch(isOnlineProvider);

              return !isOnline
                  ? ConnectionUnavailable(
                      title: HeartThriveStrings.offlineTitle,
                      description: HeartThriveStrings.offlineMessage,
                      buttonText: "Retry",
                      onRetry: () async{
                        final token = await SecureStorageUtils().read(StorageKeys.accessToken);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MyApp(initialToken: token),
                          ),
                        );
                      },
                    )
                  : ConnectionUnavailable(
                      title: HeartThriveStrings.userServerIssueTitle,
                      description:
                          HeartThriveStrings.userServerIssueDescription,
                      buttonText: "Retry",
                      onRetry: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MyApp(initialToken: ref.watch(tokenProvider)),
                          ),
                        );
                      },
                    );
            }, // SHOW OLD UI EVEN IN LOADING
            loading: () => ProfileLoadingPlaceholder(),
          ),

          // ----------------------
          // GLOBAL BLUR LOADING OVERLAY
          // ----------------------
          if (userDetailsAsync.isLoading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                child: Container(
                  color: Colors.white.withValues(alpha: 0.35),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Widget _buildStatCard(String title, String value, IconData icon, Color color) {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.05),
  //           blurRadius: 10,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       children: [
  //         Container(
  //           padding: const EdgeInsets.all(8),
  //           decoration: BoxDecoration(
  //             color: color.withOpacity(0.1),
  //             shape: BoxShape.circle,
  //           ),
  //           child: Icon(
  //             icon,
  //             color: color,
  //             size: 20,
  //           ),
  //         ),
  //         const SizedBox(height: 8),
  //         Text(
  //           title,
  //           style: const TextStyle(
  //             fontSize: 12,
  //             color: Colors.black54,
  //           ),
  //         ),
  //         const SizedBox(height: 4),
  //         Text(
  //           value,
  //           style: const TextStyle(
  //             fontSize: 16,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.black87,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        _showEditBottomSheet(context, title, value);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBottomSheet(
    BuildContext context,
    String field,
    String currentValue,
  ) {
    final TextEditingController controller = TextEditingController(
      text: currentValue,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        height: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              "Edit $field",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                hintText: "Enter $field",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // ✅ Save new value (you can call API or update state here)
                  debugPrint("Updated $field: ${controller.text}");
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    String title,
    String image,
    Color iconColor,
    VoidCallback onTap, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  image,
                  height: deviceWidth(context) > 750 ? 60 : 60,
                  width: deviceWidth(context) > 750 ? 70 : 50,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: deviceWidth(context) > 750 ? 25 : 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.primaryColor,
                size: deviceWidth(context) > 750 ? 25 : 16,
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: AppTheme.primaryColor,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Are you sure you want to log out of your account ?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
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
                    Expanded(
                      child: ElevatedButton(
                        /* onPressed: () async {
                          final user = ref.read(userDetailsDataProvider).value;

                          // Capture the notifiers BEFORE disposing the widget
                          final tokenNotifier = ref.read(tokenProvider.notifier);
                          // No need to capture invalidate, we can call it safely later via container if needed

                          Navigator.pop(context);
                          AppRouter.navigateToLanding(context);

                          Future.microtask(() async {
                            try {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.remove("heartThriveFCMToken");
                              await prefs.remove("auth_token");
                              final fcmToken = await SecureStorageUtils().read("fcm_token");
                              if (fcmToken != null && user != null) {
                                await FcmHelper.removeDeviceTokenByUser(user, fcmToken);
                              }
                              await SecureStorageUtils().delete("auth_token");
                              await SecureStorageUtils().delete("fcm_token");
                              tokenNotifier.clear();


                              // Now safe – we didn't use the disposed ref



                              // If you really need to invalidate, do it via the global container:
                              // ProviderScope.containerOf(context, listen: false).invalidate(tokenFutureProvider);
                              // But better to move this logic into a proper service as in Solution 1
                            } catch (e) {
                              debugPrint("Logout cleanup error: $e");
                            }
                          });
                        },*/
                        onPressed: () async {
                          final user = ref.read(userDetailsDataProvider).value;
                          final tokenNotifier = ref.read(
                            tokenProvider.notifier,
                          );

                          try {
                            // 1️⃣ CLEAR LOCAL STATE FIRST (CRITICAL)
                            tokenNotifier.clear();

                            // 2️⃣ CLEAR STORAGE (AWAIT EVERYTHING)

                            final prefs = await SharedPreferences.getInstance();
                            final fcmToken = prefs.getString(
                              "heartThriveFCMToken",
                            );
                            await prefs.remove("heartThriveFCMToken");
                            await prefs.remove("auth_token");
                            await prefs.remove(StorageKeys.refreshToken);

                            final secureStorage = SecureStorageUtils();
                            //final fcmToken = await secureStorage.read("fcm_token");
                            final authToken = await secureStorage.read(
                             StorageKeys.accessToken,
                            );
                            if (fcmToken != null && user != null) {
                              unawaited(
                                FcmHelper.removeDeviceTokenByUser(
                                  user,
                                  fcmToken,
                                  authToken,
                                ),
                              );
                            }
                            await secureStorage.delete(StorageKeys.accessToken,);
                            await secureStorage.delete("fcm_token");
                            await secureStorage.delete(StorageKeys.refreshToken);
                          } catch (e) {
                            debugPrint("Logout cleanup error: $e");
                          }

                          // 4️⃣ NAVIGATE LAST (AFTER CLEANUP)
                          if (context.mounted) {
                            //Navigator.of(context).popUntil((r) => r.isFirst);
                           // AppRouter.navigateToLandingClear(context);
                           // AppRouter.navigateToSignIn(context);
                            Navigator.pushAndRemoveUntil(
                                context, MaterialPageRoute(builder: (context)=>LandingPage()), (_)=>false);
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
                        child: const Text(
                          'Log Out',
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
  }
}

class ProfileLoadingPlaceholder extends StatelessWidget {
  const ProfileLoadingPlaceholder({super.key});

  // Mock stat card (same as your buildStatCard but static)
  Widget _buildMockStatCard(String title, String value, String iconPath) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(iconPath, height: 32, width: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // Mock menu item (same look as _buildMenuItem)
  Widget _buildMockMenuItem(
    String title,
    String iconPath,
    Color color, {
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Image.asset(iconPath, width: 28, height: 28, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        enabled: false, // makes it look disabled / static
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {}, // no-op for loading state
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // ==================== Profile Section ====================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Profile Image (static shimmer or placeholder)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.4),
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      // Edit icon
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue,
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Name (shimmer style)
                  Container(width: 180, height: 24, color: Colors.grey[300]),
                  const SizedBox(height: 8),

                  // Email (shimmer)
                  Container(width: 220, height: 18, color: Colors.grey[300]),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ==================== Stats Cards ====================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        _buildMockStatCard(
                          'Weight',
                          '-- kg',
                          'lib/assets/Scale.png',
                        ),
                        Positioned(
                          top: 30,
                          right: 0,
                          child: Container(
                            width: 1,
                            height: 80,
                            color: Colors.grey[300],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        _buildMockStatCard(
                          'Height',
                          '-- cm',
                          'lib/assets/height.png',
                        ),
                        Positioned(
                          top: 30,
                          right: 0,
                          child: Container(
                            width: 1,
                            height: 80,
                            color: Colors.grey[300],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildMockStatCard(
                      'BMI',
                      '--',
                      'lib/assets/Heartbeat2.png',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ==================== Menu Items ====================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildMockMenuItem(
                    'Edit Profile',
                    'lib/assets/ht2.png',
                    Colors.blue,
                  ),
                  _buildMockMenuItem(
                    'My Clinician',
                    'lib/assets/ht4.png',
                    Colors.blue,
                  ),
                  _buildMockMenuItem(
                    'Manage Clinician Connection',
                    'lib/assets/ht5.png',
                    Colors.green,
                  ),
                  _buildMockMenuItem(
                    'FAQ',
                    'lib/assets/ht6.png',
                    Colors.orange,
                  ),
                  _buildMockMenuItem(
                    'Contact us',
                    'lib/assets/ht7.png',
                    Colors.purple,
                  ),
                  _buildMockMenuItem(
                    'Privacy Policy',
                    'lib/assets/ht8.png',
                    Colors.teal,
                  ),
                  _buildMockMenuItem(
                    'Terms & Conditions',
                    'lib/assets/ht9.png',
                    Colors.indigo,
                  ),
                  _buildMockMenuItem(
                    'Logout',
                    'lib/assets/ht10.png',
                    Colors.red,
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
