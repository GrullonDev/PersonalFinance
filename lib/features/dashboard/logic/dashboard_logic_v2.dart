import 'package:flutter/material.dart';

import 'package:personal_finance/features/dashboard/logic/dashboard_models.dart';
import 'package:personal_finance/features/domain/entities/expense_entity.dart';
import 'package:personal_finance/features/domain/entities/income_entity.dart';
import 'package:personal_finance/features/domain/usecases/add_transaction_usecase.dart';
import 'package:personal_finance/features/domain/usecases/get_dashboard_data_usecase.dart';

/// Lógica del dashboard mejorada siguiendo Clean Architecture
class DashboardLogicV2 extends ChangeNotifier {
  final GetDashboardDataUseCase _getDashboardDataUseCase;
  final AddTransactionUseCase _addTransactionUseCase;

  DashboardLogicV2({
    required GetDashboardDataUseCase getDashboardDataUseCase,
    required AddTransactionUseCase addTransactionUseCase,
  }) : _getDashboardDataUseCase = getDashboardDataUseCase,
       _addTransactionUseCase = addTransactionUseCase;

  // Estado privado
  PeriodFilter _selectedPeriod = PeriodFilter.mes;
  DateTimeRange? _customPeriod;
  String? _categoryFilter;
  List<ExpenseEntity> _expenses = <ExpenseEntity>[];
  List<IncomeEntity> _incomes = <IncomeEntity>[];
  bool _isLoading = false;
  String? _error;

  // Getters públicos
  PeriodFilter get selectedPeriod => _selectedPeriod;
  DateTimeRange? get customPeriod => _customPeriod;
  String? get selectedCategory => _categoryFilter;
  List<ExpenseEntity> get expenses => _expenses;
  List<IncomeEntity> get incomes => _incomes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Getters computados
  bool get hasData => _expenses.isNotEmpty || _incomes.isNotEmpty;
  bool get hasExpenses => _expenses.isNotEmpty;
  bool get hasIncomes => _incomes.isNotEmpty;

  double get totalExpenses => _expenses.fold<double>(
    0,
    (double sum, ExpenseEntity expense) => sum + expense.amount,
  );
  double get totalIncomes => _incomes.fold<double>(
    0,
    (double sum, IncomeEntity income) => sum + income.amount,
  );
  double get balance => totalIncomes - totalExpenses;

  List<ExpenseEntity> get sortedExpenses {
    final List<ExpenseEntity> sorted = List<ExpenseEntity>.from(_expenses);
    sorted.sort((ExpenseEntity a, ExpenseEntity b) => b.date.compareTo(a.date));
    return sorted;
  }

  List<IncomeEntity> get sortedIncomes {
    final List<IncomeEntity> sorted = List<IncomeEntity>.from(_incomes);
    sorted.sort((IncomeEntity a, IncomeEntity b) => b.date.compareTo(a.date));
    return sorted;
  }

  Map<String, double> get expensesByCategory {
    final Map<String, double> categoryMap = <String, double>{};
    for (final ExpenseEntity expense in _expenses) {
      categoryMap[expense.category] =
          (categoryMap[expense.category] ?? 0) + expense.amount;
    }
    return categoryMap;
  }

  List<String> get availableCategories =>
      <String>{
        'Todas',
        ..._expenses.map((ExpenseEntity e) => e.category),
      }.toList();

