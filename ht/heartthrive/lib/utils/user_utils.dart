import '../services/user_service.dart';

/// Utility class for easy access to user information across the app
class UserUtils {
  /// Get the user's first name
  static String get firstName => UserService.userFirstName;
  
  /// Get the user's full name
  static String get fullName {
    final user = UserService.currentUser;
    if (user != null) {
      return '${user.firstname} ${user.lastname}';
    }
    return UserService.userFirstName;
  }
  
  /// Get the user's email
  static String get email {
    final user = UserService.currentUser;
    return user?.email ?? '';
  }
  
  /// Check if user data is loaded
  static bool get isUserLoaded => UserService.currentUser != null;
  
  /// Get a personalized greeting based on time of day
  static String get personalizedGreeting {
    final hour = DateTime.now().hour;
    String greeting;
    
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
    
    return '$greeting, $firstName!';
  }

  // Weight Conversion Logic
  static double kgToLbs(double kg) {
    return double.parse((kg * 2.20462).toStringAsFixed(2));
  }

  static double lbsToKg(double lbs) {
    return double.parse((lbs * 0.453592).toStringAsFixed(2));
  }

// Height Conversion Logic
  static double feetToCm(double feet) {
    return double.parse((feet * 30.48).toStringAsFixed(2));
  }

  static double cmToFeet(double cm) {
    return double.parse((cm * 0.0328084).toStringAsFixed(2));
  }

  static double cmToInch(double cm) {
    return double.parse((cm / 2.54).toStringAsFixed(2));
  }

  static double inchToCm(double inch) {
    return double.parse((inch * 2.54).toStringAsFixed(2));
  }

  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  // Date validation
 static bool validateDob(String? value) {
    if (value == null || value.isEmpty) {
      return false;
    }

    try {
      // Expected format: dd/MM/yyyy
      final parts = value.split('/');
      if (parts.length != 3) {
        return false;
      }

      final month = int.tryParse(parts[0]);
      final day = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day == null || month == null || year == null) {
        return false;
      }

      // Year range
      // First: is year valid? (not in future or before 1900)
      if (year < 1900 || year > DateTime.now().year) {
        return false; // Invalid year
      }


      if (year < DateTime.now().year - 120 || year > DateTime.now().year) {
        return false;;
      }

      // Month range
      if (month < 1 || month > 12) {
        return false;;
      }

      // Day range
      if (day < 1 || day > 31) {
        return false;
      }

      // Try constructing date
      final dob = DateTime(year, month, day);

      // Validate reconstructed date (to catch 30 Feb etc.)
      if (dob.day != day || dob.month != month || dob.year != year) {
        return false;;
      }

      // 🚫 No future dates allowed
      if (dob.isAfter(DateTime.now())) {
        return false;;
      }

      // ✅ Valid DOB
      return true;
    } catch (_) {
      return false;;
    }
  }
}
