
import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';
import '../theme/app_theme.dart';

Widget buildWrapperInkWell(BuildContext context, VoidCallback onTap,Widget child){
  return InkWell(
    onTap: onTap,
    child:child,
  );
}

Widget buildAddNewButton(BuildContext context,VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Row(
      children: [
        Text(
          "Add New",
          style: AppTheme.title16.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w500,
            fontSize: deviceWidth(context)>830?20:14,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width:deviceWidth(context)>830? 30:20,
          height: deviceWidth(context)>830? 30:20,
          decoration: const BoxDecoration(
              color: Color(0xFF95020A), shape: BoxShape.circle),
          child:
          Icon(Icons.add, color: Colors.white, size:deviceWidth(context)>830? 20:14),
        ),
      ],
    ),
  );
}
Widget buildAddNewButtonNew(
    BuildContext context,
    VoidCallback onTap,
    ) {
  final bool isTablet = deviceWidth(context) > 830;

  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 14,
        vertical: isTablet ? 12 : 10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(30), // pill shape
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon container
          Container(
            width: isTablet ? 36 : 28,
            height: isTablet ? 36 : 28,
            decoration: const BoxDecoration(
              color: Colors.white, // app red
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add,
              color: Colors.black,
              size: isTablet ? 22 : 18,
            ),
          ),
          const SizedBox(width: 10),

          // Text
          Text(
            "Add New",
            style: AppTheme.title16.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: isTablet ? 18 : 14,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildDashboardButton(BuildContext context,VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Image.asset(
          "lib/assets/dash.png",
          width: deviceWidth(context) > 830 ? 30 :deviceWidth(context) > 360 ? 22:16,
          height:deviceWidth(context) > 830 ? 30 : deviceWidth(context) > 360 ? 22:16,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 4),
        Text(
          "Dashboard",
          style:deviceWidth(context) > 830? AppTheme.body16.copyWith(
            fontSize: 18,
            color: AppTheme.primaryColor,
          ):deviceWidth(context) > 360? AppTheme.body14.copyWith(
            color: AppTheme.primaryColor,
          ):AppTheme.title12.copyWith(
            color: AppTheme.primaryColor,
          ),)
      ],
    ),
  );
}
// Expand and Close
Widget buildLessAndMoreInfoButton(
    BuildContext context, {
      required bool showMoreInfo,
      required VoidCallback onTap,
    }) {
  return GestureDetector(
    onTap: onTap,
    child: Row(
      children: [
        Container(
          width: deviceWidth(context) > 830 ? 35 : 20,
          height: deviceWidth(context) > 830 ? 35 : 20,
          decoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            showMoreInfo
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
            color: Colors.white,
            size: deviceWidth(context) > 830 ? 30 : 16,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          showMoreInfo ? "Less Info" : "More Info",
          style: TextStyle(
            fontSize: deviceWidth(context) > 830 ? 20 : 14,
            color: const Color(0xFF8B0000),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
Widget headerTitle(BuildContext context,String title){
  return Text(title, style: deviceWidth(context)>830? AppTheme.title20:AppTheme.title16);
}
//
Widget buildTitleWithIconButton(BuildContext context,VoidCallback onTap,String title, IconData icon) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: GestureDetector(
      onTap: onTap,
      child: Row(
        //crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: AppTheme.title16.copyWith(
              color: AppTheme.primaryColor,
              fontSize: deviceWidth(context)>830?18:14,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width:deviceWidth(context)>830? 30:20,
            height: deviceWidth(context)>830? 30:20,
            decoration: const BoxDecoration(
                color: Color(0xFF95020A), shape: BoxShape.circle),
            child:
            Icon(icon, color: Colors.white, size:deviceWidth(context)>830? 20:14),
          ),
        ],
      ),
    ),
  );
}
