import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/models/home/user_model.dart';
import 'package:heart_thrive/models/userdetails.dart';
import 'package:heart_thrive/providers/user/user_details_provider.dart';
import 'package:heart_thrive/routes/app_router.dart';

Widget userProfileAvatar({required BuildContext context, UserDetails? user, bool? isNavigate}) {
  //debugPrint("userProfileAvatar @@ ${user!.profileImage!}");
  return InkWell(
    onTap: (){
      if(isNavigate!){
        AppRouter.navigateToProfile(context);
      }

    },
    child: Padding(
      padding: const EdgeInsets.only(left: 15, top: 8, bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: user?.profileImage == null
            ? Image.asset(
                'lib/assets/default_profile_img.png',
                gaplessPlayback: true,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              )
            : Image.memory(
                base64Decode(user!.profileImage!),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                width: 36,
                height: 36,
                errorBuilder: (context, error, stack) =>
                    const Icon(Icons.account_circle, color: Colors.white),
              ),
      ),
    ),
  );
}
class ProfileAvatar extends ConsumerWidget{
  const ProfileAvatar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDetails = ref.watch(userDetailsDataProvider);
    return userDetails.when(
        data: (user){
          return userProfileAvatar(context: context,user: user,isNavigate: true);
        },
        error: (e,n){
          return userProfileAvatar(context: context,user: null,isNavigate: true);
        },
        loading: (){
          return userProfileAvatar(context: context,user: null,isNavigate: true);
        });
  }

}
