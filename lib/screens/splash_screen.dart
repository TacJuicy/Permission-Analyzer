import 'package:flutter/material.dart';
import 'dart:async';
import '../screens/home_screen.dart';
import '../theme/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image(
                image: AssetImage('res/logo.png'),
                height: 400,
                width: 400,
            ),
            SizedBox(
              height: 100,
            ),
            CircularProgressIndicator(
                backgroundColor: AppColors.secondary,
            )
          ],
        ),
      ),
    );
  }
}
