import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:personal_finance/utils/currency_helper.dart';

import 'package:personal_finance/features/dashboard/domain/entities/dashboard_models.dart';
import 'package:personal_finance/features/domain/entities/expense_entity.dart';
import 'package:personal_finance/features/domain/entities/income_entity.dart';
import 'package:personal_finance/features/domain/usecases/add_transaction_usecase.dart';
import 'package:personal_finance/features/domain/usecases/get_dashboard_data_usecase.dart';
import 'package:personal_finance/features/goals/domain/entities/goal.dart';
import 'package:personal_finance/features/goals/domain/usecases/get_active_goals_usecase.dart';
import 'package:personal_finance/features/budgets/domain/entities/budget.dart';
import 'package:personal_finance/features/budgets/domain/usecases/get_active_budgets_usecase.dart';
import 'package:personal_finance/core/services/vertex_ai_service.dart'
    show FinancialHealthScore, VertexAiService;
import 'package:personal_finance/core/services/notifications/notification_service.dart';
import 'package:personal_finance/features/debts/domain/entities/debt.dart';
import 'package:personal_finance/features/debts/domain/repositories/debt_repository.dart';

/// Lógica del dashboard mejorada siguiendo Clean Architecture
class DashboardLogic extends ChangeNotifier {
  final GetDashboardDataUseCase _getDashboardDataUseCase;
  final AddTransactionUseCase _addTransactionUseCase;
  final GetActiveGoalsUseCase _getActiveGoalsUseCase;
  final GetActiveBudgetsUseCase _getActiveBudgetsUseCase;

  DashboardLogic({
    required GetDashboardDataUseCase getDashboardDataUseCase,
    required AddTransactionUseCase addTransactionUseCase,
    required GetActiveGoalsUseCase getActiveGoalsUseCase,
    required GetActiveBudgetsUseCase getActiveBudgetsUseCase,
  }) : _getDashboardDataUseCase = getDashboardDataUseCase,
       _addTransactionUseCase = addTransactionUseCase,
       _getActiveGoalsUseCase = getActiveGoalsUseCase,
       _getActiveBudgetsUseCase = getActiveBudgetsUseCase;

  // Estado privado
  PeriodFilter _selectedPeriod = PeriodFilter.mes;
  List<ExpenseEntity> _expenses = <ExpenseEntity>[];
  List<IncomeEntity> _incomes = <IncomeEntity>[];
  List<Goal> _goals = <Goal>[];
  Budget? _activeBudget;
  bool _isLoading = false;
  String? _error;
  String? _personalizedTip;
  bool _isLoadingTip = false;
  String? _spendingPrediction;
  bool _isLoadingPrediction = false;
  FinancialHealthScore? _healthScore;
  bool _isLoadingHealthScore = false;

  // Getters públicos
  PeriodFilter get selectedPeriod => _selectedPeriod;
  List<ExpenseEntity> get expenses => _expenses;
  List<IncomeEntity> get incomes => _incomes;
  List<Goal> get goals => _goals;
  Budget? get activeBudget => _activeBudget;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get personalizedTip => _personalizedTip;
  bool get isLoadingTip => _isLoadingTip;
  String? get spendingPrediction => _spendingPrediction;
  bool get isLoadingPrediction => _isLoadingPrediction;
  FinancialHealthScore? get healthScore => _healthScore;
  bool get isLoadingHealthScore => _isLoadingHealthScore;

  // Getters computados
  bool get hasData =>
      _expenses.isNotEmpty || _incomes.isNotEmpty || _goals.isNotEmpty;
  bool get hasExpenses => _expenses.isNotEmpty;
  bool get hasIncomes => _incomes.isNotEmpty;

  // Compatibility getters
  bool get shouldShowExpensesChart => _expenses.isNotEmpty;
  bool get shouldShowIncomesList => _incomes.isNotEmpty;
  bool get shouldShowTransactions =>
      _expenses.isNotEmpty || _incomes.isNotEmpty;

