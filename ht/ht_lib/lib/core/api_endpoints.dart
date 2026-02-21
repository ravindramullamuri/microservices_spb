import 'package:heart_thrive/models/bmi/weight_height_model.dart';
import 'package:intl/intl.dart';

class ApiEndpoints{
  // Production
  //static String baseUrl =  "https://heartthrivellc.com";
  // CI
  static String baseUrl = "https://ciheartthrive.schoolyug.com";
  // QA
  //static String baseUrl = "https://qaheartthrive.schoolyug.com";
  // Local URL
  //static String  baseUrl ='https://48c04818dda7.ngrok-free.app';
  // Authenticate
  static String authenticateURL='$baseUrl/api/authenticate';
  static String refreshTokenURL = '$baseUrl/api/refresh-token';
  // Register Device
  static String registerFCM ='$baseUrl/api/users/register-device';
  static String removeFCM = '$baseUrl/api/users/remove-device';
  // Users
  static String userCreateURL ='$baseUrl/api/users/create';
  static String getUser = '$baseUrl/api/get_user';
  static String getCurrentUser = "$baseUrl/api/users";

  // Get User Roles
  static String userRoles='$baseUrl/api/roles';
  // Email verification Send OTP
  static String emailVerificationSendOTP='$baseUrl/api/email-verification/send-otp';
  // Verify the OTP
  static String emailVerificationVerifyOtp='$baseUrl/api/email-verification/verify-otp';
  // Validate OTP
  static String passwordValidateOtp='$baseUrl/api/password/validate-otp';
  // Password
  static String resetPassword='$baseUrl/api/password/reset-password';
  static String forgotPassword='$baseUrl/api/password/forgot-password';

  // Update User Data
  static String updateUser(int? userId){
    return '$baseUrl/api/users/$userId';
  }
  // Create Patient Weight and Height Details
  static String createPatientWeightAndHeight= '$baseUrl/api/patient-weight-height-logs/create';

  /// Risk Meter
  static String riskMetricDashboard(String userId,String timezone)=>'$baseUrl/api/patient-heart-risk-metrics/riskMetricDashboard?patientId=$userId&timeZone=$timezone';
  static String riskMetricHeroSection = '$baseUrl/api/patient-heart-risk-metrics/riskMetricDashboard';
  //static String heartRiskSummary='$baseUrl/api/patient-heart-risk-metric-histories/heart-risk-summary';
  static String heartRiskSummary='$baseUrl/api/patient-heart-risk-metrics/heart-risk-summary';
  /// Sodium

  static String patientMealLogsNutrientSummary='$baseUrl/api/patient-meal-logs/nutrient-summary';
  static String patientMealLogsNutrientSummaryByMealType='$baseUrl/api/patient-meal-logs/nutrient-summary-by-meal-type';

  static String dailyNutrientSummary({
    required String fromDate,
    required String toDate,
    required String timezone
  }) {
    return "$baseUrl/api/patient-meal-logs/daily-nutrient-summary"
        "?fromDate=$fromDate&toDate=$toDate&timezone=$timezone";
  }
  /// Sodium

  static String getMealTypesURL='$baseUrl/api/app-param-values/get-meal-types';
  static String userMealLogsByMealTypeIdEndpoint({
    required int mealTypeId,
    required String fromDate,
    required String toDate,
    required String timezone,
    required int page,
    required int size,
  }) {
    return "$baseUrl/api/patient-meal-logs/user-meal-logs"
        "?mealTypeId=$mealTypeId"
        "&fromDate=$fromDate"
        "&toDate=$toDate"
        "&timezone=$timezone"
        "&page=$page"
        "&size=$size";
  }
  static String userMealLogsEndpoint({
    required String fromDate,
    required String toDate,
    required String timezone,
    required int page,
    required int size,
  }) {
    return "$baseUrl/api/patient-meal-logs/user-meal-logs"
        "?fromDate=$fromDate"
        "&toDate=$toDate"
        "&timezone=$timezone"
        "&page=$page"
        "&size=$size";
  }

  static String heartRiskMetricComparisonEndpoint({
    required int? patientId,
    required String timezone,
  }) {
    return "$baseUrl/api/patient-heart-risk-metrics/heart-risk-metric-comparison"
        "?patientId=$patientId"
        "&timeZone=$timezone";
  }

