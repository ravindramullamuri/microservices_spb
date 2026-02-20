// AddBodyMassIndexPage.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/components/profile_avatar.dart';
import 'package:heart_thrive/constants/heart_thrive_strings_constants.dart';
import 'package:heart_thrive/providers/user/user_details_provider.dart';
import 'package:heart_thrive/routes/app_router.dart';

import '../../components/action_menu.dart';
import '../../components/connection_unavailable.dart';
import '../../constants/ui_constants.dart';
import '../../providers/bmi/bmi_provider.dart';
import '../../providers/internet_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/component_utils.dart';
import '../../utils/date_utils.dart';
import '../notification_badgeicon_widget.dart';
import 'height_weight_bmi_page.dart';

class AddBodyMassIndexPage extends ConsumerWidget {
  final String? navFromPage;
  final bool? isHome;
  const AddBodyMassIndexPage({Key? key,this.navFromPage,this.isHome=false}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint("Device Height 19 @@ ${deviceHeight(context)}");
    final curPastAsync = ref.watch(currentAndPastProvider);

    return Scaffold(
      appBar: AppBar(
          title: Center(child: const Text('Add Body Mass Index')),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(isHome!?24:0),
            ),
          ),
          leading: isHome!? ProfileAvatar():GestureDetector(
            onTap: () {
              if(navFromPage == NavPageType.home.name || navFromPage == null){
                AppRouter.replaceWithHome(context);
              }else{
                Navigator.pop(context);
              }

            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image.asset("lib/assets/Frame.png"),
            ),
          ),
          backgroundColor: AppTheme.primaryColor,
        actions: [
          isHome!?Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: NotificationBadgeIcon(),
          ):actionMenuItemResponse(
            context,
            onOpened: () {
              debugPrint('Menu opened');
            },
            onCanceled: () {
              debugPrint('Menu dismissed (outside tap)');
              // ❗ stop API calls here if needed
            },
            onSelected: (result) {
              debugPrint('Selected: $result');
              if (result == ActionMenuResult.goHome) {
                AppRouter.navigateToHome(context);
              }
            },
          ),
        ],
      ),
      body: curPastAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) {
            final isOnline = ref.watch(isOnlineProvider);

            return !isOnline
                ? ConnectionUnavailable(
              title: HeartThriveStrings.offlineTitle,
              description: HeartThriveStrings.offlineMessage,
              buttonText: "Retry",
              onRetry: () {
                ref.invalidate(userDetailsDataProvider);
                ref.invalidate(currentAndPastProvider);
              },
            )
                : ConnectionUnavailable(
              title: HeartThriveStrings.userServerIssueTitle,
              description: HeartThriveStrings.userServerIssueDescription,
              buttonText: "Retry",
              onRetry: () {
                ref.invalidate(userDetailsDataProvider);
                ref.invalidate(currentAndPastProvider);
              },
            );
          },
        data: (data) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: deviceWidth(context) > 750 ? 450: deviceHeight(context) > 640 ? 380:290,
                child: BMICalculatorScreen(),
              ),
              deviceHeight(context) > 640 ?const SizedBox(height: 15):const SizedBox(height: 10),
               Text('History (Past 30 days)', style:deviceWidth(context) > 750 ? AppTheme.title20: deviceWidth(context) > 360?AppTheme.title18:AppTheme.title16),
              deviceHeight(context) > 640 ?const SizedBox(height: 15):const SizedBox(height: 10),
              Expanded(
                child: data.history.isEmpty
                    ? const Center(child: Text("No history yet"))
                    : ListView.builder(
                  itemCount: data.history.length,
                  itemBuilder: (_, i) {
                    final item = data.history[i];
                    final category = getBMICategory(item.bmiValue);
                    return _buildHistoryItem(
                      date: DateFormatUtil.displayFormatDateBMI(item.recordedAt),
                      category: item.bmiStatus,
                      bmi: item.bmiValue.toStringAsFixed(1),
                      weight: item.weight,
                      height: item.height,
                      color: getCategoryColor(category).withAlpha(50),
                      borderColor: getCategoryColor(category),
                      context: context
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem({
    required String date,
    required String category,
    required String bmi,
    required String weight,
    required String height,
    required Color color,
    required Color borderColor,
    required BuildContext context
  }) {
    return deviceHeight(context) > 640 ? Container(

      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: borderColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date, style:  TextStyle(fontSize: deviceWidth(context) > 750 ? 18:12, color: Colors.black54)),
              Text(category, style:  TextStyle(fontSize: deviceWidth(context) > 750 ? 18:12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text('$category ($bmi)', style: TextStyle(fontSize: deviceWidth(context) > 750 ? 22:16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Weight: $weight', style: TextStyle(fontSize: 18, color: Colors.black54)),
              const SizedBox(width: 16),
              Text('Height: $height', style: TextStyle(fontSize: 18, color: Colors.black54)),
            ],
          ),
        ],
      ),
    ):Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10), // reduced padding
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: borderColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                category,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),

          Text(
            '$category ($bmi)',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),

          Row(
            children: [
              Text(
                'Weight: $weight',
                style: const TextStyle(fontSize: 10, color: Colors.black54),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 10),
              Text(
                'Height: $height',
                style: const TextStyle(fontSize: 10, color: Colors.black54),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );

  }
}