import 'package:flutter/material.dart';

/// Enumeración para filtros de período
enum PeriodFilter { dia, semana, mes, anio,   personalizado,
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
