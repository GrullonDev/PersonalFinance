import 'package:flutter/material.dart';

import 'package:hive/hive.dart';

import 'package:personal_finance/features/data/model/expense.dart';
import 'package:personal_finance/features/data/model/income.dart';

class DashboardLogic extends ChangeNotifier {
  final List<Income> _incomes = <Income>[];

  List<Income> get incomes => _incomes;

  final Box<Expense> _expenseBox = Hive.box<Expense>('expenses');
  final Box<Income> _incomeBox = Hive.box<Income>('incomes');

  double calculateTotalExpenses(List<Expense> expenses) {
    return expenses.fold(
      0.0,
      (double sum, Expense expense) => sum + expense.amount,
    );
  }

  double calculateTotalIncome(List<Income?> incomes) {
    return incomes.whereType<Income>().fold(
      0.0,
      (double sum, Income income) => sum + income.amount,
    );
  }

  double calculateBalance(double totalIncome, double totalExpenses) {
    return totalIncome - totalExpenses;
  }

  void addExpense(String title, String amount, DateTime date) {
    if (title.isEmpty || amount.isEmpty) return;

    final Expense expense = Expense(
      title: title,
      amount: double.tryParse(amount) ?? 0.0,
      date: date,
      category: getCategory(title),
    );

    _expenseBox.add(expense);
    notifyListeners();
  }

  // Método para agregar ingresos
  void addIncome(String title, String amount, DateTime date) {
    if (title.isEmpty || amount.isEmpty) return;

    final Income newIncome = Income(
      title: title,
      amount: double.parse(amount),
      date: date,
    );

    // Guardar en Hive
    _incomeBox.add(newIncome);

    notifyListeners();
  }

  // Método para asignar una categoría basada en el título del gasto
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

    for (String key in categories.keys) {
      if (title.toLowerCase().contains(key)) {
        return categories[key]!;
      }
    }
    return 'Otros'; // Si no coincide con ninguna categoría, se asigna "Otros"
  }

  // Añade estos métodos a tu clase DashboardLogic

  Map<String, double> calculateExpensesByCategory(List<Expense> expenses) {
    final Map<String, double> result = <String, double>{};

    for (final Expense expense in expenses) {
      final String category = expense.category ?? 'Otros';
      result.update(
        category,
        (double value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    return result;
  }

  List<Map<String, dynamic>> getExpensesByCategoryForChart(
    List<Expense> expenses,
  ) {
    final Map<String, double> byCategory = calculateExpensesByCategory(
      expenses,
    );

    return byCategory.entries.map((MapEntry<String, double> entry) {
      return <String, Object>{'category': entry.key, 'amount': entry.value};
    }).toList();
  }
}
