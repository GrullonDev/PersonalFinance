import 'package:flutter/material.dart';

class FinanceColors extends ThemeExtension<FinanceColors> {
  const FinanceColors({
    required this.income,
    required this.expense,
    required this.savings,
    required this.info,
  });

  final Color income; // positive amounts
  final Color expense; // negative amounts
  final Color savings; // cards/backgrounds
  final Color info; // accents

  @override
  FinanceColors copyWith({
    Color? income,
    Color? expense,
    Color? savings,
    Color? info,
  }) => FinanceColors(
        income: income ?? this.income,
        expense: expense ?? this.expense,
        savings: savings ?? this.savings,
        info: info ?? this.info,
      );

  @override
  ThemeExtension<FinanceColors> lerp(
    covariant ThemeExtension<FinanceColors>? other,
    double t,
  ) {
    if (other is! FinanceColors) return this;
    return FinanceColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      savings: Color.lerp(savings, other.savings, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

class AppTheme {
  static ThemeData light() {
    // Finance‑oriented palette: green primary with blue accents
    final ColorScheme base = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0E8F5B), // emerald/finance green
      brightness: Brightness.light,
    );
    final ColorScheme scheme = base.copyWith(
      secondary: const Color(0xFF1565C0), // blue accent
      tertiary: const Color(0xFF2E7D32), // strong green
      error: const Color(0xFFD32F2F),
    );
    return ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF7F7FA),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: scheme.onSurface,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
      ),
      textTheme: Typography.blackCupertino.apply(
        bodyColor: const Color(0xFF1B1B1F),
        displayColor: const Color(0xFF1B1B1F),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      extensions: <ThemeExtension<dynamic>>[
        const FinanceColors(
          income: Color(0xFF1E8E3E),
          expense: Color(0xFFD32F2F),
          savings: Color(0xFFE8F5E9),
          info: Color(0xFF1565C0),
        ),
      ],
    );
  }

  static ThemeData dark() {
    final ColorScheme base = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0E8F5B),
      brightness: Brightness.dark,
    );
    final ColorScheme scheme = base.copyWith(
      secondary: const Color(0xFF90CAF9),
      tertiary: const Color(0xFF81C784),
      error: const Color(0xFFEF5350),
    );
    return ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      colorScheme: scheme,
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      extensions: const <ThemeExtension<dynamic>>[
        FinanceColors(
          income: Color(0xFF81C784),
          expense: Color(0xFFEF9A9A),
          savings: Color(0xFF1B2A1F),
          info: Color(0xFF90CAF9),
        ),
      ],
    );
  }
}
