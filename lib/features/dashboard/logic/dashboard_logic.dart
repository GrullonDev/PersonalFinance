import 'package:flutter/material.dart';

import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import 'package:personal_finance/features/dashboard/logic/dashboard_models.dart';
import 'package:personal_finance/features/data/model/expense.dart';
import 'package:personal_finance/features/data/model/income.dart';
import 'package:personal_finance/utils/app_localization.dart';
import 'package:personal_finance/utils/offline_sync_service.dart';
import 'package:personal_finance/utils/pending_action.dart';

class DashboardLogic extends ChangeNotifier {
  final Box<Expense> _expenseBox = Hive.box<Expense>('expenses');
  final Box<Income> _incomeBox = Hive.box<Income>('incomes');

  PeriodFilter _selectedPeriod = PeriodFilter.mes;
  DateTimeRange? _customPeriod;
  String? _categoryFilter;

  PeriodFilter get selectedPeriod => _selectedPeriod;
  DateTimeRange? get customPeriod => _customPeriod;
  String? get selectedCategory => _categoryFilter;

  // Getters para datos filtrados
  List<Expense> get filteredExpenses => filterExpensesBySelectedPeriod();
  List<Income> get filteredIncomes => filterIncomesBySelectedPeriod();

  // Getters para cálculos
  double get totalExpenses => calculateTotalExpenses(filteredExpenses);
  double get totalIncomes => calculateTotalIncome(filteredIncomes);
  double get balance => calculateBalance(totalIncomes, totalExpenses);
  Map<String, double> get expensesByCategory =>
      calculateExpensesByCategory(filteredExpenses);
  List<String> get availableCategories =>
      <String>{
        'Todas',
        ..._expenseBox.values.map((Expense e) => e.category),
      }.toList();

  // Getters para transacciones ordenadas
  List<Income> get sortedIncomes {
    final List<Income> incomes = List<Income>.from(filteredIncomes);
    incomes.sort((Income a, Income b) => b.date.compareTo(a.date));
    return incomes;
  }

  List<Expense> get sortedExpenses {
    final List<Expense> expenses = List<Expense>.from(filteredExpenses);
    expenses.sort((Expense a, Expense b) => b.date.compareTo(a.date));
    return expenses;
  }

  // Getters para verificar si hay datos
  bool get hasExpenses => filteredExpenses.isNotEmpty;
  bool get hasIncomes => filteredIncomes.isNotEmpty;
  bool get hasData => hasExpenses || hasIncomes;

  void changePeriod(PeriodFilter period, {DateTimeRange? range}) {
    _selectedPeriod = period;
    if (range != null) {
      _customPeriod = range;
    }
    notifyListeners();
  }

  void changeCategory(String? category) {
    _categoryFilter = category == 'Todas' ? null : category;
    notifyListeners();
  }

  double calculateTotalExpenses(List<Expense> expenses) =>
      expenses.fold(0, (double sum, Expense e) => sum + e.amount);

  double calculateTotalIncome(List<Income> incomes) =>
      incomes.fold(0, (double sum, Income i) => sum + i.amount);

  double calculateBalance(double totalIncome, double totalExpenses) =>
      totalIncome - totalExpenses;

  Future<void> addExpense(
    String title,
    String amount,
    DateTime date,
    String? category,
  ) async {
    if (title.isEmpty || amount.isEmpty) return;

    final double parsedAmount = double.tryParse(amount) ?? 0.0;
    if (parsedAmount <= 0) return;

    final Expense expense = Expense(
      title: title,
      amount: parsedAmount,
      date: date,
      category: category ?? getCategory(title),
    );

    await _expenseBox.add(expense);
    notifyListeners();
  }

  Future<void> addIncome(String title, String amount, DateTime date) async {
    if (title.isEmpty || amount.isEmpty) return;

    final double parsedAmount = double.tryParse(amount) ?? 0.0;
    if (parsedAmount <= 0) return;

    final Income income = Income(
      title: title,
      amount: parsedAmount,
      date: date,
    );

    await _incomeBox.add(income);
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
      final String cat = e.category;
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
    return _expenseBox.values
        .where((Expense e) => _matchesPeriod(e.date, now))
        .where(
          (Expense e) =>
              _categoryFilter == null || e.category == _categoryFilter,
        )
        .toList();
  }

  List<Income> filterIncomesBySelectedPeriod() {
    final DateTime now = DateTime.now();
    return _incomeBox.values
        .where((Income i) => _matchesPeriod(i.date, now))
        .toList();
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
      case PeriodFilter.personalizado:
        if (_customPeriod == null) return true;
        return date.isAfter(
              _customPeriod!.start.subtract(const Duration(days: 1)),
            ) &&
            date.isBefore(_customPeriod!.end.add(const Duration(days: 1)));
    }
  }

  // Métodos para obtener colores de categorías
  Color getCategoryColor(String category) {
    final Map<String, MaterialColor> colors = <String, MaterialColor>{
      'Alimentación': Colors.orange,
      'Transporte': Colors.blue,
      'Hogar': Colors.purple,
      'Entretenimiento': Colors.pink,
      'Compras': Colors.teal,
      'Salud': Colors.red,
      'Créditos': Colors.indigo,
      'Otros': Colors.grey,
    };
    return colors[category] ?? Colors.grey;
  }

  // Métodos para datos del gráfico
  List<ChartData> getChartData() {
    if (expensesByCategory.isEmpty) return <ChartData>[];

    return expensesByCategory.entries
        .map(
          (MapEntry<String, double> e) => ChartData(
            category: e.key,
            amount: e.value,
            color: getCategoryColor(e.key),
          ),
        )
        .toList();
  }

  // Métodos para transacciones
  List<TransactionItem> getIncomeTransactions({int limit = 5}) =>
      sortedIncomes
          .take(limit)
          .map(
            (Income i) => TransactionItem(
              title: i.title,
              amount: i.amount,
              date: i.date,
              isIncome: true,
            ),
          )
          .toList();

  List<TransactionItem> getExpenseTransactions({int limit = 5}) =>
      sortedExpenses
          .take(limit)
          .map(
            (Expense e) => TransactionItem(
              title: e.title,
              amount: e.amount,
              date: e.date,
              isIncome: false,
            ),
          )
          .toList();

  // Métodos para formateo de datos
  String formatCurrency(double amount) => AppLocalizations(
    Locale(Intl.getCurrentLocale()),
  ).currencyFormatter.format(amount);

  String formatPercentage(double value, double total) {
    if (total == 0) return '0%';
    final NumberFormat percentFormatter = NumberFormat.decimalPercentPattern(
      locale: Intl.getCurrentLocale(),
      decimalDigits: 0,
    );
    return percentFormatter.format(value / total);
  }

  String formatDate(DateTime date) =>
      AppLocalizations(Locale(Intl.getCurrentLocale())).formatDate(date);

  // Métodos para validaciones
  bool get shouldShowExpensesChart =>
      hasExpenses && expensesByCategory.isNotEmpty;
  bool get shouldShowExpensesList =>
      hasExpenses && expensesByCategory.isNotEmpty;
  bool get shouldShowIncomesList => hasIncomes;
  bool get shouldShowTransactions => hasExpenses || hasIncomes;

  // Ejemplo dentro de una función que agrega un gasto
  Future<void> agregarGasto(Map<String, dynamic> gasto) async {
    // ... lógica normal ...
    // Si no hay conexión, registrar acción pendiente
    final PendingAction action = PendingAction(
      type: 'create',
      data: gasto,
      timestamp: DateTime.now(),
    );
    await OfflineSyncService().addPendingAction(action);
  }
}
