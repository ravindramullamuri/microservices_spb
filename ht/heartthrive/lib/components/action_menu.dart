import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';
import '../routes/app_router.dart';


Widget actionMenuItem(BuildContext context){
  return  PopupMenuButton<String>(
    icon: const Icon(Icons.more_vert),
    offset: const Offset(0, 50),
    onSelected: (String value) {
      if (value == 'home') {
        AppRouter.navigateToHome(context);
      }
    },
    itemBuilder: (BuildContext context) => [
      PopupMenuItem<String>(
        value: 'home',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Go To Home',style: TextStyle(fontSize:deviceWidth(context) > 750 ? 20 : 14),),
            SizedBox(width: 8),
            Image.asset('lib/assets/Home.png',height: deviceWidth(context) > 750 ? 25 :20,width: deviceWidth(context) > 750 ? 25 :20,),
          ],
        ),
      ),
    ],
  );
}
Widget actionMenuItemResponse(
    BuildContext context, {
      required void Function(ActionMenuResult result) onSelected,
      VoidCallback? onOpened,
      VoidCallback? onCanceled,
    }) {
  return PopupMenuButton<ActionMenuResult>(
    icon: const Icon(Icons.more_vert),
    offset: const Offset(0, 50),

    onOpened: () {
      if (onOpened != null) onOpened();
    },

    onCanceled: () {
      if (onCanceled != null) onCanceled();
    },

    onSelected: (result) {
      onSelected(result);
    },

    itemBuilder: (context) => const [
      PopupMenuItem<ActionMenuResult>(
        value: ActionMenuResult.goHome,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Go To Home'),
            SizedBox(width: 8),
            Icon(Icons.home),
          ],
        ),
      ),
    ],
  );
}

enum ActionMenuResult { goHome }


class Toast {
  static void show(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}
