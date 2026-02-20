import 'package:flutter/material.dart';
import 'package:heart_thrive/models/meal/edit_meal_model.dart';
import 'package:heart_thrive/pages/meal-sodium/user_today_food.dart'; // Import pages
import '../pages/landing_page.dart';
import '../pages/medication/medication_stats_dashboard_summary.dart';
import '../pages/my_doctor.dart';
import '../pages/notification/patient_notification_page.dart';
import '../pages/recipes/recipe_page.dart';
import '../pages/auth/sign_in_page.dart';
import '../pages/forgot_password_page.dart';
import '../pages/register_page.dart';
import '../pages/meal-sodium/sodium_dashboard/sodium_intake_overview_page.dart';
import '../pages/symptoms/add_symptom_page.dart';
import '../pages/verification_page.dart';
import '../pages/create_new_password_page.dart';
import '../pages/home_mask_page.dart';
import '../pages/home_page.dart';
import '../pages/riskmeter/heart_risk_dashboard_page.dart';
import '../pages/meal/add_meal_page.dart';
import '../pages/medication/all_medication_page.dart';
import '../pages/weight_bmi/add_body_mass_index_page.dart';
import '../pages/weight_bmi/weight_trend_dashboard_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/education_page.dart';
import '../pages/auth/personal_info_page.dart';
import '../pages/register_as_doctor_page.dart';
import '../pages/doctor_home_page.dart';
import '../pages/patients_list_page.dart';
import '../pages/patient_details_page.dart';
import '../pages/patient_details_risk_metric_dashboard.dart';
import '../pages/patient_details_sodium_dashboard.dart';
import '../pages/patient_details_medication_dashboard.dart';
import '../pages/patient_details_bmi_dashboard.dart';
import '../pages/doctor_education_page.dart';
import '../pages/doctor_recipe_page.dart';
import '../pages/doctor_profile_page.dart';
import '../pages/my_patients_page.dart';
import '../pages/faq_page.dart';
import '../pages/contact_us_page.dart';
import '../pages/privacy_policy_page.dart';
import '../pages/terms_conditions_page.dart';
import '../pages/manage_doctor_page.dart';
import '../pages/patient_faq_page.dart';
import '../pages/patient_contact_us_page.dart';
import '../pages/patient_privacy_policy_page.dart';
import '../pages/patient_terms_conditions_page.dart';

class AppRouter {
  // Route names
  static const String landing = '/';
  static const String signIn = '/sign-in';
  static const String forgotPassword = '/forgot-password';
  static const String register = '/register';
  static const String verification = '/verification';
  static const String createNewPassword = '/create-new-password';
  static const String homeMask = '/home-mask';
  static const String home = '/home';
  static const String doctorHome = '/doctor-home';
  static const String heartRiskDashboard = '/heart-risk-dashboard';
  static const String allMealIntake = '/all-meal-intake';
  static const String addMeal = '/add-meal';
  static const String sodiumIntakeOverview = '/sodium-intake-overview';
  static const String allMedication = '/all-medication';
  static const String medicationDashboard = '/medication-dashboard';
  static const String addBodyMassIndex = '/add-body-mass-index';
  static const String weightTrendDashboard = '/weight-trend-dashboard';
  static const String profile = '/profile';
  static const String education = '/education';
  static const String recipe = '/recipe';
  static const String personalInfo = '/personal-info';
  static const String registerAsDoctor = '/register-as-doctor';
  static const String patientsList = '/patients-list';
  static const String patientDetails = '/patient-details';
  static const String patientDetailsRiskMetricDashboard = '/patient-details-risk-metric-dashboard';
  static const String patientDetailsSodiumDashboard = '/patient-details-sodium-dashboard';
  static const String patientDetailsMedicationDashboard = '/patient-details-medication-dashboard';
  static const String patientDetailsBMIDashboard = '/patient-details-bmi-dashboard';
  static const String doctorEducation = '/doctor-education';
  static const String doctorRecipe = '/doctor-recipe';
  static const String doctorProfile = '/doctor-profile';
  static const String myPatients = '/my-patients';
  static const String faq = '/faq';
  static const String contactUs = '/contact-us';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsConditions = '/terms-conditions';
  static const String myDoctor = '/my-doctor';
  static const String manageDoctor = '/manage-doctor';
  static const String patientFAQ = '/patient-faq';
  static const String profileNotification = '/profile_notification';
  static const String patientContactUs = '/patient-contact-us';
  static const String patientPrivacyPolicy = '/patient-privacy-policy';
  static const String patientTermsConditions = '/patient-terms-conditions';
  static const String addSymptoms = '/add-symptoms';

