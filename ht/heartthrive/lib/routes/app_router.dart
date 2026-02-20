import 'package:flutter/material.dart';
import 'package:heart_thrive/models/meal/edit_meal_model.dart';
import 'package:heart_thrive/models/symptoms/symptoms_model.dart';
import 'package:heart_thrive/pages/meal-sodium/user_today_food.dart';

// Import pages
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
  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case landing:
        return MaterialPageRoute(builder: (_) => const LandingPage());
      case signIn:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => SignInPage(
            initialUserType: args?['userType'],
          ),
        );
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case verification:
        return MaterialPageRoute(builder: (_) => VerificationPage(email: ''));
      case createNewPassword:
        return MaterialPageRoute(builder: (_) => CreateNewPasswordPage(email: '',otp: '',));
      case homeMask:
        return MaterialPageRoute(builder: (_) => const HomeMaskPage());
      case home:
        return MaterialPageRoute(builder: (_) => MainPage());
      case doctorHome:
        return MaterialPageRoute(builder: (_) => const DoctorHomePage());
      case patientsList:
        return MaterialPageRoute(builder: (_) => const PatientsListPage());
      case profileNotification:
        return MaterialPageRoute(builder: (_) => const PatientNotificationPage());
        case patientDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PatientDetailsPage(
            patientName: args['patientName'],
            patientAge: args['patientAge'],
            patientGender: args['patientGender'],
            patientImage: args['patientImage'],
          ),
        );
      case patientDetailsRiskMetricDashboard:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PatientDetailsRiskMetricDashboard(
            patientName: args['patientName'],
            patientAge: args['patientAge'],
            patientGender: args['patientGender'],
            patientImage: args['patientImage'],
          ),
        );
      case patientDetailsSodiumDashboard:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PatientDetailsSodiumDashboard(
            patientName: args['patientName'],
            patientAge: args['patientAge'],
            patientGender: args['patientGender'],
            patientImage: args['patientImage'],
          ),
        );
      case patientDetailsMedicationDashboard:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PatientDetailsMedicationDashboard(
            patientName: args['patientName'],
            patientAge: args['patientAge'],
            patientGender: args['patientGender'],
            patientImage: args['patientImage'],
          ),
        );
      case patientDetailsBMIDashboard:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PatientDetailsBMIDashboard(
            patientName: args['patientName'],
            patientAge: args['patientAge'],
            patientGender: args['patientGender'],
            patientImage: args['patientImage'],
          ),
        );
      case heartRiskDashboard:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => HeartRiskDashboardPage(
            // score: (args?['score'] ?? 0) as double, // safely extract int
          ),
        );
      case allMealIntake:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => MealLogsPage(
            initialIndex: args?['tabIndex'],
            pageType: args?['pageType'],
          ),
        );
      case AppRouter.addMeal:
        final args = settings.arguments as Map<String, dynamic>?;

        return MaterialPageRoute<bool?>(
          builder: (_) => AddMealPage(
            editData: args?['editData'] as MealEditData?,   // <-- MODEL
            isEditMode: args?['isEditMode'] as bool? ?? false,
            mealMenuMode: args?['mealMenuMode'] as bool? ?? false,
            isCustomMode: args?['isCustomMode'] as bool? ?? false,
          ),
        );


      case sodiumIntakeOverview:
        return MaterialPageRoute(builder: (_) => const SodiumIntakeOverviewPage());
      case allMedication:
        final args = settings.arguments as Map<String, dynamic>?;
        final isViewFullMode = args?['isViewFullMode'];
        String? navFromPage = args?['pageType'];
        return MaterialPageRoute(
          builder: (_) => AllMedicationPage(isViewFullMode: isViewFullMode,navFromPage: navFromPage),
        );
      case medicationDashboard:
        return MaterialPageRoute(builder: (_) => const MedicationIntakeStatsDashboard());
      case addBodyMassIndex:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(builder: (_) =>  AddBodyMassIndexPage(
          navFromPage: args?['pageType'],
        ));
      case weightTrendDashboard:
        return MaterialPageRoute(builder: (_) => const WeightTrendDashboardPage());
      case profile:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(builder: (_) =>  ProfilePage(
          navFromPage: args?['pageType'],
        ));
      case education:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(builder: (_) => EducationPage(
          navFromPage: args?['pageType'],
        ));
      case recipe:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(builder: (_) =>  RecipePage(
          navFromPage: args?['pageType'],
        ));
      case personalInfo:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => PersonalInfoPage(
            userType: args?['userType'] ?? 'patient',
          ),
        );
      case registerAsDoctor:
        return MaterialPageRoute(builder: (_) => const RegisterAsDoctorPage());
      case doctorEducation:
        return MaterialPageRoute(builder: (_) => const DoctorEducationPage());
      case doctorRecipe:
        return MaterialPageRoute(builder: (_) => const DoctorRecipePage());
      case doctorProfile:
        return MaterialPageRoute(builder: (_) => const DoctorProfilePage());
      case myPatients:
        return MaterialPageRoute(builder: (_) => const MyPatientsPage());
      case faq:
        return MaterialPageRoute(builder: (_) => const FAQPage());
      case contactUs:
        return MaterialPageRoute(builder: (_) => const ContactUsPage());
      case privacyPolicy:
        return MaterialPageRoute(builder: (_) => const PrivacyPolicyPage());
      case termsConditions:
        return MaterialPageRoute(builder: (_) => const TermsConditionsPage());
      case myDoctor:
        return MaterialPageRoute(builder: (_) => const MyDoctorPage());
      case manageDoctor:
        return MaterialPageRoute(builder: (_) => const ManageDoctorPage());
      case patientFAQ:
        return MaterialPageRoute(builder: (_) => const PatientFAQPage());
      case patientContactUs:
        return MaterialPageRoute(builder: (_) => const PatientContactUsPage());
      case patientPrivacyPolicy:
        return MaterialPageRoute(builder: (_) => const PatientPrivacyPolicyPage());
      case patientTermsConditions:
        return MaterialPageRoute(builder: (_) => const PatientTermsConditionsPage());
      case addSymptoms:
        final args = settings.arguments as Map<String, dynamic>?;
        final SymptomModel? symptomModel =
        args?['symptomModel'];
        final bool? isEdit =
        args?['isEdit'];
        final bool? isHome =
        args?['isHome'];
        return MaterialPageRoute(builder: (_) => AddSymptomsScreen(
          symptomModel: symptomModel,
          isEdit: isEdit?? false,
          isHome: isHome?? true,
        ));
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  // Navigation methods
  static void navigateToLanding(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      landing,
          (route) => false,
    );
  }
  static void navigateToLandingClear(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        landing,
            (route) => false,
      );
    });
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

  // Navigation with replacement (removes previous route from stack)
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

  static void navigateToVerification(BuildContext context,) {
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

  // Navigation methods for new pages
  static void navigateToHomeMask(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      homeMask,
          (Route<dynamic> route) => false, // remove all previous routes
    );
  }

  static void navigateToHome(BuildContext context) {
   // Navigator.pushNamed(context, home);
    Navigator.pushNamedAndRemoveUntil(
      context,
      home,
          (Route<dynamic> route) => false, // remove all previous routes
    );

  }

  static void navigateToHeartRiskDashboard(BuildContext context, double score) {
    Navigator.pushNamed(context, heartRiskDashboard,arguments: {'score': score});
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

  // Navigation methods for meal intake and sodium tracking
  static void navigateToAllMealIntake(BuildContext context) {
    Navigator.pushNamed(context, allMealIntake);
  }

  static void navigateToAllMealIntakeWithTab(BuildContext context, int tabIndex,String? pageType) {
    Navigator.pushNamed(
      context,
      allMealIntake,
      arguments: {'tabIndex': tabIndex,'pageType':pageType},
    );
  }

  static Future<bool?> navigateToAddMeal(
      BuildContext context, {
        final MealEditData? editData,
        bool isEditMode = false,
        bool mealMenuMode = false,
        bool isCustomMode = false,
      }) async {
    return await Navigator.pushNamed(
      context,
      addMeal,
      arguments: {
        'editData': editData,
        'isEditMode': isEditMode,
        'mealMenuMode': mealMenuMode,
        'isCustomMode' : isCustomMode
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

  static Future<dynamic> replaceWithAllMealIntake(BuildContext context, int tabIndex,String navFromPage) {

    return Navigator.pushReplacementNamed(
      context,
      allMealIntake,
      arguments: {'tabIndex': tabIndex,'navFromPage':navFromPage},
    );

  }

  static void replaceWithSodiumIntakeOverview(BuildContext context) {
    Navigator.pushReplacementNamed(context, sodiumIntakeOverview);
  }

  // Navigation methods for medication
  static Future<dynamic> navigateToAllMedication(
      BuildContext context, {bool isViewFullMode = false,String? pageType}) {
    return Navigator.pushNamed(
      context,
      allMedication,
      arguments: {
        'isViewFullMode':isViewFullMode,
        'pageType':pageType
      }, // pass the boolean
    );
  }
  /*
  static Future<dynamic> navigateToAllMedication(BuildContext context) {

    return Navigator.pushNamed(context, allMedication);

  }
  */
  static void navigateToMedicationDashboard(BuildContext context) {
    Navigator.pushNamed(context, medicationDashboard);
  }

  // static void replaceWithAllMedication(BuildContext context) {
  //   Navigator.pushReplacementNamed(context, allMedication);
  // }

  static Future<dynamic> replaceWithAllMedication(
      BuildContext context, {bool isViewFullMode = false,String? pageType}) {
    return Navigator.pushReplacementNamed(
      context,
      allMedication,
      arguments: {
        'isViewFullMode':isViewFullMode,
        'pageType':pageType
      }, // pass the boolean
    );
  }

  static void replaceWithMedicationDashboard(BuildContext context) {
    Navigator.pushReplacementNamed(context, medicationDashboard);
  }

  // Navigation methods for weight and BMI tracking
  static void navigateToAddBodyMassIndex(BuildContext context,[ String? pageType]) {
    Navigator.pushNamed(
        context,
        addBodyMassIndex,
       arguments: {'pageType':pageType}
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

  // Navigation methods for profile
  static Future<dynamic> navigateToProfile(BuildContext context) {
    return Navigator.pushNamed(context, profile);
  }

  static void replaceWithProfile(BuildContext context) {
    Navigator.pushReplacementNamed(context, profile);
  }

  // Navigation methods for education
  static void navigateToEducation(BuildContext context) {
    Navigator.pushNamed(context, education);
  }

  static void replaceWithEducation(BuildContext context) {
    Navigator.pushReplacementNamed(context, education);
  }

  // Navigation methods for recipe
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
  static void navigateToAddSymptoms(BuildContext context, isHome) {
    Navigator.pushNamed(context, addSymptoms, arguments: {"isHome": isHome});
  }
  static void navigateToAddSymptomsWithEdit(BuildContext context,SymptomModel symptomModel,bool isEdit, bool isHome) {
    Navigator.pushNamed(context,
        addSymptoms,
        arguments: {
        "symptomModel":symptomModel,
          "isEdit":isEdit,
          "isHome":isHome
        }
    );
  }
  static void navigateToReplaceAddSymptoms(BuildContext context) {
    Navigator.pushReplacementNamed(context, addSymptoms);

  }
}
