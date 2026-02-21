import 'package:intl/intl.dart';
import 'package:timezone/standalone.dart' as tz;


class DateFormatUtil{
  static String getTimePeriod() {
    int hour = DateTime.now().hour;
    return (hour >= 5 && hour < 12) ? "morning" :
    (hour >= 12 && hour < 17) ? "afternoon" :
    (hour >= 17 && hour < 21) ? "evening" : "night";
  }
  static String convertToApiDate(String input) {
    // Input format: dd-MM-yyyy
    final parts = input.split('-');
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);

    // Create DateTime
    final date = DateTime.utc(year, month, day);

    // Convert to ISO 8601 string
    return date.toIso8601String(); // → "1992-05-20T00:00:00.000Z"
  }

  /// Convert "dd/MM/yyyy" → ISO string
  static String toApiFormat(String input) {
    final parts = input.split('/');
    final month = int.parse(parts[0]);
    final day = int.parse(parts[1]);
    final year = int.parse(parts[2]);

    final date = DateTime.utc(year, month, day);
    return date.toIso8601String(); // e.g. "1990-05-20T00:00:00.000Z"
  }

  /// Convert ISO string → "dd/MM/yyyy"
  static String fromApiFormat(String isoString) {
    final date = DateTime.parse(isoString);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return "$day/$month/$year"; // e.g. "20/05/1990"
  }

  /// Parse "dd-MM-yyyy HH:mm" → "dd/MM/yyyy"
  static String fromCustomToDisplay(String input) {
    final parts = input.split(' ');
    final dateParts = parts[0].split('-');

    final day = dateParts[0].padLeft(2, '0');
    final month = dateParts[1].padLeft(2, '0');
    final year = dateParts[2];

    return "$month/$day/$year"; // e.g. 20/01/1992
  }

  // DateTime to String
  static String getFormattedDateTimeToString(now) {
    final formatter = DateFormat('dd-MM-yyyy hh:mm a');
    return formatter.format(now);
  }

  /// Returns a formatted string for the start of the given date (00:00)
  static String getStartOfDay(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0);
    //final formatter = DateFormat('dd-MM-yyyy hh:mm a');
    final formatter = DateFormat('dd-MM-yyyy');
    return formatter.format(startOfDay);
  }

  /// Returns a formatted string for the end of the given date (23:59)
  static String getEndOfDay(DateTime date) {
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59);
    //final formatter = DateFormat('dd-MM-yyyy hh:mm a');
    final formatter = DateFormat('dd-MM-yyyy');
    return formatter.format(endOfDay);
  }

  // 24Hours
 static String formatTo24Hour(String timeString) {
    try {
      final date = DateFormat.jm().parse(timeString); // parses '02:30 PM'
      return DateFormat('HH:mm').format(date); // converts to '14:30'
    } catch (_) {
      return timeString; // fallback if already 24-hour
    }
  }

  static String startDateFormat(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }
  static String displayFormatDateBMI(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      // Example: "Oct 28, 2025"
      return DateFormat("MMM d, yyyy").format(date);
    } catch (e) {
      return ''; // or handle invalid date
    }
  }

   String convertUtcToIst(String utcString, String timezoneId) {
    // Parse UTC datetime
    final utcDate = DateTime.parse(utcString).toUtc();

    // Load timezone location
    final location = tz.getLocation(timezoneId);

    // Convert
    final istDate = tz.TZDateTime.from(utcDate, location);

    // Format output
    final day = istDate.day;
    final month = monthName(istDate.month);
    final year = istDate.year;

    int hour = istDate.hour;
    final minute = istDate.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? "PM" : "AM";
    hour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return "$month $day $year $hour:$minute $period";
  }

  String monthName(int m) {
    const months = [
      "", "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return months[m];
  }

  static String formatOfMonthDateYearDisplay(String apiDate) {
    final DateTime parsedDate = DateTime.parse(apiDate);
    return DateFormat('MM/dd/yyyy').format(parsedDate);
  }

}