  // Route generator with bottom-to-top animation for ALL screens
  static Route<dynamic> generateRoute(RouteSettings settings) {
    Widget page;

    switch (settings.name) {
      case landing:
        page = const LandingPage();
        break;
      case signIn:
        final args = settings.arguments as Map<String, dynamic>?;
        page = SignInPage(initialUserType: args?['userType']);
        break;
      case forgotPassword:
        page = const ForgotPasswordPage();
        break;
      case register:
        page = const RegisterPage();
        break;
      case verification:
        page = VerificationPage(email: '');
        break;
      case createNewPassword:
        page = CreateNewPasswordPage(email: '', otp: '');
        break;
      case homeMask:
        page = const HomeMaskPage();
        break;
      case home:
        page = MainPage();
        break;
      case doctorHome:
        page = const DoctorHomePage();
        break;
      case patientsList:
        page = const PatientsListPage();
        break;
      case profileNotification:
        page = const PatientNotificationPage();
        break;
      case patientDetails:
        final args = settings.arguments as Map<String, dynamic>;
        page = PatientDetailsPage(
          patientName: args['patientName'],
          patientAge: args['patientAge'],
          patientGender: args['patientGender'],
          patientImage: args['patientImage'],
        );
        break;
      case patientDetailsRiskMetricDashboard:
        final args = settings.arguments as Map<String, dynamic>;
        page = PatientDetailsRiskMetricDashboard(
          patientName: args['patientName'],
          patientAge: args['patientAge'],
          patientGender: args['patientGender'],
          patientImage: args['patientImage'],
        );
        break;
      case patientDetailsSodiumDashboard:
        final args = settings.arguments as Map<String, dynamic>;
        page = PatientDetailsSodiumDashboard(
          patientName: args['patientName'],
          patientAge: args['patientAge'],
          patientGender: args['patientGender'],
          patientImage: args['patientImage'],
        );
        break;
      case patientDetailsMedicationDashboard:
        final args = settings.arguments as Map<String, dynamic>;
        page = PatientDetailsMedicationDashboard(
          patientName: args['patientName'],
          patientAge: args['patientAge'],
          patientGender: args['patientGender'],
          patientImage: args['patientImage'],
        );
        break;
      case patientDetailsBMIDashboard:
        final args = settings.arguments as Map<String, dynamic>;
        page = PatientDetailsBMIDashboard(
          patientName: args['patientName'],
          patientAge: args['patientAge'],
          patientGender: args['patientGender'],
          patientImage: args['patientImage'],
        );
        break;
      case heartRiskDashboard:
        final args = settings.arguments as Map<String, dynamic>?;
        page = HeartRiskDashboardPage(
          // score: (args?['score'] ?? 0) as double,
        );
        break;
      case allMealIntake:
        final args = settings.arguments as Map<String, dynamic>?;
        page = MealLogsPage(
          initialIndex: args?['tabIndex'],
          pageType: args?['pageType'],
        );
        break;
      case AppRouter.addMeal:
        final args = settings.arguments as Map<String, dynamic>?;
        page = AddMealPage(
          editData: args?['editData'] as MealEditData?,
          isEditMode: args?['isEditMode'] as bool? ?? false,
          mealMenuMode: args?['mealMenuMode'] as bool? ?? false,
        );
        break;
      case sodiumIntakeOverview:
        page = const SodiumIntakeOverviewPage();
        break;
      case allMedication:
        final args = settings.arguments as Map<String, dynamic>?;
        final isViewFullMode = args?['isViewFullMode'];
        String? navFromPage = args?['pageType'];
        page = AllMedicationPage(isViewFullMode: isViewFullMode, navFromPage: navFromPage);
        break;
      case medicationDashboard:
        page = const MedicationIntakeStatsDashboard();
        break;
      case addBodyMassIndex:
        final args = settings.arguments as Map<String, dynamic>?;
        page = AddBodyMassIndexPage(navFromPage: args?['pageType']);
        break;
      case weightTrendDashboard:
        page = const WeightTrendDashboardPage();
        break;
      case profile:
        page = const ProfilePage();
        break;
      case education:
        page = const EducationPage();
        break;
      case recipe:
        page = const RecipePage();
        break;
      case personalInfo:
        final args = settings.arguments as Map<String, dynamic>?;
        page = PersonalInfoPage(userType: args?['userType'] ?? 'patient');
        break;
      case registerAsDoctor:
        page = const RegisterAsDoctorPage();
        break;
      case doctorEducation:
        page = const DoctorEducationPage();
        break;
      case doctorRecipe:
        page = const DoctorRecipePage();
        break;
      case doctorProfile:
        page = const DoctorProfilePage();
        break;
      case myPatients:
        page = const MyPatientsPage();
        break;
      case faq:
        page = const FAQPage();
        break;
      case contactUs:
        page = const ContactUsPage();
        break;
      case privacyPolicy:
        page = const PrivacyPolicyPage();
        break;
      case termsConditions:
        page = const TermsConditionsPage();
        break;
      case myDoctor:
        page = const MyDoctorPage();
        break;
      case manageDoctor:
        page = const ManageDoctorPage();
        break;
      case patientFAQ:
        page = const PatientFAQPage();
        break;
      case patientContactUs:
        page = const PatientContactUsPage();
        break;
      case patientPrivacyPolicy:
        page = const PatientPrivacyPolicyPage();
        break;
      case patientTermsConditions:
        page = const PatientTermsConditionsPage();
        break;
      case addSymptoms:
        page = const AddSymptomsScreen();
        break;
      default:
        page = Scaffold(
          body: Center(
            child: Text('No route defined for ${settings.name}'),
          ),
        );
    }

    // Apply bottom-to-top slide animation to every route
    return _buildBottomToTopRoute(page, settings: settings);
  }

