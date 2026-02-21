class HeartThriveStrings{
  static const String noInternet = "No Internet Connection";
  static const String noInternetDescription =
      "We’re unable to load your heart data right now. Please check your internet connection and try again.";
  // Risk Meter
  static const String riskTitle = "Heart Data";
  static const String riskMeterTitle = "Symptom Awareness Gauge";
  static const String riskMeterTitleOld = "Risk of developing symptoms";
  // Sodium
  static const String noMealAllSectionMsg = 'Find your favorite food with a quick search!';
  static const String noMealMenuSectionMsg = 'Find your favorite food with a quick search in "Browse Food"!';
  static const String noMealBreakFastSectionMsg = 'Find your favorite food with a quick search!';
  static const String noMealLunchSectionMsg = 'Find your favorite food with a quick search!';
  static const String noMealSnacksSectionMsg = 'Find your favorite food with a quick search!';
  static const String noMealDinnerSectionMsg = 'Find your favorite food with a quick search!';

  static const String noSodiumDashBoardTitle ='No Sodium Data Available';
  static const String noSodiumDashBoardDescription = "No meals have been logged for the selected period yet. Start adding food items to track your sodium intake.";

  // Medication Strings
  static const String noMedDashboardInformationTitle ='No Medications Logged';
  static const String noMedDashboardInformationDescription ='No medication entries found for the selected period. Start adding medication to track your medication intake.';

  static const String noMedicationTodayMSG ='No Today\'s Medications yet. Select \n"Find Medication" under Browse \nMedication to get started.';

  static const String noMedicationMorningMSG = 'No morning medication list yet. \nSelect "Find Medication" under Browse \nMedication to start.';
  static const String noMedicationAfterNoonMSG = 'No afternoon medication list yet. \nSelect "Find Medication" under Browse \nMedication to start.';
  static const String noMedicationEveningMSG = 'No evening medication list yet. \nSelect "Find Medication" under Browse \nMedication to start.';
  static const String noSearchMedicationMSG = 'Easily prepare your medication list from past records or medication list.';
  static const String noMedicationFoundMSG = 'No medication found.\n Create your own custom medication';

  // Symptoms
  static const String noSymptomsDescription = "You haven’t added any symptoms yet. Notice something?"
      "Add your first one anytime — we’re here to help track it.";

  static const String  noSymptomsTitle = "Great! No Symptoms Logged";
  static const String noSymptomsTitlePast = "No Symptoms for this Period";
  static const String noSymptomsTitlePastDynamic = "No Symptoms for";
  static const String noSymptomsDescriptionPast = "Nothing was logged for the selected dates.Try adjusting your filter to view other entries.";

  // Heart Comparesion
  static const String noHeartComparisonTitle = "No Week-to-Week Data Yet";
  static const String noHeartComparisonDescription = "Week-to-week comparison becomes available only after this week ends. Please check back later for insights.";

  // Offline Message
  static const String offlineTitle ="No Internet Connection";
  static const String offlineMessage ="You're currently offline. Please reconnect to the internet so we can sync "
      "your latest heart-health data and refresh your insights.";
  // Server Issues
  static const String userServerIssueTitle ="User Data Fetching Failed";
  static const String userServerIssueDescription ="Unable to load user information from server. Possible network error, authentication issue, or backend service degradation.";

  // Notifications
  static const String noNotificationTitle ='No notifications yet';
  static const String noNotificationDescription ="You'll see reminders, updates, and alerts here as you start using the app.";

  // Support Email
  static const String supportEmail = "support@heartthrivellc.com";

}

// Enums
enum NavPageType { profile, home , addMedication , allMeal}