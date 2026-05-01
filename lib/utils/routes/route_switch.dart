import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:personal_finance/features/auth/presentation/pages/auth_page.dart';
import 'package:personal_finance/features/auth/presentation/pages/register_page.dart';
import 'package:personal_finance/features/budgets/presentation/pages/budgets_crud_page.dart';
import 'package:personal_finance/features/categories/presentation/pages/categories_page.dart';
import 'package:personal_finance/features/goals/presentation/pages/goals_crud_page.dart';
import 'package:personal_finance/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:personal_finance/features/quick_finance/presentation/bloc/quick_finance_bloc.dart';
import 'package:personal_finance/features/quick_finance/presentation/pages/quick_finance_home_page.dart';
import 'package:personal_finance/features/settings/presentation/pages/settings_page.dart';
import 'package:personal_finance/features/splash/splash_screen.dart';
import 'package:personal_finance/features/transactions/presentation/pages/transactions_crud_page.dart';
import 'package:personal_finance/utils/routes/route_path.dart';

class RouteSwitch {
  static Route<dynamic> generateRoute(final RouteSettings settings) {
    switch (settings.name) {
      case RoutePath.home:
      case RoutePath.splash:
        return MaterialPageRoute<void>(
          builder: (BuildContext context) => const SplashScreen(),
        );
      case RoutePath.dashboard:
        // MVP iOS v1: la home post-login es la experiencia QuickFinance.
        // Envolvemos en BlocProvider aquí (no en MyApp) para que el Bloc se
        // reconstruya en cada login/logout y no conserve estado del usuario
        // anterior.
        return MaterialPageRoute<void>(
          builder: (BuildContext context) => BlocProvider<QuickFinanceBloc>(
            create: (_) => GetIt.instance<QuickFinanceBloc>(),
            child: const QuickFinanceHomePage(),
          ),
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
          builder: (BuildContext context) => const GoalsCrudPage(),
        );
      case RoutePath.categories:
        return MaterialPageRoute<void>(
          builder: (BuildContext context) => const CategoriesPage(),
        );
      case RoutePath.budgetsCrud:
        return MaterialPageRoute<void>(
          builder: (BuildContext context) => const BudgetsCrudPage(),
        );
      case RoutePath.goalsCrud:
        return MaterialPageRoute<void>(
          builder: (BuildContext context) => const GoalsCrudPage(),
        );
      case RoutePath.transactionsCrud:
        return MaterialPageRoute<void>(
          builder: (BuildContext context) => const TransactionsCrudPage(),
        );
      default:
        return MaterialPageRoute<void>(
          builder:
              (BuildContext context) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
        );
    }
  }
}