  // Custom bottom-to-top transition (already in your code, now used everywhere)
  static Route<dynamic> _buildBottomToTopRoute(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(
          begin: const Offset(0, 1), // from bottom
          end: Offset.zero, // to center
        ).chain(CurveTween(curve: Curves.easeOut));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  // Navigation methods (unchanged, but now they use the animated route via generateRoute)
  static void navigateToLanding(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      landing,
          (route) => false,
    );
  }

  static void navigateToSignIn(BuildContext context) {
    Navigator.pushNamed(context, signIn);
  }

  static void navigateToSignInWithUserType(BuildContext context, String userType) {
    Navigator.pushNamed(
      context,
      signIn,
      arguments: {'userType': userType},
    );
  }

  static void navigateToForgotPassword(BuildContext context) {
    Navigator.pushNamed(context, forgotPassword);
  }

  static void navigateToRegister(BuildContext context) {
    Navigator.pushNamed(context, register);
  }

  static void navigateToPersonalInfo(BuildContext context, String userType) {
    Navigator.pushNamed(
      context,
      personalInfo,
      arguments: {'userType': userType},
    );
  }

  static void replaceWithPersonalInfo(BuildContext context, String userType) {
    Navigator.pushReplacementNamed(
      context,
      personalInfo,
      arguments: {'userType': userType},
    );
  }

  static void navigateToRegisterAsDoctor(BuildContext context) {
    Navigator.pushNamed(context, registerAsDoctor);
  }

  static void replaceWithLanding(BuildContext context) {
    Navigator.pushReplacementNamed(context, landing);
  }

  static void replaceWithSignIn(BuildContext context) {
    Navigator.pushReplacementNamed(context, signIn);
  }

  static void replaceWithForgotPassword(BuildContext context) {
    Navigator.pushReplacementNamed(context, forgotPassword);
  }

  static void replaceWithRegister(BuildContext context) {
    Navigator.pushReplacementNamed(context, register);
  }

  static void navigateToVerification(BuildContext context) {
    Navigator.pushNamed(context, verification);
  }

  static void navigateToCreateNewPassword(BuildContext context) {
    Navigator.pushNamed(context, createNewPassword);
  }

  static void replaceWithVerification(BuildContext context) {
    Navigator.pushReplacementNamed(context, verification);
  }

  static void replaceWithCreateNewPassword(BuildContext context) {
    Navigator.pushReplacementNamed(context, createNewPassword);
  }

