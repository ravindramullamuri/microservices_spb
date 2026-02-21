import 'package:flutter/material.dart';
import 'package:heart_thrive/theme/app_theme.dart';

class ConnectionUnavailable extends StatelessWidget {
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onRetry;

  const ConnectionUnavailable({
    super.key,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ------------ ICON ------------
            Image.asset(
              "assets/no_internet_heart.png", // <- your red heart icon
              width: 140,
              height: 140,
            ),

            const SizedBox(height: 24),

            // ------------ TITLE ------------
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // ------------ DESCRIPTION ------------
            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // ------------ RETRY BUTTON ------------
            SizedBox(
              width: 180,
              //height: 44,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor:AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: AppTheme.title16.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
