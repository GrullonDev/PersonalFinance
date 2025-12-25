import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:personal_finance/features/alerts/presentation/providers/alerts_provider.dart';
import 'package:personal_finance/features/auth/domain/auth_repository.dart';
import 'package:personal_finance/features/auth/presentation/providers/auth_provider.dart';
import 'package:personal_finance/features/budgets/domain/repositories/budget_repository.dart';
import 'package:personal_finance/features/categories/domain/repositories/category_repository.dart';
import 'package:personal_finance/features/categories/presentation/providers/categories_provider.dart';
import 'package:personal_finance/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_finance/features/navigation/navigation_provider.dart';
import 'package:personal_finance/features/settings/presentation/providers/settings_provider.dart';
import 'package:personal_finance/features/tips/tip_provider.dart';
import 'package:personal_finance/features/transactions/domain/repositories/transaction_backend_repository.dart'
    as tx_backend;
import 'package:personal_finance/features/dashboard/presentation/providers/dashboard_logic.dart';
import 'package:personal_finance/utils/app_localization.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:personal_finance/utils/routes/route_path.dart';
import 'package:personal_finance/utils/routes/route_switch.dart';
import 'package:personal_finance/utils/theme.dart';
import 'package:personal_finance/utils/widgets/app_lifecycle_listener.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: <SingleChildWidget>[
      Provider<AuthRepository>(create: (_) => getIt<AuthRepository>()),
      Provider<CategoryRepository>(create: (_) => getIt<CategoryRepository>()),
      Provider<BudgetRepository>(create: (_) => getIt<BudgetRepository>()),
      Provider<GoalRepository>(create: (_) => getIt<GoalRepository>()),
      Provider<tx_backend.TransactionBackendRepository>(
        create: (_) => getIt<tx_backend.TransactionBackendRepository>(),
      ),
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(authRepository: getIt<AuthRepository>()),
      ),
      ChangeNotifierProvider<DashboardLogic>(create: (_) => DashboardLogic()),
      ChangeNotifierProvider<TipProvider>(create: (_) => TipProvider()),
      ChangeNotifierProvider<AlertsProvider>(create: (_) => AlertsProvider()),
      // Global providers still used across screens
      ChangeNotifierProvider<CategoriesProvider>(
        create:
            (_) => CategoriesProvider(repository: getIt<CategoryRepository>()),
      ),
      ChangeNotifierProvider<NavigationProvider>(
        create: (_) => NavigationProvider(),
      ),
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(),
      ),
    ],
    child: Consumer2<AuthProvider, SettingsProvider>(
      builder:
          (
            BuildContext context,
            AuthProvider authProvider,
            SettingsProvider settingsProvider,
            _,
          ) => AppLifecycleWrapper(
            child: MaterialApp(
              themeMode: settingsProvider.themeMode,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              onGenerateTitle:
                  (BuildContext context) =>
                      AppLocalizations.of(context)!.appTitle,
              debugShowCheckedModeBanner: false,
              // Global builder to clamp text scale (prevents layout overflow)
              builder: (BuildContext context, Widget? child) {
                final MediaQueryData mq = MediaQuery.of(context);
                final double clamped = mq.textScaler.scale(1).clamp(0.9, 1.2);
                return MediaQuery(
                  data: mq.copyWith(textScaler: TextScaler.linear(clamped)),
                  child: child ?? const SizedBox.shrink(),
                );
              },
              initialRoute: RoutePath.splash,
              onGenerateRoute: RouteSwitch.generateRoute,
              localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const <Locale>[
                Locale('es', 'GT'),
                Locale('es', 'MX'),
                Locale('en', 'US'),
              ],
              locale: WidgetsBinding.instance.platformDispatcher.locale,
            ),
          ),
    ),
  );
}
