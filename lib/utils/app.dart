import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';

import 'package:personal_finance/features/auth/domain/auth_repository.dart';
import 'package:personal_finance/features/auth/logic/auth_provider.dart';
import 'package:personal_finance/features/dashboard/logic/dashboard_logic.dart';
import 'package:personal_finance/utils/app_localization.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:personal_finance/utils/routes/route_path.dart';
import 'package:personal_finance/utils/routes/route_switch.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        Provider<AuthRepository>(create: (_) => getIt<AuthRepository>()),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authRepository: getIt<AuthRepository>()),
        ),
        ChangeNotifierProvider<DashboardLogic>(create: (_) => DashboardLogic()),
      ],
      child: MaterialApp(
        title: 'Finanzas Personales',
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        initialRoute: RoutePath.home,
        onGenerateRoute: RouteSwitch.generateRoute,
        localizationsDelegates: const <LocalizationsDelegate>[
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
        locale: const Locale('es', 'GT'),
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      textTheme: GoogleFonts.manropeTextTheme(),
      scaffoldBackgroundColor: const Color(0xFFF6F6F6),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
    );
  }
}
