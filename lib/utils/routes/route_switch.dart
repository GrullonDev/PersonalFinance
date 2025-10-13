import 'package:flutter/material.dart';

import 'package:personal_finance/features/auth/pages/auth_page.dart';
import 'package:personal_finance/features/auth/pages/register_page.dart';
import 'package:personal_finance/features/home/pages/home_page.dart';
import 'package:personal_finance/features/onboarding/pages/onboarding_page.dart';
import 'package:personal_finance/features/settings/pages/settings_page.dart';
import 'package:personal_finance/features/splash/splash_screen.dart';
import 'package:personal_finance/utils/routes/route_path.dart';

class RouteSwitch {
  static Route<dynamic> generateRoute(final RouteSettings settings) {
    switch (settings.name) {
      case RoutePath.splash:
        return MaterialPageRoute(
          builder: (BuildContext _) => const SplashScreen(),
        );
      case RoutePath.dashboard:
        return MaterialPageRoute(builder: (BuildContext _) => const HomePage());
      case RoutePath.onboarding:
        return MaterialPageRoute(
          builder: (BuildContext _) => const OnboardingPage(),
        );
      case RoutePath.login:
        return MaterialPageRoute(
          builder: (BuildContext _) => const LoginPage(),
        );
      case RoutePath.register:
        return MaterialPageRoute(
          builder: (BuildContext _) => const RegisterPage(),
        );
      case RoutePath.settings:
        return MaterialPageRoute(
          builder: (BuildContext _) => const SettingsPage(),
        );
      default:
        return MaterialPageRoute(
          builder:
              (BuildContext _) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
        );
    }
  }
}
