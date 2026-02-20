import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/ui_constants.dart';

class AppTheme {
  // Brand Colors
  static const Color appBackgroundColor = Color(0xFFF6F6F8);
  static const Color primaryColor = Color(0xFF95020A);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Colors.black87;
  static const Color lightTextColor = Colors.black54;
  static const Color buttonTextColor = Colors.white;
  static const Color linkTextColor = Colors.white;
  static const Color topBarTextColor = Colors.white;

  // Gradients
  static const LinearGradient landingGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFF8E1), // Light cream color
      Color(0xFFFFF8E1), // Light cream color
    ],
  );

  static const LinearGradient registerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFF8E1), // Light cream color
      Color(0xFFFFF8E1), // Light cream color
    ],
  );

  static const TextStyle whiteTitle14 = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  static const TextStyle whiteTitle16 = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle whiteTitle23 = TextStyle(
    fontSize: 23.0,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    color: lightTextColor,
  );

  static const TextStyle buttonTextStyle20 = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    color: AppTheme.primaryColor,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppTheme.primaryColor,
  );
  static const TextStyle buttonTextStyle12 = TextStyle(
      fontSize: 12.0,
      fontWeight: FontWeight.w600,
      color: AppTheme.primaryColor
  );

  static const TextStyle linkTextStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    color: primaryColor,
    decoration: TextDecoration.underline,
  );

  static const TextStyle hintTitle18 = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );
  // Styles
  // Titles: 20 → 12, bold
  static const TextStyle title30 = TextStyle(
    fontSize: 30.0,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  static const TextStyle title25 = TextStyle(
    fontSize: 25.0,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  static const TextStyle title20 = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  static const TextStyle title18 = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  static const TextStyle title16 = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  static const TextStyle title14 = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  static const TextStyle title12 = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  static const TextStyle title11 = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  static const TextStyle title10 = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  static const TextStyle title8 = TextStyle(
    fontSize: 8.0,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  // Subtitles: 18 → 10, normal weight
  static const TextStyle subtitle18 = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w400,
    color: Colors.black54,
  );
  static const TextStyle subtitle16 = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    color: Colors.black54,
  );
  static const TextStyle subtitle14 = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: Colors.black54,
  );

  static const TextStyle subtitle13 = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.bold,
    color: Colors.black54,
  );

  static const TextStyle subtitle12 = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: Colors.black54,
  );
  static const TextStyle subtitle10 = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.w400,
    color: Colors.black54,
  );

  // Normal text: 16 → 10
  static const TextStyle body18 = TextStyle(
    fontSize: 18.0,
    color: Colors.black54,
  );
  static const TextStyle body16 = TextStyle(
    fontSize: 16.0,
    color: Colors.black54,
  );
  static const TextStyle body14 = TextStyle(
    fontSize: 14.0,
    color: Colors.black54,
  );
  static const TextStyle body12 = TextStyle(
    fontSize: 12.0,
    color: Colors.black54,
  );
  static const TextStyle body10 = TextStyle(
    fontSize: 10.0,
    color: Colors.black54,
  );

  // Button Styles
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: buttonTextColor,
    padding: const EdgeInsets.symmetric(vertical: 15.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  );

  static final ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: const BorderSide(color: primaryColor),
    padding: const EdgeInsets.symmetric(vertical: 15.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  );

  // Input Decoration
  static InputDecoration inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.grey, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: primaryColor, width: 1.0),
      ),
    );
  }

  // App Theme Data
  static ThemeData themeData = ThemeData(
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: headingStyle,
      bodyLarge: subheadingStyle,
    ),
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: topBarTextColor,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: primaryButtonStyle,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: secondaryButtonStyle,
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: primaryColor,
      secondary: primaryColor,
    ),
  );

  static double responsiveButtonFontSize (BuildContext context) => deviceWidth(context)> 750? 20:14;
  static double responsiveSubButtonFontSize (BuildContext context) => deviceWidth(context)> 750? 18:14;
  static double responsiveTitle1FontSize (BuildContext context) => deviceWidth(context)> 750? 20:18;
  static double responsiveTitleFontSize (BuildContext context) => deviceWidth(context)> 750? 18:14;
  static double responsiveTitle2FontSize (BuildContext context) => deviceWidth(context)> 750? 16:12;
  static double responsiveTitle18_11FontSize(BuildContext context) => deviceWidth(context) > 750 ? 18:deviceWidth(context)>360?13:11;
  static double responsiveTitle16_10FontSize(BuildContext context) => deviceWidth(context) > 750 ? 16:deviceWidth(context) > 360?11:10;
  static double responsiveParaFontSize (BuildContext context) => deviceWidth(context)> 750? 16:deviceWidth(context)> 390?14:12;
}
