import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image(image: AssetImage('assets/images/splash_screen.png'), fit: BoxFit.cover),
        ],
      ),
    );
  }
}