  // Profile type — no-op stub; feature not active in current release.
  // ignore: avoid_unused_parameters
  void setProfileType(String profileType) {}

  // Category filter — used by CategorySelector widget.
  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;
  List<String> get availableCategories => ['Todas', ...expensesByCategory.keys];
  void changeCategory(String category) {
    _selectedCategory = category == 'Todas' ? null : category;
    notifyListeners();
  }

  // Weekly budget spent — sum of expenses in current week vs active budget.
  double get weeklyBudgetSpent {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return _expenses
        .where((e) => !e.date.isBefore(startOfWeek))
        .fold(0, (sum, e) => sum + e.amount);
  }

  /// Mensaje de insight basado en el balance actual. Null si no hay datos.
  String? get insightMessage {
    if (!hasData) return null;
    final double bal = balance;
    if (bal > 0) {
      return 'Tu balance es positivo (${CurrencyHelper.format(bal)}). ¡Buen trabajo manteniendo tus gastos bajo control!';
    } else if (bal < 0) {
      return 'Tus gastos superan tus ingresos en ${CurrencyHelper.format(bal.abs())}. Considera revisar tu presupuesto.';
    }
    return 'Tu balance está equilibrado. Registra más transacciones para obtener insights personalizados.';
  }

  List<IncomeEntity> get filteredIncomes => sortedIncomes;
  List<ChartData> getChartData() => chartData;

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

  List<TransactionItem> getIncomeTransactions({int limit = 5}) =>
      sortedIncomes
          .take(limit)
          .map(
            (IncomeEntity income) => TransactionItem(
              title: income.title,
              amount: income.amount,
              date: income.date,
              isIncome: true,
            ),
          )
          .toList();

  List<TransactionItem> getExpenseTransactions({int limit = 5}) =>
      sortedExpenses
          .take(limit)
          .map(
            (ExpenseEntity expense) => TransactionItem(
              title: expense.title,
              amount: expense.amount,
              date: expense.date,
              isIncome: false,
            ),
          )
          .toList();

  /// Genera recomendaciones dinámicas basadas en los datos del usuario
  List<RecommendationItem> get recommendations {
    final List<RecommendationItem> items = <RecommendationItem>[];

    // Si no hay datos, recomendar empezar
    if (!hasData) {
      items.add(
        const RecommendationItem(
          icon: '📊',
          title: 'Comienza tu viaje',
          description:
              'Registra tus primeras transacciones para obtener recomendaciones personalizadas.',
          actionLabel: 'Agregar transacción',
        ),
      );
      return items;
    }

    // Recomendación: Control de gastos (si gastas más del 80% de ingresos)
    if (totalIncomes > 0 && totalExpenses > totalIncomes * 0.8) {
      items.add(
        RecommendationItem(
          icon: '💳',
          title: 'Controla gastos',
          description:
              'Has gastado ${((totalExpenses / totalIncomes) * 100).toStringAsFixed(0)}% de tus ingresos. Revisa tus gastos.',
          actionLabel: 'Ver detalles',
          accentColor: Colors.red,
          actionType: RecommendationActionType.viewExpenses,
        ),
      );
    }

    // Recomendación: Crear meta de ahorro (si hay balance positivo pero no hay metas)
    if (balance > 0 && _goals.isEmpty) {
      items.add(
        const RecommendationItem(
          icon: '💰',
          title: 'Ahorro',
          description:
              'Tienes un balance positivo. Crea una meta de ahorro para alcanzar tus objetivos.',
          actionLabel: 'Crear meta',
          accentColor: Colors.orange,
          actionType: RecommendationActionType.createGoal,
        ),
      );
    }

    // Recomendación: Invertir (si el balance es muy alto)
    if (balance > totalIncomes * 2) {
      items.add(
        const RecommendationItem(
          icon: '📈',
          title: 'Invierte',
          description:
              'Tu balance es saludable. Considera opciones de inversión para hacer crecer tu dinero.',
          actionLabel: 'Explorar opciones',
          accentColor: Colors.green,
          actionType: RecommendationActionType.viewInvestments,
        ),
      );
    }

    // Recomendación: Balance negativo
    if (balance < 0) {
      items.add(
        RecommendationItem(
          icon: '⚠️',
          title: 'Atención',
          description:
              'Tu balance es negativo. Revisa tus gastos y considera ajustar tu presupuesto.',
          actionLabel: 'Ver gastos',
          accentColor: Colors.red.shade700,
          actionType: RecommendationActionType.viewExpenses,
        ),
      );
    }

    // Si no hay recomendaciones específicas, mostrar una genérica positiva
    if (items.isEmpty) {
      items.add(
        const RecommendationItem(
          icon: '✨',
          title: '¡Buen trabajo!',
          description:
              'Tus finanzas están en buen estado. Sigue registrando tus transacciones.',
          actionLabel: 'Continuar',
          accentColor: Colors.green,
        ),
      );
    }

    return items;
  }

