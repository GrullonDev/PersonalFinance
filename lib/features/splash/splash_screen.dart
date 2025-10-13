import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    await Future<void>.delayed(const Duration(seconds: 2));

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool onboardingComplete =
        prefs.getBool('onboarding_complete') ?? false;

    if (mounted) {
      if (onboardingComplete) {
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.blue,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              size: 64,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Personal Finance',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tu compañero financiero',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    ),
  );
}
