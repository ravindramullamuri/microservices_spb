import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import '../../components/profile_avatar.dart';
import '../../providers/user/user_details_provider.dart';
import '../../theme/app_theme.dart';
import '../notification_badgeicon_widget.dart';


class SubscriptionExpiredOverlay extends ConsumerWidget {
  const SubscriptionExpiredOverlay({super.key});

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final userDetailsAsync = ref.watch(userDetailsDataProvider);
    return Scaffold(
     // backgroundColor: Colors.transparent,
     appBar: userDetailsAsync.when(
         data: (user){
           return AppBar(
             backgroundColor: AppTheme.primaryColor,
             elevation: 0,
             shape: const RoundedRectangleBorder(
               borderRadius: BorderRadius.vertical(
                 bottom: Radius.circular(24),
               ),
             ),
             leading: userProfileAvatar(
               context: context,
               user: user,
               isNavigate: true,
             ),
             title: Container(
               alignment: Alignment.centerLeft,
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     user?.firstname?.isEmpty ?? true
                         ? "Hi User! 👋"
                         : "Hi, ${user!.firstname} ${user!.lastname}! 👋",
                     style: AppTheme.title18.copyWith(
                       fontWeight: FontWeight.bold,
                       color: Colors.white,
                     ),
                   ),
                   Text(
                     _getGreeting(),
                     style: const TextStyle(
                       fontSize: 14,
                       color: Colors.white,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                 ],
               ),
             ),
             actions: [
               Padding(
                 padding: EdgeInsets.only(right: 16.0),
                 child: NotificationBadgeIcon(),
               ),
             ],
           );
         },
         error: (e,s){
          return AppBar();
         },
         loading: (){

         }),
      body: Positioned.fill(
        child: AbsorbPointer(
          absorbing: true, // blocks clicks behind
          child: Container(
            height: deviceHeight(context),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFFFF), // pure white (top)
                  Color(0xFFFFF6D8), // very light warm yellow
                  Color(0xFFFFE6A6), // soft golden yellow
                ],
                stops: [
                  0.5,
                  0.65,
                  1.0,
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.all(8.0),
                  child: Image.asset(
                    "lib/assets/subscribe/Splash-Screen-Img.png",
                    height: 200,
                  ),
                ),
                _buildBottomCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // Build

  Widget _buildBottomCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(30, 20, 20, 30),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            "Unlock Heart-Healthy Care",
            style: AppTheme.title16.copyWith(
              color: Colors.black,
              fontSize: deviceWidth(context) > 400?28:24,
              fontWeight: FontWeight.bold,
            ),
          ),
           SizedBox(height: deviceWidth(context)> 400?24:40),
          //Get full access to smart heart tools.
           Text(
            "Get full access to smart heart tools.",
            style: AppTheme.title16.copyWith(
             // color: Colors.white,
              fontSize: 18
            ),
          ),
          const SizedBox(height: 12),
          _feature("Track sodium intake"),
          _feature("Medicine reminders"),
          _feature("Body weight alerts"),
          _feature("Heart health tips"),
          _feature("Low-sodium recipes"),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: Colors.white,
                    width: 2
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              onPressed: () {
                //AppRouter.navigateToSubscription(context);
              },
              child:  Text(
                "Subscribe Now",
                style: TextStyle(
                  fontSize: deviceWidth(context) > 400?20:18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _feature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check, size: 25,fontWeight: FontWeight.bold),
          const SizedBox(width: 10),
          Text(
            text,
            style: AppTheme.title16.copyWith(
            //  color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "Good Morning!";
    if (hour >= 12 && hour < 17) return "Good Afternoon!";
    if (hour >= 17 && hour < 21) return "Good Evening!";
    return "Good Night!";
  }
}