  List<TransactionItem> getRecentTransactions({int limit = 5}) {
    final List<TransactionItem> allItems = <TransactionItem>[
      ..._expenses.map(
        (ExpenseEntity e) => TransactionItem(
          title: e.title,
          amount: e.amount,
          date: e.date,
          isIncome: false,
        ),
      ),
      ..._incomes.map(
        (IncomeEntity i) => TransactionItem(
          title: i.title,
          amount: i.amount,
          date: i.date,
          isIncome: true,
        ),
      ),
    ];

    allItems.sort(
      (TransactionItem a, TransactionItem b) => b.date.compareTo(a.date),
    );
    return allItems.take(limit).toList();
  }

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

      final either = await _getDashboardDataUseCase.execute(params);
      late final DashboardResult result;
      either.fold(
        (failure) => throw Exception(failure.toString()),
        (data) => result = data,
      );

      // Fetch goals and budgets in parallel could be better, but sequential for simplicity first
      // or better yet, move this to the use case if they were part of "Dashboard Data".
      // Since they are separate features, we fetch them here.

      final goalsResult = await _getActiveGoalsUseCase.execute();
      goalsResult.fold((failure) => _goals = [], (goals) => _goals = goals);

      final budgetsResult = await _getActiveBudgetsUseCase.execute();
      budgetsResult.fold((failure) => _activeBudget = null, (budgets) {
        // For now take the first one or logic to find active
        if (budgets.isNotEmpty) {
          _activeBudget = budgets.first;
        } else {
          _activeBudget = null;
        }
      });

      _expenses = result.expenses;
      _incomes = result.incomes;

      notifyListeners();

