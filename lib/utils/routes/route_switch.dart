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
import 'package:personal_finance/features/update/pages/force_update_page.dart';
import 'package:personal_finance/features/debts/presentation/pages/debts_page.dart';
import 'package:personal_finance/features/ai_chat/presentation/pages/ai_chat_page.dart';
import 'package:personal_finance/features/notifications/presentation/pages/notification_inbox_page.dart';
import 'package:personal_finance/utils/routes/route_path.dart';
import 'package:personal_finance/core/services/version_service.dart';
import 'package:personal_finance/utils/injection_container.dart';

class RouteSwitch {
  // Mapa de constructores de widgets por ruta. Para añadir una nueva ruta
  // basta con insertar una entrada aquí — sin tocar ningún otro lugar.
  static final Map<String, WidgetBuilder> _routes = {
    RoutePath.home: (_) => const SplashScreen(),
    RoutePath.splash: (_) => const SplashScreen(),
    RoutePath.onboarding: (_) => const OnboardingPage(),
    RoutePath.login: (_) => const LoginPage(),
    RoutePath.register: (_) => const RegisterPage(),
    RoutePath.settings: (_) => const SettingsPage(),
    RoutePath.goals: (_) => const GoalsCrudPage(),
    RoutePath.goalsCrud: (_) => const GoalsCrudPage(),
    RoutePath.categories: (_) => const CategoriesPage(),
    RoutePath.budgetsCrud: (_) => const BudgetsCrudPage(),
    RoutePath.transactionsCrud: (_) => const TransactionsCrudPage(),
    RoutePath.notificationsInbox: (_) => const NotificationInboxPage(),
    RoutePath.debts: (_) => const DebtsPage(),
    RoutePath.aiChat: (_) => const AiChatPage(),
    RoutePath.forceUpdate: (_) => ForceUpdatePage(
          storeUrl: getIt<VersionService>().storeUrl,
        ),
    // El dashboard recibe su propio BlocProvider para que el Bloc se
    // reconstruya en cada login/logout y no conserve estado del usuario anterior.
    RoutePath.dashboard: (_) => BlocProvider<QuickFinanceBloc>(
          create: (_) => GetIt.instance<QuickFinanceBloc>(),
          child: const QuickFinanceHomePage(),
        ),
  };

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final builder = _routes[settings.name];

    if (builder != null) {
      return MaterialPageRoute<void>(builder: builder, settings: settings);
    }

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => Scaffold(
        body: Center(
          child: Text('Ruta no definida: ${settings.name}'),
        ),
      ),
    );
  }
}
