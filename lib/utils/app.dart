import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:personal_finance/features/alerts/alerts_provider.dart';
import 'package:personal_finance/features/auth/domain/auth_repository.dart';
import 'package:personal_finance/features/auth/logic/auth_provider.dart';
import 'package:personal_finance/features/dashboard/logic/dashboard_logic.dart';
import 'package:personal_finance/features/navigation/navigation_provider.dart';
import 'package:personal_finance/features/tips/tip_provider.dart';
import 'package:personal_finance/utils/app_localization.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:personal_finance/utils/routes/route_path.dart';
import 'package:personal_finance/utils/routes/route_switch.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: <SingleChildWidget>[
      Provider<AuthRepository>(create: (_) => getIt<AuthRepository>()),
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(authRepository: getIt<AuthRepository>()),
      ),
      ChangeNotifierProvider<DashboardLogic>(create: (_) => DashboardLogic()),
      ChangeNotifierProvider<TipProvider>(create: (_) => TipProvider()),
      ChangeNotifierProvider<AlertsProvider>(create: (_) => AlertsProvider()),
      ChangeNotifierProvider<NavigationProvider>(
        create: (_) => NavigationProvider(),
      ),
    ],
    child: Consumer<AuthProvider>(
      builder: (BuildContext context, AuthProvider authProvider, _) => MaterialApp(
        themeMode: authProvider.themeMode,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
          ),
          // Configuraciones adicionales para mejor contraste en tema claro
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            labelStyle: const TextStyle(color: Colors.black54),
            hintStyle: const TextStyle(color: Colors.black38),
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.black87),
            bodyMedium: TextStyle(color: Colors.black87),
            bodySmall: TextStyle(color: Colors.black54),
            titleLarge: TextStyle(color: Colors.black87),
            titleMedium: TextStyle(color: Colors.black87),
            titleSmall: TextStyle(color: Colors.black87),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
          ),
        ),
        onGenerateTitle:
            (BuildContext context) => AppLocalizations.of(context)!.appTitle,
        debugShowCheckedModeBanner: false,
        initialRoute: RoutePath.login,
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
  );
}
