import 'package:flutter/material.dart';

class AppTheme {
  // Premium/Neon Palette
  static const Color _seedColor = Color(0xFF6C63FF); // Electric Violet
  static const Color _primaryLight = Color(0xFF6C63FF);
  static const Color _primaryDark = Color(0xFF8B80F9);

  static const Color _bgLight = Color(0xFFF0F2F5);
  static const Color _bgDark = Color(0xFF0F111A); // Deep Midnight Blue

  static const Color _surfaceLight = Colors.white;
  static const Color _surfaceDark = Color(0xFF1E2130);

  static const Color _success = Color(0xFF00E676); // Neon Green
  static const Color _error = Color(0xFFFF2D55); // Neon Red

  static ThemeData dark() {
    final ColorScheme base = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
    final ColorScheme scheme = base.copyWith(
      primary: _primaryDark,
      secondary: const Color(0xFF03DAC6),
      surface: _surfaceDark,
      error: _error,
      // background: _bgDark,
    );
    return _buildTheme(scheme, _bgDark);
  }

  static ThemeData light() {
    final ColorScheme base = ColorScheme.fromSeed(seedColor: _seedColor);
    final ColorScheme scheme = base.copyWith(
      primary: _primaryLight,
      secondary: const Color(0xFF03DAC6),
      surface: _surfaceLight,
      error: _error,
      // background: _bgLight,
    );
    return _buildTheme(scheme, _bgLight);
  }

  static ThemeData _buildTheme(ColorScheme scheme, Color scaffoldBg) {
    final bool isDark = scheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      fontFamily: 'Roboto', // Or 'Inter' if added to pubspec

      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: scheme.onSurface,
          letterSpacing: 0.5,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      textTheme: Typography.material2021(platform: TargetPlatform.iOS)
          .englishLike
          .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2F40) : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: scheme.onSurface.withOpacity(0.6)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: scheme.primary.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0, // We will use custom shadows or glass effects
        color: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurface.withOpacity(0.4),
        backgroundColor: isDark ? const Color(0xFF1E2130) : Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outline.withOpacity(0.1),
        thickness: 1,
      ),

      extensions: <ThemeExtension<dynamic>>[
        FinanceColors(
          income: _success,
          expense: _error,
          savings: isDark ? const Color(0xFF1B2A1F) : const Color(0xFFE8F5E9),
          info: const Color(0xFF2196F3),
          glassBackground:
              isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.7),
          glassBorder:
              isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.2),
        ),
      ],
    );
  }
}

class FinanceColors extends ThemeExtension<FinanceColors> {
  final Color income; // positive amounts

  final Color expense; // negative amounts
  final Color savings; // cards/backgrounds
  final Color info; // accents
  final Color glassBackground;
  final Color glassBorder;
  const FinanceColors({
    required this.income,
    required this.expense,
    required this.savings,
    required this.info,
    required this.glassBackground, // New for glassmorphism
    required this.glassBorder, // New for glassmorphism
  });

  @override
  FinanceColors copyWith({
    Color? income,
    Color? expense,
    Color? savings,
    Color? info,
    Color? glassBackground,
    Color? glassBorder,
  }) => FinanceColors(
    income: income ?? this.income,
    expense: expense ?? this.expense,
    savings: savings ?? this.savings,
    info: info ?? this.info,
    glassBackground: glassBackground ?? this.glassBackground,
    glassBorder: glassBorder ?? this.glassBorder,
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
      glassBackground: Color.lerp(glassBackground, other.glassBackground, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
    );
  }
}
