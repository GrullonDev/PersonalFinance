import 'package:flutter/material.dart';

import 'package:personal_finance/features/auth/pages/auth_page.dart';
import 'package:personal_finance/features/dashboard/page/dashboard_page.dart';
import 'package:personal_finance/features/dashboard/widgets/add_expense_modal.dart';
import 'package:personal_finance/features/home.dart';
import 'package:personal_finance/utils/routes/route_path.dart';

class RouteSwitch {
  static Route<dynamic> generateRoute(final RouteSettings settings) {
    switch (settings.name) {
      case RoutePath.home:
        return MaterialPageRoute(builder: (BuildContext _) => const MyHomePage());
      case RoutePath.dashboard:
        return MaterialPageRoute(builder: (BuildContext _) => const DashboardPage());
      case RoutePath.addExpense:
        return MaterialPageRoute(builder: (BuildContext _) => const AddExpenseModal());
      case RoutePath.login:
        return MaterialPageRoute(builder: (BuildContext _) => const LoginPage());
      default:
        return MaterialPageRoute(
          builder: (BuildContext _) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
