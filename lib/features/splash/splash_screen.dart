import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';

import 'package:personal_finance/core/security/security_preferences.dart';
import 'package:provider/provider.dart';

import 'package:personal_finance/features/auth/presentation/providers/auth_provider.dart';
import 'package:personal_finance/utils/routes/route_path.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final bool onboardingComplete =
        await SecurityPreferences.getOnboardingComplete();

    if (mounted) {
      if (onboardingComplete) {
        final AuthProvider auth = context.read<AuthProvider>();
        await firebase_auth.FirebaseAuth.instance.authStateChanges().first;
        await auth.syncSessionFromFirebase(notify: false);
        if (auth.isAuthenticated) {
          await auth.loadCurrentUser();
          if (!mounted) return;
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(RoutePath.dashboard, (_) => false);
        } else {
          if (!mounted) return;
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(RoutePath.login, (_) => false);
        }
      } else {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(RoutePath.onboarding, (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).colorScheme.primary,
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
            child: Image.asset(
              'assets/logo.png',
              width: 72,
              height: 72,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Personal Finance',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tu compañero financiero',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    ),
  );
}