  static void navigateToHomeMask(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      homeMask,
          (Route<dynamic> route) => false,
    );
  }

  static void navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      home,
          (Route<dynamic> route) => false,
    );
  }

  static void navigateToHeartRiskDashboard(BuildContext context, double score) {
    Navigator.pushNamed(context, heartRiskDashboard, arguments: {'score': score});
  }

  static void replaceWithHomeMask(BuildContext context) {
    Navigator.pushReplacementNamed(context, homeMask);
  }

  static void replaceWithHome(BuildContext context) {
    Navigator.pushReplacementNamed(context, home);
  }

  static void replaceWithHeartRiskDashboard(BuildContext context) {
    Navigator.pushReplacementNamed(context, heartRiskDashboard);
  }

  static void navigateToAllMealIntake(BuildContext context) {
    Navigator.pushNamed(context, allMealIntake);
  }

  static void navigateToAllMealIntakeWithTab(BuildContext context, int tabIndex, String? pageType) {
    Navigator.pushNamed(
      context,
      allMealIntake,
      arguments: {'tabIndex': tabIndex, 'pageType': pageType},
    );
  }

  static Future<bool?> navigateToAddMeal(
      BuildContext context, {
        final MealEditData? editData,
        bool isEditMode = false,
        bool mealMenuMode = false,
      }) async {
    return await Navigator.pushNamed(
      context,
      addMeal,
      arguments: {
        'editData': editData,
        'isEditMode': isEditMode,
        'mealMenuMode': mealMenuMode,
      },
    );
  }

  static void navigateToSodiumIntakeOverview(BuildContext context) {
    Navigator.pushNamed(context, sodiumIntakeOverview);
  }

  static Future<dynamic> replaceWithAllMealIntakeIndex(BuildContext context, int tabIndex) {
    return Navigator.pushReplacementNamed(
      context,
      allMealIntake,
      arguments: {'tabIndex': tabIndex},
    );
  }

  static Future<dynamic> replaceWithAllMealIntake(BuildContext context, int tabIndex, String navFromPage) {
    return Navigator.pushReplacementNamed(
      context,
      allMealIntake,
      arguments: {'tabIndex': tabIndex, 'navFromPage': navFromPage},
    );
  }

  static void replaceWithSodiumIntakeOverview(BuildContext context) {
    Navigator.pushReplacementNamed(context, sodiumIntakeOverview);
  }

  static Future<dynamic> navigateToAllMedication(
      BuildContext context, {
        bool isViewFullMode = false,
        String? pageType,
      }) {
    return Navigator.pushNamed(
      context,
      allMedication,
      arguments: {
        'isViewFullMode': isViewFullMode,
        'pageType': pageType,
      },
    );
  }

  static void navigateToMedicationDashboard(BuildContext context) {
    Navigator.pushNamed(context, medicationDashboard);
  }

  static Future<dynamic> replaceWithAllMedication(
      BuildContext context, {
        bool isViewFullMode = false,
        String? pageType,
      }) {
    return Navigator.pushReplacementNamed(
      context,
      allMedication,
      arguments: {
        'isViewFullMode': isViewFullMode,
        'pageType': pageType,
      },
    );
  }

  static void replaceWithMedicationDashboard(BuildContext context) {
    Navigator.pushReplacementNamed(context, medicationDashboard);
  }

  static void navigateToAddBodyMassIndex(BuildContext context, [String? pageType]) {
    Navigator.pushNamed(
      context,
      addBodyMassIndex,
      arguments: {'pageType': pageType},
    );
  }

  static void navigateToWeightTrendDashboard(BuildContext context) {
    Navigator.pushNamed(context, weightTrendDashboard);
  }

  static void replaceWithAddBodyMassIndex(BuildContext context) {
    Navigator.pushReplacementNamed(context, addBodyMassIndex);
  }

  static void replaceWithWeightTrendDashboard(BuildContext context) {
    Navigator.pushReplacementNamed(context, weightTrendDashboard);
  }

  static Future<dynamic> navigateToProfile(BuildContext context) {
    return Navigator.pushNamed(context, profile);
  }

  static void replaceWithProfile(BuildContext context) {
    Navigator.pushReplacementNamed(context, profile);
  }

  static void navigateToEducation(BuildContext context) {
    Navigator.pushNamed(context, education);
  }

  static void replaceWithEducation(BuildContext context) {
    Navigator.pushReplacementNamed(context, education);
  }

  static void navigateToRecipe(BuildContext context) {
    Navigator.pushNamed(context, recipe);
  }

  static void replaceWithRecipe(BuildContext context) {
    Navigator.pushReplacementNamed(context, recipe);
  }

  static void navigateToDoctorHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      doctorHome,
          (route) => false,
    );
  }

  static void replaceWithDoctorHome(BuildContext context) {
    Navigator.pushReplacementNamed(context, doctorHome);
  }

  static void navigateToPatientsList(BuildContext context) {
    Navigator.pushNamed(context, patientsList);
  }

  static void replaceWithPatientsList(BuildContext context) {
    Navigator.pushReplacementNamed(context, patientsList);
  }

  static void navigateToPatientDetails(
      BuildContext context,
      String patientName,
      String patientAge,
      String patientGender,
      String patientImage,
      ) {
    Navigator.pushNamed(
      context,
      patientDetails,
      arguments: {
        'patientName': patientName,
        'patientAge': patientAge,
        'patientGender': patientGender,
        'patientImage': patientImage,
      },
    );
  }

  static void navigateToPatientDetailsRiskMetricDashboard(
      BuildContext context,
      String patientName,
      String patientAge,
      String patientGender,
      String patientImage,
      ) {
    Navigator.pushNamed(
      context,
      patientDetailsRiskMetricDashboard,
      arguments: {
        'patientName': patientName,
        'patientAge': patientAge,
        'patientGender': patientGender,
        'patientImage': patientImage,
      },
    );
  }

  static void navigateToPatientDetailsSodiumDashboard(
      BuildContext context,
      String patientName,
      String patientAge,
      String patientGender,
      String patientImage,
      ) {
    Navigator.pushNamed(
      context,
      patientDetailsSodiumDashboard,
      arguments: {
        'patientName': patientName,
        'patientAge': patientAge,
        'patientGender': patientGender,
        'patientImage': patientImage,
      },
    );
  }

  static void navigateToPatientDetailsMedicationDashboard(
      BuildContext context,
      String patientName,
      String patientAge,
      String patientGender,
      String patientImage,
      ) {
    Navigator.pushNamed(
      context,
      patientDetailsMedicationDashboard,
      arguments: {
        'patientName': patientName,
        'patientAge': patientAge,
        'patientGender': patientGender,
        'patientImage': patientImage,
      },
    );
  }

  static void navigateToPatientDetailsBMIDashboard(
      BuildContext context,
      String patientName,
      String patientAge,
      String patientGender,
      String patientImage,
      ) {
    Navigator.pushNamed(
      context,
      patientDetailsBMIDashboard,
      arguments: {
        'patientName': patientName,
        'patientAge': patientAge,
        'patientGender': patientGender,
        'patientImage': patientImage,
      },
    );
  }

  static void navigateToDoctorEducation(BuildContext context) {
    Navigator.pushNamed(context, doctorEducation);
  }

  static void navigateToDoctorRecipe(BuildContext context) {
    Navigator.pushNamed(context, doctorRecipe);
  }

  static void navigateToDoctorProfile(BuildContext context) {
    Navigator.pushNamed(context, doctorProfile);
  }

  static void replaceWithDoctorEducation(BuildContext context) {
    Navigator.pushReplacementNamed(context, doctorEducation);
  }

  static void replaceWithDoctorRecipe(BuildContext context) {
    Navigator.pushReplacementNamed(context, doctorRecipe);
  }

  static void replaceWithDoctorProfile(BuildContext context) {
    Navigator.pushReplacementNamed(context, doctorProfile);
  }

  static void navigateToMyPatients(BuildContext context) {
    Navigator.pushNamed(context, myPatients);
  }

  static void navigateToFAQ(BuildContext context) {
    Navigator.pushNamed(context, faq);
  }

  static void navigateToContactUs(BuildContext context) {
    Navigator.pushNamed(context, contactUs);
  }

  static void navigateToPrivacyPolicy(BuildContext context) {
    Navigator.pushNamed(context, privacyPolicy);
  }

  static void navigateToTermsConditions(BuildContext context) {
    Navigator.pushNamed(context, termsConditions);
  }

  static void navigateToProfileNotificattion(BuildContext context) {
    Navigator.pushNamed(context, profileNotification);
  }

  static void navigateTomyDoctor(BuildContext context) {
    Navigator.pushNamed(context, myDoctor);
  }

  static void navigateToManageDoctor(BuildContext context) {
    Navigator.pushNamed(context, manageDoctor);
  }

  static void navigateToPatientFAQ(BuildContext context) {
    Navigator.pushNamed(context, patientFAQ);
  }

  static void navigateToPatientContactUs(BuildContext context) {
    Navigator.pushNamed(context, patientContactUs);
  }

  static void navigateToPatientPrivacyPolicy(BuildContext context) {
    Navigator.pushNamed(context, patientPrivacyPolicy);
  }

  static void navigateToPatientTermsConditions(BuildContext context) {
    Navigator.pushNamed(context, patientTermsConditions);
  }

  static void navigateToAddSymptoms(BuildContext context) {
    Navigator.pushNamed(context, addSymptoms);
  }

  static void navigateToReplaceAddSymptoms(BuildContext context) {
    Navigator.pushReplacementNamed(context, addSymptoms);
  }
}