      // Iniciar cargas asíncronas de IA y reprogramar notificaciones
      fetchPersonalizedTip();
      fetchSpendingPrediction();
      fetchHealthScore();
      _rescheduleLocalNotifications();
    } catch (e) {
      _setError('Error al cargar datos: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Calcula la racha actual de ahorro (días consecutivos registrando transacciones)
  int get savingsStreak {
    final List<DateTime> dates = <DateTime>[
      ..._expenses.map((e) => e.date),
      ..._incomes.map((i) => i.date),
    ];
    if (dates.isEmpty) return 0;

    final uniqueDates =
        dates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()
          ..sort((a, b) => b.compareTo(a));

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final yesterday = today.subtract(const Duration(days: 1));

    if (uniqueDates.isEmpty ||
        (uniqueDates.first != today && uniqueDates.first != yesterday)) {
      return 0;
    }

    int streak = 0;
    DateTime currentDay = uniqueDates.first;

    for (final date in uniqueDates) {
      if (date == currentDay) {
        streak++;
        currentDay = currentDay.subtract(const Duration(days: 1));
      } else if (date.isBefore(currentDay)) {
        break;
      }
    }
    return streak;
  }

  /// Obtiene un consejo financiero personalizado desde Vertex AI in Firebase (Gemini)
  Future<void> fetchPersonalizedTip() async {
    if (!hasData) return;
    _isLoadingTip = true;
    notifyListeners();
    try {
      final aiService = GetIt.instance<VertexAiService>();

      List<Debt> activeDebts = [];
      try {
        final debtRepository = GetIt.instance<DebtRepository>();
        final debtsResult = await debtRepository.getDebts();
        debtsResult.fold(
          (failure) =>
              debugPrint('Error al cargar deudas para Gemini: $failure'),
          (debts) => activeDebts = debts,
        );
      } catch (e) {
        debugPrint('Error al instanciar o usar DebtRepository: $e');
      }

      _personalizedTip = await aiService.getPersonalizedTip(
        _expenses,
        _incomes,
        goals: _goals,
        debts: activeDebts,
      );
    } catch (e) {
      debugPrint('Error al obtener consejo personalizado de Gemini: $e');
    } finally {
      _isLoadingTip = false;
      notifyListeners();
    }
  }

  /// Genera predicción de gasto para la próxima semana usando Gemini.
  Future<void> fetchSpendingPrediction() async {
    if (_expenses.isEmpty) return;
    _isLoadingPrediction = true;
    notifyListeners();
    try {
      final aiService = GetIt.instance<VertexAiService>();
      _spendingPrediction = await aiService.getSpendingPrediction(
        _expenses,
        _incomes,
      );
    } catch (e) {
      debugPrint('Error al obtener predicción de gastos: $e');
    } finally {
      _isLoadingPrediction = false;
      notifyListeners();
    }
  }

  /// Calcula el score de salud financiera 0–100 usando Gemini.
  Future<void> fetchHealthScore() async {
    if (totalIncomes == 0 && totalExpenses == 0) return;
    _isLoadingHealthScore = true;
    notifyListeners();
    try {
      final aiService = GetIt.instance<VertexAiService>();

      double goalsProgress = 0;
      if (_goals.isNotEmpty) {
        goalsProgress =
            _goals.fold<double>(0, (sum, g) {
              final pct =
                  g.objetivoAsDouble > 0
                      ? (g.actualAsDouble / g.objetivoAsDouble * 100).clamp(
                        0,
                        100,
                      )
                      : 0.0;
              return sum + pct;
            }) /
            _goals.length;
      }

      List<Debt> debts = [];
      try {
        final debtRepository = GetIt.instance<DebtRepository>();
        final result = await debtRepository.getDebts();
        result.fold((_) {}, (d) => debts = d);
      } catch (_) {}

      final totalDebtBalance = debts.fold<double>(
        0,
        (s, d) => s + d.currentBalance,
      );

      _healthScore = await aiService.getFinancialHealthScore(
        totalIncomes: totalIncomes,
        totalExpenses: totalExpenses,
        activeGoals: _goals.length,
        activeDebts: debts.length,
        goalsProgress: goalsProgress,
        totalDebtBalance: totalDebtBalance,
      );
    } catch (e) {
      debugPrint('Error al calcular health score: $e');
    } finally {
      _isLoadingHealthScore = false;
      notifyListeners();
    }
  }

  /// Reprograma las notificaciones locales con los datos actualizados
  Future<void> _rescheduleLocalNotifications() async {
    try {
      final notifService = GetIt.instance<NotificationService>();
      await notifService.local.scheduleStreakReminder(savingsStreak);
      await notifService.local.scheduleWeeklySummary();
    } catch (e) {
      debugPrint('Error reprogramando notificaciones locales: $e');
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

  void changePeriod(PeriodFilter period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      loadDashboardData();
    }
  }

  // Métodos de utilidad
  String formatCurrency(double amount) => CurrencyHelper.format(amount);

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
      case PeriodFilter.historico:
        return DateTimeRange(start: DateTime(2000), end: DateTime(3000));
      case PeriodFilter.personalizado:
        // Custom range not implemented in this view — fall back to current month.
        final DateTime startOfMonth = DateTime(now.year, now.month);
        final DateTime endOfMonth = DateTime(now.year, now.month + 1, 0);
        return DateTimeRange(
          start: startOfMonth,
          end: endOfMonth.add(const Duration(days: 1)),
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
