import 'package:flutter/material.dart';
import '../constants/ui_constants.dart';
import '../theme/app_theme.dart';

class UserTypeCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const UserTypeCard({
    Key? key,
    required this.title,
    required this.imagePath,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: deviceWidth(context) > 750? Container(
       // width: 300,
        height: 450,
        padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Image section
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imagePath,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Title & arrow section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style:  TextStyle(
                    fontSize: deviceWidth(context) > 750?22:deviceWidth(context) > 360?18:14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: Colors.black,
                ),
              ],
            ),
          ],
        ),
      ) :Container(
        width: deviceWidth(context) > 360? 170 :100,
        height: deviceHeight(context) > 640 ?280: 200,
        padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Image section
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imagePath,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Title & arrow section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style:  TextStyle(
                    fontSize: deviceWidth(context) > 360?18:14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: Colors.black,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