  List<ChartData> get chartData {
    final Map<String, double> categoryMap = expensesByCategory;
    final List<ChartData> data = <ChartData>[];
    final List<Color> colors = <Color>[
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    int colorIndex = 0;
    categoryMap.forEach((String category, double amount) {
      data.add(
        ChartData(
          category: category,
          amount: amount,
          color: colors[colorIndex % colors.length],
        ),
      );
      colorIndex++;
    });

    return data;
  }

  List<TransactionItem> getIncomeTransactions() =>
      sortedIncomes
          .take(5)
          .map(
            (IncomeEntity income) => TransactionItem(
              title: income.title,
              amount: income.amount,
              date: income.date,
              isIncome: true,
            ),
          )
          .toList();

  List<TransactionItem> getExpenseTransactions() =>
      sortedExpenses
          .take(5)
          .map(
            (ExpenseEntity expense) => TransactionItem(
              title: expense.title,
              amount: expense.amount,
              date: expense.date,
              isIncome: false,
            ),
          )
          .toList();

  // Métodos públicos
  Future<void> loadDashboardData() async {
    _setLoading(true);
    _clearError();

    try {
      final DateTimeRange dateRange = _getDateRangeForPeriod(_selectedPeriod);
      final DashboardParams params = DashboardParams(
        startDate: dateRange.start,
        endDate: dateRange.end,
      );

      final DashboardResult result = await _getDashboardDataUseCase.execute(
        params,
      );

      _expenses =
          result.expenses
              .where(
                (ExpenseEntity e) =>
                    _categoryFilter == null || e.category == _categoryFilter,
              )
              .toList();
      _incomes = result.incomes;

      notifyListeners();
    } catch (e) {
      _setError('Error al cargar datos: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addExpense({
    required String title,
    required String amount,
    required DateTime date,
    required String category,
    String? description,
    String? notes,
  }) async {
    try {
      final double parsedAmount = double.tryParse(amount) ?? 0.0;
      if (parsedAmount <= 0) {
        throw Exception('El monto debe ser mayor a 0');
      }

      final AddExpenseParams params = AddExpenseParams(
        title: title,
        amount: parsedAmount,
        date: date,
        category: category,
        description: description,
        notes: notes,
      );

      await _addTransactionUseCase.addExpense(params);
      await loadDashboardData(); // Recargar datos
    } catch (e) {
      _setError('Error al agregar gasto: $e');
    }
  }

  Future<void> addIncome({
    required String title,
    required String amount,
    required DateTime date,
    required String source,
    String? description,
    String? notes,
  }) async {
    try {
      final double parsedAmount = double.tryParse(amount) ?? 0.0;
      if (parsedAmount <= 0) {
        throw Exception('El monto debe ser mayor a 0');
      }

      final AddIncomeParams params = AddIncomeParams(
        title: title,
        amount: parsedAmount,
        date: date,
        source: source,
        description: description,
        notes: notes,
      );

      await _addTransactionUseCase.addIncome(params);
      await loadDashboardData(); // Recargar datos
    } catch (e) {
      _setError('Error al agregar ingreso: $e');
    }
  }

  void changePeriod(PeriodFilter period, {DateTimeRange? range}) {
    if (_selectedPeriod != period || range != null) {
      _selectedPeriod = period;
      if (range != null) {
        _customPeriod = range;
      }
      loadDashboardData();
    }
  }

  void changeCategory(String? category) {
    _categoryFilter = category == 'Todas' ? null : category;
    loadDashboardData();
  }

  // Métodos de utilidad
  String formatCurrency(double amount) => '\$${amount.toStringAsFixed(2)}';

  String formatPercentage(double value, double total) {
    if (total == 0) return '0%';
    final double percentage = (value / total) * 100;
    return '${percentage.toStringAsFixed(1)}%';
  }

  String formatDate(DateTime date) {
    final List<String> months = <String>[
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'alimentación':
      case 'comida':
        return Colors.red;
      case 'transporte':
        return Colors.blue;
      case 'entretenimiento':
        return Colors.green;
      case 'salud':
        return Colors.teal;
      case 'educación':
        return Colors.orange;
      case 'vivienda':
        return Colors.purple;
      case 'ropa':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  // Métodos privados
  DateTimeRange _getDateRangeForPeriod(PeriodFilter period) {
    final DateTime now = DateTime.now();
    final DateTime startOfDay = DateTime(now.year, now.month, now.day);

    switch (period) {
      case PeriodFilter.dia:
        return DateTimeRange(
          start: startOfDay,
          end: startOfDay.add(const Duration(days: 1)),
        );
      case PeriodFilter.semana:
        final DateTime startOfWeek = startOfDay.subtract(
          Duration(days: now.weekday - 1),
        );
        return DateTimeRange(
          start: startOfWeek,
          end: startOfWeek.add(const Duration(days: 7)),
        );
      case PeriodFilter.mes:
        final DateTime startOfMonth = DateTime(now.year, now.month);
        final DateTime endOfMonth = DateTime(now.year, now.month + 1, 0);
        return DateTimeRange(
          start: startOfMonth,
          end: endOfMonth.add(const Duration(days: 1)),
        );
      case PeriodFilter.anio:
        final DateTime startOfYear = DateTime(now.year);
        final DateTime endOfYear = DateTime(now.year, 12, 31);
        return DateTimeRange(
          start: startOfYear,
          end: endOfYear.add(const Duration(days: 1)),
        );
      case PeriodFilter.personalizado:
        return _customPeriod ??
            DateTimeRange(
              start: startOfDay,
              end: startOfDay.add(const Duration(days: 1)),
            );
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
