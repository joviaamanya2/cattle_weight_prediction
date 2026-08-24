import 'package:flutter/material.dart';

import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/prediction_home_page.dart';

void main() {
  runApp(const AnimalWeightApp());
}

class AnimalWeightApp extends StatelessWidget {
  const AnimalWeightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animal Weight Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/auth': (_) => const LoginScreen(),
        '/dashboard': (_) => const PredictionHomePage(),
      },
    );
  }
}