  static String foodItemsWithNutrients='$baseUrl/api/food-items/with-nutrients';
  static String userPatientMealLogs(int mealLogId)=>'$baseUrl/api/patient-meal-logs/$mealLogId';
  static String userPatientMealMenuLogs(int mealLogId)=>'$baseUrl/api/patient-meal-menus/$mealLogId';
  static String createMeal = '$baseUrl/api/patient-meal-logs/create-meal';
  static String editMeal(int mealId)=>'$baseUrl/api/patient-meal-logs/edit-meal/$mealId';
  static String editMealMenu = '$baseUrl/api/patient-meal-menus/edit';
  static String userMealLogs = '$baseUrl/api/patient-meal-logs/user-meal-logs';
  static String patientMealMenusWithNutrients= '$baseUrl/api/patient-meal-menus/with-nutrients';
  /** Medication Endpoints */
  // MedicationsList
  static String medicationsList({int? page = 0, int? size = 10}){
    return '$baseUrl/api/medications/list?page=$page&size=$size&sort=name,asc';
  }
  // Track Intake Medication
  static String trackInTakeMedications = '$baseUrl/api/medications/track-intake';
  // medicationsScheduleList
  static String medicationsScheduleList='$baseUrl/api/medications/schedule-list';
  // My Medication
  static String myMedicationsList='$baseUrl/api/medications/my-medications';
  // intakeStatsOfMedications
  static String intakeStatsOfMedications='$baseUrl/api/medications/intake-stats';
  // editScheduleMedications
  static String editScheduleMedications='$baseUrl/api/medications/edit-schedule';
  //
  static String medicationScheduleByUUID(String scheduleUuid){
    return '$baseUrl/api/medications/schedule/$scheduleUuid';
  }
  // removeMyMedication
  static String removeMyMedication='$baseUrl/api/medications/remove-my-medication';
  // delete
  static String deleteMedicationByScheduleUUID(String scheduleUuid){
    return '$baseUrl/api/medications/schedule/$scheduleUuid';
  }
  // intakeMedicationCountSummary
  static String intakeMedicationCountSummary = '$baseUrl/api/medications/intake-count-summary';
  // medicationScheduleOverviewInfo
  static String medicationScheduleOverviewInfo='$baseUrl/api/medications/schedule-overview';
  static String medicationsDailyIntakeStats='$baseUrl/api/medications/daily-intake-stats';
  static String medicationsIntakeStats='$baseUrl/api/medications/intake-stats';
  static String medicationsAdd='$baseUrl/api/medications/add';
  static String medicationMenuByUUID(menuUuid)=>'$baseUrl/api/medications/menu/$menuUuid';

  ///symptoms
  static String symptomSummary({
    required String fromDate,
    required String toDate,
    required String timezone,
  }) {
    return "$baseUrl/api/patient-symptom-tracks/summary-report"
        "?fromDate=$fromDate"
        "&toDate=$toDate"
        "&timezone=$timezone";
  }
  static String symptomReportSummary({
    required String fromDate,
    required String toDate,
    required String timezone,
  }) {
    return "$baseUrl/api/patient-symptom-tracks/symptoms-report"
        "?fromDate=$fromDate"
        "&toDate=$toDate"
        "&timezone=$timezone";
  }

  /// BMI Endpoints

  static String patientWeightHeightLogsRange='$baseUrl/api/patient-weight-height-logs/range';
  static String bmiStatus(int id)=>'$baseUrl/api/bmi-statuses/$id';
  static String patientWeightHeightLogs='$baseUrl/api/patient-weight-height-logs';
  static String heroDashboardOfBMI ='$baseUrl/api/patient-weight-height-logs/heroDashboard';
  static String createPatientWeightHeight='$baseUrl/api/patient-weight-height-logs/create';
  static String updatePatientWeightHeight(WeightHeightLog log)=> '$baseUrl/api/patient-weight-height-logs/${log.id}';
  static String userCurrentAndPastDataOfBMI='$baseUrl/api/patient-weight-height-logs/currentAndPastData';
  static String dashboardWeightAndHeightEndpoint({
    required DateTime start,
    required DateTime end,
    String? timezone,
    String? groupBy
  }) {
    final startDate = DateFormat('yyyy-MM-dd').format(start);
    final endDate = DateFormat('yyyy-MM-dd').format(end);

    return "$baseUrl/api/patient-weight-height-logs/dashborad"
        "?startDate=$startDate"
        "&endDate=$endDate"
        "&timezone=$timezone&groupBy=$groupBy";
  }


  // Profile  Endpoints

  static String patientProfilesURL='$baseUrl/api/patient-profiles';

  static String get notificationMarkSeen => "$baseUrl/api/notifications/mark-seen";


  // Profile Image Upload using userId
  static String uploadUserProfileImage(int? userId) {
    return "$baseUrl/api/users/$userId/profile-image";
  }

  // Notifications
  static String notificationsDataURL({int page = 0, int size = 20})=>'$baseUrl/api/notifications?page=$page&size=$size';
  // Add Symptoms
  static String createPatientSymptoms = '$baseUrl/api/patient-symptom-tracks/create-new';
}

const timeoutDuration = Duration(seconds: 15);