import 'package:flutter/material.dart';
import 'package:personal_finance/features/dashboard/logic/dashboard_logic.dart';
import 'package:personal_finance/features/dashboard/logic/dashboard_logic_v2.dart';
import 'package:personal_finance/features/dashboard/logic/dashboard_models.dart';

/// Adaptador que permite usar tanto DashboardLogic como DashboardLogicV2
/// Implementa el patrón Adapter para compatibilidad
abstract class DashboardLogicAdapter {
  // Getters básicos
  bool get hasData;
  bool get hasExpenses;
  bool get hasIncomes;
  double get totalExpenses;
  double get totalIncomes;
  double get balance;

  // Getters para UI
  bool get shouldShowExpensesChart;
  bool get shouldShowIncomesList;
  bool get shouldShowTransactions;

  // Datos ordenados
  List<dynamic> get sortedExpenses;
  List<dynamic> get sortedIncomes;

  // Datos para gráficos y listas
  Map<String, double> get expensesByCategory;
  List<ChartData> get chartData;

  // Métodos de utilidad
  String formatCurrency(double amount);
  String formatPercentage(double value, double total);
  String formatDate(DateTime date);
  Color getCategoryColor(String category);

  // Métodos de transacciones
  List<TransactionItem> getIncomeTransactions();
  List<TransactionItem> getExpenseTransactions();

  // Métodos de período
  PeriodFilter get selectedPeriod;
  void changePeriod(PeriodFilter period);
}

/// Adaptador para DashboardLogic original
class DashboardLogicAdapterV1 implements DashboardLogicAdapter {
  final DashboardLogic _logic;

  DashboardLogicAdapterV1(this._logic);

  @override
  bool get hasData => _logic.hasData;

  @override
  bool get hasExpenses => _logic.hasExpenses;

  @override
  bool get hasIncomes => _logic.hasIncomes;

  @override
  double get totalExpenses => _logic.totalExpenses;

  @override
  double get totalIncomes => _logic.totalIncomes;

  @override
  double get balance => _logic.balance;

  @override
  bool get shouldShowExpensesChart => _logic.shouldShowExpensesChart;

  @override
  bool get shouldShowIncomesList => _logic.shouldShowIncomesList;

  @override
  bool get shouldShowTransactions => _logic.shouldShowTransactions;

  @override
  List<dynamic> get sortedExpenses => _logic.sortedExpenses;

  @override
  List<dynamic> get sortedIncomes => _logic.sortedIncomes;

  @override
  Map<String, double> get expensesByCategory => _logic.expensesByCategory;

  @override
  List<ChartData> get chartData => _logic.getChartData();

  @override
  String formatCurrency(double amount) => _logic.formatCurrency(amount);

  @override
  String formatPercentage(double value, double total) =>
      _logic.formatPercentage(value, total);

  @override
  String formatDate(DateTime date) => _logic.formatDate(date);

  @override
  Color getCategoryColor(String category) => _logic.getCategoryColor(category);

  @override
  List<TransactionItem> getIncomeTransactions() =>
      _logic.getIncomeTransactions();

  @override
  List<TransactionItem> getExpenseTransactions() =>
      _logic.getExpenseTransactions();

  @override
  PeriodFilter get selectedPeriod => _logic.selectedPeriod;

  @override
  void changePeriod(PeriodFilter period) => _logic.changePeriod(period);
}

/// Adaptador para DashboardLogicV2
class DashboardLogicAdapterV2 implements DashboardLogicAdapter {
  final DashboardLogicV2 _logic;

  DashboardLogicAdapterV2(this._logic);

  @override
  bool get hasData => _logic.hasData;

  @override
  bool get hasExpenses => _logic.hasExpenses;

  @override
  bool get hasIncomes => _logic.hasIncomes;

  @override
  double get totalExpenses => _logic.totalExpenses;

  @override
  double get totalIncomes => _logic.totalIncomes;

  @override
  double get balance => _logic.balance;

  @override
  bool get shouldShowExpensesChart =>
      _logic.hasExpenses && _logic.expensesByCategory.isNotEmpty;

  @override
  bool get shouldShowIncomesList => _logic.hasIncomes;

  @override
  bool get shouldShowTransactions => _logic.hasExpenses || _logic.hasIncomes;

  @override
  List<dynamic> get sortedExpenses => _logic.sortedExpenses;

  @override
  List<dynamic> get sortedIncomes => _logic.sortedIncomes;

  @override
  Map<String, double> get expensesByCategory => _logic.expensesByCategory;

  @override
  List<ChartData> get chartData => _logic.chartData;

  @override
  String formatCurrency(double amount) => _logic.formatCurrency(amount);

  @override
  String formatPercentage(double value, double total) =>
      _logic.formatPercentage(value, total);

  @override
  String formatDate(DateTime date) => _logic.formatDate(date);

  @override
  Color getCategoryColor(String category) => _logic.getCategoryColor(category);

  @override
  List<TransactionItem> getIncomeTransactions() =>
      _logic.getIncomeTransactions();

  @override
  List<TransactionItem> getExpenseTransactions() =>
      _logic.getExpenseTransactions();

  @override
  PeriodFilter get selectedPeriod => _logic.selectedPeriod;

  @override
  void changePeriod(PeriodFilter period) => _logic.changePeriod(period);
}
