import 'package:flutter/material.dart';

import 'package:hive/hive.dart';

import 'package:personal_finance/features/data/model/expense.dart';
import 'package:personal_finance/features/data/model/income.dart';

enum PeriodFilter { dia, semana, mes, anio }

class DashboardLogic extends ChangeNotifier {
  final Box<Expense> _expenseBox = Hive.box<Expense>('expenses');
  final Box<Income> _incomeBox = Hive.box<Income>('incomes');

  PeriodFilter _selectedPeriod = PeriodFilter.mes;

  PeriodFilter get selectedPeriod => _selectedPeriod;

  void changePeriod(PeriodFilter period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  double calculateTotalExpenses(List<Expense> expenses) {
    return expenses.fold(0.0, (double sum, Expense e) => sum + e.amount);
  }

  double calculateTotalIncome(List<Income> incomes) {
    return incomes.fold(0.0, (double sum, Income i) => sum + i.amount);
  }

  double calculateBalance(double totalIncome, double totalExpenses) {
    return totalIncome - totalExpenses;
  }

  void addExpense(
    String title,
    String amount,
    DateTime date,
    String? category,
  ) {
    if (title.isEmpty || amount.isEmpty) return;

    final Expense expense = Expense(
      title: title,
      amount: double.tryParse(amount) ?? 0.0,
      date: date,
      category: category ?? getCategory(title),
    );

    _expenseBox.add(expense);
    notifyListeners();
  }

  void addIncome(String title, String amount, DateTime date) {
    if (title.isEmpty || amount.isEmpty) return;

    final Income income = Income(
      title: title,
      amount: double.tryParse(amount) ?? 0.0,
      date: date,
    );

    _incomeBox.add(income);
    notifyListeners();
  }

  String getCategory(String title) {
    final Map<String, String> categories = <String, String>{
      'comida': 'Alimentación',
      'restaurante': 'Alimentación',
      'supermercado': 'Alimentación',
      'transporte': 'Transporte',
      'gasolina': 'Transporte',
      'uber': 'Transporte',
      'casa': 'Hogar',
      'renta': 'Hogar',
      'luz': 'Hogar',
      'agua': 'Hogar',
      'internet': 'Hogar',
      'telefono': 'Hogar',
      'cine': 'Entretenimiento',
      'netflix': 'Entretenimiento',
      'spotify': 'Entretenimiento',
      'ropa': 'Compras',
      'zapatos': 'Compras',
      'electronica': 'Compras',
      'medico': 'Salud',
      'hospital': 'Salud',
      'medicina': 'Salud',
    };

    for (final String key in categories.keys) {
      if (title.toLowerCase().contains(key)) return categories[key]!;
    }

    return 'Otros';
  }

  Map<String, double> calculateExpensesByCategory(List<Expense> expenses) {
    final Map<String, double> result = <String, double>{};

    for (final Expense e in expenses) {
      final String cat = e.category ?? 'Otros';
      result.update(
        cat,
        (double val) => val + e.amount,
        ifAbsent: () => e.amount,
      );
    }

    return result;
  }

  List<Expense> filterExpensesBySelectedPeriod() {
    final DateTime now = DateTime.now();
    return _expenseBox.values.where((Expense e) {
      return _matchesPeriod(e.date, now);
    }).toList();
  }

  List<Income> filterIncomesBySelectedPeriod() {
    final DateTime now = DateTime.now();
    return _incomeBox.values.where((Income i) {
      return _matchesPeriod(i.date, now);
    }).toList();
  }

  bool _matchesPeriod(DateTime date, DateTime now) {
    switch (_selectedPeriod) {
      case PeriodFilter.dia:
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case PeriodFilter.semana:
        final DateTime startOfWeek = now.subtract(
          Duration(days: now.weekday - 1),
        );
        final DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
        return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            date.isBefore(endOfWeek.add(const Duration(days: 1)));
      case PeriodFilter.mes:
        return date.year == now.year && date.month == now.month;
      case PeriodFilter.anio:
        return date.year == now.year;
    }
  }
}
