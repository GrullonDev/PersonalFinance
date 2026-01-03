import 'package:flutter/material.dart';

/// Constantes de la aplicación
/// Centraliza todos los valores constantes para mejor mantenimiento
class AppConstants {
  // Constructor privado para evitar instanciación
  AppConstants._();

  // ===== CONSTANTES DE LA APLICACIÓN =====
  static const String appName = 'Personal Finance';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Aplicación de finanzas personales';

  // ===== CONSTANTES DE BASE DE DATOS =====
  static const String expenseBoxName = 'expenses';
  static const String incomeBoxName = 'incomes';
  static const String settingsBoxName = 'settings';

  // ===== CONSTANTES DE UI =====
  static const double defaultPadding = 16;
  static const double smallPadding = 8;
  static const double largePadding = 24;
  static const double defaultRadius = 12;
  static const double cardRadius = 16;
  static const double buttonRadius = 8;

  // ===== CONSTANTES DE ANIMACIÓN =====
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // ===== CONSTANTES DE VALIDACIÓN =====
  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 500;
  static const double minAmount = 0.01;
  static const double maxAmount = 999999.99;

  // ===== CONSTANTES DE CATEGORÍAS =====
  static const List<String> expenseCategories = <String>[
    'Alimentación',
    'Transporte',
    'Hogar',
    'Entretenimiento',
    'Compras',
    'Salud',
    'Educación',
    'Otros',
  ];

  static const List<String> incomeSources = <String>[
    'Salario',
    'Freelance',
    'Inversiones',
    'Negocio',
    'Regalo',
    'Otros',
  ];

  // ===== CONSTANTES DE COLORES =====
  // Finance palette aligned with Theme (see AppTheme)
  static const Color primaryColor = Color(0xFF0E8F5B); // Emerald
  static const Color secondaryColor = Color(0xFF2E7D32); // Strong green
  static const Color accentColor = Color(0xFF1565C0); // Blue accent
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color warningColor = Color(0xFFFFB300);
  static const Color successColor = Color(0xFF1E8E3E);
  static const Color infoColor = Color(0xFF1565C0);

  // ===== MAPA DE COLORES POR CATEGORÍA =====
  static const Map<String, Color> categoryColors = <String, Color>{
    'Alimentación': Color(0xFFFFA726),
    'Transporte': Color(0xFF1565C0),
    'Hogar': Color(0xFF7E57C2),
    'Entretenimiento': Color(0xFFEC407A),
    'Compras': Color(0xFF00897B),
    'Salud': Color(0xFFD32F2F),
    'Educación': Color(0xFF3949AB),
    'Otros': Color(0xFF9E9E9E),
  };

  // ===== MAPA DE COLORES POR FUENTE DE INGRESO =====
  static const Map<String, Color> sourceColors = <String, Color>{
    'Salario': Color(0xFF1E8E3E),
    'Freelance': Color(0xFF1565C0),
    'Inversiones': Color(0xFFFFA726),
    'Negocio': Color(0xFF7E57C2),
    'Regalo': Color(0xFFEC407A),
    'Otros': Color(0xFF9E9E9E),
  };

  // ===== CONSTANTES DE FORMATO =====
  /// @deprecated Use AppLocalizations.of(context).currencySymbol instead
  /// Este símbolo es solo para compatibilidad. Usa el locale del dispositivo.
  static const String currencySymbol = '\$';
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // ===== CONSTANTES DE PERÍODOS =====
  static const List<String> periodNames = <String>[
    'Día',
    'Semana',
    'Mes',
    'Año',
  ];

  // ===== CONSTANTES DE LÍMITES =====
  static const int maxTransactionsToShow = 5;
  static const int maxChartItems = 8;
  static const int maxRecentTransactions = 10;

  // ===== CONSTANTES DE CACHE =====
  static const Duration cacheExpiration = Duration(hours: 1);
  static const int maxCacheSize = 100;

  // ===== CONSTANTES DE RED =====
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  // ===== MÉTODOS DE UTILIDAD =====

  /// Obtiene el color para una categoría
  static Color getCategoryColor(String category) =>
      categoryColors[category] ?? Colors.grey;

  /// Obtiene el color para una fuente de ingreso
  static Color getSourceColor(String source) =>
      sourceColors[source] ?? Colors.green;

  /// Valida si un monto es válido
  static bool isValidAmount(double amount) =>
      amount >= minAmount && amount <= maxAmount;

  /// Valida si un título es válido
  static bool isValidTitle(String title) =>
      title.isNotEmpty && title.length <= maxTitleLength;

  /// Formatea un monto como moneda
  /// @deprecated Use AppLocalizations.of(context).formatCurrency(amount) instead
  /// Este método usa un símbolo hardcodeado. Prefiere usar el locale del dispositivo.
  static String formatCurrency(double amount) =>
      '$currencySymbol${amount.toStringAsFixed(2)}';

  /// Obtiene el nombre del período
  static String getPeriodName(int index) {
    if (index >= 0 && index < periodNames.length) {
      return periodNames[index];
    }
    return 'Desconocido';
  }
}
