import 'package:flutter/material.dart';

/// Enumeración para filtros de período
enum PeriodFilter { dia, semana, mes, anio, historico, personalizado }

extension PeriodFilterExtension on PeriodFilter {
  String get label {
    switch (this) {
      case PeriodFilter.dia:
        return 'Hoy';
      case PeriodFilter.semana:
        return 'Semana';
      case PeriodFilter.mes:
        return 'Mes';
      case PeriodFilter.anio:
        return 'Año';
      case PeriodFilter.historico:
        return 'Todo';
      case PeriodFilter.personalizado:
        return 'Personalizado';
    }
  }
}

/// Datos para el gráfico
class ChartData {
  final String category;
  final double amount;
  final Color color;

  ChartData({
    required this.category,
    required this.amount,
    required this.color,
  });
}

/// Elemento de transacción para mostrar en la UI
class TransactionItem {
  final String title;
  final double amount;
  final DateTime date;
  final bool isIncome;

  TransactionItem({
    required this.title,
    required this.amount,
    required this.date,
    required this.isIncome,
  });
}

/// Tipos de acción para recomendaciones
enum RecommendationActionType {
  createGoal,
  viewExpenses,
  viewInvestments,
  none,
}

/// Modelo de Recomendación
class RecommendationItem {
  final String icon;
  final String title;
  final String description;
  final String actionLabel;
  final Color accentColor;
  final RecommendationActionType actionType;

  RecommendationItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.accentColor,
    required this.actionType,
  });
}
