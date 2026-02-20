import 'package:flutter/material.dart';

class ResponsiveUtils {
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double blockSizeHorizontal(BuildContext context) {
    return screenWidth(context) / 100;
  }

  static double blockSizeVertical(BuildContext context) {
    return screenHeight(context) / 100;
  }

  static double safeBlockHorizontal(BuildContext context) {
    final safeAreaHorizontal = MediaQuery.of(context).padding.left +
        MediaQuery.of(context).padding.right;
    final safeWidth = screenWidth(context) - safeAreaHorizontal;
    return safeWidth / 100;
  }

  static double safeBlockVertical(BuildContext context) {
    final safeAreaVertical = MediaQuery.of(context).padding.top +
        MediaQuery.of(context).padding.bottom;
    final safeHeight = screenHeight(context) - safeAreaVertical;
    return safeHeight / 100;
  }

  // Font sizes based on screen size
  static double getResponsiveFontSize(BuildContext context, double fontSize) {
    final double scaleFactor = _getScaleFactor(context);
    final double responsiveFontSize = fontSize * scaleFactor;

    // Ensure font size is within reasonable bounds
    final double minFontSize = fontSize * 0.8;
    final double maxFontSize = fontSize * 1.2;

    return responsiveFontSize.clamp(minFontSize, maxFontSize);
  }

  static double _getScaleFactor(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) return 0.8; // Small phones
    if (width < 480) return 0.9; // Normal phones
    if (width < 600) return 1.0; // Large phones
    if (width < 720) return 1.05; // Small tablets
    if (width < 1024) return 1.1; // Tablets
    return 1.2; // Large tablets and beyond
  }

  // Padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) {
      return const EdgeInsets.all(12.0); // Small phones
    } else if (width < 600) {
      return const EdgeInsets.all(16.0); // Phones
    } else if (width < 900) {
      return const EdgeInsets.all(24.0); // Tablets
    } else {
      return const EdgeInsets.all(32.0); // Large tablets and beyond
    }
  }

  // Accessibility helpers
  static Widget addSemantics({
    required Widget child,
    required String label,
    String? hint,
    bool isButton = false,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      enabled: true,
      child: child,
    );
  }

  // Helper for creating accessible text with proper contrast
  static Text accessibleText(
    String text, {
    required TextStyle style,
    TextAlign? textAlign,
  }) {
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      semanticsLabel: text,
    );
  }
}
