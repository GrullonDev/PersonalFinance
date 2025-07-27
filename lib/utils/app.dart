import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:personal_finance/features/auth/domain/auth_repository.dart';
import 'package:personal_finance/features/auth/logic/auth_provider.dart';
import 'package:personal_finance/features/dashboard/logic/dashboard_logic.dart';
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
    ],
    child: MaterialApp(
      onGenerateTitle:
          (BuildContext context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      initialRoute: RoutePath.home,
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
  );

  ThemeData _buildLightTheme() => ThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF1A237E), // Azul oscuro
      onPrimary: Colors.white,
      secondary: Color(0xFF00BFA6), // Verde esmeralda
      onSecondary: Colors.white,
      error: Color(0xFFE53935),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF222B45),
    ),
    textTheme: GoogleFonts.manropeTextTheme().copyWith(
      bodyLarge: GoogleFonts.manrope(
        fontSize: 16,
        color: const Color(0xFF222B45),
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14,
        color: const Color(0xFF222B45),
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1A237E),
      ),
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1A237E),
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Color(0xFF1A237E),
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      iconTheme: IconThemeData(color: Color(0xFF1A237E)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.manrope(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );

  ThemeData _buildDarkTheme() => ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF1A237E),
      onPrimary: Colors.white,
      secondary: Color(0xFF00BFA6),
      onSecondary: Colors.white,
      error: Color(0xFFE53935),
      onError: Colors.white,
      surface: Color(0xFF23243B),
      onSurface: Color(0xFFF5F7FA),
    ),
    textTheme: GoogleFonts.manropeTextTheme(
      ThemeData.dark().textTheme,
    ).copyWith(
      bodyLarge: GoogleFonts.manrope(
        fontSize: 16,
        color: const Color(0xFFF5F7FA),
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14,
        color: const Color(0xFFF5F7FA),
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF00BFA6),
      ),
    ),
    scaffoldBackgroundColor: const Color(0xFF181A20),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF23243B),
      foregroundColor: Color(0xFF00BFA6),
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Color(0xFF00BFA6),
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      iconTheme: IconThemeData(color: Color(0xFF00BFA6)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00BFA6),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.manrope(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF23243B),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
