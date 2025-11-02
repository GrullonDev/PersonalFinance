import 'package:flutter/material.dart';

import 'package:personal_finance/features/auth/presentation/pages/auth_page.dart';
import 'package:personal_finance/features/auth/presentation/pages/register_page.dart';
import 'package:personal_finance/features/goals/presentation/pages/goals_page.dart';
import 'package:personal_finance/features/home/pages/home_page.dart';
import 'package:personal_finance/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:personal_finance/features/settings/presentation/pages/settings_page.dart';
import 'package:personal_finance/features/splash/splash_screen.dart';
import 'package:personal_finance/utils/routes/route_path.dart';

class RouteSwitch {
  static Route<dynamic> generateRoute(final RouteSettings settings) {
    switch (settings.name) {
      case RoutePath.splash:
        return MaterialPageRoute<void>(
          builder: (BuildContext context) => const SplashScreen(),
        );
      case RoutePath.dashboard:
        return MaterialPageRoute<void>(
          builder: (BuildContext context) => const HomePage(),
        );
      case RoutePath.onboarding:
        return MaterialPageRoute<void>(
          builder: (BuildContext context) => const OnboardingPage(),
        );
      case RoutePath.login:
        return MaterialPageRoute<void>(
          builder: (BuildContext context) => const LoginPage(),
        );
      case RoutePath.register:
        return MaterialPageRoute<void>(
          builder: (BuildContext context) => const RegisterPage(),
        );
      case RoutePath.settings:
        return MaterialPageRoute<void>(
          builder: (BuildContext context) => const SettingsPage(),
        );
      case RoutePath.goals:
        return MaterialPageRoute<void>(
          builder: (BuildContext context) => const GoalsPage(),
        );
      default:
        return MaterialPageRoute<void>(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
