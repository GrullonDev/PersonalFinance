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
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultRadius = 12.0;
  static const double cardRadius = 16.0;
  static const double buttonRadius = 8.0;
  
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
  static const List<String> expenseCategories = [
    'Alimentación',
    'Transporte',
    'Hogar',
    'Entretenimiento',
    'Compras',
    'Salud',
    'Educación',
    'Otros',
  ];
  
  static const List<String> incomeSources = [
    'Salario',
    'Freelance',
    'Inversiones',
    'Negocio',
    'Regalo',
    'Otros',
  ];
  
  // ===== CONSTANTES DE COLORES =====
  static const Color primaryColor = Colors.blue;
  static const Color secondaryColor = Colors.green;
  static const Color accentColor = Colors.orange;
  static const Color errorColor = Colors.red;
  static const Color warningColor = Colors.amber;
  static const Color successColor = Colors.green;
  static const Color infoColor = Colors.blue;
  
  // ===== MAPA DE COLORES POR CATEGORÍA =====
  static const Map<String, Color> categoryColors = {
    'Alimentación': Colors.orange,
    'Transporte': Colors.blue,
    'Hogar': Colors.purple,
    'Entretenimiento': Colors.pink,
    'Compras': Colors.teal,
    'Salud': Colors.red,
    'Educación': Colors.indigo,
    'Otros': Colors.grey,
  };
  
  // ===== MAPA DE COLORES POR FUENTE DE INGRESO =====
  static const Map<String, Color> sourceColors = {
    'Salario': Colors.green,
    'Freelance': Colors.blue,
    'Inversiones': Colors.orange,
    'Negocio': Colors.purple,
    'Regalo': Colors.pink,
    'Otros': Colors.grey,
  };
  
  // ===== CONSTANTES DE FORMATO =====
  static const String currencySymbol = '\$';
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  
  // ===== CONSTANTES DE PERÍODOS =====
  static const List<String> periodNames = [
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
  static Color getCategoryColor(String category) {
    return categoryColors[category] ?? Colors.grey;
  }
  
  /// Obtiene el color para una fuente de ingreso
  static Color getSourceColor(String source) {
    return sourceColors[source] ?? Colors.green;
  }
  
  /// Valida si un monto es válido
  static bool isValidAmount(double amount) {
    return amount >= minAmount && amount <= maxAmount;
  }
  
  /// Valida si un título es válido
  static bool isValidTitle(String title) {
    return title.isNotEmpty && title.length <= maxTitleLength;
  }
  
  /// Formatea un monto como moneda
  static String formatCurrency(double amount) {
    return '$currencySymbol${amount.toStringAsFixed(2)}';
  }
  
  /// Obtiene el nombre del período
  static String getPeriodName(int index) {
    if (index >= 0 && index < periodNames.length) {
      return periodNames[index];
    }
    return 'Desconocido';
  }
} 