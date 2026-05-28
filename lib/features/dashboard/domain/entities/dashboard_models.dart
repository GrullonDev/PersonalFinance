import 'package:flutter/material.dart';

enum PeriodFilter { 
  dia, 
  semana, 
  mes, 
  anio, 
  personalizado, 
  historico 
}

extension PeriodFilterExtension on PeriodFilter {
  String get label {
    switch (this) {
      case PeriodFilter.dia: return 'Hoy';
      case PeriodFilter.semana: return 'Esta Semana';
      case PeriodFilter.mes: return 'Este Mes';
      case PeriodFilter.anio: return 'Este Año';
      case PeriodFilter.personalizado: return 'Personalizado';
      case PeriodFilter.historico: return 'Histórico';
    }
  }
}

class ChartData {
  final String category;
  final double amount;
  final Color color;

  const ChartData({
    required this.category,
    required this.amount,
    required this.color,
  });
}

class TransactionItem {
  final String title;
  final double amount;
  final DateTime date;
  final bool isIncome;

  const TransactionItem({
    required this.title,
    required this.amount,
    required this.date,
    required this.isIncome,
  });
}

enum RecommendationType { savings, investment, budgetAlert, goal, tip, trend }

enum RecommendationActionType {
  none,
  viewExpenses,
  createGoal,
  viewInvestments,
  createBudgetAlert,
}

class RecommendationItem {
  final String icon;
  final String title;
  final String description;
  final String actionLabel;
  final Color accentColor;
  final RecommendationActionType actionType;
  final Map<String, dynamic>? metadata;

  const RecommendationItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    this.accentColor = Colors.blue,
    this.actionType = RecommendationActionType.none,
    this.metadata,
  });
}
