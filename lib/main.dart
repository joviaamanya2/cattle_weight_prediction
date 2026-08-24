import 'package:flutter/material.dart';

import 'screens/auth_screen.dart';
import 'screens/prediction_home_page.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const AnimalWeightApp());
}

class AnimalWeightApp extends StatelessWidget {
  const AnimalWeightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cattle Weight By Jaguza',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const SplashScreen(),
      routes: {
        '/auth': (_) => const LoginScreen(),
        '/dashboard': (_) => const PredictionHomePage(),
        '/signup': (_) => const SignUpScreen(),
      },
    );
  }
}
