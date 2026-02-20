// Splash Screen
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user/user_details_provider.dart';
import '../routes/app_router.dart';
import '../utils/secure_storage_utils.dart';

class SplashWrapper extends ConsumerStatefulWidget {
  const SplashWrapper({super.key});

  @override
  ConsumerState<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends ConsumerState<SplashWrapper> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = SecureStorageUtils();
    final token = await storage.read("auth_token");

    if (token != null) {
      ref.read(userDetailsDataProvider.notifier).loadUser(token: token);
    }

    // Wait 2 seconds for splash
    await Future.delayed(const Duration(seconds: 2),(){
      print("token ${token}");
      Navigator.pushReplacementNamed(
        context,
        token != null ? AppRouter.home : AppRouter.landing,
      );
    });
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      token != null ? AppRouter.home : AppRouter.landing,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}


class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.redAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              "Heart Thrive",
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
