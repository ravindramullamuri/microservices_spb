import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/ui_constants.dart';
import '../providers/bmi/notification_provider.dart';
import '../routes/app_router.dart';
import '../theme/app_theme.dart';

class NotificationBadgeIcon extends ConsumerWidget {
  final Color iconColor;
  final double iconSize;

  const NotificationBadgeIcon({
    super.key,
    this.iconColor = Colors.white,
    this.iconSize = 30,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unseenCount = ref.watch(notificationProvider).unseenCount;

    return GestureDetector(
      onTap: () {
        AppRouter.navigateToProfileNotificattion(context);

      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main Notification Icon
          Image.asset(
            "lib/assets/notification_bell_icon.png",
            height: deviceWidth(context)>830?46:40,
            width: deviceWidth(context)>830?46:40,
          ),

          // Badge
          if (unseenCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Center(
                  child: Text(
                    unseenCount > 99 ? "99+" : unseenCount.toString(),
                    style:  AppTheme.title16.copyWith(
                      color: Colors.white,
                      fontSize: deviceWidth(context)>830?14:10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
